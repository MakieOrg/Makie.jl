
function arrows(
        parent, points::AbstractVector{Pair{Point2f0, Point2f0}};
        arrowhead = '▲', arrowtail = nothing, arrowsize = 0.3,
        linecolor = :black, arrowcolor = :black, linewidth = 1,
        linestyle = nothing, scale = Vec3f0(1)
    )
    linesegment(parent, points, color = linecolor, linewidth = linewidth, linestyle = linestyle, scale = scale)
    rotations = map(points) do p
        p1, p2 = p
        dir = p2 .- p1
        GLVisualize.rotation_between(Vec3f0(0, 1, 0), Vec3f0(dir[1], dir[2], 0))
    end
    scatter(
        last.(points), marker = arrowhead, markersize = arrowsize, color = arrowcolor,
        rotations = rotations, scale = scale
    )
end
