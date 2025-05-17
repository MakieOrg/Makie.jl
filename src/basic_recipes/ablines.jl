"""
    ablines(intercepts, slopes; attrs...)

Creates a line defined by `f(x) = slope * x + intercept` crossing a whole `Scene` with 2D projection at its current limits.
You can pass one or multiple intercepts or slopes.
"""
@recipe ABLines begin
    MakieCore.documented_attributes(LineSegments)...
end

function Makie.plot!(p::ABLines)
    scene = Makie.parent_scene(p)
    transf = transform_func(scene)

    is_identity_transform(transf) || throw(ArgumentError("ABLines is only defined for the identity transform, not $(typeof(transf))."))

    limits = projview_to_2d_limits(p)

    points = Observable(Point2d[])

    onany(p, limits, p[1], p[2]) do lims, intercept, slope
        empty!(points[])
        f(x) = x * b + a
        broadcast_foreach(intercept, slope) do intercept, slope
            f(x) = intercept + slope * x
            xmin, xmax = first.(extrema(lims))
            push!(points[], Point2d(xmin, f(xmin)))
            push!(points[], Point2d(xmax, f(xmax)))
        end
        notify(points)
    end

    notify(p[1])

    linesegments!(p, p.attributes, points)
    p
end

data_limits(::ABLines) = Rect3f(Point3f(NaN), Vec3f(NaN))
boundingbox(::ABLines, space::Symbol = :data) = Rect3f(Point3f(NaN), Vec3f(NaN))

function abline!(args...; kwargs...)
    Base.depwarn("abline! is deprecated and will be removed in the future. Use ablines / ablines! instead." , :abline!, force = true)
    ablines!(args...; kwargs...)
end
