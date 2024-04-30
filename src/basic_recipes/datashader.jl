# originally from https://github.com/cjdoris/ShadeYourData.jl
module Aggregation

import Base.Threads: @threads
import Makie: Makie, (..), Rect2, widths
abstract type AggOp end

"""
    Canvas(bounds::Rect2; resolution::Tuple{Int,Int}=(800, 800), op=AggCount())
    Canvas(xmin::Number, xmax::Number, ymin::Number, ymax::Number; args...)

# Example

```Julia
using Makie
canvas = Canvas(-1, 1, -1, 1; op=AggCount(), resolution=(800, 800))
aggregate!(canvas, points; point_transform=reverse, method=AggThreads())
aggregated_values = get_aggregation(canvas; operation=equalize_histogram, local_operation=identiy)
# Recipes are defined for canvas as well and incorperate the `get_aggregation`, but `aggregate!` must be called manually.
image!(canvas; operation=equalize_histogram, local_operation=identiy, colormap=:viridis, colorrange=(0, 20))
surface!(canvas; operation=equalize_histogram, local_operation=identiy)
```
"""
mutable struct Canvas
    bounds::Rect2{Float64}
    resolution::Tuple{Int,Int}
    op::AggOp
    # temporaries / results
    aggbuffer::Vector
    pixelbuffer::Vector
    data_extrema::Tuple{Float64,Float64}
end

"""
    get_aggregation(canvas::Canvas; operation=equalize_histogram, local_operation=identity, result=similar(canvas.pixelbuffer, canvas.resolution))

Basically does `operation(map!(local_operation, result, canvas.pixelbuffer))`, but does the correct reshaping of the flat pixelbuffer and
simplifies passing a local or global operation.
Allocates the result buffer every time and can be made non allocating by passing the correct result buffer.
"""
function get_aggregation(canvas::Canvas; operation=equalize_histogram, local_operation=identity, result=similar(canvas.pixelbuffer, canvas.resolution))
    pix_reshaped = Base.ReshapedArray(canvas.pixelbuffer, canvas.resolution, ())
    # we want to make it easy to set local_operation or operation, without them clashing, while also being able to set both!
    if operation === Makie.automatic
        postfunc = local_operation === identity ? Makie.equalize_histogram : identity
    else
        postfunc = operation
    end
    return postfunc(map!(local_operation, result, pix_reshaped))
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
        canvas.aggbuffer = fill(o0, size(c.aggbuffer))
        canvas.pixelbuffer = fill(o0, size(c.pixelbuffer))
    end
    return true
end

using InteractiveUtils

"""
    aggregate!(c::Canvas, points; point_transform=identity, method::AggMethod=AggSerial())

Aggregate points into a canvas. The points are transformed by `point_transform` before aggregation.
Method can be `AggSerial()` or `AggThreads()`.
"""
function aggregate!(c::Canvas, points; point_transform=identity, method::AggMethod=AggSerial())
    resize!(c, c.resolution, n_threads(method)) # make sure we have the right size for the method
    aggbuffer, pixelbuffer = c.aggbuffer, c.pixelbuffer
    fill!(aggbuffer, null(c.op))
    return aggregation_implementation!(method, aggbuffer, pixelbuffer, c, c.op, points, point_transform)
end

function aggregation_implementation!(::AggSerial,
                                     aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
                                     c::Canvas, op::AggOp,
                                     points, point_transform)
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
        p = point_transform(point)
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
                                     points, point_transform)
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
            p = point_transform(points[idx])
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

using ..Aggregation
using ..Aggregation: Canvas, change_op!, aggregate!

function equalize_histogram(matrix; nbins=256)
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

!!! warning
    This feature might change outside breaking releases, since the API is not yet finalized.
    Please be wary of bugs in the implementation and open issues if you encounter odd behaviour.

Points can be any array type supporting iteration & getindex, including memory mapped arrays.
If you have separate arrays for x and y coordinates and want to avoid conversion and copy, consider using:
```Julia
using Makie.StructArrays
points = StructArray{Point2f}((x, y))
datashader(points)
```
Do pay attention though, that if x and y don't have a fast iteration/getindex implemented, this might be slower than just copying the data into a new array.

For best performance, use `method=Makie.AggThreads()` and make sure to start julia with `julia -tauto` or have the environment variable `JULIA_NUM_THREADS` set to the number of cores you have.
"""
@recipe DataShader (points,) begin
    """
    Can be `AggCount()`, `AggAny()` or `AggMean()`. User-extensible by overloading:

    ```julia
    struct MyAgg{T} <: Makie.AggOp end
    MyAgg() = MyAgg{Float64}()
    Makie.Aggregation.null(::MyAgg{T}) where {T} = zero(T)
    Makie.Aggregation.embed(::MyAgg{T}, x) where {T} = convert(T, x)
    Makie.Aggregation.merge(::MyAgg{T}, x::T, y::T) where {T} = x + y
    Makie.Aggregation.value(::MyAgg{T}, x::T) where {T} = x
    ```
    """
    agg = AggCount()
    """
    Can be `AggThreads()` or `AggSerial()` for threaded vs. serial aggregation.
    """
    method = AggThreads()
    """
    Will calculate `get_aggregation` in a task, and skip any zoom/pan updates while busy. Great for interaction, but must be disabled for saving to e.g. png or when inlining in Documenter.
    """
    async = true
    # Defaults to equalize_histogram
    # just set to automatic, so that if one sets local_operation, one doesn't do equalize_histogram on top of things.
    """
    Defaults to `Makie.equalize_histogram` function which gets called on the whole get_aggregation array before display (`operation(final_aggregation_result)`).
    """
    operation=automatic
    """
    Function which gets called on each element after the aggregation (`map!(x-> local_operation(x), final_aggregation_result)`).
    """
    local_operation=identity

    """
    Function which gets applied to every point before aggregating it.
    """
    point_transform = identity
    """
    Factor defining how many bins one wants per screen pixel. Set to n > 1 if you want a coarser image.
    """
    binsize = 1
    """
    Set to `true` to show how long it takes to aggregate each frame.
    """
    show_timings = false
    """
    If the resulting image should be displayed interpolated.
    """
    interpolate = true
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
end

function fast_bb(points, f)
    N = length(points)
    NT = Threads.nthreads()
    slices = ceil(Int, N / NT)
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


function canvas_obs(limits::Observable, pixel_area::Observable, op, binsize::Observable)
    canvas = Canvas(limits[]; resolution=(widths(pixel_area[])...,), op=op[])
    canvas_obs = Observable(canvas)
    onany(limits, pixel_area, binsize, op) do lims, pxarea, binsize, op
        binsize isa Int || error("Bin factor $binsize is not an Int.")
        xsize, ysize = round.(Int, Makie.widths(pxarea) ./ binsize)
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
    limits = projview_to_2d_limits(p)
    viewport = lift(identity, p, scene.viewport; ignore_equal_values=true)
    canvas = canvas_obs(limits, viewport, p.agg, p.binsize)
    p._boundingbox = lift(fast_bb, p.points, p.point_transform)
    on_func = p.async[] ? onany_latest : onany
    canvas_with_aggregation = Observable(canvas[]) # Canvas that only gets notified after get_aggregation happened
    p.canvas = canvas_with_aggregation
    colorrange = Observable(Vec2f(0, 1))
    on(p.colorrange; update=true) do crange
        if !(crange isa Automatic)
            colorrange[] = Vec2f(crange)
        end
    end

    on_func(canvas, p.points, p.point_transform) do canvas, points, f
        Aggregation.aggregate!(canvas, points; point_transform=f, method=p.method[])
        canvas_with_aggregation[] = canvas
        # If not automatic, it will get updated by the above on(p.colorrange)
        if p.colorrange[] isa Automatic
            colorrange[] = Vec2f(distinct_extrema_nan(canvas.data_extrema))
        end
        return
    end
    p.raw_colorrange = colorrange
    image!(p, canvas_with_aggregation, p.operation, p.local_operation;
        interpolate=p.interpolate,
        MakieCore.generic_plot_attributes(p)...,
        MakieCore.colormap_attributes(p)...)
    return p
end


function aggregate_categories!(canvases, categories; method=AggThreads())
    for (k, canvas) in canvases
        points = categories[k]
        Aggregation.aggregate!(canvas, points; method=method)
    end
end

Makie.convert_arguments(::Type{<:DataShader}, x::Dict{String,Vector{<:Point2}}) = (x,)

function Makie.convert_arguments(::Type{<:DataShader}, groups::AbstractVector, points::AbstractVector{<:Point2})
    if length(groups) != length(points)
        error("Each point needs a group. Length $(length(groups)) != $(length(points))")
    end
    categories = Dict{String, Vector{Point2f}}()
    for (g, p) in zip(groups, points)
        gpoints = get!(()-> Point2f[], categories, string(g))
        push!(gpoints, p)
    end
    return (categories,)
end

function Makie.plot!(p::DataShader{<:Tuple{Dict{String, Vector{Point{2, Float32}}}}})
    scene = parent_scene(p)
    limits = projview_to_2d_limits(p)
    viewport = lift(identity, p, scene.viewport; ignore_equal_values=true)
    canvas = canvas_obs(limits, viewport, Observable(AggCount{Float32}()), p.binsize)
    p._boundingbox = lift(p.points, p.point_transform) do cats, func
        rects = map(points -> fast_bb(points, func), values(cats))
        return reduce(union, rects)
    end
    categories = p.points[]
    canvases = Dict(k => Canvas(canvas[].bounds; resolution=canvas[].resolution, op=AggCount{Float32}())
                    for (k, v) in categories)

    on_func = p.async[] ? onany_latest : onany
    canvas_with_aggregation = Observable(canvas[]) # Canvas that only gets notified after get_aggregation happened
    p.canvas = canvas_with_aggregation
    toal_value = Observable(0f0)
    on_func(canvas, p.points) do canvas, cats
        for (k, c) in canvases
            Base.resize!(c, canvas.resolution)
            c.bounds = canvas.bounds
        end
        aggregate_categories!(canvases, cats; method=p.method[])
        toal_value[] = Float32(maximum(sum(map(x -> x.pixelbuffer, values(canvases)))))
        return
    end
    colors = Dict(k => Makie.wong_colors()[i] for (i, (k, v)) in enumerate(categories))
    p._categories = colors
    op = map(total -> (x -> log10(x + 1) / log10(total + 1)), toal_value)

    for (k, canv) in canvases
        color = colors[k]
        cmap = [(color, 0.0), (color, 1.0)]
        image!(p, canv, identity, op; colorrange=Vec2f(0, 1), colormap=cmap)
    end
    return p
end

data_limits(p::DataShader) =  p._boundingbox[]
boundingbox(p::DataShader, space::Symbol = :data) =  transform_bbox(p, p._boundingbox[])

function convert_arguments(P::Type{<:Union{MeshScatter,Image,Surface,Contour,Contour3d}}, canvas::Canvas, operation=automatic, local_operation=identity)
    pixel = Aggregation.get_aggregation(canvas; operation=operation, local_operation=local_operation)
    (xmin, ymin), (xmax, ymax) = extrema(canvas.bounds)
    return convert_arguments(P, xmin .. xmax, ymin .. ymax, pixel)
end

# TODO improve color legend API, to not need a fake plot like this
struct FakePlot <: AbstractPlot{Poly}
    attributes::Attributes
end
Base.getindex(x::FakePlot, key::Symbol) = getindex(getfield(x, :attributes), key)

function get_plots(plot::DataShader)
    return map(collect(plot._categories[])) do (name, color)
        return FakePlot(Attributes(; label=name, color=color))
    end
end

function legendelements(plot::FakePlot, legend)
    return [PolyElement(; color=plot.attributes.color, strokecolor=legend.polystrokecolor, strokewidth=legend.polystrokewidth)]
end

# Sadly we must define the colorbar here and cant use the default fallback,
# Since the Image plot will only see the scaled data, and since its hard to make Colorbar support the equalize_histogram
# transform, we just create the colorbar form the raw data.
# TODO, should we merge the local/global op with colorscale?
function extract_colormap(plot::DataShader)
    color = map(x -> x.aggbuffer, plot.canvas)
    return ColorMapping(
       color[], color, plot.colormap, plot.raw_colorrange,
        plot.colorscale,
        plot.alpha,
        plot.highclip,
        plot.lowclip,
        plot.nan_color)
end
