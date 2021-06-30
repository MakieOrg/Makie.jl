@recipe(Stairs) do scene
    a = Attributes(
        step = :pre, # :center :post
    )
    merge(a, default_theme(scene, Lines))
end

conversion_trait(::Type{<:Stairs}) = PointBased()

function plot!(p::Stairs{<:Tuple{<:AbstractVector{<:Point2}}})
    points = p[1]

    steppoints = lift(points, p.step) do points, step
        if step == :pre
            s_points = Vector{Point2f0}(undef, length(points) * 2 - 1)
            s_points[1] = points[1]
            for i in 1:length(points)-1
                s_points[2i] = Point2f0(points[i][1], points[i+1][2])
                s_points[2i + 1] = points[i+1]
            end
            s_points
        elseif step == :post
            s_points = Vector{Point2f0}(undef, length(points) * 2 - 1)
            s_points[1] = points[1]
            for i in 1:length(points)-1
                s_points[2i] = Point2f0(points[i+1][1], points[i][2])
                s_points[2i + 1] = points[i+1]
            end
            s_points
        elseif step == :center
            s_points = Vector{Point2f0}(undef, length(points) * 2)
            s_points[1] = points[1]
            s_points[end] = points[end]
            for i in 1:length(points)-1
                halfx = 0.5 * (points[i][1] + points[i+1][1])
                s_points[2i] = Point2f0(halfx, points[i][2])
                s_points[2i + 1] = Point2f0(halfx, points[i+1][2])
            end
            s_points
        else
            error("Invalid step $step. Valid options are :pre, :post and :center")
        end
    end

    lines!(p, steppoints; [x for x in pairs(p.attributes) if x[1] != :step]...)
    p
end

