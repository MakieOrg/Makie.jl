# =============================================================================
# draw_atomic for Makie.MeshScatter
# =============================================================================

# Convert marker to mesh via dispatch (mirrors Makie's convert_attribute for meshscatter)
meshscatter_marker_mesh(marker::GeometryBasics.Mesh) = marker
meshscatter_marker_mesh(marker::GeometryBasics.GeometryPrimitive) = GeometryBasics.normal_mesh(marker)
meshscatter_marker_mesh(::Makie.Automatic) = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1.0f0))
function meshscatter_marker_mesh(marker::Symbol)
    marker === :Sphere && return GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1.0f0))
    return GeometryBasics.normal_mesh(Makie.default_marker_map()[marker])
end

function meshscatter_transforms(positions, markersize, rotation, plot_transform::Mat4f)
    n = length(positions)

    # Use Makie's conversion utilities (same as RPRMakie)
    scales3d = Makie.to_3d_scale(markersize)
    scales = scales3d isa Vec3f ? Iterators.repeated(scales3d, n) : scales3d

    rots = Makie.to_rotation(rotation)
    rotations = rots isa Quaternionf ? Iterators.repeated(rots, n) : rots

    # Build transform matrices using Makie's transformationmatrix
    transforms = Mat4f[]
    for (pos, s, r) in zip(positions, scales, rotations)
        local_transform = Makie.transformationmatrix(Makie.to_ndim(Point3f, pos, 0f0), s, r)
        push!(transforms, plot_transform * local_transform)
    end

    return transforms
end

function extract_meshscatter_materials(plot::Makie.MeshScatter, n_instances::Int)
    color = to_value(plot.color)
    has_material = haskey(plot, :material) && !isnothing(to_value(plot.material))
    material_template = has_material ? to_value(plot.material) : nothing

    # Always return Vector{Diffuse} with 0D (ConstTexture) for type stability
    # across reactive updates — ComputePipeline types the Ref from the first return.

    # Per-instance colors: use Makie's compute_colors to resolve colormapping
    if color isa AbstractVector && length(color) == n_instances
        computed = Makie.compute_colors(plot.attributes)
        if computed isa AbstractVector{<:Colorant}
            return [create_material_with_color(to_color(c), material_template) for c in computed]
        end
    end

    # Uniform color: replicate the same material for all instances
    base_color = if color isa Colorant
        to_color(color)
    elseif color isa Union{String, Symbol}
        to_color(color)
    elseif color isa AbstractVector{<:Colorant} && !isempty(color)
        to_color(first(color))
    else
        computed = Makie.compute_colors(plot.attributes)
        if computed isa AbstractVector{<:Colorant} && !isempty(computed)
            to_color(first(computed))
        elseif computed isa Colorant
            to_color(computed)
        else
            RGBAf(0.8, 0.8, 0.8, 1.0)
        end
    end

    return [create_material_with_color(base_color, material_template) for _ in 1:n_instances]
end

# --- TLAS creation helper ---

function meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances)
    handles = Hikari.SceneHandle[]
    for (transform, mat) in zip(transforms, materials)
        handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
        push!(handles, handle)
    end
    state.needs_film_clear = true
    return (
        handles=handles, n_instances=n_instances, materials=materials,
    )
end

# =============================================================================
# draw_atomic — granular compute graph
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.MeshScatter)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Marker → GB.Mesh (only recomputes when marker changes)
    register_computation!(attr, [:marker], [:trace_marker_mesh]) do args, changed, last
        return (meshscatter_marker_mesh(args.marker),)
    end

    # 2. Positions/scale/rotation/model → transform matrices (independent of color)
    # positions_transformed_f32c has model+f32c applied as needed; model_f32c is the residual.
    register_computation!(attr, [:positions_transformed_f32c, :markersize, :rotation, :model_f32c], [:trace_transforms]) do args, changed, last
        isempty(args.positions_transformed_f32c) && return (Mat4f[],)
        return (meshscatter_transforms(args.positions_transformed_f32c, args.markersize, args.rotation, Mat4f(args.model_f32c)),)
    end

    # 3. Color → materials (independent of transforms)
    # NOTE: Always return a valid material (never `nothing`) so the edge type
    # is stable across reactive updates (ComputePipeline types the Ref from
    # the first return value).
    register_computation!(attr, [:color], [:trace_materials]) do args, changed, last
        positions = to_value(attr[:positions])
        n = max(length(positions), 1)
        return (extract_meshscatter_materials(plot, n),)
    end

    # 4. TLAS management: combine marker mesh, transforms, materials
    # NOTE: Never return (nothing,) — ComputePipeline types its Ref from the first
    # return value. If the first call returns nothing (empty positions), subsequent
    # calls with data can't assign a NamedTuple to Ref{Nothing}.
    # Instead, meshscatter_create! handles empty transforms naturally (0 TLAS entries).
    #
    # Always do a full delete+recreate when anything changes.  In-place transform
    # updates via first_instance_idx are unsafe: when multiple meshscatter plots
    # exist, one plot's deletion shifts the indices of all others.
    register_computation!(attr, [:trace_marker_mesh, :trace_transforms, :trace_materials], [:trace_renderobject]) do args, changed, last
        gb_mesh = args.trace_marker_mesh
        transforms = args.trace_transforms
        materials = args.trace_materials

        n_instances = length(transforms)

        if isnothing(last) || isnothing(last.trace_renderobject) || !hasproperty(last.trace_renderobject, :handles)
            return (meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances),)
        end

        robj = last.trace_renderobject

        # Any change → full rebuild (delete old instances, create new ones).
        if changed.trace_marker_mesh || changed.trace_transforms || changed.trace_materials
            delete_trace_handles!(hikari_scene, robj)
            if n_instances != robj.n_instances
                materials = extract_meshscatter_materials(plot, n_instances)
            end
            return (meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances),)
        end

        return (robj,)
    end
end
