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

function meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances;
                              reuse_mi_indices::Union{Nothing, AbstractVector{UInt32}}=nothing)
    # One BLAS + N instances, per-instance material routed through
    # `InstanceDescriptor.instance_id` (Hikari's `resolve_mi_idx` picks it
    # up as a `medium_interface_idx` override).
    #
    # `reuse_mi_indices` lets rebuild frames reuse the previously-returned
    # per-instance mi_indices: `update_material!` on each old slot instead
    # of `push!(scene.materials, …)`.  With this, scene.materials grows only
    # up to the high water mark of N instead of by N every frame.
    handles = if n_instances == 0
        Hikari.SceneHandle[]
    else
        push!(hikari_scene, gb_mesh, collect(materials), collect(transforms);
              reuse_mi_indices)
    end
    mi_indices = UInt32[h.interface for h in handles]
    state.needs_film_clear = true
    return (
        handles=handles, n_instances=n_instances, materials=materials,
        mi_indices=mi_indices,
    )
end

# =============================================================================
# GPU-resident path helpers
# =============================================================================

"""
    ensure_lava_rotations(rotation, n) -> LavaArray{Vec4f, 1}

Convert a rotation argument to a `LavaArray{Vec4f, 1}` of length `n`,
where each element is `Vec4f(x, y, z, w)` (unit quaternion).

Accepts:
- `LavaArray{Vec4f, 1}`: returned as-is (no copy).
- `Quaternionf` scalar: broadcast identity quaternion over all n instances.
- `Vec4f` scalar: broadcast over all n instances.
- `AbstractVector{Quaternionf}`: convert each to Vec4f.
- `AbstractVector{Vec4f}`: upload to GPU.

Any other type errors loudly -- the GPU path does not support arbitrary
rotation representations; convert to one of the above forms first.
"""
function ensure_lava_rotations(rotation, n::Int)
    if rotation isa Lava.LavaArray{Vec4f, 1}
        return rotation
    elseif rotation isa Quaternionf
        d = rotation.data  # (x, y, z, w)
        q = Vec4f(d[1], d[2], d[3], d[4])
        return Lava.LavaArray([q for _ in 1:n])
    elseif rotation isa Vec4f
        return Lava.LavaArray([rotation for _ in 1:n])
    elseif rotation isa AbstractVector{Quaternionf}
        length(rotation) == n || throw(ArgumentError(
            "rotation length $(length(rotation)) != positions length $n"))
        cpu = [Vec4f(q.data[1], q.data[2], q.data[3], q.data[4]) for q in rotation]
        return Lava.LavaArray(cpu)
    elseif rotation isa AbstractVector{Vec4f}
        length(rotation) == n || throw(ArgumentError(
            "rotation length $(length(rotation)) != positions length $n"))
        return Lava.LavaArray(collect(rotation))
    else
        error("meshscatter GPU path: unsupported rotation type $(typeof(rotation)). " *
              "Provide a Quaternionf scalar, Vec4f scalar, " *
              "AbstractVector{Quaternionf}, AbstractVector{Vec4f}, or " *
              "LavaArray{Vec4f, 1}.")
    end
end

"""
    uniform_scale_f32(markersize) -> Float32

Extract a uniform scalar scale from `markersize`. Supports:
- Number: converted to Float32 directly.
- Vec3f with equal components: uses the first component.
- Vec3f with unequal components: errors (non-uniform scale not supported on GPU path).

Per-instance markersize (AbstractVector) is not yet supported on the GPU
path -- use a uniform scalar instead.
"""
function uniform_scale_f32(markersize)
    if markersize isa Number
        return Float32(markersize)
    elseif markersize isa Vec3f
        if markersize[1] ≈ markersize[2] ≈ markersize[3]
            return Float32(markersize[1])
        else
            error("meshscatter GPU path: non-uniform Vec3f markersize $markersize " *
                  "is not supported. Use a scalar Float32 markersize.")
        end
    elseif markersize isa AbstractVector
        error("meshscatter GPU path: per-instance markersize (AbstractVector) " *
              "is not supported. Use a uniform scalar Float32 markersize.")
    else
        error("meshscatter GPU path: unsupported markersize type $(typeof(markersize)).")
    end
end

"""
    meshscatter_create_gpu!(hikari_scene, state, gb_mesh,
                             positions, rotations, scale, instance_mask)

GPU-resident meshscatter first-sync path. Builds the BLAS from `gb_mesh`,
allocates a `LavaArray{LavaInstanceRecord}` of length `n`, runs
`write_meshscatter_instances_kernel` to fill it, registers the batch via
`push!(tlas, mesh, instance_buf)`, and calls `Raycore.sync!` to build the TLAS.

Returns a NamedTuple stored as the recipe's `trace_renderobject`:
  `(handle, n_instances, instance_buf, blas_addr, scale, mask, gpu_path=true)`

`state` may be `nothing` when called from tests.
"""
function meshscatter_create_gpu!(hikari_scene, state, gb_mesh::GeometryBasics.Mesh,
                                  positions::Lava.LavaArray{Point3f, 1},
                                  rotations::Lava.LavaArray{Vec4f, 1},
                                  scale::Float32,
                                  instance_mask::UInt8)
    n = length(positions)
    tlas = hikari_scene.accel

    # Attach neutral TriangleMeta (medium_interface_idx=0, no area lights) so
    # hwtlas_add_geometry! builds Triangle{TriangleMeta} matching the HWTLAS
    # type parameter.  The GPU path does not register materials per-instance;
    # the hit shader falls back to the face's material_idx=0 (transparent/miss)
    # or is used in a physics-visibility-only mode.
    gb_faces = GeometryBasics.faces(gb_mesh)
    n_faces = length(gb_faces)
    face_meta = [Hikari.TriangleMeta(UInt32(0), UInt32(i), UInt32(0)) for i in 1:n_faces]
    mesh_with_meta = GeometryBasics.mesh(gb_mesh;
                                          face_meta=GeometryBasics.per_face(face_meta, gb_mesh))

    # Allocate the instance buffer (must have AS_INPUT_USAGE so the driver can
    # use it as an AS build input).
    instance_buf = Lava.LavaArray{Lava.LavaInstanceRecord}(undef, n;
                                                             extra_usage=Lava.AS_INPUT_USAGE)

    # push!(tlas, mesh_with_meta, instance_buf) builds the BLAS internally and
    # registers the batch in tlas.instance_batches.  The BLAS address is now
    # available.
    handle = Base.push!(tlas, mesh_with_meta, instance_buf; instance_mask=instance_mask)
    blas_addr = tlas.instance_batches[end].blas.address

    # Fill the instance buffer on the GPU.
    backend = Lava.LavaBackend()
    Lava.write_meshscatter_instances_kernel(backend)(
        positions, rotations, scale, blas_addr, instance_mask, instance_buf;
        ndrange = n)
    Lava.vk_flush!(Lava.vk_context().default_bq)

    # Build the TLAS from the now-filled instance buffer.
    Raycore.sync!(tlas)

    state !== nothing && (state.needs_film_clear = true)
    return (handle=handle, n_instances=n, instance_buf=instance_buf,
            blas_addr=blas_addr, scale=scale, mask=instance_mask, gpu_path=true)
end

"""
    meshscatter_refit_gpu!(hikari_scene, state, positions, rotations, robj)

GPU-resident meshscatter per-frame refit path. Re-runs
`write_meshscatter_instances_kernel` into the existing instance buffer (fetched
via `Raycore.instance_buffer`), then calls `Raycore.refit_tlas!`.

`robj` must be the NamedTuple returned by a prior `meshscatter_create_gpu!` call.
Returns the same `robj` (handle/instance_buf identity is preserved).
"""
function meshscatter_refit_gpu!(hikari_scene, state,
                                 positions::Lava.LavaArray{Point3f, 1},
                                 rotations::Lava.LavaArray{Vec4f, 1},
                                 robj)
    tlas = hikari_scene.accel
    instance_buf = Raycore.instance_buffer(tlas, robj.handle)

    backend = Lava.LavaBackend()
    Lava.write_meshscatter_instances_kernel(backend)(
        positions, rotations, robj.scale, robj.blas_addr, robj.mask, instance_buf;
        ndrange = robj.n_instances)
    Lava.vk_flush!(Lava.vk_context().default_bq)

    Raycore.refit_tlas!(tlas)
    state !== nothing && (state.needs_film_clear = true)
    return robj
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
    # GPU-resident path: when positions is a LavaArray{Point3f, 1} the recipe
    # bypasses the CPU transform pipeline and drives TLAS instances directly from
    # GPU buffers via write_meshscatter_instances_kernel + refit_tlas!.
    # The CPU path (Vector positions) is preserved unchanged for backward compat.
    register_computation!(attr, [:trace_marker_mesh, :trace_transforms, :trace_materials], [:trace_renderobject]) do args, changed, last
        gb_mesh = args.trace_marker_mesh
        transforms = args.trace_transforms
        materials = args.trace_materials

        # --- GPU-resident branch ---
        # Positions Observable value (before f32c transform) determines the path.
        positions_raw = to_value(attr[:positions])
        if positions_raw isa Lava.LavaArray{Point3f, 1}
            n = length(positions_raw)
            rotation_raw = to_value(attr[:rotation])
            rotations_arr = ensure_lava_rotations(rotation_raw, n)
            scale = uniform_scale_f32(to_value(attr[:markersize]))
            mask = UInt8(0x04)

            robj = isnothing(last) || isnothing(last.trace_renderobject) ||
                   !hasproperty(last.trace_renderobject, :gpu_path) ?
                   nothing : last.trace_renderobject

            if robj === nothing || changed.trace_marker_mesh || n != robj.n_instances
                # Full rebuild path.
                # If a prior GPU batch exists and the marker or count changed, we
                # cannot delete the old batch from HWTLAS (batch deletion is not yet
                # implemented). For the physics demo use case this branch should
                # never be hit after the first frame -- positions count and marker
                # geometry are fixed across frames. Error loudly if it happens so
                # the caller knows to build a fresh plot.
                if robj !== nothing && (changed.trace_marker_mesh || n != robj.n_instances)
                    error("meshscatter GPU path: marker mesh or instance count changed " *
                          "after initial sync. The GPU-resident path does not support " *
                          "in-place batch replacement. Build a new meshscatter plot " *
                          "instead of updating the existing one.")
                end
                return (meshscatter_create_gpu!(hikari_scene, state, gb_mesh,
                                                positions_raw, rotations_arr,
                                                scale, mask),)
            else
                # Incremental: re-derive instance records and refit TLAS.
                return (meshscatter_refit_gpu!(hikari_scene, state,
                                               positions_raw, rotations_arr, robj),)
            end
        end

        # --- CPU path (unchanged) ---
        n_instances = length(transforms)

        if isnothing(last) || isnothing(last.trace_renderobject) || !hasproperty(last.trace_renderobject, :handles)
            return (meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances),)
        end

        robj = last.trace_renderobject

        # Marker mesh OR instance count change: needs full BLAS rebuild.
        # We pass the prior mi_indices into meshscatter_create! so the
        # material MultiTypeSet slots are reused — scene.materials grows
        # only up to the high water mark, never unbounded per frame.
        if changed.trace_marker_mesh || n_instances != robj.n_instances
            delete_trace_handles!(hikari_scene, robj)
            if n_instances != robj.n_instances
                materials = extract_meshscatter_materials(plot, n_instances)
            end
            reuse = hasproperty(robj, :mi_indices) ? robj.mi_indices : nothing
            return (meshscatter_create!(hikari_scene, state, gb_mesh, transforms, materials, n_instances;
                                         reuse_mi_indices=reuse),)
        end

        # Arity-stable incremental path: update per-instance transforms and/or
        # materials in place via `Raycore.update_transform!` / `Hikari.update_material!`.
        # This keeps `scene.materials` / `scene.media_interfaces` / `hwtlas.instance_transforms`
        # at a fixed size across frames — critical for streamplot / quiver /
        # meshscatter animations that rebuild every frame (otherwise each
        # frame piles N new material entries onto the MultiTypeSet and every
        # subsequent `rebuild_static!` re-adapts the full accumulated vector,
        # leaking hundreds of MiB/frame).
        # Single TLASHandle owns all N instances (see the batch push! in
        # scene-mesh.jl); each instance is index `i` within that range.
        if changed.trace_transforms
            base_handle = robj.handles[1].geometry
            for (i, h) in enumerate(robj.handles)
                Raycore.update_transform_at!(hikari_scene.accel, base_handle, i, transforms[i])
            end
        end
        if changed.trace_materials
            for (i, h) in enumerate(robj.handles)
                Hikari.update_material!(hikari_scene, h.interface, materials[i])
            end
        end
        state.needs_film_clear = true
        return ((handles=robj.handles, n_instances=n_instances, materials=materials,
                 mi_indices=robj.mi_indices),)
    end
end
