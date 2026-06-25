"""
    ablines(intercepts, slopes; attrs...)

Creates a line defined by `f(x) = slope * x + intercept` crossing a whole `Scene` with 2D projection at its current limits.
You can pass one or multiple intercepts or slopes.

Under a non-identity axis scale the line is drawn as a subdivided curve, so it stays correct on e.g. log axes.
"""
@recipe ABLines (intercept, slope) begin
    documented_attributes(Lines)...
end

const N_ABLINE_SUBDIVISIONS = 256

function Makie.plot!(p::ABLines)
    add_axis_limits!(p)

    map!(
        p.attributes,
        [:axis_limits, :axis_limits_transformed, :intercept, :slope, :transform_func],
        :points
    ) do lims, lims_transformed, intercept, slope, transf
        points = Point2d[]
        broadcast_foreach(intercept, slope) do intercept, slope
            append_abline_curve!(points, lims, lims_transformed, transf, intercept, slope)
        end
        return points
    end

    for attr in (:color, :linewidth)
        map!(p.attributes, [attr, :intercept, :slope, :transform_func], Symbol(attr, :_expanded)) do val, intercept, slope, transf
            return expand_per_abline(val, n_ablines(intercept, slope), points_per_abline(transf))
        end
    end

    lines!(
        p, Attributes(p), p.points,
        color = p.color_expanded, linewidth = p.linewidth_expanded,
        transformation = :inherit_model
    )
    return p
end

points_per_abline(transf) = (is_identity_transform(transf) ? 2 : N_ABLINE_SUBDIVISIONS) + 1

n_ablines(intercept, slope) = max(_broadcast_length(intercept), _broadcast_length(slope))
_broadcast_length(x) = x isa AbstractArray ? length(x) : 1

function expand_per_abline(val, n, points_per_line)
    val isa AbstractArray && length(val) == n || return val
    return repeat(val, inner = points_per_line)
end

function append_abline_curve!(points, lims, lims_transformed, transf, intercept, slope)
    f(x) = intercept + slope * x

    if is_identity_transform(transf)
        xmin, xmax = first.(extrema(lims))
        push!(points, Point2d(xmin, f(xmin)), Point2d(xmax, f(xmax)), Point2d(NaN))
        return
    end

    xscale, yscale = transf[1], transf[2]
    inv_xscale = inverse_transform(xscale)
    xtmin, xtmax = first.(extrema(lims_transformed))

    y_interval = defined_interval(yscale)
    transformed_y(x) = (y = f(x); y in y_interval ? _apply_y_transform(transf, y) : NaN)
    for xt in range(xtmin, xtmax, length = N_ABLINE_SUBDIVISIONS)
        push!(points, Point2d(xt, transformed_y(inv_xscale(xt))))
    end
    push!(points, Point2d(NaN))
    return
end

data_limits(::ABLines) = Rect3d(Point3f(NaN), Vec3f(NaN))
boundingbox(::ABLines, space::Symbol = :data) = Rect3d(Point3f(NaN), Vec3f(NaN))

function abline!(args...; kwargs...)
    Base.depwarn("abline! is deprecated and will be removed in the future. Use ablines / ablines! instead.", :abline!, force = true)
    return ablines!(args...; kwargs...)
end
