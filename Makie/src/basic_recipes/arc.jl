"""
Plots a circular arc centered at `origin` with the given `radius` from `start_angle`
to `stop_angle`.

## Arguments

* `origin, radius, start_angle, stop_angle` Defines a circular arc where `origin` is a 2D `Point{2, <:Real}` determining the center position, `radius` is a `Real` determining the radius measured from `origin`, `start_angle` is a `Real` determining the angle from the x-axis at which the arc starts, and `stop_angle` is a `Real` determining the angle from the x-axis at which the arc stops.
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
