module ShadeYourData

# originally from https://github.com/cjdoris/ShadeYourData.jl

import Base.Threads: @threads
import Makie: Makie, FRect3D, lift, (..)

struct Canvas{T}
    xmin :: T
    xmax :: T
    xsize :: Int
    ymin :: T
    ymax :: T
    ysize :: Int
end

Base.size(c::Canvas) = (c.xsize, c.ysize)
xlims(c::Canvas) = (c.xmin, c.xmax)
ylims(c::Canvas) = (c.ymin, c.ymax)
Base.:(==)(a::Canvas, b::Canvas) = size(a)==size(b) && xlims(a)==xlims(b) && ylims(a)==ylims(b)

abstract type AggOp end

update(a::AggOp, x, args...) = merge(a, x, embed(a, args...))

struct AggCount{T} <: AggOp end
AggCount() = AggCount{Int}()
null(::AggCount{T}) where {T} = zero(T)
embed(::AggCount{T}) where {T} = oneunit(T)
merge(::AggCount{T}, x::T, y::T) where {T} = x + y
value(::AggCount{T}, x::T) where {T} = x

struct AggAny <: AggOp end
null(::AggAny) = false
embed(::AggAny) = true
merge(::AggAny, x::Bool, y::Bool) = x | y
value(::AggAny, x::Bool) = x

struct AggSum{T} <: AggOp end
AggSum() = AggSum{Float64}()
null(::AggSum{T}) where {T} = zero(T)
embed(::AggSum{T}, x) where {T} = convert(T, x)
merge(::AggSum{T}, x::T, y::T) where {T} = x + y
value(::AggSum{T}, x::T) where {T} = x

struct AggMean{T} <: AggOp end
AggMean() = AggMean{Float64}()
null(::AggMean{T}) where {T} = (zero(T), zero(T))
embed(::AggMean{T}, x) where {T} = (convert(T,x), oneunit(T))
merge(::AggMean{T}, x::Tuple{T,T}, y::Tuple{T,T}) where {T} = (x[1]+y[1], x[2]+y[2])
value(::AggMean{T}, x::Tuple{T,T}) where {T} = float(x[1]) / float(x[2])

abstract type AggMethod end

struct AggSerial <: AggMethod end
struct AggThreads <: AggMethod end

aggregate(c::Canvas, points; op::AggOp=AggCount(), method::AggMethod=AggSerial()) =
    _aggregate(c, op, method, points)

function _aggregate(c::Canvas, op::AggOp, ::AggSerial, points)
    xmin, xmax = xlims(c)
    ymin, ymax = ylims(c)
    xsize, ysize = size(c)
    xmax > xmin || error("require xmax > xmin")
    ymax > ymin || error("require ymax > ymin")
    xscale = xsize / (xmax - xmin)
    yscale = ysize / (ymax - ymin)
    out = fill(null(op), xsize, ysize)
    @inbounds for point in points
        x = point[1]
        y = point[2]
        if length(point) > 2 # should compile away
            z = point[3]
        end
        xmin ≤ x ≤ xmax || continue
        ymin ≤ y ≤ ymax || continue
        i = clamp(1+floor(Int, xscale*(x-xmin)), 1, xsize)
        j = clamp(1+floor(Int, yscale*(y-ymin)), 1, ysize)
        if length(point) == 2 # should compile away
            out[i,j] = update(op, out[i,j])
        elseif length(point) == 3
            out[i,j] = update(op, out[i,j], z)
        end
        nothing
    end
    map(x->value(op, x), out)
end

function _aggregate(c::Canvas, op::AggOp, ::AggThreads, points)
    xmin, xmax = xlims(c)
    ymin, ymax = ylims(c)
    xsize, ysize = size(c)
    xmax > xmin || error("require xmax > xmin")
    ymax > ymin || error("require ymax > ymin")
    xscale = xsize / (xmax - xmin)
    yscale = ysize / (ymax - ymin)
    # each thread reduces some of the data separately
    out = fill(null(op), Threads.nthreads(), xsize, ysize)
    @threads for idx in eachindex(points)
        t = Threads.threadid()
        p = @inbounds points[idx]
        x = p[1]
        y = p[2]
        if length(p) > 2 # should compile away
            z = p[3]
        end
        xmin ≤ x ≤ xmax || continue
        ymin ≤ y ≤ ymax || continue
        i = clamp(1+floor(Int, xscale*(x-xmin)), 1, xsize)
        j = clamp(1+floor(Int, yscale*(y-ymin)), 1, ysize)
        if length(p) == 2 # should compile away
            @inbounds out[t,i,j] = update(op, out[t,i,j])
        elseif length(p) == 3
            @inbounds out[t,i,j] = update(op, out[t,i,j], z)
        end
    end
    # reduce along the thread dimension
    out2 = fill(null(op), xsize, ysize)
    for j in 1:ysize
        for i in 1:xsize
            @inbounds val = out[1,i,j]
            for t in 2:Threads.nthreads()
                @inbounds val = merge(op, val, out[t,i,j])
            end
            @inbounds out2[i,j] = val
        end
    end
    map(x->value(op, x), out2)
end

const DEFAULT_SPREAD_MASKS = Matrix{Bool}[
    ones(Int, 1, 1),
    [0 1 0; 1 1 1; 0 1 0],
    [1 1 1; 1 1 1; 1 1 1],
    [0 0 1 0 0; 0 1 1 1 0; 1 1 1 1 1; 0 1 1 1 0; 0 0 1 0 0],
    [0 1 1 1 0; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 0 1 1 1 0],
    [1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1; 1 1 1 1 1],
]

function spread(img::AbstractMatrix, r::Integer; masks=DEFAULT_SPREAD_MASKS, opts...)
    Base.require_one_based_indexing(masks)
    spread(img, masks[r+1]; opts...)
end

function spread(img::AbstractMatrix, w::AbstractMatrix; op=max)
    Base.require_one_based_indexing(img, w)
    wsz = size(w)
    all(isodd, wsz) || error("weights must have odd size in each dimension")
    r = map(x->fld(x,2), wsz)
    sz = size(img)
    out = zeros(typeof(zero(eltype(img))*zero(eltype(w))), size(img)...)
    for j in -r[2]:r[2]
        for i in -r[1]:r[1]
            wt = w[r[1]+1+i,r[2]+1+j]
            vout = @view out[i ≥ 0 ? (1+i:end) : (1:end+i), j ≥ 0 ? (j+1:end) : (1:end+j)]
            vimg = @view img[i ≥ 0 ? (1:end-i) : (1-i:end), j ≥ 0 ? (1:end-j) : (1-j:end)]
            vout .= op.(vout, vimg .* Ref(wt))
        end
    end
    out
end

function autospread(img::AbstractMatrix; masks=DEFAULT_SPREAD_MASKS, rmax=length(masks)-1, thresh=0.5, opts...)
    Base.require_one_based_indexing(img, masks)
    0 ≤ rmax < length(masks) || error("rmax out of range")
    n₀ = count(x->!iszero(x), img)
    out = spread(img, masks[1]; opts...)
    for r in 1:rmax
        mask = masks[r+1]
        s = count(x->!iszero(x), mask)
        newout = spread(img, mask; opts...)
        n = count(x->!iszero(x), newout)
        n < thresh * s * n₀ && break
        # out = newout
        # linearly interpolate between out and newout depending on where n is in the
        # interval [thresh * s * n₀, s * n₀]
        p = (n / (s * n₀) - thresh) / (1 - thresh)
        out = @. p * newout + (1 - p) * out
    end
    return out
end

end

import .ShadeYourData

@recipe(DataShader) do scene
    Theme(
        agg = ShadeYourData.AggCount(),
        post = identity,
        method = ShadeYourData.AggThreads(),
        colormap = theme(scene, :colormap),
        binfactor = 1,
    )
end

conversion_trait(::Type{<: DataShader}) = PointBased()

function Makie.plot!(p::DataShader{<: Tuple{<: Vector{<: Point}}})
    scene = parent_scene(p)
    # transf = transform_func_obs(scene)

    limits = lift(projview_to_2d_limits, p, scene.camera.projectionview)
    px_area = lift(identity, p, scene.px_area)

    canvas = lift(limits, px_area, p.binfactor) do lims, pxarea, binfactor
        binfactor isa Int || error("Bin factor $binfactor is not an Int.")
        xsize, ysize = round.(Int, Makie.widths(pxarea) ./ binfactor)
        xmin, ymin = minimum(lims)
        xmax, ymax = maximum(lims)
        ShadeYourData.Canvas(xmin, xmax, xsize, ymin, ymax, ysize)
    end

    points = p[1]

    sorted_points = lift(points) do data
        sort(data, by = x -> (x[1], x[2]))
    end

    xrange = Observable(0f0..1f0)
    yrange = Observable(0f0..1f0)
    
    pixels = Observable(Float32[0; 0;; 1; 1])
    onany(canvas, p.agg, p.post, p.method, sorted_points) do canvas, agg, post, method, sorted_points
        xrange.val = canvas.xmin .. canvas.xmax
        yrange.val = canvas.ymin .. canvas.ymax
        pixels[] = float(post(ShadeYourData.aggregate(canvas, sorted_points; op=agg, method)))
    end
    heatmap!(p, xrange, yrange, pixels, colormap = p.colormap)
    return p
end

function Makie.data_limits(p::DataShader{Tuple{Vector{Point2f}}})
    FRect3D(FRect2D(p[1][]))
end