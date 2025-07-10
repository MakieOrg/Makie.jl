"""
    stairs(xs, ys; kwargs...)

Plot a stair function.

The conversion trait of `stairs` is `PointBased`.
"""
@recipe Stairs begin
    """
    The `step` parameter can take the following values:
    - `:pre`: horizontal part of step extends to the left of each value in `xs`.
    - `:post`: horizontal part of step extends to the right of each value in `xs`.
    - `:center`: horizontal part of step extends halfway between the two adjacent values of `xs`.
    """
    step = :pre
    documented_attributes(Lines)...
end

conversion_trait(::Type{<:Stairs}) = PointBased()

function plot!(p::Stairs{<:Tuple{<:AbstractVector{T}}}) where {T <: Point2}
    map!(p, [:converted_1, :step], :steppoints) do points, step
        if step === :pre
            s_points = Vector{T}(undef, length(points) * 2 - 1)
            s_points[1] = point = points[1]
            for i in 1:(length(points) - 1)
                nextpoint = points[i + 1]
                s_points[2i] = T(point[1], nextpoint[2])
                s_points[2i + 1] = nextpoint
                point = nextpoint
            end
            s_points
        elseif step === :post
            s_points = Vector{T}(undef, length(points) * 2 - 1)
            s_points[1] = point = points[1]
            for i in 1:(length(points) - 1)
                nextpoint = points[i + 1]
                s_points[2i] = T(nextpoint[1], point[2])
                s_points[2i + 1] = nextpoint
                point = nextpoint
            end
            s_points
        elseif step === :center
            s_points = Vector{T}(undef, length(points) * 2)
            s_points[1] = point = points[1]
            for i in 1:(length(points) - 1)
                nextpoint = points[i + 1]
                halfx = (point[1] + nextpoint[1]) / 2
                s_points[2i] = T(halfx, point[2])
                s_points[2i + 1] = T(halfx, nextpoint[2])
                point = nextpoint
            end
            s_points[end] = point
            s_points
        else
            error("Invalid step $step. Valid options are :pre, :post and :center")
        end
    end

    lines!(p, shared_attributes(p, Lines), p.steppoints)
    return p
end
