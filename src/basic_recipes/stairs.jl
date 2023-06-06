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

function Makie.plot!(p::Stairs{<:Tuple{<:AbstractVector{<:Point2}}})
    points = p[1]

    steppoints = lift(p, points, p.step) do points, step
        if !(step in (:pre, :post, :center))
            error("Invalid step $step. Valid options are :pre, :post and :center")
        end

        s_points = Vector{eltype(points)}(undef, length(points) * 2 - (step !== :center))
        s_points[1] = point = points[1]
        
        if step === :pre
            for i in 1:length(points)-1
                nextpoint = points[i + 1]
                s_points[2i] = Point2(point[1], nextpoint[2])
                s_points[2i + 1] = nextpoint
                point = nextpoint
            end
        elseif step === :post
            for i in 1:length(points)-1
                nextpoint = points[i + 1]
                s_points[2i] = Point2(nextpoint[1], point[2])
                s_points[2i + 1] = nextpoint
                point = nextpoint
            end
        elseif step === :center
            for i in 1:length(points)-1
                nextpoint = points[i+1]
                halfx = (point[1] + nextpoint[1]) / 2
                s_points[2i] = Point2(halfx, point[2])
                s_points[2i + 1] = Point2(halfx, nextpoint[2])
                point = nextpoint
            end
            s_points[end] = point
        end
        
        return s_points
    end

    lines!(p, steppoints; [x for x in pairs(p.attributes) if x[1] !== :step]...)
    p
end
