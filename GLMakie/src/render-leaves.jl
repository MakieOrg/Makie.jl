################################################################################
### Render leaves
################################################################################

"""
    register_render_leaves!(scene::Scene, plot::Makie.Plot) -> (inputs, uniforms)

Register the computations producing the render-ready leaf nodes of a primitive
plot and return their names.

`inputs` names leaves that need backend specific handling (colormapping, marker
images, ...), `uniforms` names leaves that are handed to the render object
unchanged. A backend maps both onto its own naming via a lookup table.

These computations only touch the plot's compute graph, so they run without a
GPU context or a loaded backend.
"""
function register_render_leaves! end

function depthsort!(positions, depth_vals, indices, pvm)
    pvm24 = pvm[Vec(3, 4), Vec(1, 2, 3, 4)] # only calculate zw
    resize!(depth_vals, length(positions))
    resize!(indices, length(positions))
    map!(depth_vals, positions) do p
        p4d = pvm24 * to_ndim(Point4f, to_ndim(Point3f, p, 0.0f0), 1.0f0)
        return p4d[1] / p4d[2]
    end
    sortperm!(indices, depth_vals; rev = true)
    indices .-= 1
    return depth_vals, indices
end

function sumlengths(points, resolution)
    # normalize w component if available
    f(p::VecTypes{4}) = p[Vec(1, 2)] / p[4]
    f(p::VecTypes) = p[Vec(1, 2)]

    invalid(p::VecTypes{4}) = p[4] <= 1.0e-6
    invalid(p::VecTypes) = false

    T = eltype(eltype(typeof(points)))
    result = zeros(T, length(points))
    for (i, idx) in enumerate(eachindex(points))
        idx0 = max(idx - 1, 1)
        p1, p2 = points[idx0], points[idx]
        if any(map(isnan, p1)) || any(map(isnan, p2)) || invalid(p1) || invalid(p2)
            result[i] = 0.0f0
        else
            result[i] = result[max(i - 1, 1)] + 0.5 * norm(resolution .* (f(p1) - f(p2)))
        end
    end
    return result
end

function generate_indices(ps, indices = Cuint[], valid = Float32[])
    empty!(indices)
    resize!(valid, length(ps))

    # can't draw a line with less than 2 points so there are no indices to generate
    # and valid is irrelevant
    if length(ps) < 2
        valid .= 0 # just in case random data is problematic
        return (indices, valid)
    end

    sizehint!(indices, length(ps) + 2)

    # This loop identifies sections of line points A B C D E F bounded by
    # the start/end of the list ps or by NaN and generates indices for them:
    # if A == F (loop):      E A B C D E F B 0
    # if A != F (no loop):   0 A B C D E F 0
    # where 0 is NaN
    # It marks vertices as invalid (0) if they are NaN, valid (1) if they
    # are part of a continuous line section, or as ghost edges (2) used to
    # cleanly close a loop. The shader detects successive vertices with
    # 1-2-0 and 0-2-1 validity to avoid drawing ghost segments (E-A from
    # 0-E-A-B and F-B from E-F-B-0 which would duplicate E-F and A-B)

    last_start_pos = eltype(ps)(NaN)
    last_start_idx = -1

    for (i, p) in enumerate(ps)
        not_nan = isfinite(p)
        valid[i] = not_nan

        if not_nan
            if last_start_idx == -1
                # place nan before section of line vertices
                # (or duplicate ps[1])
                push!(indices, max(1, i - 1))
                last_start_idx = length(indices) + 1
                last_start_pos = p
            end
            # add line vertex
            push!(indices, i)

            # case loop (loop index set, loop contains at least 3 segments, start == end)
        elseif (last_start_idx != -1) &&
                (length(indices) - last_start_idx > 2) &&
                (ps[max(1, i - 1)] ≈ last_start_pos)

            # add ghost vertices before an after the loop to cleanly connect line
            indices[last_start_idx - 1] = max(1, i - 2)
            push!(indices, indices[last_start_idx + 1], i)
            # mark the ghost vertices
            valid[i - 2] = 2
            valid[indices[last_start_idx + 1]] = 2
            # not in loop anymore
            last_start_idx = -1

            # non-looping line end
        elseif (last_start_idx != -1) # effective "last index not NaN"
            push!(indices, i)
            last_start_idx = -1
            # else: we don't need to push repeated NaNs
        end
    end

    # treat ps[end+1] as NaN to correctly finish the line
    if (last_start_idx != -1) && (length(indices) - last_start_idx > 2) && (ps[end] ≈ last_start_pos)
        indices[last_start_idx - 1] = length(ps) - 1
        push!(indices, indices[last_start_idx + 1])
        valid[end - 1] = 2
        valid[indices[last_start_idx + 1]] = 2
    elseif last_start_idx != -1
        push!(indices, length(ps))
    end

    indices .-= Cuint(1)

    return (indices, valid)
end

function generate_indices(positions::NamedTuple, changed::NamedTuple, cached)
    if isnothing(cached)
        indices = Cuint[]
        valid = Float32[]
    else
        indices = empty!(cached[1])
        valid = cached[2]
    end
    ps = positions[1]
    return generate_indices(ps, indices, valid)
end

function register_render_leaves!(scene::Makie.Scene, plot::Scatter)
    attr = plot.attributes

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    if attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        register_computation!(
            attr,
            [:positions_transformed_f32c, :projectionview, :preprojection, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, projectionview, preprojection, model), changed, last
            pvm = projectionview * preprojection * model
            depth_vals = isnothing(last) ? Float32[] : last.gl_depth_cache
            indices = isnothing(last) ? Cuint[] : last.gl_indices
            return depthsort!(pos, depth_vals, indices, pvm)
        end
    else
        map!(length, attr, :positions_transformed_f32c, :gl_indices)
    end

    map!(ps -> Int32(length(ps)), attr, :positions_transformed_f32c, :gl_len)

    inputs = [
        # Special
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
        :sdf_marker_shape,
        # read by the construction path; kept last so inputs[1] stays positions
        :space, :markerspace, :marker,
    ]
    if attr[:marker][] isa FastPixel
        map!(attr, :markerspace, :gl_markerspace) do space
            space == :pixel && return Int32(0)
            space == :data && return Int32(1)
            return error("Unsupported markerspace for FastPixel marker: $space")
        end

        map!(marker -> marker.marker_type, attr, :marker, :sdf_marker_shape)

        uniforms = [
            :positions_transformed_f32c,
            :gl_markerspace, :quad_scale, :model_f32c, :f32c_scale,
            :lowclip_color, :highclip_color, :nan_color, :gl_indices, :gl_len,
            :marker_offset,
        ]

    else
        Makie.all_marker_computations!(attr)

        # Simple forwards
        uniforms = [
            :positions_transformed_f32c,
            :sdf_uv, :quad_scale, :quad_offset,
            :image, :lowclip_color, :highclip_color, :nan_color,
            :strokecolor, :strokewidth, :glowcolor, :glowwidth,
            :model_f32c, :converted_rotation, :billboard, :transform_marker,
            :gl_indices, :gl_len, :marker_offset, :f32c_scale,
        ]
    end

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Lines)
    attr = plot.attributes

    Makie.add_computation!(attr, :gl_miter_limit)
    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)

    # TODO: Is this useful for other backends?
    map!(*, attr, [:projectionview, :model_f32c], :gl_pvm32)
    register_computation!(
        attr, [:gl_pvm32, :positions_transformed_f32c], [:gl_projected_positions]
    ) do (pvm32, positions), changed, last
        output = isnothing(last) ? Point4f[] : last.gl_projected_positions
        resize!(output, length(positions))
        map!(output, positions) do pos
            return pvm32 * to_ndim(Point4d, to_ndim(Point3d, pos, 0.0), 1.0)
        end
        return (output,)
    end

    # TODO: This is a compile time constant that should be settable from the plot.
    # No point in making it an input here, since this is just before compilation.
    # Keeping `haskey()` in case add_constant is handled differently in the future
    haskey(attr, :debug) || Makie.add_constant!(attr, :debug, false)

    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)

    if isnothing(plot.linestyle[])
        positions = :positions_transformed_f32c
        # unused dummy data
        map!(pos -> collect(Float32.(eachindex(pos))), attr, positions, :gl_last_length)
    else
        positions = :gl_projected_positions
        map!(sumlengths, attr, [positions, :resolution], :gl_last_length)
    end

    # Derived vertex attributes
    register_computation!(generate_indices, attr, [positions], [:gl_indices, :gl_valid_vertex])
    map!(indices -> Int32(length(indices) - 2), attr, :gl_indices, :gl_total_length)

    inputs = [
        # relevant to creation time decisions
        positions,
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange, :color_mapping_type,
        # read by the construction path; kept last so inputs[1] stays positions
        :linestyle,
    ]
    # uniforms getting passed through
    uniforms = [
        :gl_indices, :gl_valid_vertex, :gl_total_length, :gl_last_length,
        :uniform_pattern, :uniform_pattern_length, :linecap, :gl_miter_limit, :joinstyle, :uniform_linewidth,
        :scene_origin, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Voxels)
    attr = plot.attributes

    Makie.add_computation!(attr, scene, Val(:voxel_model))
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :voxel_model)

    Makie.register_world_normalmatrix!(attr, :voxel_model)

    map!(attr, [:chunk_u8, :gap], :instances) do chunk, gap
        N = sum(size(chunk))
        return ifelse(gap > 0.01, 2 * N, N + 3)
    end

    Makie.add_computation!(attr, scene, Val(:voxel_uv_transform))

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :chunk_u8, :packed_uv_transform,
        # read by the construction path; kept last so inputs[1] stays positions
        :interpolate,
    ]
    uniforms = [
        :instances, :voxel_model, :gap, :depthsorting,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
    ]

    haskey(attr, :voxel_color) && push!(inputs, :voxel_color) # needs interpolation handling
    haskey(attr, :voxel_colormap) && push!(uniforms, :voxel_colormap)

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Volume)
    attr = plot.attributes

    Makie.add_computation!(attr, scene, Val(:uniform_model)) # bit different from voxel_model

    # TODO: check if this should be the normal model matrix (for voxel too)
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :model, :uniform_model)

    # TODO: reuse in clip planes
    map!(model -> Mat4f(inv(model)), attr, :uniform_model, :modelinv)

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_colorrange, :color_mapping_type,
        # read by the construction path; kept last so inputs[1] stays positions
        :interpolate, :enable_depth,
    ]
    uniforms = [
        :scaled_color, :modelinv, :algorithm, :absorption, :isovalue, :isorange,
        :diffuse, :specular, :shininess, :backlight,
        :lowclip_color, :highclip_color, :nan_color,
        :uniform_model, :samples,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Surface)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.add_computation!(attr, Val(:surface_transform))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)
    Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))

    map!(z -> (size(z, 1) - 1) * (size(z, 2) - 1), attr, :z, :instances)

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
        # read by add_mesh_color_attributes!
        :interpolate,
    ]
    uniforms = [
        :x_transformed_f32c, :y_transformed_f32c, :z_transformed_f32c,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :model_f32c, :instances,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :view_normalmatrix,
        :invert_normals, :pattern_uv_transform, :fetch_pixel,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Mesh)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
        # read by add_mesh_color_attributes!
        :interpolate,
    ]
    uniforms = [
        :positions_transformed_f32c, :faces, :normals, :texturecoordinates,
        :lowclip_color, :highclip_color, :nan_color, :model_f32c, :matcap,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix,
        :view_normalmatrix, :pattern_uv_transform, :fetch_pixel,
        :interpolate_in_fragment_shader,
    ]

    return inputs, uniforms
end

"""
    register_image_render_leaves!(scene::Scene, plot) -> (inputs, uniforms)

Render leaves for plots a backend draws as a textured quad. Used for `Image` and
potentially as a fast path for regular `Heatmap`s.
"""
function register_image_render_leaves!(scene::Makie.Scene, plot)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
    ]
    uniforms = [
        :positions_transformed_f32c,
        :lowclip_color, :highclip_color, :nan_color,
        :model_f32c, :uv_transform,
    ]
    push!(inputs, :interpolate)   # read by assemble_image_robj!

    return inputs, uniforms
end

register_render_leaves!(scene::Makie.Scene, plot::Image) = register_image_render_leaves!(scene, plot)

function register_render_leaves!(scene::Makie.Scene, plot::Heatmap)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.add_computation!(attr, scene, Val(:heatmap_transform))

    map!(attr, [:x_transformed_f32c, :y_transformed_f32c], :instances) do x, y
        return (length(x) - 1) * (length(y) - 1)
    end

    inputs = [
        :x_transformed_f32c, :y_transformed_f32c,
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
        # read by the construction path; kept last so inputs[1] stays positions
        :interpolate,
    ]
    uniforms = [
        :lowclip_color, :highclip_color, :nan_color,
        :model_f32c, :instances,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::LineSegments)
    attr = plot.attributes

    # linestyle/pattern handling
    Makie.add_computation!(attr, :uniform_pattern, :uniform_pattern_length)
    haskey(attr, :debug) || Makie.add_constant!(attr, :debug, false) # see Lines
    # could use world space, but clip space fits better with other backends
    # costs ~1µs per clip plane
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)

    map!(length, attr, :positions_transformed_f32c, :indices)

    inputs = [
        :space,
        :scaled_color, :alpha_colormap, :scaled_colorrange, :color_mapping_type,
        # read by the construction path; kept last so inputs[1] stays positions
        :linestyle,
    ]
    uniforms = [
        :positions_transformed_f32c, :indices,
        :uniform_pattern, :uniform_pattern_length, :linecap, :uniform_linewidth,
        :scene_origin, :model_f32c,
        :lowclip_color, :highclip_color, :nan_color, :debug,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::MeshScatter)
    attr = plot.attributes

    Makie.add_computation!(attr, Val(:disassemble_mesh), :marker)
    Makie.add_computation!(attr, Val(:uniform_clip_planes))
    Makie.add_computation!(attr, scene, Val(:uv_transform_packing))
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    Makie.register_world_normalmatrix!(attr)
    Makie.register_view_normalmatrix!(attr)

    map!(attr, :positions_transformed_f32c, [:instances, :gl_len]) do pos
        return length(pos), Int32(length(pos))
    end

    inputs = [
        # Special
        :space,
        # Needs explicit handling
        :alpha_colormap, :scaled_color, :scaled_colorrange, :color_mapping_type,
        :packed_uv_transform,
    ]
    uniforms = [
        :positions_transformed_f32c, :markersize, :rotation, :f32c_scale, :instances,
        :vertex_position, :faces, :normal, :uv,
        :lowclip_color, :highclip_color, :nan_color, :matcap,
        :fetch_pixel, :model_f32c,
        :diffuse, :specular, :shininess, :backlight, :world_normalmatrix, :view_normalmatrix,
        :gl_len, :transform_marker,
    ]

    return inputs, uniforms
end

function register_render_leaves!(scene::Makie.Scene, plot::Text)
    attr = plot.attributes

    if haskey(attr, :depthsorting) && attr[:depthsorting][]
        # is projectionview enough to trigger on scene resize in all cases?
        register_computation!(
            attr,
            [:per_char_positions_transformed_f32c, :projectionview, :model_f32c],
            [:gl_depth_cache, :gl_indices]
        ) do (pos, projectionview, space, model), changed, last
            pvm = projectionview * model
            depth_vals = isnothing(last) ? Float32[] : last.gl_depth_cache
            indices = isnothing(last) ? Cuint[] : last.gl_indices
            return depthsort!(pos, depth_vals, indices, pvm)
        end
    else
        map!(length, attr, :per_char_positions_transformed_f32c, :gl_indices)
    end

    map!(ps -> Int32(length(ps)), attr, :per_char_positions_transformed_f32c, :gl_len)

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    # read by the construction path (register_camera!, default_shader)
    inputs = Symbol[:space, :markerspace, :positions_transformed_f32c]

    # Simple forwards
    uniforms = [
        :per_char_positions_transformed_f32c,
        :text_color, :text_strokecolor, :text_rotation,
        :marker_offset, :quad_offset, :sdf_uv, :quad_scale,
        :lowclip_color, :highclip_color, :nan_color,
        :strokewidth, :glowcolor, :glowwidth,
        :model_f32c, :transform_marker,
        :gl_indices, :gl_len, :f32c_scale,
    ]

    Makie.add_computation!(attr, Val(:uniform_clip_planes))

    return inputs, uniforms
end
