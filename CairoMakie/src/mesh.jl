function cairo_project_to_screen_impl(projectionview, resolution, model, pos, output_type = Point2f, yflip = true)
    # the existing methods include f32convert matrices which are already
    # applied in :positions_transformed_f32c (using this makes CairoMakie
    # less performant (extra O(N) step) but allows code reuse with other backends)
    M = cairo_viewport_matrix(resolution, yflip) * projectionview * model
    return project_position(output_type, M, pos, eachindex(pos))
end

function cairo_project_to_screen_impl(projectionview, resolution, model, pos::VecTypes, output_type = Point2f, yflip = true)
    p4d = to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1)
    p4d = model * p4d
    p4d = projectionview * p4d
    p4d = cairo_viewport_matrix(resolution, yflip) * p4d
    return output_type(p4d) / p4d[4]
end


function cairo_project_to_screen(attr;
        input_name = :positions_transformed_f32c, yflip = true, output_type = Point2f
    )
    Makie.register_computation!(attr,
            [:projectionview, :resolution, :model_f32c, input_name], [:cairo_screen_pos]
        ) do inputs, changed, cached

        output = cairo_project_to_screen_impl(values(inputs)..., output_type, yflip)
        return (output,)
    end

    return attr[:cairo_screen_pos][]
end

function draw_atomic(scene::Scene, screen::Screen, primitive::Makie.Mesh)
    Makie.compute_colors!(plot)
    if Makie.cameracontrols(scene) isa Union{Camera2D, Makie.PixelCamera, Makie.EmptyCamera}
        draw_mesh2D(scene, screen, primitive)
    else
        draw_mesh3D(scene, screen, primitive)
    end
    return nothing
end

function draw_mesh2D(scene, screen, @nospecialize(plot::Makie.Mesh))
    # TODO: no clip_planes?
    vs = cairo_project_to_screen(plot)
    fs = plot.faces[]
    uv = plot.texturecoordinates[]
    uv_transform = plot.pattern_uv_transform[]
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = compute_colors(plot)
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    if cols isa Cairo.CairoPattern
        align_pattern(cols, scene, plot.model[])
    end
    return draw_mesh2D(screen, cols, vs, fs)
end

# Mesh + surface entry point
function draw_mesh3D(scene, screen, @nospecialize(plot::Plot))
    @get_attribute(plot, (clip_planes, ))
    uv_transform = plot.pattern_uv_transform[]

    # per-element in meshscatter
    world_points = Makie.apply_model(plot.model_f32c[], plot.positions_transformed_f32c[])
    screen_points = cairo_project_to_screen(plot, output_type = Point3f)
    meshfaces = plot.faces[]
    meshnormals = plot.normals[]
    _meshuvs = plot.texturecoordinates[]

    if (_meshuvs isa AbstractVector{<:Vec3})
        error("Only 2D texture coordinates are supported right now. Use GLMakie for 3D textures.")
    end
    meshuvs::Union{Nothing,Vector{Vec2f}} = _meshuvs

    color = compute_colors(plot)

    draw_mesh3D(
        scene, screen, plot,
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes
    )
end

function draw_mesh3D(
        scene, screen, @nospecialize(plot::Plot),
        world_points, screen_points, meshfaces, meshnormals, meshuvs,
        uv_transform, color, clip_planes, model = plot.model_f32c[]::Mat4f
    )

    @get_attribute(plot, (shading, diffuse, specular, shininess, faceculling))

    shading = shading && (scene.compute.shading[] != NoShading)

    if meshuvs isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        meshuvs = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), meshuvs)
    end

    matcap = to_value(get(plot, :matcap, nothing))
    per_face_col = per_face_colors(color, matcap, meshfaces, meshnormals, meshuvs)

    space = plot.space[]::Symbol
    if per_face_col isa Cairo.CairoPattern
        # plot.model_f32c[] is f32c corrected, not f32c * model
        f32c_model = Makie.f32_convert_matrix(scene.float32convert, space) * plot.model[]
        align_pattern(per_face_col, scene, f32c_model)
    end

    faceculling = to_value(get(plot, :faceculling, -10))

    draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading::Bool, diffuse::Vec3f,
        specular::Vec3f, shininess::Float32, faceculling::Int, clip_planes, plot.eyeposition[]
    )
end

to_vec(c::Colorant) = Vec3f(red(c), green(c), blue(c))

function draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading, diffuse, specular, shininess, faceculling, clip_planes, eyeposition
    )
    ctx = screen.context

    # local_model applies rotation and markersize from meshscatter to vertices
    i = Vec(1, 2, 3)
    normalmatrix = transpose(inv(model[i, i])) # see issue #3702

    if Makie.is_data_space(space) && !isempty(clip_planes)
        valid = Bool[is_visible(clip_planes, p) for p in world_points]
    else
        valid = Bool[]
    end

    # Approximate zorder
    average_zs = map(f -> average_z(screen_points, f), meshfaces)
    zorder = sortperm(average_zs)

    if isnothing(meshnormals)
        ns = nothing
    else
        ns = map(n -> normalize(normalmatrix * n), meshnormals)
    end

    # Face culling
    if isempty(valid) && !isnothing(ns)
        zorder = filter(i -> any(last.(ns[meshfaces[i]]) .> faceculling), zorder)
    elseif !isempty(valid)
        zorder = filter(i -> all(valid[meshfaces[i]]), zorder)
    else
        # no clipped faces, no normals to rely on for culling -> do nothing
    end

    # If per_face_col is a CairoPattern the plot is using an AbstractPattern
    # as a color. In this case we don't do shading and fall back to mesh2D
    # rendering
    if per_face_col isa Cairo.CairoPattern
        return draw_mesh2D(ctx, per_face_col, screen_points, meshfaces, reverse(zorder))
    end

    ambient = to_vec(scene.compute[:ambient_color][])
    light_color = to_vec(scene.compute[:dirlight_color][])
    light_direction = scene.compute[:dirlight_final_direction][]

    # vs are used as camdir (camera to vertex) for light calculation (in world space)
    vs = map(v -> normalize(to_ndim(Point3f, v, 0) - eyeposition), world_points)

    draw_pattern(
        ctx, zorder, shading, meshfaces, screen_points, per_face_col, ns, vs,
        light_direction, light_color, shininess, diffuse, ambient, specular)

    return
end
