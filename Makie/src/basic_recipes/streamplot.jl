"""
    streamplot(f::function, xinterval, yinterval[, zinterval]; color = norm, kwargs...)
    streamplot(f::function, rect; color = norm, kwargs...)

Plots streamlines of the function `f` in the given bounding box. A streamline is
defined by matching its tangent vector with `f(p)` at any point `p`.

`f` must either accept `f(::Point)` or `f(x::Number, y::Number[, z::Number])`
and must return a subtype of `VecTypes{2}` or `VecTypes{3}`, for example a
`Vec2f` or `Point3d`.

Example:
```julia
v(x::Point2{T}) where T = Point2f(x[2], 4*x[1])
streamplot(v, -2..2, -2..2)
```

## Implementation
See the function `Makie.streamplot_impl` for implementation details.
"""
@recipe StreamPlot (f, limits) begin
    """
    Controls the discretization of streamlines. The smaller `stepsize`, the
    closer line points are together. The stepsize acts on the normalized output
    of `f` without taking limits into account.
    """
    stepsize = 0.01
    """
    Controls the discretization of the bounding box. With `density = 1` each
    square/cube will be visited by at least one streamline.
    """
    gridsize = (32, 32, 32)
    "Controls the maximum number of points per streamline."
    maxsteps = 500
    """
    One can choose the color of the lines by passing a function `color_func(dx::Point)` to the `color` attribute.
    This can be set to any function or composition of functions.
    The `dx` which is passed to `color_func` is the output of `f` at the point being colored.
    """
    color = norm

    """
    Sets the size of arrow markers. The default is scaled to the bounding box
    and gridsize of the plot
    """
    arrow_size = automatic
    """
    Sets the marker for arrows which show the direction of the streamline. The
    default marker is either a (scatter) triangle or cone mesh, depending on
    dimensionality.
    """
    arrow_head = automatic
    """
    Sets the number of cells which need to be visited by streamlines. This must
    be between 0 and 1.
    """
    density = 1.0
    "Sets the quality of the cone mesh generated for 3D arrow markers."
    quality = 16

    "Sets the linewidth of streamlines."
    linewidth = @inherit linewidth
    """
    Sets the type of line cap used for streamlines. Options are `:butt` (flat without extrusion),
    `:square` (flat with half a linewidth extrusion) or `:round`.
    """
    linecap = @inherit linecap
    """
    Controls the rendering at line corners. Options are `:miter` for sharp corners,
    `:bevel` for cut-off corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    joinstyle = @inherit joinstyle
    """"
    Sets the minimum inner line join angle below which miter joins truncate. See
    also `Makie.miter_distance_to_angle`.
    """
    miter_limit = @inherit miter_limit
    "Sets the dash pattern for lines. See `?lines`."
    linestyle = nothing
    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
end

argument_dims(::Type{<:StreamPlot}, f, rect) = nothing
argument_dims(::Type{<:StreamPlot}, f, x, y) = (0, 1, 2)
argument_dims(::Type{<:StreamPlot}, f, x, y, z) = (0, 1, 2, 3)

# Normalize x, y, (z) types for dim converts
function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange::RangeLike, yrange::RangeLike)
    return (f, extrema(xrange), extrema(yrange))
end
function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange::RangeLike, yrange::RangeLike, zrange::RangeLike)
    return (f, extrema(xrange), extrema(yrange), extrema(zrange))
end

function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange::RangeLike{<:Real}, yrange::RangeLike{<:Real})
    xmin, xmax = extrema(xrange)
    ymin, ymax = extrema(yrange)
    return (f, Rect(xmin, ymin, xmax - xmin, ymax - ymin))
end

function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange::RangeLike{<:Real}, yrange::RangeLike{<:Real}, zrange::RangeLike{<:Real})
    xmin, xmax = extrema(xrange)
    ymin, ymax = extrema(yrange)
    zmin, zmax = extrema(zrange)
    mini = Vec3(xmin, ymin, zmin)
    maxi = Vec3(xmax, ymax, zmax)
    return (f, Rect(mini, maxi .- mini))
end

function convert_arguments(::Type{<:StreamPlot}, f::Function, limits::Rect)
    return (f, limits)
end

scatterfun(N) = N == 2 ? scatter! : meshscatter!

function arrow_head(N, ::Automatic, quality)
    if N == 2
        return :utriangle
    else
        return Tessellation(Cone(Point3f(0), Point3f(0, 0, 1), 0.5f0), quality)
    end
end
arrow_head(N, marker, quality) = marker

"""
streamplot_impl(CallType, f, limits::Rect{N, T}, resolutionND, stepsize)

Code adapted from an example implementation by Moritz Schauer (@mschauer)
from https://github.com/MakieOrg/Makie.jl/issues/355#issuecomment-504449775

Background: The algorithm puts an arrow somewhere and extends the
streamline in both directions from there. Then, it chooses a new
position (from the remaining ones), repeating the the exercise until the
streamline gets blocked, from which on a new starting point, the process
repeats.

So, ideally, the new starting points for streamlines are not too close to
current streamlines.

Links:

[Quasirandom sequences](http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/)
"""
function streamplot_impl(CallType, f, limits::Rect{N, T}, resolutionND, stepsize, maxsteps = 500, dens = 1.0, color_func = norm) where {N, T}
    resolution = to_ndim(Vec{N, Int}, resolutionND, last(resolutionND))
    mask = trues(resolution...) # unvisited squares
    arrow_pos = Point{N, Float32}[]
    arrow_dir = Vec{N, Float32}[]
    line_points = Point{N, Float32}[]
    _cfunc = x -> to_color(color_func(x))
    ColorType = typeof(_cfunc(Point{N, Float32}(0.0)))
    line_colors = ColorType[]
    colors = ColorType[]
    dt = Point{N, Float32}(stepsize)
    mini, maxi = minimum(limits), maximum(limits)
    r = ntuple(N) do i
        LinRange(mini[i], maxi[i], resolution[i] + 1)
    end
    apply_f(x0, P) = P <: Point ? f(x0) : f(x0...)

    # see http://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
    ϕ = (MathConstants.φ, 1.324717957244746, 1.2207440846057596)[N]
    acoeff = ϕ .^ (-(1:N))
    n_points = 0 # count visited squares
    ind = 0 # index of low discrepancy sequence
    while n_points < prod(resolution) * min(one(dens), dens) # fill up to 100*dens% of mask
        # next index from low discrepancy sequence
        c = CartesianIndex(
            ntuple(N) do i
                j = ceil(Int, ((0.5 + acoeff[i] * ind) % 1) * resolution[i])
                clamp(j, 1, size(mask, i))
            end
        )
        ind += 1
        if mask[c]
            x0 = Point{N}(
                ntuple(N) do i
                    first(r[i]) + (c[i] - 0.5) * step(r[i])
                end
            )
            point = apply_f(x0, CallType)
            if !(point isa Union{VecTypes{2}, VecTypes{3}})
                error("Function passed to streamplot must return Point2 or Point3")
            end
            pnorm = norm(point)
            color = _cfunc(point)
            push!(arrow_pos, x0)
            push!(arrow_dir, point ./ pnorm)
            push!(colors, color)
            mask[c] = false
            n_points += 1
            for d in (-1, 1)
                n_linepoints = 1
                x = x0
                ccur = c
                push!(line_points, Point{N, Float32}(NaN), x)
                push!(line_colors, color, color)
                while x in limits && n_linepoints < maxsteps
                    point = apply_f(x, CallType)
                    pnorm = norm(point)
                    x = x .+ d .* dt .* point ./ pnorm
                    if !(x in limits)
                        break
                    end
                    # WHAT? Why does point behave different from tuple in this
                    # broadcast
                    idx = CartesianIndex(searchsortedlast.(r, Tuple(x)))
                    if idx != ccur
                        if !mask[idx]
                            break
                        end
                        mask[idx] = false
                        n_points += 1
                        ccur = idx
                    end
                    push!(line_points, x)
                    push!(line_colors, _cfunc(point))
                    n_linepoints += 1
                end
            end
        end
    end

    return (
        arrow_pos,
        arrow_dir,
        line_points,
        colors,
        line_colors,
    )
end

function plot!(p::StreamPlot)
    # TODO: if reasonable, break this up into parts

    map!(
        p,
        [:f, :limits, :gridsize, :stepsize, :maxsteps, :density, :color],
        [:arrow_positions, :arrow_directions, :line_points, :arrow_colors, :line_colors]
    ) do f, args...
        CallType = applicable(f, Point2f(0)) || applicable(f, Point3f(0)) ? Point : Number
        return streamplot_impl(CallType, f, args...)
    end

    lines!(p, p.attributes, p.line_points, color = p.line_colors, fxaa = false)

    N = ndims(p.limits[])

    if N == 2
        # In 2D rotations apply in markerspace (pixel space here), which means
        # they may be affected by the transform_func (e.g. curved space) and
        # scaling from projection pipeline (including float32convert). To correct
        # for this we use:
        register_projected_rotations_2d!(
            p,
            position_name = :arrow_positions, direction_name = :arrow_directions,
            rotation_transform = x -> x - 0.5f0 * pi
        )
    else
        # In 3D rotations apply in model space, i.e. after `transform_func` and
        # before `model`. So here we only need to consider `transform_func` with:
        register_transformed_rotations_3d!(
            p, position_name = :arrow_positions, direction_name = :arrow_directions
        )
    end

    map!(p, [:arrow_size, :limits, :gridsize], :computed_arrow_size) do arrow_size, limits, gridsize
        if arrow_size === automatic
            if N == 3
                return 0.2 * minimum(p.limits[].widths) / minimum(p.gridsize[])
            else
                return 15
            end
        else
            return arrow_size
        end
    end

    map!((ah, q) -> arrow_head(N, ah, q), p, [:arrow_head, :quality], :arrow_marker)

    scatterfun(N)(
        p,
        p.attributes,
        p.arrow_positions;
        markersize = p.computed_arrow_size,
        rotation = getindex(p, :rotations),
        color = p.arrow_colors,
        marker = p.arrow_marker,
        fxaa = N == 3
    )

    return p
end
