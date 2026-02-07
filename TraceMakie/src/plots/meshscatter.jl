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

    # Per-instance colors: use Makie's compute_colors to resolve colormapping
    if color isa AbstractVector && length(color) == n_instances
        computed = Makie.compute_colors(plot.attributes)
        if computed isa AbstractVector{<:Colorant}
            return [create_material_with_color(to_color(c), material_template) for c in computed]
        end
    end

    return extract_material(plot, plot.color)
end

# --- TLAS creation helper ---

function _meshscatter_create!(hikari_scene, state, tmesh, transforms, materials, n_instances)
    has_per_instance = materials isa Vector

    if has_per_instance
        handles = Raycore.TLASHandle[]
        first_instance_idx = length(hikari_scene.accel.instances) + 1
        for (transform, mat) in zip(transforms, materials)
            mat_idx = push!(hikari_scene, mat)
            handle = push!(hikari_scene.accel, tmesh, mat_idx, transform)
            push!(handles, handle)
        end
        state.needs_film_clear = true
        return (
            handles=handles, tmesh=tmesh, per_instance=true,
            first_instance_idx=first_instance_idx,
            n_instances=n_instances, materials=materials,
        )
    else
        mat_idx = push!(hikari_scene, materials)
        first_instance_idx = length(hikari_scene.accel.instances) + 1
        handle = push!(hikari_scene.accel, Raycore.Instance(tmesh, transforms,
                      [mat_idx for _ in 1:n_instances]))
        state.needs_film_clear = true
        return (
            handle=handle, tmesh=tmesh, per_instance=false,
            first_instance_idx=first_instance_idx,
            n_instances=n_instances, material=materials, mat_idx=mat_idx,
        )
    end
end

function _meshscatter_delete_handles!(hikari_scene, robj)
    isnothing(robj) && return
    tlas = hikari_scene.accel
    if hasproperty(robj, :handles)
        for h in robj.handles
            delete!(tlas, h)
        end
    elseif hasproperty(robj, :handle)
        delete!(tlas, robj.handle)
    end
end

# =============================================================================
# draw_atomic — granular compute graph
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.MeshScatter)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Marker → TriangleMesh (only recomputes when marker changes)
    register_computation!(attr, [:marker], [:trace_marker_mesh]) do args, changed, last
        mesh = meshscatter_marker_mesh(args.marker)
        return (Raycore.TriangleMesh(mesh),)
    end

    # 2. Positions/scale/rotation/model → transform matrices (independent of color)
    register_computation!(attr, [:positions, :markersize, :rotation, :model], [:trace_transforms]) do args, changed, last
        isempty(args.positions) && return (Mat4f[],)
        return (meshscatter_transforms(args.positions, args.markersize, args.rotation, Mat4f(args.model)),)
    end

    # 3. Color → materials (independent of transforms)
    register_computation!(attr, [:color], [:trace_materials]) do args, changed, last
        positions = to_value(attr[:positions])
        n = length(positions)
        n == 0 && return (nothing,)
        return (extract_meshscatter_materials(plot, n),)
    end

    # 4. TLAS management: combine marker mesh, transforms, materials
    register_computation!(attr, [:trace_marker_mesh, :trace_transforms, :trace_materials], [:trace_renderobject]) do args, changed, last
        tmesh = args.trace_marker_mesh
        transforms = args.trace_transforms
        materials = args.trace_materials

        isempty(transforms) && return (nothing,)
        isnothing(materials) && return (nothing,)

        n_instances = length(transforms)

        if isnothing(last) || isnothing(last.trace_renderobject)
            # First run
            return (_meshscatter_create!(hikari_scene, state, tmesh, transforms, materials, n_instances),)
        end

        robj = last.trace_renderobject

        # Full rebuild if marker changed or instance count changed
        if changed.trace_marker_mesh || n_instances != robj.n_instances
            _meshscatter_delete_handles!(hikari_scene, robj)
            # Re-extract materials if count changed (since materials node didn't know about count change)
            if n_instances != robj.n_instances
                materials = extract_meshscatter_materials(plot, n_instances)
            end
            return (_meshscatter_create!(hikari_scene, state, tmesh, transforms, materials, n_instances),)
        end

        if changed.trace_transforms
            tlas = hikari_scene.accel
            backend = KernelAbstractions.get_backend(tlas.instances.transform)
            transforms_gpu = KernelAbstractions.allocate(backend, Mat4f, length(transforms))
            copyto!(transforms_gpu, transforms)
            Raycore.update_instance_transforms!(tlas, transforms_gpu, length(transforms), robj.first_instance_idx)
            state.needs_film_clear = true
        end

        if changed.trace_materials
            computed = Makie.compute_colors(plot.attributes)
            if robj.per_instance && computed isa AbstractVector{<:Colorant}
                for (i, mat) in enumerate(robj.materials)
                    tex = _get_material_texture(mat)
                    !isnothing(tex) && fill!(tex.data, to_spectrum(to_color(computed[i])))
                end
            elseif !robj.per_instance
                tex = _get_material_texture(robj.material)
                if !isnothing(tex) && computed isa Colorant
                    fill!(tex.data, to_spectrum(to_color(computed)))
                end
            end
            state.needs_film_clear = true
        end

        return (robj,)
    end
end
