
"""
    register_projected_positions!(plot[, output_type = Point3f]; kwargs...)

Register projected positions for the given plot starting from plot argument space.

Note that this also generates compute nodes for transformed positions (i.e. with
transform_func applied) and float32-converted positions (i.e. with float32convert
applied).

Optionally `output_type` can be set to control the element type of projected
positions. (4D points will not be w-normalized, 1D - 3D points will be. This is
to allow clip space clipping to happen elsewhere.)

## Keyword Arguments:
- `input_space = :space` sets the input space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `output_space = :clip` sets the output space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `input_name = :positions` sets the source positions which will be projected.
- `transformed_name = Symbol(input_name, :_transformed)` sets the name of positions after the `transform_func` is applied.
- `transformed_f32c_name = Symbol(transformed_name, :_f32c)` sets the name of positions after float32convert is applied.
- `output_name = Symbol(output_space, :_, input_name)` sets the name of the projected positions.
- `apply_transform = input_space === :space` controls whether transformations and float32convert are applied.
- `apply_clip_planes = !is_data_space(output_space)` controls whether points clipped by `clip_planes` are replaced by NaN. (Does not consider clip space clipping. Only applies if `is_data_space(input_space)`.)
"""
function register_projected_positions!(@nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    return register_projected_positions!(parent_scene(plot), plot, OT; kwargs...)
end
function register_projected_positions!(scene::Scene, @nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    return register_projected_positions!(scene.compute, plot.attributes, OT; kwargs...)
end
function register_projected_positions!(
        scene_graph::ComputePipeline.ComputeGraph,
        plot_graph::ComputePipeline.ComputeGraph,
        ::Type{OT} = Point3f;
        input_space::Symbol = :space,
        output_space::Symbol = :clip, # TODO: would :pixel be more useful?
        input_name::Symbol = :positions,
        transformed_name::Symbol = Symbol(input_name, :_transformed),
        transformed_f32c_name::Symbol = Symbol(transformed_name, :_f32c),
        output_name::Symbol = Symbol(output_space, :_, input_name),
        yflip::Bool = false,
        apply_transform::Bool = input_space === :space,
        apply_clip_planes::Bool = false,
    ) where {OT <: VecTypes}

    # Handle transform function + f32c
    if apply_transform
        register_positions_transformed!(plot_graph; input_name, output_name = transformed_name)
        if is_data_space(output_space)
            # Pipeline will apply f32c if the input space is data space, so we
            # should avoid it here. TODO: also dynamically
            transformed_f32c_name = transformed_name
        else
            register_positions_transformed_f32c!(plot_graph; input_name = transformed_name, output_name = transformed_f32c_name)
        end
    else
        transformed_f32c_name = input_name
    end

    register_positions_projected!(
        scene_graph, plot_graph, OT;
        input_space, output_space,
        input_name = transformed_f32c_name, output_name,
        yflip, apply_transform, apply_clip_planes
    )

    return getindex(plot_graph, output_name)
end

"""
    register_positions_projected!(plot[, output_type = Point3f]; kwargs)

Register projected positions for the given plot starting from transformed space.

Note that this does not apply `transform_func` or `float32convert`. The input
positions are assumed to already be transformed. `model` is still applied if
`apply_transform == true`.

## Keyword Arguments:
- `input_space = :space` sets the input space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `output_space = :clip` sets the output space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `input_name = :positions_transformed_f32c` sets the source positions which will be projected.
- `output_name = Symbol(output_space, :_, positions)` sets the name of the projected positions.
- `apply_transform = input_space === :space` controls whether transformations and float32convert are applied.
- `apply_clip_planes = !is_data_space(output_space)` controls whether points clipped by `clip_planes` are replaced by NaN. (Does not consider clip space clipping. Only applies if `is_data_space(input_space)`.)
"""
function register_positions_projected!(@nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    return register_positions_projected!(parent_scene(plot), plot, OT; kwargs...)
end
function register_positions_projected!(scene::Scene, @nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    return register_positions_projected!(scene.compute, plot.attributes, OT; kwargs...)
end
function register_positions_projected!(
        scene_graph::ComputePipeline.ComputeGraph,
        plot_graph::ComputePipeline.ComputeGraph,
        ::Type{OT} = Point3f;
        input_space::Symbol = :space,
        output_space::Symbol = :clip, # TODO: would :pixel be more useful?
        input_name::Symbol = :positions_transformed_f32c,
        output_name::Symbol = Symbol(output_space, :_positions),
        yflip::Bool = false,
        apply_transform::Bool = input_space === :space,
        apply_clip_planes::Bool = !is_data_space(output_space)
    ) where {OT <: VecTypes}

    # Connect necessary projection matrix from scene
    projection_matrix_name = register_camera_matrix!(scene_graph, plot_graph, input_space, output_space)
    merged_matrix_name = Symbol(ifelse(yflip, "yflip_", "") * string(projection_matrix_name) * "_model")

    # TODO: Names may collide and ComputePipeline doesn't check strictly enough
    # by default to catch this...
    if haskey(plot_graph, output_name)
        node = getindex(plot_graph, output_name)
        names = map(n -> n.name, node.parent.inputs::Vector{ComputePipeline.Computed})
        inputs = Symbol[merged_matrix_name, input_name]
        if apply_clip_planes && (is_data_space(input_space) || input_space === :space)
            push!(inputs, ifelse(apply_transform, :model_clip_planes, :clip_planes))
            input_space === :space && push!(inputs, :space)
        end
        if names != inputs
            error("Could not register $output_name - already exists with different inputs: \nold:   $names\nnew   $inputs")
        else
            return getindex(plot_graph, output_name)
        end
    end

    # connect resolution for yflip (Cairo) and model matrix if requested
    inputs = Symbol[]
    if yflip
        is_pixel_space(output_space) || error("`yflip = true` is currently only allowed when targeting pixel space")
        if !haskey(plot_graph, :resolution)
            add_input!(plot_graph, :resolution, scene_graph[:resolution])
        end
        push!(inputs, :resolution)
    end

    push!(inputs, projection_matrix_name)
    # in data space f32c is not applied and we should use the plain model matrix
    apply_transform && push!(inputs, ifelse(is_data_space(output_space), :model, :model_f32c))

    # merge/create projection related matrices
    combine_matrices(res::Vec2, pv::Mat4, m::Mat4) = Mat4f(flip_matrix(res) * pv * m)::Mat4f
    combine_matrices(res::Vec2, pv::Mat4) = Mat4f(flip_matrix(res) * pv)::Mat4f
    combine_matrices(pv::Mat4, m::Mat4) = Mat4f(pv * m)::Mat4f
    combine_matrices(pv::Mat4) = Mat4f(pv)::Mat4f
    map!(combine_matrices, plot_graph, inputs, merged_matrix_name)

    # apply projection
    # clip planes only apply from data/world space.
    if apply_clip_planes && (is_data_space(input_space) || input_space === :space)
        # easiest to transform them to the space of the projection input and
        # clip based on those points
        if apply_transform
            register_model_clip_planes!(plot_graph)
            clip_planes_name = :model_clip_planes
        else
            clip_planes_name = :clip_planes
        end

        if input_space === :space # dynamic
            map!(plot_graph, [merged_matrix_name, input_name, clip_planes_name, :space], output_name) do matrix, pos, clip_planes, space
                return _project(OT, matrix, pos, clip_planes, space)
            end
        else # static
            map!(plot_graph, [merged_matrix_name, input_name, clip_planes_name], output_name) do matrix, pos, clip_planes
                return _project(OT, matrix, pos, clip_planes, :data)
            end
        end

    else
        # no clip planes, just project everything
        map!(plot_graph, [merged_matrix_name, input_name], output_name) do matrix, pos
            return _project(OT, matrix, pos)
        end
    end

    return getindex(plot_graph, output_name)
end

function register_model_clip_planes!(attr, modelname = :model_f32c)
    map!(to_model_space, attr, [modelname, :clip_planes], :model_clip_planes)
    return
end

################################################################################

function register_markerspace_positions!(@nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    haskey(plot, :markerspace) || error("Cannot compute markerspace positions for a plot that doesn't have markerspace.")
    # kwargs get overwritten by later keyword arguments
    return register_projected_positions!(plot, OT; kwargs..., input_space = :space, output_space = :markerspace)
end