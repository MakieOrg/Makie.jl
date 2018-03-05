using Makie, GeometryTypes
using Makie: VecLike
arrow_head(::Type{<: Point{3}}) = Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0)
arrow_head(::Type{<: Point{2}}) = '▲'

scatterfun(::Type{<: Point{2}}) = scatter
scatterfun(::Type{<: Point{3}}) = meshscatter

function arrows(
        parent, points::AbstractVector{T}, directions::AbstractVector{<: VecLike};
        arrowhead = Pyramid(Point3f0(0, 0, -0.5), 1f0, 1f0), arrowtail = nothing,
        linecolor = :black, arrowcolor = linecolor, linewidth = 1,
        arrowsize = 0.3, linestyle = nothing, scale = Vec3f0(1),
        normalize = false, lengthscale = 1.0f0
    ) where T <: VecLike

    points_n = to_node(points)
    directions_n = to_node(directions)
    newparent = Scene(parent,
        positions = points_n, directions = directions_n,
        linewidth = linewidth,
        arrowsize = arrowsize, linestyle = linestyle, scale = Vec3f0(1),
        normalize = normalize, lengthscale = lengthscale,
        arrowcolor = arrowcolor
    )
    headstart = lift_node(points_n, directions_n, newparent[:lengthscale]) do points, directions, s
        map(points, directions) do p1, dir
            dir = to_value(newparent, :normalize) ? StaticArrays.normalize(dir) : dir
            p1 => p1 .+ (dir .* Float32(s))
        end
    end

    ls = linesegment(
        newparent,
        headstart, color = linecolor, linewidth = linewidth,
        linestyle = linestyle, scale = scale
    )

    scatterfun(T)(
        newparent,
        last.(headstart), marker = arrowhead, markersize = newparent[:arrowsize],
        color = newparent[:arrowcolor],
        rotations = directions_n, scale = scale
    )
    newparent
end
