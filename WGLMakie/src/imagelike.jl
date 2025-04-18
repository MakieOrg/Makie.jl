using Makie: el32convert, surface_normals, get_dim

# TODO, speed up GeometryBasics
function fast_faces(nvertices)
    w, h = nvertices
    idx = LinearIndices(nvertices)
    nfaces = 2 * (w - 1) * (h - 1)
    faces = Vector{GLTriangleFace}(undef, nfaces)
    face_idx = 1
    @inbounds for i in 1:(w - 1)
        for j in 1:(h - 1)
            a, b, c, d = idx[i, j], idx[i + 1, j], idx[i + 1, j + 1], idx[i, j + 1]
            faces[face_idx] = GLTriangleFace(a, b, c)
            face_idx += 1
            faces[face_idx] = GLTriangleFace(a, c, d)
            face_idx += 1
        end
    end
    return faces
end

# TODO, speed up GeometryBasics
function fast_uv(nvertices)
    xrange, yrange = LinRange.((0, 1), (1, 0), nvertices)
    return [Vec2f(x, y) for y in yrange for x in xrange]
end

function limits_to_uvmesh(plot, f32c)
    px, py, pz = plot[1], plot[2], plot[3]
    # Special path for ranges of length 2 which
    # can be displayed as a rectangle
    t = Makie.transform_func_obs(plot)[]
    px = lift(identity, plot, px; ignore_equal_values=true)
    py = lift(identity, plot, py; ignore_equal_values=true)
    if px[] isa Makie.EndPoints && py[] isa Makie.EndPoints && Makie.is_identity_transform(t)
        rect = lift(plot, px, py) do x, y
            xmin, xmax = x
            ymin, ymax = y
            return Rect2f(xmin, ymin, xmax - xmin, ymax - ymin)
        end
        ps = lift(rect -> decompose(Point2f, rect), plot, rect)
        positions = Buffer(apply_transform_and_f32_conversion(plot, f32c, ps))
        # UV + Faces stay the same for the rectangle
        faces = Buffer(decompose(GLTriangleFace, rect[]))
        uv = Buffer(decompose_uv(rect[]))
    else
        px = lift((x, z) -> xy_convert(x, size(z, 1)), px, pz; ignore_equal_values=true)
        py = lift((y, z) -> xy_convert(y, size(z, 2)), py, pz; ignore_equal_values=true)
        # TODO: Use Makie.surface2mesh
        grid_ps = lift((x, y) -> Makie.matrix_grid(x, y, zeros(length(x), length(y))), plot, px, py)
        positions = Buffer(apply_transform_and_f32_conversion(plot, f32c, grid_ps))
        resolution = lift((x, y) -> (length(x), length(y)), plot, px, py; ignore_equal_values=true)
        faces = Buffer(lift(fast_faces, plot, resolution))
        uv = Buffer(lift(fast_uv, plot, resolution))
    end
    return Dict(:positions => positions, :faces => faces, :uv => uv)
end
