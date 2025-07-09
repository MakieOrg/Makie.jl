"""
    arc(origin, radius, start_angle, stop_angle; kwargs...)

This function plots a circular arc, centered at `origin` with radius `radius`,
from `start_angle` to `stop_angle`.
`origin` must be a coordinate in 2 dimensions (i.e., a `Point2`); the rest of the arguments must be
`<: Number`.

Examples:

`arc(Point2f(0), 1, 0.0, π)`
`arc(Point2f(1, 2), 0.3, π, -π)`

"""
@recipe Arc (origin, radius, start_angle, stop_angle) begin
    documented_attributes(Lines)...
    "The number of line points approximating the arc."
    resolution = 361
end

function plot!(p::Arc)
    map!(p, [:origin, :radius, :start_angle, :stop_angle, :resolution], :positions) do origin, radius, start_angle, stop_angle, resolution
        return map(range(start_angle, stop = stop_angle, length = resolution)) do angle
            return origin .+ Point2f((cos(angle), sin(angle)) .* radius)
        end
    end
    return lines!(p, Attributes(p), p.positions)
end
