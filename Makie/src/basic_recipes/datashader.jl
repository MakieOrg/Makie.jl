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
    aggregated_values = get_aggregation(canvas; operation=equalize_histogram, local_operation=identity)
    # Recipes are defined for canvas as well and incorporate the `get_aggregation`, but `aggregate!` must be called manually.
    image!(canvas; operation=equalize_histogram, local_operation=identity, colormap=:viridis, colorrange=(0, 20))
    surface!(canvas; operation=equalize_histogram, local_operation=identity)
    ```
    """
    mutable struct Canvas
        bounds::Rect2{Float64}
        resolution::Tuple{Int, Int}
        op::AggOp
        # temporaries / results
        aggbuffer::Vector
        pixelbuffer::Vector
        data_extrema::Tuple{Float64, Float64}
    end

    """
        get_aggregation(canvas::Canvas; operation=equalize_histogram, local_operation=identity, result=similar(canvas.pixelbuffer, canvas.resolution))

    Basically does `operation(map!(local_operation, result, canvas.pixelbuffer))`, but does the correct reshaping of the flat pixelbuffer and
    simplifies passing a local or global operation.
    Allocates the result buffer every time and can be made non allocating by passing the correct result buffer.
    """
    function get_aggregation(canvas::Canvas; operation = equalize_histogram, local_operation = identity, result = similar(canvas.pixelbuffer, canvas.resolution))
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
    merge(::AggMean{T}, x::Tuple{T, T}, y::Tuple{T, T}) where {T} = (x[1] + y[1], x[2] + y[2])
    value(::AggMean{T}, x::Tuple{T, T}) where {T} = float(x[1]) / float(x[2])

    abstract type AggMethod end

    struct AggSerial <: AggMethod end
    struct AggThreads <: AggMethod end

    function Canvas(xmin::Number, xmax::Number, ymin::Number, ymax::Number; args...)
        return Canvas(Rect2(xmin, ymin, xmax - xmin, ymax - ymin); args...)
    end

    function Canvas(bounds::Rect2; resolution::Tuple{Int, Int} = (800, 800), op = AggCount())
        xsize, ysize = resolution
        n_elements = xsize * ysize
        o0 = null(op)
        v0 = value(op, o0)
        aggbuffer = fill(o0, n_elements)
        pixelbuffer = fill(v0, n_elements)
        # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
        return Canvas(Rect2{Float64}(bounds), resolution, op, aggbuffer, pixelbuffer, (v0, v0))
    end

    n_threads(::AggSerial) = 1
    n_threads(::AggThreads) = Threads.nthreads()

    function Base.resize!(canvas::Canvas, resolution::Tuple{Int, Int}, nthreads = 1)
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
        v0 = value(op, o0)
        if eltype(canvas.aggbuffer) != typeof(o0)
            canvas.aggbuffer = fill(o0, size(c.aggbuffer))
            canvas.pixelbuffer = fill(v0, size(c.pixelbuffer))
        end
        return true
    end

    using InteractiveUtils

    """
        aggregate!(c::Canvas, points; point_transform=identity, method::AggMethod=AggSerial())

    Aggregate points into a canvas. The points are transformed by `point_transform` before aggregation.
    Method can be `AggSerial()` or `AggThreads()`.
    """
    function aggregate!(c::Canvas, points; point_transform = identity, method::AggMethod = AggSerial())
        resize!(c, c.resolution, n_threads(method)) # make sure we have the right size for the method
        aggbuffer, pixelbuffer = c.aggbuffer, c.pixelbuffer
        fill!(aggbuffer, null(c.op))
        return aggregation_implementation!(method, aggbuffer, pixelbuffer, c, c.op, points, point_transform)
    end

    function aggregation_implementation!(
            ::AggSerial,
            aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
            c::Canvas, op::AggOp,
            points, point_transform
        )
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

    function aggregation_implementation!(
            ::AggThreads,
            aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
            c::Canvas, op::AggOp,
            points, point_transform
        )
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
        chunks = round.(Int, range(1, n; length = Threads.nthreads() + 1))

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

function equalize_histogram(matrix; nbins = 256)
    h_eq = StatsBase.fit(StatsBase.Histogram, vec(matrix); nbins = nbins)
    h_eq = normalize(h_eq; mode = :density)
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
    Can be `AggCount()`, `AggAny()` or `AggMean()`.
    Be sure, to use the correct element type e.g. `AggCount{Float32}()`, which needs to accommodate the output of `local_operation`.
    User-extensible by overloading:
    ```julia
    struct MyAgg{T} <: Makie.AggOp end
    MyAgg() = MyAgg{Float64}()
    Makie.Aggregation.null(::MyAgg{T}) where {T} = zero(T)
    Makie.Aggregation.embed(::MyAgg{T}, x) where {T} = convert(T, x)
    Makie.Aggregation.merge(::MyAgg{T}, x::T, y::T) where {T} = x + y
    Makie.Aggregation.value(::MyAgg{T}, x::T) where {T} = x
    ```
    """
    agg = AggCount{Float32}()
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
    operation = automatic
    """
    Function which gets called on each element after the aggregation (`map!(x-> local_operation(x), final_aggregation_result)`).
    """
    local_operation = identity

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
    Note that interpolation can make NaN-adjacent bins also NaN in some backends, for example
    due to interpolation schemes used in GPU hardware. This can make it look
    like there are more NaN bins than there actually are.
    """
    interpolate = false
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

function fast_bb(points, f)
    N = length(points)
    NT = Threads.nthreads()
    slices = ceil(Int, N / NT)
    results = fill(Point2d(0), NT, 2)
    R = eltype(points) isa Point2 ? Rect2d : Rect3d
    Threads.@threads for i in 1:NT
        start = ((i - 1) * slices + 1)
        stop = min(length(points), i * slices)
        pmin, pmax = extrema(R(view(points, start:stop)))
        results[i, 1] = f(Point2d(Point3d(pmin)))
        results[i, 2] = f(Point2d(Point3d(pmax)))
    end
    return Rect3f(Rect2f(vec(results)))
end


function canvas_computation!(p::DataShader)
    return register_computation!(p, [:axis_limits, :pixel_area, :binsize, :agg], [:canvas]) do (lims, pxarea, binsize, op), _, last
        if isnothing(last)
            canvas = Canvas(lims; resolution = (widths(pxarea)...,), op = op)
        else
            canvas = last.canvas
        end
        binsize isa Int || error("Bin factor $binsize is not an Int.")
        xsize, ysize = round.(Int, Makie.widths(pxarea) ./ binsize)
        has_changed = Base.resize!(canvas, (xsize, ysize))
        has_changed = has_changed || change_op!(canvas, op)
        lims64 = Rect2{Float64}(lims)
        if canvas.bounds != lims64
            has_changed = true
            canvas.bounds = lims64
        end
        has_changed = has_changed || isnothing(last)
        return has_changed ? (canvas,) : nothing
    end
end

function Makie.plot!(p::DataShader{<:Tuple{<:AbstractVector{<:Point}}})
    scene = parent_scene(p)
    add_axis_limits!(p)
    add_input!(p.attributes, :pixel_area, scene.viewport)
    canvas_computation!(p)

    register_computation!(p, [:points, :point_transform], [:data_limits]) do (points, f), _, _
        return (fast_bb(points, f),)
    end

    register_computation!(p, [:canvas, :points, :point_transform, :method, :colorrange], [:canvas_with_aggregation, :raw_colorrange]) do (canvas, points, f, method, crange), changed, _
        Aggregation.aggregate!(canvas, points; point_transform = f, method = method)
        if crange isa Automatic
            cr = Vec2f(distinct_extrema_nan(canvas.data_extrema))
        else
            cr = Vec2f(crange)
        end
        return (canvas, cr)
    end
    image!(
        p, p.canvas_with_aggregation, p.operation, p.local_operation;
        interpolate = p.interpolate,
        generic_plot_attributes(p)...,
        colormap_attributes(p)...
    )
    return p
end


function aggregate_categories!(canvases, categories; method = AggThreads())
    for (k, canvas) in canvases
        points = categories[k]
        Aggregation.aggregate!(canvas, points; method = method)
    end
    return
end

Makie.convert_arguments(::Type{<:DataShader}, x::Dict{String, Vector{<:Point2}}) = (x,)

function Makie.convert_arguments(::Type{<:DataShader}, groups::AbstractVector, points::AbstractVector{<:Point2})
    if length(groups) != length(points)
        error("Each point needs a group. Length $(length(groups)) != $(length(points))")
    end
    categories = Dict{String, Vector{Point2f}}()
    for (g, p) in zip(groups, points)
        gpoints = get!(() -> Point2f[], categories, string(g))
        push!(gpoints, p)
    end
    return (categories,)
end

function Makie.plot!(p::DataShader{<:Tuple{Dict{String, Vector{Point{2, Float32}}}}})
    scene = parent_scene(p)
    add_axis_limits!(p)
    add_input!(p.attributes, :pixel_area, scene.viewport)
    canvas_computation!(p)
    register_computation!(p, [:points, :point_transform], [:data_limits]) do (categories, f), _, _
        rects = map(points -> fast_bb(points, f), values(categories))
        return (reduce(union, rects),)
    end
    categories = p.points[]
    canvas = p.canvas[]
    canvases = Dict(
        k => Canvas(canvas.bounds; resolution = canvas.resolution, op = AggCount{Float32}())
            for (k, v) in categories
    )

    register_computation!(p, [:canvas, :points], [:canvas_with_aggregation, :total_value]) do (canvas, cats), _, _
        for (k, c) in canvases
            Base.resize!(c, canvas.resolution)
            c.bounds = canvas.bounds
        end
        aggregate_categories!(canvases, cats; method = p.method[])
        total_value = Float32(maximum(sum(map(x -> x.pixelbuffer, values(canvases)))))
        return (canvases, total_value)
    end
    colors = Dict(k => Makie.wong_colors()[i] for (i, (k, v)) in enumerate(categories))
    p._categories = colors
    op = lift(total -> (x -> log10(x + 1) / log10(total + 1)), p, p.total_value)

    for (k, canv) in canvases
        color = colors[k]
        cmap = [(color, 0.0), (color, 1.0)]
        image!(p, canv, identity, op; colorrange = Vec2f(0, 1), colormap = cmap)
    end
    return p
end

data_limits(p::DataShader)::Rect3d = p.data_limits[]
boundingbox(p::DataShader, space::Symbol = :data)::Rect3d = apply_transform_and_model(p, p.data_limits[])

function convert_arguments(P::Type{<:Union{MeshScatter, Image, Surface, Contour, Contour3d}}, canvas::Canvas, operation = automatic, local_operation = identity)
    pixel = Aggregation.get_aggregation(canvas; operation = operation, local_operation = local_operation)
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
        return FakePlot(Attributes(; plot = plot, label = name, color = color))
    end
end

function legendelements(plot::FakePlot, legend)
    return [PolyElement(; plots = plot.attributes.plot[], color = plot.attributes.color, strokecolor = legend.polystrokecolor, strokewidth = legend.polystrokewidth)]
end

# Sadly we must define the colorbar here and can't use the default fallback,
# Since the Image plot will only see the scaled data, and since its hard to make Colorbar support the equalize_histogram
# transform, we just create the colorbar form the raw data.
# TODO, should we merge the local/global op with colorscale?
function extract_colormap(plot::DataShader)
    color = lift(x -> x.pixelbuffer, plot, plot.canvas)
    attributes = [:colormap, :raw_colorrange, :colorscale, :alpha, :highclip, :lowclip, :nan_color]
    return ColorMapping(color[], color, map(k -> getindex(plot, k), attributes)...)
end

function xy_to_rect(x, y)
    xmin, xmax = extrema(x)
    ymin, ymax = extrema(y)
    return Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
end

"""
    Resampler(matrix; max_resolution=automatic, method=Interpolations.Linear(), update_while_button_pressed=false)

Creates a resampling type which can be used with `heatmap`, to display large images/heatmaps.
Passed can be any array that supports `array(linrange, linrange)`, as the interpolation interface from Interpolations.jl.
If the array doesn't support this, it will be converted to an interpolation object via: `Interpolations.interpolate(data, Interpolations.BSpline(method))`.
* `max_resolution` can be set to `automatic` to use the full resolution of the screen, or a tuple/integer of the desired resolution.
* `method` is the interpolation method used, defaulting to `Interpolations.Linear()`.
* `update_while_button_pressed` will update the heatmap while a mouse button is pressed, useful for zooming/panning. Set it to false for e.g. WGLMakie to avoid updating while dragging.
* `lowres_background` will always show a low resolution background while the high resolution image is being calculated.
"""
struct Resampler{T <: AbstractMatrix{<:Union{Real, Colorant}}}
    data::T
    max_resolution::Union{Automatic, Tuple{Int, Int}}
    update_while_button_pressed::Bool
    lowres_background::Bool
end

function Base.:(==)(a::Resampler, b::Resampler)
    return a.data == b.data && a.max_resolution == b.max_resolution &&
        a.update_while_button_pressed == b.update_while_button_pressed &&
        a.lowres_background == b.lowres_background
end

using Interpolations: Interpolations
using ImageBase: ImageBase

_to_resolution(::Automatic) = automatic
_to_resolution(x::Tuple{Int, Int}) = x
_to_resolution(x::Int) = (x, x)
_to_resolution(x) = error("Resolution must be automatic, a tuple or integer, got $x")

function Resampler(resampler::Resampler, new_data)
    return Resampler(
        new_data, resampler.max_resolution,
        resampler.update_while_button_pressed,
        resampler.lowres_background
    )
end

function Resampler(
        data;
        max_resolution = automatic,
        method = Interpolations.Linear(),
        update_while_button_pressed = false,
        lowres_background = true,
        resolution = nothing
    )
    if resolution !== nothing
        @warn "Resampler(data; resolution=...) got renamed to max_resolution, please update your code"
        max_resolution = resolution
    end
    # Our interpolation interface is to do matrix(linrange, linrange)
    # There doesn't seem to be an official trait for this,
    # so we fall back to just check if this method applies:
    # The type of LinRange has changed since Julia 1.6, so we need to construct it and use that
    lr = LinRange(0, 1, 10)
    res = _to_resolution(max_resolution)
    if applicable(data, lr, lr)
        return Resampler(data, res, update_while_button_pressed, lowres_background)
    else
        dataf32 = el32convert(data)
        ET = eltype(dataf32)
        # Interpolations happily converts to Float64 here, but that's not desirable for e.g. RGB{N0f8}, or Float32 data
        # Since we expect these arrays to be huge, this is no laughing matter ;)
        interp = Interpolations.interpolate(eltype(ET), ET, data, Interpolations.BSpline(method))
        return Resampler(interp, res, update_while_button_pressed, lowres_background)
    end
end

const HeatmapShader = Heatmap{<:Tuple{EndPoints{Float32}, EndPoints{Float32}, <:Resampler}}

# The things we need to do, to allow the atomic Heatmap plot type to be overloaded as a recipe
struct HeatmapShaderConversion <: ConversionTrait end

function conversion_trait(::Type{<:Heatmap}, x, y, ::Resampler)
    return HeatmapShaderConversion()
end
function conversion_trait(::Type{<:Heatmap}, ::Resampler)
    return HeatmapShaderConversion()
end

function types_for_plot_arguments(::Type{<:Heatmap}, ::HeatmapShaderConversion)
    return Tuple{EndPoints{Float32}, EndPoints{Float32}, <:Resampler}
end

function data_limits(p::HeatmapShader)
    return Rect3d(p.data_limits[])
end

function boundingbox(p::HeatmapShader, space::Symbol = :data)
    return apply_transform_and_model(p, data_limits(p))
end

function calculated_attributes!(::Type{Heatmap}, plot::HeatmapShader)
    return
end

extract_colormap_recursive(plot::HeatmapShader) = extract_colormap_recursive(plot.plots[1])


function resample_image(x, y, image, max_resolution, limits)
    # extent of the image in data coordinates (same as limits)
    xmin, xmax = x
    ymin, ymax = y
    data_rect = Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
    visible_rect = GeometryBasics.intersect(data_rect, limits)
    vmini = minimum(visible_rect)
    vw = widths(visible_rect)
    if !(visible_rect in data_rect) || any(w -> w <= 0, vw)
        return nothing
    end

    # (xmin, ymin), (xmax, ymax)
    ranges = minmax.(vmini, vmini .+ vw)
    # scaling from data coordinates to indices
    data_min = (xmin, ymin)
    data_width = (xmax - xmin, ymax - ymin)
    imgsize = size(image)
    x_index_range, y_index_range = ntuple(2) do i
        nrange = ranges[i]
        si = imgsize[i]
        indices = ((nrange .- data_min[i]) ./ data_width[i]) .* (si .- 1) .+ 1
        resolution = max(2, round(Int, indices[2] - indices[1]))
        len = min(resolution, max_resolution[i])
        return LinRange(max(1, indices[1]), min(indices[2], si), len)
    end
    if isempty(x_index_range) || isempty(y_index_range)
        return nothing
    end
    interpolated = image(x_index_range, y_index_range)
    return EndPoints{Float32}(ranges[1]), EndPoints{Float32}(ranges[2]), interpolated
end


function convert_arguments(::Type{Heatmap}, image::Resampler)
    x, y, _ = convert_arguments(Heatmap, image.data)
    return (x, y, image)
end

function convert_arguments(::Type{Heatmap}, x, y, image::Resampler)
    x, y, _ = convert_arguments(Heatmap, x, y, image.data)
    return (EndPoints{Float32}(x...), EndPoints{Float32}(y...), image)
end

function empty_channel!(channel::Channel)
    return lock(channel.cond_take) do
        while !isempty(channel)
            take!(channel)
        end
    end
end


function calculate_colorrange(img, crange)
    if eltype(img) <: Number
        if crange isa Automatic
            return Vec2f(nan_extrema(img))
        else
            return Vec2f(crange)
        end
    else
        return automatic # Matrix{<:Colorant}
    end
end

function Makie.plot!(p::HeatmapShader)
    scene = Makie.parent_scene(p)
    events = scene.events
    add_axis_limits!(p)
    slow_limits = Observable(Rect2f())
    onany(p, p.axis_limits, events.mousebutton, events.keyboardbutton) do lims, mbs, kbs
        update_while_pressed = p.image[].update_while_button_pressed
        no_mbutton = isempty(events.mousebuttonstate)
        no_kbutton = isempty(events.keyboardstate)
        last_lims = slow_limits[]
        if update_while_pressed || (no_mbutton && no_kbutton)
            # instead of ignore_equal_values=true (uses ==),
            # we check with isapprox to not update when there are very small changes
            if !(minimum(lims) ≈ minimum(last_lims) && widths(lims) ≈ widths(last_lims))
                slow_limits[] = lims
            end
        end
        return
    end
    add_input!(p.attributes, :slow_limits, slow_limits)

    map!(p.attributes, :resolution, :max_resolution) do resolution
        resampler = p.image[]
        res = resampler.max_resolution isa Automatic ? resolution : resampler.max_resolution
        return round.(Int, max.(res, 512)) # Not sure why, but viewport can become (1, 1)
    end

    map!(xy_to_rect, p.attributes, [:x, :y], :data_limits)

    map!(p.attributes, [:image, :x, :y, :max_resolution, :data_limits, :colorrange], [:x_endpoints, :y_endpoints, :overview_image, :computed_colorrange]) do image, x, y, max_resolution, image_area, crange
        x, y, img = resample_image(x, y, image.data, max_resolution, image_area)
        cr = calculate_colorrange(img, crange)
        if image.lowres_background
            val = cr isa Vec2 ? mean(cr) : 0.0f0 # TODO color mean?
            _img = Float32[val for _ in 1:1, _ in 1:1]
        else
            _img = img
        end
        return x, y, _img, cr
    end

    register_computation!(p.attributes, [:image, :x, :y, :max_resolution, :slow_limits], [:lx_endpoints, :ly_endpoints, :limit_image, :l_visible]) do (image, x, y, max_resolution, limits), changed, last
        xe_ye_oimg = resample_image(x, y, image.data, max_resolution, limits)
        if isnothing(xe_ye_oimg)
            if isnothing(last) # first downsample
                return (x, x, fill(0.0f0, 2, 2), false)
            else
                return (nothing, nothing, nothing, false) # simply dont update!
            end
        end
        return (xe_ye_oimg..., true)
    end

    gpa = generic_plot_attributes(p)
    cpa = colormap_attributes(p)


    # Create an overview image that gets shown behind, so we always see the "big picture"
    # In case updating the detailed view takes longer
    lp = image!(p, p.x, p.y, p.overview_image; gpa..., cpa..., interpolate = p.interpolate, colorrange = p.computed_colorrange)
    translate!(lp, 0, 0, -1)

    image!(
        p, p.lx_endpoints, p.ly_endpoints, p.limit_image;
        gpa..., cpa..., interpolate = p.interpolate, colorrange = p.computed_colorrange, visible = p.l_visible,
    )

    return p
end

struct Pyramid{T, M <: AbstractMatrix{T}} <: AbstractMatrix{T}
    data::Vector{M}
end

function Pyramid(data::AbstractMatrix; min_resolution = 1024, mode = Interpolations.Linear())
    ranges(d) = (LinRange(1, size(data, 1), size(d, 1)), LinRange(1, size(data, 2), size(d, 2)))
    ET = ImageBase.restrict_eltype(first(data))
    resized = convert(Matrix{ET}, data)
    pyramid = [Interpolations.interpolate(eltype(ET), ET, ranges(resized), resized, Interpolations.Gridded(mode))]
    while any(x -> x > min_resolution, size(resized))
        resized = ImageBase.restrict(resized)
        interp = Interpolations.interpolate(
            eltype(ET), ET, ranges(resized), resized,
            Interpolations.Gridded(mode)
        )
        push!(pyramid, interp)
    end
    return Pyramid(pyramid)
end

function (p::Pyramid)(x::LinRange, y::LinRange)
    xystep = step.((x, y))
    maxsize = size(p.data[1])
    val, idx = findmin(p.data) do data
        steps = step.(LinRange.(1, maxsize, size(data)))
        return norm(xystep .- steps)
    end
    level = p.data[idx]
    return level(x, y)
end

function Base.size(p::Pyramid)
    return size(p.data[1])
end
function Base.show(io::IO, ::MIME"text/plain", p::Pyramid)
    return show(io, p)
end
function Base.show(io::IO, p::Pyramid)
    return println(io, "Pyramid with levels: $(size.(p.data))")
end

export Resampler
