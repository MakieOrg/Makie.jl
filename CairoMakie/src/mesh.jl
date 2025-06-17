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


function cairo_project_to_screen(
        attr;
        input_name = :positions_transformed_f32c, yflip = true, output_type = Point2f
    )
    Makie.register_computation!(
        attr,
        [:projectionview, :resolution, :model_f32c, input_name], [:cairo_screen_pos]
    ) do inputs, changed, cached

        output = cairo_project_to_screen_impl(values(inputs)..., output_type, yflip)
        return (output,)
    end

    return attr[:cairo_screen_pos][]
end

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
    # TODO: no clip_planes?
    vs = cairo_project_to_screen(attr)
    fs = attr.faces[]
    uv = attr.texturecoordinates[]
    uv_transform = attr.pattern_uv_transform[]
    if uv isa Vector{Vec2f} && to_value(uv_transform) !== nothing
        uv = map(uv -> uv_transform * to_ndim(Vec3f, uv, 1), uv)
    end
    color = compute_colors(attr)
    cols = per_face_colors(color, nothing, fs, nothing, uv)
    if cols isa Cairo.CairoPattern
        align_pattern(cols, scene, attr.model[])
    end
    return draw_mesh2D(screen, cols, vs, fs)
end


function draw_mesh2D(screen, color, vs::Vector{<:Point2}, fs::Vector{GLTriangleFace})
    return draw_mesh2D(screen.context, color, vs, fs, eachindex(fs))
end

function draw_mesh2D(ctx::Cairo.CairoContext, per_face_cols, vs::Vector, fs::Vector{GLTriangleFace}, indices)
    # Prioritize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!

    for i in indices
        c1, c2, c3 = per_face_cols[i]
        t1, t2, t3 = vs[fs[i]] #triangle points

        # don't draw any mesh faces with NaN components.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        pattern = Cairo.CairoPatternMesh()

        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1[1], t1[2])
        Cairo.mesh_pattern_line_to(pattern, t2[1], t2[2])
        Cairo.mesh_pattern_line_to(pattern, t3[1], t3[2])

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
        Cairo.set_source(ctx, pattern)
        Cairo.close_path(ctx)
        Cairo.paint(ctx)
        Cairo.destroy(pattern)
        # Reset any lingering pattern state
        Cairo.set_source_rgba(ctx, 0, 0, 0, 1)
    end
    return nothing
end

function draw_mesh2D(ctx::Cairo.CairoContext, pattern::Cairo.CairoPattern, vs::Vector, fs::Vector{GLTriangleFace}, indices)
    # Prioritize colors of the mesh if present
    # This is a hack, which needs cleaning up in the Mesh plot type!
    Cairo.set_source(ctx, pattern)

    for i in indices
        t1, t2, t3 = vs[fs[i]] # triangle points

        # don't draw any mesh faces with NaN components.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        # TODO:
        # - this may create gaps like heatmap?
        # - for some reason this is liqhter than it should be?
        Cairo.move_to(ctx, t1[1], t1[2])
        Cairo.line_to(ctx, t2[1], t2[2])
        Cairo.line_to(ctx, t3[1], t3[2])
        Cairo.close_path(ctx)
        Cairo.fill(ctx)
    end
    pattern_set_matrix(pattern, Cairo.CairoMatrix(1, 0, 0, 1, 0, 0))
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
    # if this is one expression it introduces allocations??
    new_c_part1 = (ambient .+ light_color .* diff_coeff .* diffuse) .* Vec3f(c.r, c.g, c.b) #.+
    new_c = new_c_part1 .+ light_color .* specular * spec_coeff
    return RGBAf(new_c..., c.alpha)
end

function draw_pattern(ctx, zorder, shading, meshfaces, ts, per_face_col, ns, vs, lightdir, light_color, shininess, diffuse, ambient, specular)
    for k in reverse(zorder)

        f = meshfaces[k]
        # avoid SizedVector through Face indexing
        t1 = ts[f[1]]
        t2 = ts[f[2]]
        t3 = ts[f[3]]

        # skip any mesh segments with NaN points.
        if isnan(t1) || isnan(t2) || isnan(t3)
            continue
        end

        facecolors = per_face_col[k]
        # light calculation
        if shading && !isnothing(ns)
            # these face index expressions currently allocate for SizedVectors
            # if done like `ns[f]`
            mean_normal = sum(i -> ns[i], f) / length(f)
            c1, c2, c3 = Base.Cartesian.@ntuple 3 i -> begin
                # normals are usually interpolated on the face, which allows
                # Vec3f(0) to be used to give a vertex no weight on the normal
                # direction. To reproduce this here we mix in a tiny amount of
                # the mean normal direction.
                N = normalize(ns[f[i]] + 1.0e-20 * mean_normal)
                v = vs[f[i]]
                c = facecolors[i]
                _calculate_shaded_vertexcolors(N, v, c, lightdir, light_color, ambient, diffuse, specular, shininess)
            end
        else
            c1, c2, c3 = facecolors
        end

        # debug normal coloring
        # n1, n2, n3 = Vec3f(0.5) .+ 0.5ns[f]
        # c1 = RGB(n1...)
        # c2 = RGB(n2...)
        # c3 = RGB(n3...)

        pattern = Cairo.CairoPatternMesh()

        Cairo.mesh_pattern_begin_patch(pattern)

        Cairo.mesh_pattern_move_to(pattern, t1[1], t1[2])
        Cairo.mesh_pattern_line_to(pattern, t2[1], t2[2])
        Cairo.mesh_pattern_line_to(pattern, t3[1], t3[2])

        mesh_pattern_set_corner_color(pattern, 0, c1)
        mesh_pattern_set_corner_color(pattern, 1, c2)
        mesh_pattern_set_corner_color(pattern, 2, c3)

        Cairo.mesh_pattern_end_patch(pattern)
        Cairo.set_source(ctx, pattern)
        Cairo.close_path(ctx)
        Cairo.paint(ctx)
        Cairo.destroy(pattern)
        # Reset any lingering pattern state
        Cairo.set_source_rgba(ctx, 0, 0, 0, 1)
    end

    return
end

# Still used for voxels
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


# Mesh + surface entry point
function draw_mesh3D(scene, screen, plot::ComputeGraph)
    clip_planes = plot.clip_planes[]
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

    local faceculling::Int = to_value(get(plot, :faceculling, -10))

    return draw_mesh3D(
        scene, screen, space, world_points, screen_points, meshfaces, meshnormals, per_face_col,
        model, shading[], plot.diffuse[]::Vec3f,
        plot.specular[]::Vec3f, plot.shininess[]::Float32, faceculling,
        clip_planes, plot.eyeposition[]
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
        ns = map(n -> zero_normalize(normalmatrix * n), meshnormals)
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
        light_direction, light_color, shininess, diffuse, ambient, specular
    )

    return
end

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(plot::Makie.MeshScatter))
    # We combine vertices and positions in world space.
    # Here we do the transformation to world space of meshscatter args
    # The rest happens in draw_scattered_mesh()
    transformed_pos = Makie.apply_model(plot.model_f32c[], plot.positions_transformed_f32c[])
    colors = compute_colors(plot)
    uv_transform = plot.pattern_uv_transform[]

    return draw_scattered_mesh(
        scene, screen, plot.attributes, plot.marker[],
        transformed_pos, plot.markersize[], plot.rotation[], colors,
        plot.clip_planes[], plot.transform_marker[], uv_transform
    )
end

function draw_scattered_mesh(
        scene, screen, plot::ComputeGraph, mesh,
        # positions in world space, acting as translations for mesh
        positions, scales, rotations, colors,
        clip_planes, transform_marker, uv_transform
    )
    space = plot.space[]

    meshpoints = decompose(Point3f, mesh)
    meshfaces = decompose(GLTriangleFace, mesh)
    meshnormals = normals(mesh)
    meshuvs = texturecoordinates(mesh)

    # transformation matrix to mesh into world space, see loop
    f32c_model = ifelse(transform_marker, strip_translation(plot.model[]), Mat4d(I))
    if !isnothing(scene.float32convert) && Makie.is_data_space(space)
        f32c_model = Makie.scalematrix(scene.float32convert.scaling[].scale::Vec3d) * f32c_model
    end

    # Z sorting based on meshscatter arguments
    # For correct z-ordering we need to be in view/camera or screen space
    view = plot.view[]
    zorder = sortperm(
        positions, by = p -> begin
            p4d = to_ndim(Vec4d, p, 1)
            cam_pos = view[Vec(3, 4), Vec(1, 2, 3, 4)] * p4d
            cam_pos[1] / cam_pos[2]
        end, rev = false
    )

    proj_mat = cairo_viewport_matrix(plot.resolution[]) * plot.projectionview[]

    for i in zorder
        # Get per-element data
        element_color = Makie.sv_getindex(colors, i)
        element_uv_transform = Makie.sv_getindex(uv_transform, i)
        element_translation = to_ndim(Point4d, positions[i], 0)
        element_rotation = Makie.rotationmatrix4(Makie.sv_getindex(rotations, i))
        element_scale = Makie.scalematrix(Makie.sv_getindex(scales, i))
        element_transform = element_rotation * element_scale # different order from transformationmatrix()

        # Note: These are not part of the compute graph because the number of
        # vertices of the mesh * number of positions in meshscatter could become
        # quite large

        # mesh transformations
        # - transform_func does not apply to vertices (only pos)
        # - only scaling from float32convert applies to vertices
        #   f32c_scale * (maybe model) *  rotation * scale * vertices  +  f32c * model * transform_func(plot[1])
        # =        f32c_model          * element_transform * vertices  +       element_translation
        element_world_pos = map(meshpoints) do p
            p4d = to_ndim(Point4d, to_ndim(Point3d, p, 0), 1)
            p4d = f32c_model * element_transform * p4d + element_translation
            return Point3f(p4d) / p4d[4]
        end

        element_screen_pos = project_position(Point3f, proj_mat, element_world_pos, eachindex(element_world_pos))

        draw_mesh3D(
            scene, screen, plot,
            element_world_pos, element_screen_pos, meshfaces, meshnormals, meshuvs,
            element_uv_transform, element_color, clip_planes, f32c_model * element_transform
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

    # transformation to world space
    transformed_pos = _transform_to_world(scene, primitive, pos)

    # clip full voxel instead of faces
    if !isempty(primitive.clip_planes[]) && Makie.is_data_space(primitive)
        valid = [is_visible(primitive.clip_planes[], p) for p in transformed_pos]
        transformed_pos = transformed_pos[valid]
        colors = colors[valid]
    end

    # sneak in model_f32c so we don't have to pass through another variable
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
