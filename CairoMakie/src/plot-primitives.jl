


include("lines.jl")
include("scatter.jl")
include("image-hmap.jl")
include("mesh.jl")




################################################################################
#                                   Surface                                    #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.Surface))
    attr = primitive.attributes::Makie.ComputeGraph

    Makie.add_computation!(attr, Val(:surface_as_mesh))

    Makie.register_pattern_uv_transform!(attr)

    draw_mesh3D(scene, screen, primitive)
    return nothing
end


################################################################################
#                                 MeshScatter                                  #
################################################################################


function draw_atomic(scene::Scene, screen::Screen, @nospecialize(primitive::Makie.MeshScatter))
    @get_attribute(primitive, (
        model_f32c, marker, markersize, rotation, positions_transformed_f32c,
        clip_planes, transform_marker))

    # We combine vertices and positions in world space.
    # Here we do the transformation to world space of meshscatter args
    # The rest happens in draw_scattered_mesh()
    transformed_pos = Makie.apply_model(model_f32c, positions_transformed_f32c)
    colors = compute_colors(primitive)
    uv_transform = primitive.pattern_uv_transform[]

    draw_scattered_mesh(
        scene, screen, primitive, marker,
        transformed_pos, markersize, rotation, colors,
        clip_planes, transform_marker, uv_transform
    )
end

function draw_scattered_mesh(
        scene, screen, @nospecialize(plot::Plot), mesh,
        # positions in world space, acting as translations for mesh
        positions, scales, rotations, colors,
        clip_planes, transform_marker, uv_transform
    )
    @get_attribute(plot, (model, space))

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
    zorder = sortperm(positions, by = p -> begin
        p4d = to_ndim(Vec4d, p, 1)
        cam_pos = view[Vec(3,4), Vec(1,2,3,4)] * p4d
        cam_pos[1] / cam_pos[2]
    end, rev=false)

    proj_mat = cairo_viewport_matrix(plot.resolution[]) * plot.projectionview[]

    for i in zorder
        # Get per-element data
        element_color = Makie.sv_getindex(colors, i)
        element_uv_transform = Makie.sv_getindex(uv_transform, i)
        element_translation = to_ndim(Point4d, positions[i], 0)
        element_rotation = Makie.rotationmatrix4(Makie.sv_getindex(rotations, i))
        element_scale = Makie.scalematrix(Makie.sv_getindex(scales, i))
        element_transform = element_rotation * element_scale # different order from transformationmatrix()

        # TODO: Should we cache this? Would be a lot of data...
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

        # TODO: And this?
        element_screen_pos = project_position(Point3f, proj_mat, element_world_pos, eachindex(element_world_pos))

        draw_mesh3D(
            scene, screen, plot,
            element_world_pos, element_screen_pos, meshfaces, meshnormals, meshuvs,
            element_uv_transform, element_color, clip_planes, f32c_model * element_transform
        )
    end

    return nothing
end


################################################################################
#                                    Voxel                                     #
################################################################################


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
        scene, screen, primitive, marker,
        transformed_pos, scale, Quaternionf(0,0,0,1), colors,
        Plane3f[], true, primitive.uv_transform[]
    )

    return nothing
end
