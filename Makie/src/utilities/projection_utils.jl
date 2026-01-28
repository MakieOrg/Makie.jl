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
- `input_space = :space` sets the input space. Can be `:space` or `:markerspace` to refer to those plot attributes or any static space like `:data`.
- `output_space = :pixel` sets the output space. Can be `:space` or `:markerspace` to refer to those plot attributes or any static space like `:pixel`.
- `input_name = :positions` sets the source positions which will be projected.
- `output_name = Symbol(output_space, :_, input_name)` sets the name of the projected positions.
- `apply_transform = input_space === :space` controls whether forward transformations and float32convert are applied.
- `apply_transform_func = apply_transform` controls whether `transform_func` is applied.
- `apply_float32convert = apply_transform` controls whether `float32convert` is applied.
- `apply_model = apply_transform` controls whether the `model` matrix is applied.
- `apply_clip_planes = false` controls whether points clipped by `clip_planes` are replaced by NaN. (Does not consider clip space clipping. Only applies if `is_data_space(input_space)`.)
- `apply_inverse_transform = output_space === :space` controls whether inverse transformations are applied when projecting to data space.
- `apply_inverse_transform_func = apply_inverse_transform` controls whether inverse `transform_func` is applied.
- `apply_inverse_float32convert = apply_inverse_transform` controls whether inverse `float32convert` is applied.
- `apply_inverse_model = apply_inverse_transform` controls whether inverse `model` matrix is applied.
- `yflip = false` flips the `y` coordinate if set to true and `output_space = :pixel`

Related: [`register_position_transforms!`](@ref), [`register_positions_transformed!`](@ref),
[`register_positions_transformed_f32c!`](@ref), [`register_projected_rotations_2d!`](@ref)
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
        output_space::Symbol = :pixel,
        input_name::Symbol = :positions,
        output_name::Symbol = Symbol(output_space, :_, input_name),
        yflip::Bool = false,
        # Forward transforms
        apply_transform::Bool = input_space === :space,
        apply_transform_func::Bool = apply_transform,
        apply_float32convert::Bool = apply_transform && (output_space != :space),
        apply_model::Bool = apply_transform,
        apply_clip_planes::Bool = false,
        # Inverse transforms
        apply_inverse_transform::Bool = output_space === :space && !apply_transform,
        apply_inverse_transform_func::Bool = apply_inverse_transform,
        apply_inverse_float32convert::Bool = apply_inverse_transform,
        apply_inverse_model::Bool = apply_inverse_transform,
    ) where {OT <: VecTypes}

    #=
    - projections (space) and transformations (transform func, model) are orthogonal,
      meaning they don't depend on each other
    - float32convert is special:
        - (forward) f32c only applies when the input space is :data (or dynamic
          data via :space, :markerspace), because the other spaces can't have
          float32 precision issues
        - plots apply f32c based on their space, so it's generally desirable to
          have f64 (pre f32c) outputs here when targeting :data space

    With inverse transforms we have:
    1. apply transform func
    2. apply float32convert
    3. apply model_f32c
    4. apply projection (input_space -> output_space) (+ clip planes, yflip)
    5. apply inverse model_f32c
    6. apply inverse float32convert
    7. apply inverse transform func

    To figure out what can be skipped we need to figure out which parts combine
    to identities.

    Note that the order of float32convert and model is swapped so that GLMakie
    and WGLMakie can apply a Float32 safe version of the model matrix on the GPU.
        f32c(model(data)) = model_f32(f32c(data))
    =#

    # We can statically skip steps if they combine to an identity regardless of
    # what other steps do. This is the case if everything between the step and
    # its inverse is also an identity (statically).
    # There can still be dynamic identities, but these require computations to
    # exist for dynamic evaluation.
    is_static_identity_camera_projection = input_space === output_space && !yflip
    is_static_identity_projection = is_static_identity_camera_projection && (apply_model === apply_inverse_model)
    is_static_identity_f32convert = is_static_identity_projection && (apply_float32convert === apply_inverse_float32convert)

    # "is_static_identity_transform" which implies everything is an identity
    if is_static_identity_f32convert && (apply_transform_func == apply_inverse_transform_func)
        ComputePipeline.alias!(plot_graph, input_name, output_name)
        return getindex(plot_graph, output_name)
    end

    current_output = input_name

    # Handle forward transform function
    if apply_transform_func
        # This checks if plot.space[] == :data.
        # input_space == :data does not overwrite this
        transformed_name = Symbol(current_output, :_transformed)
        register_positions_transformed!(plot_graph; input_name = current_output, output_name = transformed_name)
        current_output = transformed_name
    end

    # Handle forward float32convert
    if apply_float32convert && !is_static_identity_f32convert
        transformed_f32c_name = Symbol(current_output, :_f32c)
        register_positions_transformed_f32c!(plot_graph; input_name = current_output, output_name = transformed_f32c_name)
        current_output = transformed_f32c_name
    end

    # Use intermediate name for projection output if any inverse transforms will be applied
    needs_any_inverse =
        (apply_inverse_float32convert && !is_static_identity_f32convert) ||
        (apply_inverse_transform_func && !is_static_identity_transform)
    projection_output = needs_any_inverse ? Symbol(current_output, :_projected) : output_name

    if !is_static_identity_projection
        register_positions_projected!(
            scene_graph, plot_graph, OT;
            input_space, output_space,
            input_name = current_output, output_name = projection_output,
            model_name = ifelse(apply_float32convert, :model_f32c, :model),
            inverse_model_name = ifelse(apply_inverse_float32convert, :inverse_model_f32c, :inverse_model),
            yflip, apply_model, apply_inverse_model, apply_clip_planes
        )
        current_output = projection_output
    end


    if apply_inverse_float32convert && !is_static_identity_f32convert
        inv_f32c_name = apply_inverse_transform_func ? Symbol(current_output, :_inv_f32c) : output_name

        if output_space === :space  # dynamic
            map!(plot_graph, [current_output, :f32c, :space], inv_f32c_name) do pos, f32c, space
                return is_data_space(space) ? inv(f32c).(pos) : pos
            end
            current_output = inv_f32c_name
        elseif is_data_space(output_space)  # static data space
            map!(plot_graph, [current_output, :f32c], inv_f32c_name) do pos, f32c
                return inv(f32c).(pos)
            end
            current_output = inv_f32c_name
        end
    end

    if apply_inverse_transform_func
        map!(inverse_transform, plot_graph, :transform_func, :inverse_transform_func)
        # Use Makie. prefix to avoid shadowing by kwarg `apply_transform::Bool`
        map!(Makie.apply_transform, plot_graph, [:inverse_transform_func, current_output], output_name)
        current_output = output_name
    end

    # Alias to final output name if different
    if current_output !== output_name
        ComputePipeline.alias!(plot_graph, current_output, output_name)
    end

    return getindex(plot_graph, output_name)
end

"""
    register_positions_projected!(plot[, output_type = Point3f]; kwargs)

Register projected positions for the given plot starting from transformed space.

Note that this does not apply `transform_func` or `float32convert`. The input
positions are assumed to already be transformed. `model_f32c`/`model` is still applied if
`apply_model == true`.

## Keyword Arguments:
- `input_space = :space` sets the input space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `output_space = :pixel` sets the output space. Can be `:space` or `:markerspace` to refer to those plot attributes.
- `input_name = :positions_transformed_f32c` sets the source positions which will be projected.
- `output_name = Symbol(output_space, :_, positions)` sets the name of the projected positions.
- `apply_model = input_space === :space` controls whether the model matrix is applied.
- `apply_clip_planes = false` controls whether points clipped by `clip_planes` are replaced by NaN. (Does not consider clip space clipping. Only applies if `is_data_space(input_space)`.)
- `yflip = false` flips the `y` coordinate if set to true and `output_space = :pixel`

Related: [`register_position_transforms!`](@ref), [`register_positions_transformed!`](@ref),
[`register_positions_transformed_f32c!`](@ref), [`register_projected_positions!`](@ref)
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
        output_space::Symbol = :pixel,
        input_name::Symbol = :positions_transformed_f32c,
        output_name::Symbol = Symbol(output_space, :_positions),
        model_name::Symbol = :model,
        inverse_model_name::Symbol = :inverse_model,
        yflip::Bool = false,
        apply_model::Bool = input_space === :space,
        apply_inverse_model::Bool = false,
        apply_clip_planes::Bool = false
    ) where {OT <: VecTypes}

    # Connect necessary projection matrix from scene
    projection_matrix_name = register_camera_matrix!(scene_graph, plot_graph, input_space, output_space)
    merged_matrix_name = Symbol(
        ifelse(apply_inverse_model, "$(inverse_model_name)_", "") *
        ifelse(yflip, "yflip_", "") *
        string(projection_matrix_name) *
        ifelse(apply_model, "_$model_name", "") * "4d"
    )

    inputs = Symbol[]

    # Technically we should use:
    # - model if f32convert was not applied
    # - model_f32c if f32convert was applied
    if apply_inverse_model
        map!(inv, plot_graph, :model, :inverse_model)
        map!(inv, plot_graph, :model_f32c, :inverse_model_f32c)
        push!(inputs, inverse_model_name)
    end

    # connect resolution for yflip (Cairo) and model matrix if requested
    if yflip
        is_pixel_space(output_space) || error("`yflip = true` is currently only allowed when targeting pixel space")
        if !haskey(plot_graph, :resolution)
            add_input!(plot_graph, :resolution, scene_graph[:resolution])
        end
        push!(inputs, :resolution)
    end

    push!(inputs, projection_matrix_name)
    apply_model && push!(inputs, model_name)

    # merge/create projection related matrices
    flip_matrix(res::Vec2) = transformationmatrix(Vec3d(0, res[2], 0), Vec3d(1, -1, 1))
    combine_matrices(im::Mat4, res::Vec2, pv::Mat4, m::Mat4) = Mat4d(im * flip_matrix(res) * pv * m)::Mat4d
    combine_matrices(im::Mat4, res::Vec2, pv::Mat4) = Mat4d(im * flip_matrix(res) * pv)::Mat4d
    combine_matrices(res::Vec2, pv::Mat4, m::Mat4) = Mat4d(flip_matrix(res) * pv * m)::Mat4d
    combine_matrices(res::Vec2, pv::Mat4) = Mat4d(flip_matrix(res) * pv)::Mat4d
    combine_matrices(im::Mat4, pv::Mat4, m::Mat4) = Mat4d(im * pv * m)::Mat4d
    combine_matrices(pv::Mat4, m::Mat4) = Mat4d(pv * m)::Mat4d
    combine_matrices(pv::Mat4) = Mat4d(pv)::Mat4d

    map!(combine_matrices, plot_graph, inputs, merged_matrix_name)

    # apply projection
    # clip planes only apply from data/world space.
    if apply_clip_planes && (is_data_space(input_space) || input_space === :space)
        # easiest to transform them to the space of the projection input and
        # clip based on those points
        if apply_model
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

function register_f32c_matrix!(attr)
    return map!(attr, :f32c, :f32c_matrix)
end

function apply_inverse_model_to_positions(model::Mat4, positions)
    inv_model = inv(model)
    return map(positions) do p
        p4d = to_ndim(Point4d, to_ndim(Point3d, p, 0), 1)
        p4d = inv_model * p4d
        return Point3f(p4d[Vec(1, 2, 3)] ./ p4d[4])
    end
end

################################################################################

function register_markerspace_positions!(@nospecialize(plot::Plot), ::Type{OT} = Point3f; kwargs...) where {OT}
    haskey(plot, :markerspace) || error("Cannot compute markerspace positions for a plot that doesn't have markerspace.")
    # kwargs get overwritten by later keyword arguments
    return register_projected_positions!(plot, OT; kwargs..., input_space = :space, output_space = :markerspace)
end

"""
    angle2d(p1, p2)

Computes the angle between the `(1, 0)` direction and `p2 - p1`. z values are
ignored. The result is in [-π, π].
"""
angle2d(p1::VecTypes{2}, p2::VecTypes{2}) = Float32(atan(p2[2] - p1[2], p2[1] - p1[1]))
angle2d(p1::VecTypes, p2::VecTypes) = angle2d(p1[Vec(1, 2)], p2[Vec(1, 2)])

@deprecate angle(p1, p2) angle2d(p1, p2) false

"""
    to_upright_angle(angle)

Maps an angle from [-π, π] to [-π/2; π/2] by adding or subtracting π.
"""
to_upright_angle(angle) = angle - ifelse(abs(angle) > 0.5f0 * π, copysign(Float32(π), angle), 0)

function local_basis_transformation_matrix(M, p)
    #=
    A projection matrix is applied as
    f(p) = (M * p)[1:3] / (M * p)[4]
    Because of the division (perpsective projection), the local basis may change
    in space. To calulate it, we need to calculate the jacobian and evaluate it
    at the given position.
    =#
    p3d = to_ndim(Point3d, p, 0)
    p4d = to_ndim(Point4d, p3d, 1)
    w = dot(M[4, :], p4d)
    deriv1 = M[Vec(1, 2, 3), Vec(1, 2, 3)] * w
    deriv2 = (M[Vec(1, 2, 3), :] * p4d) * M[4, Vec(1, 2, 3)]'
    return (deriv1 .- deriv2) ./ (w * w)
end

function contains_perspective_projection(M::Mat4)
    return (M[4, 1] != 0) || (M[4, 2] != 0) || (M[4, 3] != 0)
end

"""
    register_projected_rotations_2d!(plot; position_name, direction_name, kwargs...)

Computes the angles of direction vectors at given positions while taking into
account distortions picked up in the transformation and projection pipeline.

To do this, `apply_transform_to_direction()` is used to apply the transform
function to directions. Then the remaining matrix transformations (including
float32convert) are applied under the assumption that they do not include
perspective projection. Finally the 2D angle to the x-axis (1, 0) is calculated
using `atan(dir[2], dir[1])` and the optional `rotation_transform` is applied.

## Keyword Arguments

- `position_name::Symbol` name of the positions where the directions apply
- `direction_name::Symbol` name of the directions to be processed
- `output_name::Symbol = :rotations` name of the rotation output
- `rotation_transform = identity` A transformation that is applied to angles before outputting them. E.g. `to_upright_angle`.
- `relative_delta = 1e-3` sets the delta for `apply_transform_to_direction()` relative to the data scale
"""
function register_projected_rotations_2d!(plot::Plot; kwargs...)
    return register_projected_rotations_2d!(parent_scene(plot).compute, plot.attributes; kwargs...)
end
function register_projected_rotations_2d!(
        scene_graph::ComputeGraph, plot_graph::ComputeGraph;
        position_name::Symbol,
        direction_name::Symbol,
        output_name::Symbol = :rotations,
        rotation_transform = identity,
        relative_delta = 1.0e-3
    )

    projection_matrix_name = register_camera_matrix!(scene_graph, plot_graph, :space, :pixel)
    register_model_f32c!(plot_graph)

    map!(
        plot_graph,
        [projection_matrix_name, :model_f32c, :f32c, :transform_func, position_name, direction_name],
        output_name
    ) do proj_matrix, model, f32c, transform_func, positions, directions

        pvmf32 = proj_matrix * model

        if f32c !== nothing
            pvmf32 *= f32_convert_matrix(f32c)
        end

        delta = relative_delta * norm(widths(Rect3d(positions)))

        if contains_perspective_projection(pvmf32)
            # Perspective projection makes the basis position dependent
            map(positions, directions) do pos, dir
                transformed_dir = apply_transform_to_direction(transform_func, pos, dir, delta)
                local_pvmf32 = local_basis_transformation_matrix(pvmf32, pos)
                transformed_dir = local_pvmf32 * to_ndim(Vec3f, transformed_dir, 0)
                angle = atan(transformed_dir[2], transformed_dir[1])
                return rotation_transform(angle)
            end
        else
            pvmf32_3 = pvmf32[Vec(1, 2, 3), Vec(1, 2, 3)]
            map(positions, directions) do pos, dir
                transformed_dir = apply_transform_to_direction(transform_func, pos, dir, delta)
                transformed_dir = pvmf32_3 * to_ndim(Vec3f, transformed_dir, 0)
                angle = atan(transformed_dir[2], transformed_dir[1])
                return rotation_transform(angle)
            end
        end
    end

    return getindex(plot_graph, output_name)
end

"""
    register_transformed_rotations_3d!(plot; position_name, direction_name, kwargs...)

Computes `transform_func`-aware 3D direction vectors using
`apply_transform_to_direction()`.

## Keyword Arguments

- `position_name::Symbol` name of the positions where the directions apply
- `direction_name::Symbol` name of the directions to be processed
- `output_name::Symbol = :rotations` name of the rotation output
- `relative_delta = 1e-3` sets the delta for `apply_transform_to_direction()` relative to the data scale
"""
function register_transformed_rotations_3d!(
        @nospecialize(plot::Plot);
        position_name::Symbol,
        direction_name::Symbol,
        output_name::Symbol = :rotations,
        relative_delta = 1.0e-3
    )

    map!(
        plot, [:transform_func, position_name, direction_name], output_name
    ) do transform_func, positions, directions
        delta = relative_delta * norm(widths(Rect3d(positions)))
        return apply_transform_to_direction(transform_func, positions, directions, delta)
    end

    return getproperty(plot, output_name)
end
