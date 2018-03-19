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



@default function contour(scene, kw_args)
    levels = to_float(levels)
    color = to_color(color)
    linewidth = to_float(1)
    fillrange = to_bool(fillrange)
end

function contour(scene::makie, x, y, z, attributes)
    attributes = contour_defaults(scene, attributes)

    if to_value(attributes[:fillrange])
        return heatmap(scene, x, y, z, attributes)
    else
        levels = round(Int, to_value(attributes[:levels]))
        T = eltype(z)

        contours = Contour.contours(T.(x), T.(y), z, levels)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        col = to_value(attributes[:color])
        cols = if isa(col, AbstractVector)
            if length(col) != levels
                error("Please have one color per level. Found: $(length(col)) colors and $levels level")
            end
            col
        else
            repeated(col, levels)
        end
        for (color, c) in zip(cols, Contour.levels(contours))
            for elem in Contour.lines(c)
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                append!(colors, fill(color, length(elem.vertices) + 1))
            end
        end
        attributes[:color] = colors
        return lines(scene, result, attributes)
    end
end


function wireframe(scene::Scene, x::AbstractVector, y::AbstractVector, z::AbstractMatrix, attributes::Dict)
    wireframe(ngrid(x, y)..., z, attributes)
end

function wireframe(scene::Scene, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix, attributes::Dict)
    if (length(x) != length(y)) || (length(y) != length(z))
        error("x, y and z must have the same length. Found: $(length(x)), $(length(y)), $(length(z))")
    end
    points = lift_node(to_node(x), to_node(y), to_node(z)) do x, y, z
        Point3f0.(vec(x), vec(y), vec(z))
    end
    NF = (length(z) * 4) - ((size(z, 1) + size(z, 2)) * 2)
    faces = Vector{Int}(NF)
    idx = (i, j) -> sub2ind(size(z), i, j)
    li = 1
    for i = 1:size(z, 1), j = 1:size(z, 2)
        if i < size(z, 1)
            faces[li] = idx(i, j);
            faces[li + 1] = idx(i + 1, j)
            li += 2
        end
        if j < size(z, 2)
            faces[li] = idx(i, j)
            faces[li + 1] = idx(i, j + 1)
            li += 2
        end
    end
    linesegment(scene, view(points, faces), attributes)
end


function wireframe(scene::Scene, mesh, attributes::Dict)
    mesh = to_node(mesh, x-> to_mesh(scene, x))
    points = lift_node(mesh) do g
        decompose(Point3f0, g) # get the point representation of the geometry
    end
    indices = lift_node(mesh) do g
        idx = decompose(Face{2, GLIndex}, g) # get the point representation of the geometry
    end
    linesegment(scene, view(points, indices), attributes)
end
