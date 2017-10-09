function wireframe(x::AbstractVector, y::AbstractVector, z::AbstractMatrix; kw_args...)
    wireframe(ngrid(x, y)..., z; kw_args...)
end

@default function linesegments(scene, kw_args)
    positions = to_positions(positions)
    color = to_color(color)
    linewidth = linewidth::Float32
end

function line_2glvisualize(kw_args)
    result = Dict{Symbol, Any}()
    for (k, v) in kw_args
        k in (:vertex, :positions) && continue
        if k == :linewidth
            k = :thickness
        end
        if k == :positions
            k = :vertex
        end
        result[k] = to_signal(v)
    end
    result[:visible] = true
    result[:fxaa] = false
    result[:model] = eye(Mat4f0)
    result
end

function wireframe(x::AbstractMatrix, y::AbstractMatrix, z::AbstractMatrix; kw_args...)
    if (length(x) != length(y)) || (length(y) != length(z))
        error("x, y and z must have the same length. Found: $(length(x)), $(length(y)), $(length(z))")
    end
    points = lift_node(to_node(x), to_node(y), to_node(z)) do x, y, z
        Point3f0.(vec(x), vec(y), vec(z))
    end
    NF = (length(z) * 4) - ((size(z, 1) + size(z, 2)) * 2)
    faces = Vector{Cuint}(NF)
    idx = (i, j) -> sub2ind(size(z), i, j) - 1
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
    scene = get_global_scene()
    kw_args = expand_kwargs(kw_args)
    kw_args[:positions] = points
    attributes = lines_defaults(scene, kw_args)
    gl_data = line_2glvisualize(attributes)
    gl_data[:indices] = faces
    scene = get_global_scene()
    viz = visualize(to_signal(attributes[:positions]), Style(:linesegment), gl_data)
    insert_scene!(scene, :wireframe, viz, attributes)
end
