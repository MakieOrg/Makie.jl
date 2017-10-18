function wireframe(backend::Backend, x::AbstractVector, y::AbstractVector, z::AbstractMatrix, attributes::Dict)
    wireframe(ngrid(x, y)..., z, attributes)
end

function wireframe(backend::Backend, x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix, attributes::Dict)
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
    linesegment(backend, view(points, faces), attributes)
end


function wireframe(backend::Backend, mesh, attributes::Dict)
    mesh = to_node(mesh, x-> to_mesh(backend, x))
    points = lift_node(mesh) do g
        decompose(Point3f0, g) # get the point representation of the geometry
    end
    indices = lift_node(mesh) do g
        idx = decompose(Face{2, GLIndex}, g) # get the point representation of the geometry
    end
    linesegment(backend, view(points, indices), attributes)
end
