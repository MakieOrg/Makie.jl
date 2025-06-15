"""
    ablines(intercepts, slopes; attrs...)

Creates a line defined by `f(x) = slope * x + intercept` crossing a whole `Scene` with 2D projection at its current limits.
You can pass one or multiple intercepts or slopes.
"""
@recipe ABLines (intercept, slope) begin
    documented_attributes(LineSegments)...
end

function Makie.plot!(p::ABLines)
    scene = Makie.parent_scene(p)
    transf = transform_func(scene)
    is_identity_transform(transf) || throw(ArgumentError("ABLines is only defined for the identity transform, not $(typeof(transf))."))

    add_axis_limits!(p)

    map!(p.attributes, [:axis_limits, :intercept, :slope], :points) do lims, intercept, slope
        points = Point2d[]
        broadcast_foreach(intercept, slope) do intercept, slope
            f(x) = intercept + slope * x
            xmin, xmax = first.(extrema(lims))
            push!(points, Point2d(xmin, intercept + slope * xmin))
            push!(points, Point2d(xmax, intercept + slope * xmax))
        end
        return points
    end
    linesegments!(p, Attributes(p), p.points)
    return p
end

data_limits(::ABLines) = Rect3d(Point3f(NaN), Vec3f(NaN))
boundingbox(::ABLines, space::Symbol = :data) = Rect3d(Point3f(NaN), Vec3f(NaN))

function abline!(args...; kwargs...)
    Base.depwarn("abline! is deprecated and will be removed in the future. Use ablines / ablines! instead.", :abline!, force = true)
    return ablines!(args...; kwargs...)
end
