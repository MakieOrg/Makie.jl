"""
    arc(origin, radius, start_angle, stop_angle; kwargs...)

This function plots a circular sector, centered at `origin` with radius `radius`,
from `start_angle` to `stop_angle`.

`inner_radius` is optional. If set, the center is cut out.

`origin` must be a coordinate in 2 dimensions (i.e., a `Point2`); the rest of the arguments must be
`<: Number`.

Examples:

`sector(Point2f(0), 1, 0.0, π)`

`sector(Point2f(1, 2), 1, π, -π/2, inner_radius = 0.5)`

## Attributes
$(ATTRIBUTES)
"""
@recipe(Sector, origin, radius, start_angle, stop_angle) do scene
    Attributes(;
        inner_radius = 0.,
        default_theme(scene, Lines)...
    )
end

function plot!(p::Sector)
    args = getindex.(p, (:origin, :radius, :start_angle, :stop_angle, :inner_radius))

    positions = lift(p, args...) do origin, radius, start_angle, stop_angle, inner_radius

        if inner_radius > 0
            # Make sector with inner radius cut out
            return BezierPath([
            MoveTo(origin .+ Point2f((cos(start_angle), sin(start_angle)) .* inner_radius)),
            EllipticalArc(origin, radius, radius, 0, start_angle, stop_angle),
            EllipticalArc(origin, inner_radius, inner_radius, 0, stop_angle, start_angle),
            ClosePath()])
        else
            # Use origin as center
            return BezierPath([
                MoveTo(origin),
                EllipticalArc(origin, radius, radius, 0, start_angle, stop_angle),
                ClosePath()])
        end
    end

    attr = Attributes(p)
    poly!(p, attr, positions)
end
