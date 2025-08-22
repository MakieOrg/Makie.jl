"""
    streamplot(f::function, xinterval, yinterval; color = norm, kwargs...)

f must either accept `f(::Point)` or `f(x::Number, y::Number)`.
f must return a Point2.

Example:
```julia
v(x::Point2{T}) where T = Point2f(x[2], 4*x[1])
streamplot(v, -2..2, -2..2)
```

## Implementation
See the function `Makie.streamplot_impl` for implementation details.
"""
@recipe StreamPlot (f, limits) begin
    stepsize = 0.01
    gridsize = (32, 32, 32)
    maxsteps = 500
    """
    One can choose the color of the lines by passing a function `color_func(dx::Point)` to the `color` attribute.
    This can be set to any function or composition of functions.
    The `dx` which is passed to `color_func` is the output of `f` at the point being colored.
    """
    color = norm

    arrow_size = automatic
    arrow_head = automatic
    density = 1.0
    quality = 16

    linewidth = @inherit linewidth
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    linestyle = nothing
    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
end

function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange, yrange)
    xmin, xmax = extrema(xrange)
    ymin, ymax = extrema(yrange)
    return (f, Rect(xmin, ymin, xmax - xmin, ymax - ymin))
end

function convert_arguments(::Type{<:StreamPlot}, f::Function, xrange, yrange, zrange)
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
            if !(point isa Point2 || point isa Point3)
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
