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

    limits = lift(projview_to_2d_limits, scene.camera.projectionview)

    points = Observable(Point2f[])
    
    onany(limits, p[1], p[2]) do lims, intercept, slope
        inv = inverse_transform(transf)
        empty!(points[])
        f(x) = x * b + a
        broadcast_foreach(intercept, slope) do intercept, slope
            f(x) = intercept + slope * x
            xmin, xmax = first.(extrema(lims))
            push!(points[], Point2f(xmin, f(xmin)))
            push!(points[], Point2f(xmax, f(xmax)))
        end
        notify(points)
    end

    notify(p[1])

    linesegments!(p, points; p.attributes...)
    p
end

function abline!(args...; kwargs...)
    Base.depwarn("abline! is deprecated and will be removed in the future. Use ablines / ablines! instead." , :abline!, force = true)
    ablines!(args...; kwargs...)
end
