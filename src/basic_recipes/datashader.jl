# originally from https://github.com/cjdoris/ShadeYourData.jl

module PixelAggregation

import Base.Threads: @threads
import Makie: Makie, FRect3D, lift, (..), Colors
using Makie.DocStringExtensions

"""
    struct Canvas{T}
    Canvas(xmin::T, xmax::T, xsize::Int, ymin::T, ymax::T, ysize::Int)

This represents a canvas on which to draw.  
It holds a representation of a Rect2f in the x/y min/max variables, 
and the size of the canvas in the x/y size variables.

## Fields
$(FIELDS)
"""
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

"""
    abstract type AggOp

Abstract type for aggregation operations. These are used to aggregate
values in a bin. The `update` function is called for each value in a bin,
and the `value` function is called to get the final value for the bin.

!!! note
    This lives in the `Makie.PixelAggregation` module, and should be used as such.

## API

Any aggregation operation must be a subtype of `AggOp`, and must implement
the following methods:
- `null(::MyAggOpp)`: return the null value for the aggregation operation.
- `embed(::MyAggOpp)`: return the one value for the aggregation operation.
- `merge(::MyAggOpp, x, y)`: merge `x` and `y`, which are both of the type which 
  `null` and `embed` return, and return the result.
- `value(::MyAggOpp, x)`: return the final value for the aggregation operation.  
   For example, a mean may aggregate a sum and count of values, then divide them in `value`.
- `update(::MyAggOpp, x, args...)`: update the aggregation operation with a new value `x` 
   and any additional arguments `args...`.  A fallback implementation is defined, so you don't
   usually need to define this.  The fallback is `update(a::AggOp, x, args...) = merge(a, x, embed(a, args...))`.

## Built-in aggregation operations
See [`AggCount`](@ref), [`AggAny`](@ref), [`AggSum`](@ref), and [`AggMean`](@ref).
"""
abstract type AggOp end

@inline update(a::AggOp, x, args...) = merge(a, x, embed(a, args...))

"""
    AggCount()

Aggregation operation which counts the number of values in a bin.

See the [`AggOp`](@ref) documentation for more information on how to use this.
"""
struct AggCount{T} <: AggOp end
AggCount() = AggCount{Int}()
null(::AggCount{T}) where {T} = zero(T)
embed(::AggCount{T}) where {T} = oneunit(T)
merge(::AggCount{T}, x::T, y::T) where {T} = x + y
value(::AggCount{T}, x::T) where {T} = x

"""
    AggAny()

Aggregation operation which returns `true` if any value exists in a bin.

See the [`AggOp`](@ref) documentation for more information on how to use this.
"""
struct AggAny <: AggOp end
null(::AggAny) = false
embed(::AggAny) = true
merge(::AggAny, x::Bool, y::Bool) = x | y
value(::AggAny, x::Bool) = x

"""
    AggSum()

Aggregation operation which sums values in a bin.

See the [`AggOp`](@ref) documentation for more information on how to use this.
"""
struct AggSum{T} <: AggOp end
AggSum() = AggSum{Float64}()
null(::AggSum{T}) where {T} = zero(T)
embed(::AggSum{T}, x) where {T} = convert(T, x)
merge(::AggSum{T}, x::T, y::T) where {T} = x + y
value(::AggSum{T}, x::T) where {T} = x

"""
    AggMean()

Aggregation operation which computes the mean of values in a bin.

See the [`AggOp`](@ref) documentation for more information on how to use this.
"""
struct AggMean{T} <: AggOp end
AggMean() = AggMean{Float64}()
null(::AggMean{T}) where {T} = (zero(T), zero(T))
embed(::AggMean{T}, x) where {T} = (convert(T,x), oneunit(T))
merge(::AggMean{T}, x::Tuple{T,T}, y::Tuple{T,T}) where {T} = (x[1]+y[1], x[2]+y[2])
value(::AggMean{T}, x::Tuple{T,T}) where {T} = float(x[1]) / float(x[2])

"""
    AggColorPalette(palette::Vector{ColorType} = Makie.wong_colors(), null_color = zero(ColorType))

Aggregation operation which computes the colorimetric mean of values in a bin.

By default, this operates in RGB space using the Wong color palette.  However, 
the intrepid user can specify their own color space by converting the input palette
into e.g. `Lab` or `XYZ` space.

We personally recommend using `Lab` (CIELAB) space, since addition there is actual color composition.
"""
struct AggColorPalette{ColorType <: Colors.Colorant} <: AggOp
    palette::Vector{ColorType}
    null_color::ColorType
    AggColorPalette{T}(palette::Vector{T}, null_color = zero(T)) where {T <: Colors.Colorant} = new{T}(palette, T(null_color))
end
# define some constructors
AggColorPalette() = AggColorPalette{Makie.Colors.Lab{Float32}}(Makie.wong_colors(), zero(Makie.Colors.XYZ))
AggColorPalette(palette::Vector{T}, null_color = zero(T)) where {T <: Colors.Colorant} = AggColorPalette{T}(convert.((T,), palette), convert(T, null_color))
AggColorPalette{T1}(palette::Vector{T2}, null_color = zero(T)) where {T1 <: Colors.Colorant, T2 <: Union{Colors.Colorant, Symbol, String}} = AggColorPalette{T1}(convert.((T1,), palette), convert(T1, null_color))
# implement the AggOp API
null(agg::AggColorPalette{ColorType}) where ColorType = (agg.null_color, 1)
embed(agg::AggColorPalette{ColorType}, z) where ColorType = (agg.palette[round(Int, z)], 1)
merge(::AggColorPalette{ColorType}, x::Tuple{ColorType, Int}, y::Tuple{ColorType, Int}) where ColorType = begin
    total = x[2] + y[2]
    (Makie.Colors.weighted_color_mean(x[2]/total, x[1], y[1]), total)
end
value(::AggColorPalette{ColorType}, x::Tuple{ColorType, Int}) where ColorType = x[1]

"""
    abstract type AggMethod

Abstract type for aggregation methods.

These indicate whether to use serial processing, threads, etc.

## Available methods
- [`AggSerial`](@ref): Serial aggregation on 1 CPU thread
- [`AggThreads`](@ref): Parallel aggregation on multiple CPU threads, 
  specifically `Threads.nthreads()` threads.  This uses Julia's native 
  threading semantics.  In order to control the number of threads used, 
  you must start Julia with `julia -t N` where `N` is the number of threads to use.

!!! note
    This lives in the `Makie.PixelAggregation` module, and should be used as such.

## Future work
- GPU aggregation: One could pretty easily define a method, perhaps in an extension package which works on the GPU using CUDA.jl or AMDGPU.jl.
"""
abstract type AggMethod end

struct AggSerial <: AggMethod end
struct AggThreads <: AggMethod end

function aggregate!(aggbuffer, pixelbuffer, c::Canvas, points, local_op, point_func; op::AggOp=AggCount(), method::AggMethod=AggSerial())
    fill!(aggbuffer, null(op))
    return aggregation_implementation!(method, aggbuffer, pixelbuffer, c, op, points, local_op, point_func)
end

function aggregation_implementation!(
        ::AggSerial,
        aggbuffer::AbstractVector, pixelbuffer::AbstractVector,
        c::Canvas, op::AggOp,
        points, local_op, point_func)

    xmin, xmax = xlims(c)
    ymin, ymax = ylims(c)
    xsize, ysize = size(c)
    xmax > xmin || error("require xmax > xmin")
    ymax > ymin || error("require ymax > ymin")
    xwidth = xmax - xmin
    xscale = xsize / (xwidth + eps(xwidth))
    ywidth = ymax - ymin
    yscale = ysize / (ywidth + eps(ywidth))

    @assert length(aggbuffer) == xsize * ysize
    @assert length(pixelbuffer) == xsize * ysize
    @assert eltype(aggbuffer) === typeof(null(op))

    # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
    out = Base.ReshapedArray(aggbuffer, (xsize, ysize), ())

    @inbounds for point in points
        p = point_func(point)
        x = p[1]
        y = p[2]
        if length(p) > 2 # should compile away
            z = p[3]
        end
        xmin ≤ x ≤ xmax || continue
        ymin ≤ y ≤ ymax || continue
        i = 1 + floor(Int, xscale*(x-xmin))
        j = 1 + floor(Int, yscale*(y-ymin))
        if length(p) == 2 # should compile away
            out[i,j] = update(op, out[i,j])
        elseif length(p) == 3
            out[i,j] = update(op, out[i,j], z)
        end
    end

    mini, maxi = Inf, -Inf
    map!(pixelbuffer, aggbuffer) do x
        final_value = local_op(value(op, x))
        if isfinite(final_value)
            mini = min(final_value, mini)
            maxi = max(final_value, maxi)
        end
        return final_value
    end
    return (mini, maxi)
end
# TODO: lift type of pixbuf, and return (0, 1) colorrange if it's not a number
function aggregation_implementation!(
        ::AggThreads,
        aggbuffer::AbstractVector, pixelbuffer::AbstractVector{ValueType},
        c::Canvas, op::AggOp,
        points, local_op, point_func) where ValueType
    xmin, xmax = xlims(c)
    ymin, ymax = ylims(c)
    xsize, ysize = size(c)
    xmax > xmin || error("require xmax > xmin")
    ymax > ymin || error("require ymax > ymin")
    # by adding eps to width we can use the scaling factor plus floor directly to compute the bin indices
    xwidth = xmax - xmin
    xscale = xsize / (xwidth + eps(xwidth))
    ywidth = ymax - ymin
    yscale = ysize / (ywidth + eps(ywidth))

    # each thread reduces some of the data separately
    @assert length(aggbuffer) == Threads.nthreads() * xsize * ysize
    @assert length(pixelbuffer) == xsize * ysize
    @assert eltype(aggbuffer) === typeof(null(op))

    # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
    out = Base.ReshapedArray(aggbuffer, (xsize, ysize, Threads.nthreads()), ())
    out2 = Base.ReshapedArray(pixelbuffer, (xsize, ysize), ())
    n = length(points)
    chunks = round.(Int, range(1, n, length = Threads.nthreads()+1))

    @threads for t in 1:Threads.nthreads()
        from = chunks[t]
        to = chunks[t+1]
        for idx in from:to
            p = @inbounds point_func(points[idx])
            x = p[1]
            y = p[2]
            if length(p) > 2 # should compile away
                z = p[3]
            end
            xmin ≤ x ≤ xmax || continue
            ymin ≤ y ≤ ymax || continue
            i = 1 + floor(Int, xscale*(x-xmin))
            j = 1 + floor(Int, yscale*(y-ymin))
            if length(p) == 2 # should compile away
                @inbounds out[i,j,t] = update(op, out[i,j,t])
            elseif length(p) == 3
                @inbounds out[i,j,t] = update(op, out[i,j,t], z)
            end
        end
    end
    # reduce along the thread dimension
    if ValueType <: Number
        mini, maxi = Inf, -Inf
        for j in 1:ysize
            for i in 1:xsize
                @inbounds val = out[i,j,1]
                for t in 2:Threads.nthreads()
                    @inbounds val = merge(op, val, out[i,j,t])
                end
                # update the value in out2 directly in this loop
                final_value = local_op(value(op, val))
                if isfinite(final_value)
                    mini = min(final_value, mini)
                    maxi = max(final_value, maxi)
                end
                @inbounds out2[i, j] = final_value
            end
        end
        return (mini, maxi)
    else
        mini, maxi = Inf, -Inf
        for j in 1:ysize
            for i in 1:xsize
                @inbounds val = out[i,j,1]
                for t in 2:Threads.nthreads()
                    @inbounds val = merge(op, val, out[i,j,t])
                end
                # update the value in out2 directly in this loop
                final_value = local_op(value(op, val))
                @inbounds out2[i, j] = final_value
            end
        end
        return (0, 1)
    end
end


export AggAny, AggCount, AggMean, AggSum, AggSerial, AggThreads

end

using ..PixelAggregation

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
- `async_latest::Bool = true` will calculate aggregation in a task, and skip any zoom/pan updates while busy. Great for interaction, but must be disabled for saving to e.g. png or when inlining in documenter.

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
        async_latest = true,
        # Defaults to equalize_histogram
        # just set to automatic, so that if one sets local_post, one doesn't do equalize_histogram on top of things.
        global_post = automatic,
        local_post = identity,

        point_func = identity,
        binfactor = 1,
        show_timings = false,

        colormap = theme(scene, :colormap),
        colorrange = automatic,
        lowclip = to_color(:black),
        highclip = nothing,
        nan_color = :transparent
    )
end

conversion_trait(::Type{<: DataShader}) = PointBased()

function fast_bb(points::AbstractArray{<: Point2}, f)
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

fast_bb(points::AbstractArray{<: Point3}, f) = fast_bb(to_ndim.(Point2f, points, 0), f)

function Makie.plot!(p::DataShader{<: Tuple{<: AbstractVector{<: Point}}})
    scene = parent_scene(p)

    limits = lift(projview_to_2d_limits, p, scene.camera.projectionview; ignore_equal_values=true)
    px_area = lift(identity, p, scene.px_area; ignore_equal_values=true)

    canvas = lift(limits, px_area, p.binfactor; ignore_equal_values=true) do lims, pxarea, binfactor
        # binfactor isa Int || error("Bin factor $binfactor is not an Int.")
        xsize, ysize = round.(Int, Makie.widths(pxarea) ./ binfactor)
        xmin, ymin = minimum(lims)
        xmax, ymax = maximum(lims)
        return PixelAggregation.Canvas(xmin, xmax, xsize, ymin, ymax, ysize)
    end

    # optimize `data_limits` to be only calculated on changed data
    p._boundingbox = lift(fast_bb, p.points, p.point_func)

    xrange = Observable((canvas[].xmin .. canvas[].xmax); ignore_equal_values=true)
    yrange = Observable((canvas[].ymin .. canvas[].ymax); ignore_equal_values=true)

    # use resizable buffer vectors for aggregation

    # first - get the null type of the aggregator
    # TODO: this means that the aggregator type can't be changed!
    null_agg = PixelAggregation.null(p.agg[])
    # then get the type of the final result
    value_agg = PixelAggregation.value(p.agg[], null_agg)
    # now, construct the resizable buffers
    aggbuffer = fill(null_agg, 0)
    pixelbuffer = fill(value_agg, canvas[].xsize * canvas[].ysize)
    pixels = Observable{Matrix{typeof(value_agg)}}()

    # handle colorrange - ideally, we should go from 0 to 1, with `lowclip` defined.
    colorrange = Observable(Vec2f(0, 1))
    on(p, p.colorrange; update=true) do crange
        if crange isa Tuple || crange isa Vec2
            colorrange[] = Vec2f(crange)
        end
    end
    # TODO move this out into a function one can directly call without going through the recipe
    # to just get Matrix{<: Float} -> Matrix{<: Colorant}
    function update_pixels(canvas, agg, global_post, local_post, method, points, point_func)
        tstart = time()
        w = canvas.xsize
        h = canvas.ysize
        xrange.val = canvas.xmin .. canvas.xmax
        yrange.val = canvas.ymin .. canvas.ymax

        n_threads(::AggSerial) = 1
        n_threads(::AggThreads) = Threads.nthreads()
        n_elements = w * h * n_threads(method)

        # if aggbuffer has the appropriate element type for the current aggregation scheme
        # we can reuse it
        if eltype(aggbuffer) === typeof(PixelAggregation.null(agg))
            resize!(aggbuffer, n_elements)
        else
            # otherwise we allocate a new array
            aggbuffer = fill(PixelAggregation.null(agg), n_elements)
        end

        resize!(pixelbuffer, w * h)

        mini_maxi = PixelAggregation.aggregate!(aggbuffer, pixelbuffer, canvas, points, local_post,
                                                point_func; op=agg, method)
        # using ReshapedArray directly like this is not advised, but as it lives only briefly it should be ok
        pixelbuffer_reshaped = Base.ReshapedArray(pixelbuffer, (canvas.xsize, canvas.ysize), ())

        if global_post === automatic
            _global_post = local_post === identity ? equalize_histogram : identity
        else
            _global_post = global_post
        end

        pixels[] = _global_post(pixelbuffer_reshaped)

        if _global_post !== identity && p.colorrange[] isa Automatic
            cmin, cmax = extrema(pixels[])
            colorrange[] = if cmin < 0
                Vec2f(cmin, cmax)
            else
                Vec2f(1, cmax)
            end
        elseif _global_post === identity && p.colorrange[] isa Automatic
            cmin, cmax = mini_maxi
            colorrange[] = if cmin < 0
                Vec2f(cmin, cmax)
            else
                Vec2f(1, cmax)
            end
        end
        elapsed = time() - tstart
        if p.show_timings[]
            println("aggregation took $(round(elapsed; digits=5))s")
        end
        return
    end
    @show p.async_latest[]
    if p.async_latest[]
        onany_latest(update_pixels, canvas, p.agg, p.global_post, p.local_post, p.method, p.points, p.point_func;
                 update=true)
    else
        onany(update_pixels, canvas, p.agg, p.global_post, p.local_post, p.method, p.points[], p.point_func)
        update_pixels(canvas[], p.agg[], p.global_post[], p.local_post[], p.method[], p.points[], p.point_func[])
    end
    image!(p, xrange, yrange, pixels; colorrange=colorrange, colormap = p.colormap, lowclip = p.lowclip, highclip = p.highclip, nan_color = p.nan_color)
    return p
end

function Makie.data_limits(p::DataShader{<: Tuple{<:AbstractVector{<:Point}}})
    return p._boundingbox[]
end

# ```julia
# normaldist = randn(Point2f, 1_000_000)
# ds1 = to_ndim.(Point3f, normaldist .+ (Point2f(-1, 0),), 1)
# ds2 = to_ndim.(Point3f, normaldist .+ (Point2f(1, 0),), 2)
# datashader(vcat(ds1, ds2); agg = Makie.PixelAggregation.AggColorPalette(Makie.to_color.([:red, :blue])), global_post = identity, async_latest = false)
# ```

# # RGBA v/s LAB compositing
# The difference is actually quite a lot!
# ```julia
# with_theme(theme_dark()) do
#     fig = Figure(resolution = (800, 1600))
#     titles = ("RGBA", "LAB")
#     axs = [Axis(fig[i, j]; title = titles[i], titlesize = 60) for i in 1:2, j in (1,)]
#     hidedecorations!.(axs)
#     datashader!(axs[1], vcat(ds1, ds2); agg = Makie.PixelAggregation.AggColorPalette(to_color.([:red, :blue]), to_color(:black)), global_post = identity, async_latest = false)
#     datashader!(axs[2], vcat(ds1, ds2); agg = Makie.PixelAggregation.AggColorPalette{Makie.Colors.Lab{Float32}}(to_color.([:red, :blue]), to_color(:black)), global_post = identity, async_latest = false)
#     fig
# end
# ```
# and in light theme,
# ```julia
# with_theme(Makie.minimal_default) do
#     fig = Figure(resolution = (800, 1600))
#     titles = ("RGBA", "LAB")
#     axs = [Axis(fig[i, j]; title = titles[i], titlesize = 60) for i in 1:2, j in (1,)]
#     hidedecorations!.(axs)
#     datashader!(axs[1], vcat(ds1, ds2); agg = Makie.PixelAggregation.AggColorPalette(to_color.([:red, :blue]), to_color(:white)), global_post = identity, async_latest = false)
#     datashader!(axs[2], vcat(ds1, ds2); agg = Makie.PixelAggregation.AggColorPalette{Makie.Colors.ALab{Float32}}(to_color.([:red, :blue]), to_color(:transparent)), global_post = identity, async_latest = false)
#     fig
# end
# ```