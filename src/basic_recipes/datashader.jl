# originally from https://github.com/cjdoris/ShadeYourData.jl
module PixelAggregation

import Base.Threads: @threads
import Makie: Makie, (..), Rect2, widths
abstract type AggOp end

mutable struct Canvas
    bounds::Rect2{Float64}
    resolution::Tuple{Int,Int}
    op::AggOp
    # temporaries / results
    aggbuffer::Vector
    pixelbuffer::Vector
    data_extrema::Tuple{Float64,Float64}
end

function aggregation(canvas::Canvas; operation=equalize_histogram, local_operation=identity, result=similar(canvas.pixelbuffer, canvas.resolution))
    pix_reshaped = Base.ReshapedArray(canvas.pixelbuffer, canvas.resolution, ())
    return operation(map!(local_operation, result, pix_reshaped))
end

Base.size(c::Canvas) = c.resolution
Base.:(==)(a::Canvas, b::Canvas) = size(a) == size(b) && (a.bounds == b.bounds) && a.op == b.op

@inline update(a::AggOp, x, args...) = merge(a, x, embed(a, args...))

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
embed(::AggMean{T}, x) where {T} = (convert(T, x), oneunit(T))
merge(::AggMean{T}, x::Tuple{T,T}, y::Tuple{T,T}) where {T} = (x[1] + y[1], x[2] + y[2])
value(::AggMean{T}, x::Tuple{T,T}) where {T} = float(x[1]) / float(x[2])

abstract type AggMethod end

struct AggSerial <: AggMethod end
struct AggThreads <: AggMethod end

function Canvas(xmin::Number, xmax::Number, ymin::Number, ymax::Number; args...)
    return Canvas(Rect2(xmin, ymin, xmax - xmin, ymax - ymin); args...)
end

function Canvas(bounds::Rect2; resolution::Tuple{Int,Int}=(800, 800), op=AggCount())
    xsize, ysize = resolution
    n_elements = xsize * ysize
    o0 = null(op)
    aggbuffer = fill(o0, n_elements)
    pixelbuffer = fill(o0, n_elements)
    # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
    return Canvas(Rect2{Float64}(bounds), resolution, op, aggbuffer, pixelbuffer, (o0, o0))
end

n_threads(::AggSerial) = 1
n_threads(::AggThreads) = Threads.nthreads()

function Base.resize!(canvas::Canvas, resolution::Tuple{Int,Int}, nthreads=1)
    npixel = prod(resolution)
    n_elements = npixel * nthreads
    length(canvas.pixelbuffer) == npixel && length(canvas.aggbuffer) == n_elements && return false
    canvas.resolution = resolution
    Base.resize!(canvas.pixelbuffer, npixel)
    Base.resize!(canvas.aggbuffer, n_elements)
    return true
end

function change_op!(canvas::Canvas, op::AggOp)
    op == canvas.op && return false
    o0 = null(op)
    if eltype(canvas.aggbuffer) != typeof(o0)
        c.aggbuffer = fill(o0, size(c.aggbuffer))
        c.pixelbuffer = fill(o0, size(c.pixelbuffer))
    end
    return true
end

using InteractiveUtils

function aggregate!(c::Canvas, points; point_func=identity, method::AggMethod=AggSerial())
    resize!(c, c.resolution, n_threads(method)) # make sure we have the right size for the method
    aggbuffer, pixelbuffer = c.aggbuffer, c.pixelbuffer
    fill!(aggbuffer, null(c.op))
    return aggregation_implementation!(method, aggbuffer, pixelbuffer, c, c.op, points, point_func)
end

function aggregation_implementation!(::AggSerial,
                                     aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
                                     c::Canvas, op::AggOp,
                                     points, point_func)
    (xmin, ymin), (xmax, ymax) = extrema(c.bounds)
    xsize, ysize = size(c)
    xwidth, ywidth = widths(c.bounds)
    xscale = xsize / (xwidth + eps(xwidth))
    yscale = ysize / (ywidth + eps(ywidth))

    @assert length(aggbuffer) == xsize * ysize
    @assert length(pixelbuffer) == xsize * ysize
    @assert eltype(aggbuffer) === typeof(null(op)) "$(eltype(aggbuffer)) !== $(typeof(null(op)))"

    # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
    out = Base.ReshapedArray(aggbuffer, (xsize, ysize), ())
    for point in points
        p = point_func(point)
        x = p[1]
        y = p[2]
        if length(p) > 2 # should compile away
            z = p[3]
        end
        xmin ≤ x ≤ xmax || continue
        ymin ≤ y ≤ ymax || continue
        i = 1 + floor(Int, xscale * (x - xmin))
        j = 1 + floor(Int, yscale * (y - ymin))
        if length(p) == 2 # should compile away
            out[i, j] = update(op, out[i, j])
        elseif length(p) == 3
            out[i, j] = update(op, out[i, j], z)
        end
    end

    mini, maxi = Inf, -Inf
    map!(pixelbuffer, aggbuffer) do x
        final_value = value(op, x)
        if isfinite(final_value)
            mini = min(final_value, mini)
            maxi = max(final_value, maxi)
        end
        return final_value
    end
    c.data_extrema = (mini, maxi)
    return c
end

function aggregation_implementation!(::AggThreads,
                                     aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
                                     c::Canvas, op::AggOp,
                                     points, point_func)
    (xmin, ymin), (xmax, ymax) = extrema(c.bounds)
    xsize, ysize = size(c)
    # by adding eps to width we can use the scaling factor plus floor directly to compute the bin indices
    xwidth = xmax - xmin
    xscale = xsize / (xwidth + eps(xwidth))
    ywidth = ymax - ymin
    yscale = ysize / (ywidth + eps(ywidth))
    # each thread reduces some of the data separately
    @assert length(aggbuffer) == Threads.nthreads() * xsize * ysize
    @assert length(pixelbuffer) == xsize * ysize
    @assert eltype(aggbuffer) === typeof(null(op)) "$(eltype(aggbuffer)) !== $(typeof(null(op)))"

    # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
    # https://stackoverflow.com/questions/41781621/resizing-a-matrix/41804908#41804908
    out = Base.ReshapedArray(aggbuffer, (xsize, ysize, Threads.nthreads()), ())
    out2 = Base.ReshapedArray(pixelbuffer, (xsize, ysize), ())

    n = length(points)
    chunks = round.(Int, range(1, n; length=Threads.nthreads() + 1))

    @threads for t in 1:Threads.nthreads()
        from = chunks[t]
        to = chunks[t + 1]
        @inbounds for idx in from:to
            p = point_func(points[idx])
            x = p[1]
            y = p[2]
            if length(p) > 2 # should compile away
                z = p[3]
            end
            xmin ≤ x ≤ xmax || continue
            ymin ≤ y ≤ ymax || continue
            i = 1 + floor(Int, xscale * (x - xmin))
            j = 1 + floor(Int, yscale * (y - ymin))
            if length(p) == 2 # should compile away
                out[i, j, t] = update(op, out[i, j, t])
            elseif length(p) == 3
                out[i, j, t] = update(op, out[i, j, t], z)
            end
        end
    end
    # reduce along the thread dimension
    mini, maxi = Inf, -Inf
    for j in 1:ysize
        @inbounds for i in 1:xsize
            val = out[i, j, 1]
            for t in 2:Threads.nthreads()
                val = merge(op, val, out[i, j, t])
            end
            # update the value in out2 directly in this loop
            final_value = value(op, val)
            if isfinite(final_value)
                mini = min(final_value, mini)
                maxi = max(final_value, maxi)
            end
            out2[i, j] = final_value
        end
    end
    c.data_extrema = (mini, maxi)
    return c
end

export AggAny, AggCount, AggMean, AggSum, AggSerial, AggThreads

end

using ..PixelAggregation
using ..PixelAggregation: Canvas, change_op!

function equalize_histogram(matrix; nbins=256 * 256)
    h_eq = StatsBase.fit(StatsBase.Histogram, vec(matrix); nbins=nbins)
    h_eq = normalize(h_eq; mode=:density)
    cdf = cumsum(h_eq.weights)
    cdf = cdf / cdf[end]
    edg = h_eq.edges[1]
    # TODO is this the correct linear interpolation?
    return Makie.interpolated_getindex.((cdf,), matrix, (Vec2f(first(edg), last(edg)),))
end

"""
    datashader(points::AbstractVector{<: Point})

Points can be any array type supporting iteration & getindex, including memory mapped arrays.
If you have x + y coordinates seperated and want to avoid conversion + copy, consider using:
```Julia
using Makie.StructArrays
points = StructArray{Point2f}((x, y))
datashader(points)
```
Do pay attention though, that if x and y don't have a fast iteration/getindex implemented, this might be slower then just copying it into a new array.

For best performance, use `method=Makie.AggThreads()` and make sure to start julia with `julia -t8` or have the environment variable `JULIA_NUM_THREADS` set to the number of cores you have.

## Attributes

### Specific to `DataShader`

- `agg = AggCount()` can be `AggCount()`, `AggAny()` or `AggMean()`. User extendable by overloading:


    ```Julia
        struct MyAgg{T} <: Makie.AggOp end
        MyAgg() = MyAgg{Float64}()
        Makie.PixelAggregation.null(::MyAgg{T}) where {T} = zero(T)
        Makie.PixelAggregation.embed(::MyAgg{T}, x) where {T} = convert(T, x)
        Makie.PixelAggregation.merge(::MyAgg{T}, x::T, y::T) where {T} = x + y
        Makie.PixelAggregation.value(::MyAgg{T}, x::T) where {T} = x
    ```

- `method = AggThreads()` can be `AggThreads()` or `AggSerial()`.
- `async::Bool = true` will calculate aggregation in a task, and skip any zoom/pan updates while busy. Great for interaction, but must be disabled for saving to e.g. png or when inlining in documenter.

- `global_post::Function = Makie.equalize_histogram` function which gets called on the whole aggregation array before display (`global_post(final_aggregation_result)`).
- `local_post::Function = identity` function which gets call on each element after aggregation (`map!(x-> local_post(x), final_aggregation_result)`).

- `point_func::Function = identity` function which gets applied to every point before aggregating it.
- `binfactor::Number = 1` factor defining how many bins one wants per screen pixel. Set to n > 1 if you want a corser image.
- `show_timings::Bool = false` show how long it takes to aggregate each frame.
- `interpolate::Bool = true` If the resulting image should be displayed interpolated.

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = true` adjusts whether the plot is rendered with fxaa (anti-aliasing).
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.
- `lowclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value below the colorrange.
- `highclip::Union{Automatic, Symbol, <:Colorant} = automatic` sets a color for any value above the colorrange.
- `space::Symbol = :data` sets the transformation space for the plot
"""
@recipe(DataShader, points) do scene
    Theme(

        agg = AggCount(),
        method = AggThreads(),
        async = true,
        # Defaults to equalize_histogram
        # just set to automatic, so that if one sets local_post, one doesn't do equalize_histogram on top of things.
        global_post = automatic,
        local_post = identity,

        point_func = identity,
        binfactor = 1,
        show_timings = false,

        colormap = theme(scene, :colormap),
        colorrange = automatic
    )
end

function fast_bb(points, f)
    N = length(points)
    NT = Threads.nthreads()
    slices = ceil(Int, N / NT)
    offset = 1
    results = fill(Point2f(0), NT, 2)
    Threads.@threads for i in 1:NT
        start = ((i - 1) * slices + 1)
        stop = min(length(points), i * slices)
        pmin, pmax = extrema(Rect2f(view(points, start:stop)))
        results[i, 1] = f(pmin)
        results[i, 2] = f(pmax)
    end
    return Rect3f(Rect2f(vec(results)))
end



function canvas_obs(limits::Observable, pixel_area::Observable, op, binfactor::Observable)
    canvas = Canvas(limits[]; resolution=(widths(pixel_area[])...,), op=op[])
    canvas_obs = Observable(canvas)
    onany(limits, pixel_area, binfactor, op) do lims, pxarea, binfactor, op
        binfactor isa Int || error("Bin factor $binfactor is not an Int.")
        xsize, ysize = round.(Int, Makie.widths(pxarea) ./ binfactor)
        has_changed = Base.resize!(canvas, (xsize, ysize))
        has_changed = has_changed || change_op!(canvas, op)
        lims64 = Rect2{Float64}(lims)
        if canvas.bounds != lims64
            has_changed = true
            canvas.bounds = lims64
        end
        if has_changed
            canvas_obs[] = canvas
        end
    end
    return canvas_obs
end

function Makie.plot!(p::DataShader{<: Tuple{<: AbstractVector{<: Point}}})
    scene = parent_scene(p)
    limits = lift(projview_to_2d_limits, p, scene.camera.projectionview; ignore_equal_values=true)
    px_area = lift(identity, p, scene.px_area; ignore_equal_values=true)
    canvas = canvas_obs(limits, px_area, p.agg, p.binfactor)
    p._boundingbox = lift(fast_bb, p.points, p.point_func)
    on_func = p.async[] ? onany_latest : onany
    canvas_with_aggregation = Observable(canvas[]) # Canvas that only gets notified after aggregation happened
    p.canvas = canvas_with_aggregation
    on_func(canvas, p.points, p.point_func) do canvas, points, f
        PixelAggregation.aggregate!(canvas, points; point_func=f, method=p.method[])
        canvas_with_aggregation[] = canvas
        return
    end
    image!(p, canvas_with_aggregation; colorrange=p.colorrange, colormap=p.colormap)
    return p
end

function aggregate_categories!(canvases, categories; method=AggThreads())
    for (k, canvas) in canvases
        points = categories[k]
        PixelAggregation.aggregate!(canvas, points; method=method)
    end
end


Makie.convert_arguments(::Type{<: DataShader}, x::Dict{String,Vector{<:Point2}}) = (x,)

function Makie.plot!(p::DataShader{<:Tuple{Dict{String, Vector{Point{2, Float32}}}}})
    scene = parent_scene(p)
    limits = lift(projview_to_2d_limits, p, scene.camera.projectionview; ignore_equal_values=true)
    px_area = lift(identity, p, scene.px_area; ignore_equal_values=true)
    canvas = canvas_obs(limits, px_area, Observable(AggCount{Float32}()), p.binfactor)
    p._boundingbox = lift(p.points, p.point_func) do cats, func
        rects = map(points -> fast_bb(points, func), values(cats))
        return reduce(union, rects)
    end
    categories = p.points[]
    canvases = Dict(k => Canvas(canvas[].bounds; resolution=canvas[].resolution, op=AggCount{Float32}())
                    for (k, v) in categories)

    on_func = p.async[] ? onany_latest : onany
    canvas_with_aggregation = Observable(canvas[]) # Canvas that only gets notified after aggregation happened
    p.canvas = canvas_with_aggregation
    toal_value = Observable(0f0)
    onany(canvas, p.points) do canvas, cats
        for (k, c) in canvases
            Base.resize!(c, canvas.resolution)
            c.bounds = canvas.bounds
        end
        aggregate_categories!(canvases, cats; method=p.method[])
        toal_value[] = Float32(maximum(sum(map(x -> x.pixelbuffer, values(canvases)))))
        return
    end
    colors = Dict(k => Makie.wong_colors()[i] for (i, (k, v)) in enumerate(categories))
    op = map(total -> (x -> log10(x + 1) / log10(total + 1)), toal_value)
    for (k, canvas) in canvases
        color = colors[k]
        cmap = [(color, 0.0), (color, 1.0)]
        image!(p, canvas; colorrange=Vec2f(0, 1), colormap=cmap, operation=identity, local_operation=op)
    end
    return p
end

Makie.data_limits(p::DataShader) =  p._boundingbox[]

Makie.used_attributes(::Type{<:Any}, ::Canvas) = (:operation, :local_operation)

function convert_arguments(P::Type{<:Union{MeshScatter,Image,Surface,Contour,Contour3d}}, canvas::Canvas;
                           operation=equalize_histogram, local_operation=identity)
    pixel = PixelAggregation.aggregation(canvas; operation=operation, local_operation=local_operation)
    (xmin, ymin), (xmax, ymax) = extrema(canvas.bounds)
    xrange = range(xmin, stop = xmax, length = size(pixel, 1))
    yrange = range(ymin, stop = ymax, length = size(pixel, 2))
    return convert_arguments(P, xrange, yrange, pixel)
end

# function Makie.plot!(plot::Combined{PlotType, <: Tuple{<: Canvas}}) where PlotType
#     println("jey")
#     xrange = Observable((canvas[].xmin .. canvas[].xmax); ignore_equal_values=true)
#     yrange = Observable((canvas[].ymin .. canvas[].ymax); ignore_equal_values=true)
#     canvas = plot.canvas
#     result = Observable(similar(canvas[].pixelbuffer, canvas[].resolution))
#     lift(plot, canvas, plot.global_operation, local_operation, ) do canvas, global_op, local_op
#         aggregation(canvas::Canvas; operation=global_op, local_operation=local_op, result=result[])
#         notify(result)
#         return
#     end
#     plot!(plot, PlotType, result)
# end
