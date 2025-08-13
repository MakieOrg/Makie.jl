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
- `apply_transform = input_space === :space` controls whether transformations and float32convert are applied.
- `apply_transform_func = apply_transform` controls whether `transform_func` is applied.
- `apply_float32convert = apply_transform` controls whether `float32convert` is applied.
- `apply_model = apply_transform` controls whether the `model` matrix is applied.
- `apply_clip_planes = false` controls whether points clipped by `clip_planes` are replaced by NaN. (Does not consider clip space clipping. Only applies if `is_data_space(input_space)`.)
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
        apply_transform::Bool = input_space === :space,
        apply_transform_func::Bool = apply_transform,
        apply_float32convert::Bool = apply_transform,
        apply_model::Bool = apply_transform,
        apply_clip_planes::Bool = false,
    ) where {OT <: VecTypes}

    # Handle transform function + f32c
    if apply_transform_func
        transformed_name = Symbol(input_name, :_transformed)
        register_positions_transformed!(plot_graph; input_name, output_name = transformed_name)
    else
        transformed_name = input_name
    end

    if apply_float32convert && !is_data_space(output_space)
        transformed_f32c_name = Symbol(transformed_name, :_f32c)
        register_positions_transformed_f32c!(plot_graph; input_name = transformed_name, output_name = transformed_f32c_name)
    else
        # Pipeline will apply f32c if the input space is data space, so we
        # should avoid it here. TODO: also dynamically
        transformed_f32c_name = transformed_name
    end

    if apply_model || (input_space !== output_space) || yflip
        register_positions_projected!(
            scene_graph, plot_graph, OT;
            input_space, output_space,
            input_name = transformed_f32c_name, output_name,
            yflip, apply_model, apply_clip_planes
        )
    else
        ComputePipeline.alias!(plot_graph, transformed_f32c_name, output_name)
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
        yflip::Bool = false,
        apply_model::Bool = input_space === :space,
        apply_clip_planes::Bool = false
    ) where {OT <: VecTypes}

    # Connect necessary projection matrix from scene
    projection_matrix_name = register_camera_matrix!(scene_graph, plot_graph, input_space, output_space)
    merged_matrix_name = Symbol(ifelse(yflip, "yflip_", "") * string(projection_matrix_name) * "_model")

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
    apply_model && push!(inputs, ifelse(is_data_space(output_space), :model, :model_f32c))

    # merge/create projection related matrices
    flip_matrix(res::Vec2) = transformationmatrix(Vec3(0, res[2], 0), Vec3(1, -1, 1))
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
