function draw_atomic(scene::Scene, screen::Screen, primitive::Makie.Mesh)
    Makie.compute_colors!(primitive.attributes)
    if Makie.cameracontrols(scene) isa Union{Camera2D, Makie.PixelCamera, Makie.EmptyCamera}
        draw_mesh2D(scene, screen, primitive.attributes)
    else
        draw_mesh3D(scene, screen, primitive.attributes)
    end
    return nothing
end

function draw_mesh2D(scene, screen, attr::ComputeGraph)
    vs = cairo_project_to_screen(attr)
    fs = attr.faces[]
    uv = attr.texturecoordinates[]
    uv_transform = attr.pattern_uv_transform[]
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = compute_colors(attr)
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    return draw_mesh2D(screen, cols, vs, fs)
end

function draw_mesh2D(screen::Screen, color, vs::Vector, fs::Vector{GLTriangleFace})
    return _draw_mesh2D_triangles(screen.canvas, color, vs, fs)
end

function _draw_mesh2D_triangles(canvas, per_face_cols, vs::Vector, fs::Vector{GLTriangleFace})
    paint = new_paint()

    for i in eachindex(fs)
        c1, c2, c3 = per_face_cols[i]
        t1, t2, t3 = vs[fs[i]]

        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        # Use average color for the triangle (Skia doesn't have mesh gradient patterns)
        avg_color = RGBAf(
            (red(c1) + red(c2) + red(c3)) / 3,
            (green(c1) + green(c2) + green(c3)) / 3,
            (blue(c1) + blue(c2) + blue(c3)) / 3,
            (alpha(c1) + alpha(c2) + alpha(c3)) / 3,
        )
        set_paint_color!(paint, avg_color)

        path = sk_path_new()
        sk_path_move_to(path, Float32(t1[1]), Float32(t1[2]))
        sk_path_line_to(path, Float32(t2[1]), Float32(t2[2]))
        sk_path_line_to(path, Float32(t3[1]), Float32(t3[2]))
        sk_path_close(path)
        sk_canvas_draw_path(canvas, path, paint)
        sk_path_delete(path)
    end

    sk_paint_delete(paint)
    return nothing
end

function average_z(positions, face)
    vs = positions[face]
    return sum(v -> v[3], vs) / length(vs)
end

function strip_translation(M::Mat4{T}) where {T}
    return @inbounds Mat4{T}(
        M[1], M[2], M[3], M[4],
        M[5], M[6], M[7], M[8],
        M[9], M[10], M[11], M[12],
        0, 0, 0, M[16],
    )
end

function _calculate_shaded_vertexcolors(N, v, c, lightdir, light_color, ambient, diffuse, specular, shininess)
    L = lightdir
    diff_coeff = max(dot(L, -N), 0.0f0)
    H = normalize(L + v)
    spec_coeff = max(dot(H, -N), 0.0f0)^shininess
    c = RGBAf(c)
    new_c_part1 = (ambient .+ light_color .* diff_coeff .* diffuse) .* Vec3f(c.r, c.g, c.b)
    new_c = new_c_part1 .+ light_color .* specular * spec_coeff
    return RGBAf(new_c..., c.alpha)
end

to_vec(c::Colorant) = Vec3f(red(c), green(c), blue(c))
prepare_normals(normalmatrix::Mat3f, normals::Nothing) = nothing
function prepare_normals(normalmatrix::Mat3f, normals::Vector{Vec3f})
    return [zero_normalize(normalmatrix * normal) for normal in normals]
end

function draw_mesh3D(scene, screen, plot::ComputeGraph)
    clip_planes = plot.clip_planes[]::Vector{Plane3f}
    uv_transform = plot.pattern_uv_transform[]::Union{Nothing, Mat{2, 3, Float32, 6}}

    world_points = Makie.apply_model(
        plot.model_f32c[]::Mat4f,
        plot.positions_transformed_f32c[]::Union{Vector{Point3f}, Vector{Point2f}}
    )
    screen_points = cairo_project_to_screen(plot, output_type = Point3f)::Vector{Point3f}
    meshfaces = plot.faces[]::Vector{GLTriangleFace}
    meshnormals = plot.normals[]::Union{Nothing, Vector{Vec3f}}
    _meshuvs = plot.texturecoordinates[]

    if (_meshuvs isa AbstractVector{<:Vec3})
        error("Only 2D texture coordinates are supported right now.")
    end
    meshuvs::Union{Nothing, Vector{Vec2f}} = _meshuvs

    color = compute_colors(plot)

    return draw_mesh3D(
        scene, screen, plot,
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes
    )
end

function draw_mesh3D(
        scene, screen, plot::ComputeGraph,
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes, model = plot.model_f32c[]::Mat4f
    )

    local shading::Bool = plot.shading[] && (scene.compute.shading[] != NoShading)

    if meshuvs isa Vector{Vec2f} && uv_transform !== nothing
        uvt = uv_transform::Mat{2, 3, Float32, 6}
        meshuvs = map(uv -> uvt * to_ndim(Vec3f, uv, 1), meshuvs)
    end

    matcap::Union{Nothing, Matrix{RGBAf}} = to_value(get(plot, :matcap, nothing))
    space = plot.space[]::Symbol

    per_face_col = per_face_colors(
        color::Union{RGBAf, Vector{RGBAf}, Matrix{RGBAf}},
        matcap, meshfaces, meshnormals, meshuvs
    )

    local faceculling::Int = to_value(get(plot, :faceculling, -10))

    return draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading, plot.diffuse[]::Vec3f,
        plot.specular[]::Vec3f, plot.shininess[]::Float32, faceculling,
        clip_planes, plot.eyeposition[]::Vec3f
    )
end

function draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading, diffuse, specular, shininess, faceculling, clip_planes, eyeposition
    )
    canvas = screen.canvas
    i = Vec(1, 2, 3)
    normalmatrix = transpose(inv(Mat3f(model[i, i])))
    ns = prepare_normals(normalmatrix, meshnormals)

    average_zs = map(f -> average_z(screen_points, f), meshfaces)
    zorder = sortperm(average_zs)

    if Makie.is_data_space(space) && !isempty(clip_planes)
        valid = Bool[is_visible(clip_planes, p) for p in world_points]
        filter!(zorder) do face_index
            face = meshfaces[face_index]
            return all(vertex_index -> valid[vertex_index], face)
        end
    end

    viewdir = scene.camera.view_direction[]::Vec3f
    if !isnothing(ns)
        filter!(zorder) do face_index
            face = meshfaces[face_index]
            return any(vertex_index -> dot(-ns[vertex_index], viewdir) > faceculling, face)
        end
    end

    ambient = to_vec(scene.compute[:ambient_color][])
    light_color = to_vec(scene.compute[:dirlight_color][])
    light_direction = scene.compute[:dirlight_final_direction][]::Vec3f
    vs = map(v -> normalize(to_ndim(Point3f, v, 0) - eyeposition), world_points)

    paint = new_paint()
    for k in reverse(zorder)
        f = meshfaces[k]
        t1 = screen_points[f[1]]
        t2 = screen_points[f[2]]
        t3 = screen_points[f[3]]
        (isnan(t1) || isnan(t2) || isnan(t3)) && continue

        facecolors = per_face_col[k]
        if shading && !isnothing(ns)
            mean_normal = sum(i -> ns[i], f) / length(f)
            c1, c2, c3 = Base.Cartesian.@ntuple 3 i -> begin
                N = normalize(ns[f[i]] + 1.0e-20 * mean_normal)
                v = vs[f[i]]
                c = facecolors[i]
                _calculate_shaded_vertexcolors(N, v, c, light_direction, light_color, ambient, diffuse, specular, shininess)
            end
        else
            c1, c2, c3 = facecolors
        end

        avg_color = RGBAf(
            (red(c1) + red(c2) + red(c3)) / 3,
            (green(c1) + green(c2) + green(c3)) / 3,
            (blue(c1) + blue(c2) + blue(c3)) / 3,
            (alpha(c1) + alpha(c2) + alpha(c3)) / 3,
        )
        set_paint_color!(paint, avg_color)

        path = sk_path_new()
        sk_path_move_to(path, Float32(t1[1]), Float32(t1[2]))
        sk_path_line_to(path, Float32(t2[1]), Float32(t2[2]))
        sk_path_line_to(path, Float32(t3[1]), Float32(t3[2]))
        sk_path_close(path)
        sk_canvas_draw_path(canvas, path, paint)
        sk_path_delete(path)
    end
    sk_paint_delete(paint)
    return
end

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(plot::Makie.MeshScatter))
    transformed_pos = Makie.apply_model(
        plot.model_f32c[]::Mat4f,
        plot.positions_transformed_f32c[]::Union{Vector{Point2f}, Vector{Point3f}}
    )
    colors = compute_colors(plot)
    uv_transform = plot.pattern_uv_transform[]

    return draw_scattered_mesh(
        scene, screen, plot.attributes, plot.marker[],
        transformed_pos, plot.markersize[], plot.rotation[], colors,
        plot.clip_planes[], plot.transform_marker[]::Bool, uv_transform
    )
end

function draw_scattered_mesh(
        scene, screen, plot::ComputeGraph, mesh,
        positions, scales, rotations, colors,
        clip_planes, transform_marker, uv_transform
    )
    space = plot.space[]

    meshpoints = decompose(Point3f, mesh)
    meshfaces = decompose(GLTriangleFace, mesh)
    meshnormals = normals(mesh)
    meshuvs = texturecoordinates(mesh)

    f32c_model = ifelse(transform_marker, strip_translation(plot.model[]::Mat4d), Mat4d(I))
    if !isnothing(scene.float32convert) && Makie.is_data_space(space)
        f32c_model = Makie.scalematrix(scene.float32convert.scaling[].scale::Vec3d) * f32c_model
    end

    view = plot.view[]::Mat4f
    zorder = sortperm(
        positions, by = p -> begin
            p4d = to_ndim(Vec4d, p, 1)
            cam_pos = view[Vec(3, 4), Vec(1, 2, 3, 4)] * p4d
            cam_pos[1] / cam_pos[2]
        end, rev = false
    )

    proj_mat = cairo_viewport_matrix(plot.resolution[]) * plot.projectionview[]

    for i in zorder
        element_color = Makie.sv_getindex(colors, i)
        element_uv_transform = Makie.sv_getindex(uv_transform, i)
        element_translation = to_ndim(Point4d, positions[i], 0)
        element_rotation = Makie.rotationmatrix4(Makie.sv_getindex(rotations, i))
        element_scale = Makie.sv_getindex(scales, i)
        element_scale_matrix = Makie.scalematrix(element_scale)
        element_transform = f32c_model * element_rotation * element_scale_matrix

        element_world_pos = map(meshpoints) do p
            p4d = to_ndim(Point4d, to_ndim(Point3d, p, 0), 1)
            p4d = element_transform * p4d + element_translation
            return Point3f(p4d) / p4d[4]
        end

        element_screen_pos = project_position(Point3f, proj_mat, element_world_pos, eachindex(element_world_pos))

        finite_element_scale = @. ifelse(element_scale >= 0, +1, -1) * max(abs(element_scale), 1.0e-6)
        model = f32c_model * element_rotation * Makie.scalematrix(finite_element_scale)

        draw_mesh3D(
            scene, screen, plot,
            element_world_pos, element_screen_pos, meshfaces, meshnormals, meshuvs,
            element_uv_transform, element_color, clip_planes, model
        )
    end
    return nothing
end

function draw_atomic(scene::Scene, screen::Screen, plot::Makie.Surface)
    attr = plot.attributes
    Makie.add_computation!(attr, Val(:surface_as_mesh))
    Makie.register_pattern_uv_transform!(attr)
    draw_mesh3D(scene, screen, attr)
    return nothing
end

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Voxels))
    pos = Makie.voxel_positions(primitive)
    scale = Makie.voxel_size(primitive)
    colors = Makie.voxel_colors(primitive)
    marker = GeometryBasics.expand_faceviews(normal_mesh(Rect3f(Point3f(-0.5), Vec3f(1))))

    transformed_pos = _transform_to_world(scene, primitive, pos)

    clip_planes = primitive.clip_planes[]::Vector{Plane3f}
    if !isempty(clip_planes) && Makie.is_data_space(primitive)
        valid = [is_visible(clip_planes, p) for p in transformed_pos]
        transformed_pos = transformed_pos[valid]
        colors = colors[valid]
    end

    Makie.register_computation!(primitive.attributes::Makie.ComputeGraph, [:model], [:model_f32c]) do (model,), _, __
        return (Mat4f(model),)
    end

    draw_scattered_mesh(
        scene, screen, primitive.attributes, marker,
        transformed_pos, scale, Quaternionf(0, 0, 0, 1), colors,
        Plane3f[], true, primitive.uv_transform[]
    )
    return nothing
end

function _transform_to_world(scene::Scene, @nospecialize(plot), pos)
    space = plot.space[]::Symbol
    model = plot.model[]::Mat4d
    f32_model = Makie.f32_convert_matrix(scene.float32convert, space) * model
    tf = Makie.transform_func(plot)
    return _transform_to_world(f32_model, tf, pos)
end

function _transform_to_world(f32_model, tf, pos)
    return map(pos) do p
        transformed = Makie.apply_transform(tf, p)
        p4d = to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
        p4d = f32_model * p4d
        return p4d[Vec(1, 2, 3)] / p4d[4]
    end
end
