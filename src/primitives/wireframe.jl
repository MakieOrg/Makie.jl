function wireframe(x::AbstractArray, y::AbstractArray, z::AbstractArray, kw_args)
    if length(x) != length(y) || length(y) == length(z)
        error("x, y and z must have the same length. Found: $(length(x)), $(length(y)), $(length(z))")
    end
    points = broadcast(Point3f0, vec(x), vec(y), vec(z))
    NF = (length(z) * 4) - ((size(z, 1) + size(z, 2)) * 2)
    faces = Vector{Cuint}(NF)
    idx = (i,j) -> sub2ind(size(z), i, j) - 1
    li = 1
    for i = 1:size(z, 1), j = 1:size(z, 2)
        if i < size(z, 1)
            faces[li] = idx(i, j); faces[li + 1] = idx(i + 1, j)
            li += 2
        end
        if j < size(z, 2)
            faces[li] = idx(i, j)
            faces[li + 1] = idx(i, j + 1)
            i += 2
        end
    end
    kw_args[:indices] = faces
    return visualize(points, Style(:linesegment), kw_args)
end
