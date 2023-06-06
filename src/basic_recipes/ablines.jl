"""
    ablines(intercepts, slopes; attrs...)

Creates a line defined by `f(x) = slope * x + intercept` crossing a whole `Scene` with 2D projection at its current limits.
You can pass one or multiple intercepts or slopes.

All style attributes are the same as for `LineSegments`.
"""
@recipe(ABLines) do scene
    Theme(;
        xautolimits = false,
        yautolimits = false,
        default_theme(LineSegments, scene)...,
        cycle = :color,
    )
end

function Makie.plot!(p::ABLines)
    scene = Makie.parent_scene(p)
    transf = transform_func(scene)

    is_identity_transform(transf) || throw(ArgumentError("ABLines is only defined for the identity transform, not $(typeof(transf))."))

    limits = lift(projview_to_2d_limits, p, scene.camera.projectionview)

    points = map(p, limits, p[1], p[2]) do lims, intercept, slope
        points = sizehint!(Point2e[], 2length(slope))
        broadcast_foreach(intercept, slope) do intercept, slope
            xmin, xmax = first.(extrema(lims))
            push!(points, Point2e(xmin, slope * xmin + intercept))
            push!(points, Point2e(xmax, slope * xmax + intercept))
        end
        return points
    end

    linesegments!(p, points; p.attributes...)
    p
end

function abline!(args...; kwargs...)
    Base.depwarn("abline! is deprecated and will be removed in the future. Use ablines / ablines! instead." , :abline!, force = true)
    ablines!(args...; kwargs...)
end
