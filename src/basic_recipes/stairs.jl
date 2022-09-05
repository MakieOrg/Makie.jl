"""
    stairs(xs, ys; kwargs...)

Plot a stair function.

The `step` parameter can take the following values:
- `:pre`: horizontal part of step extends to the left of each value in `xs`.
- `:post`: horizontal part of step extends to the right of each value in `xs`.
- `:center`: horizontal part of step extends halfway between the two adjacent values of `xs`.

The conversion trait of stem is `PointBased`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Stairs) do scene
    a = Attributes(
        step = :pre, # :center :post
    )
    merge(a, default_theme(scene, Lines))
end

conversion_trait(::Type{<:Stairs}) = PointBased()

function plot!(plot::Stairs{<:Tuple{<:AbstractVector{<:Point2}}})
    s_points = Point2f[]
    steppoints = lift(plot[1], plot.step) do points, step
        empty!(s_points)
        sizehint!(s_points, length(points) * 2)
        point = points[1]
        push!(s_points, point)
        for i in 2:length(points)
            nextpoint = points[i]
            if step == :pre
                p = Point2f(point[1], nextpoint[2])
                push!(s_points, p, p, nextpoint, nextpoint)
            elseif step == :post
                p = Point2f(nextpoint[1], point[2])
                push!(s_points, p, p, nextpoint, nextpoint)
            elseif step == :center
                halfx = (point[1] + nextpoint[1]) / 2
                p1 = Point2f(halfx, point[2])
                p2 = Point2f(halfx, nextpoint[2])
                push!(s_points, p1, p1, p2, p2)
            else
                error("Invalid step $step. Valid options are :pre, :post and :center")
            end
            point = nextpoint
        end
        if step == :center
            push!(s_points, point)
        end
        return s_points
    end
    linesegments!(plot, steppoints; [x for x in pairs(plot.attributes) if x[1] != :step]...)
end
