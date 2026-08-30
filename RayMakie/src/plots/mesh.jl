# =============================================================================
# draw_atomic for Makie.Mesh
# =============================================================================
#
# A Mesh has two render paths chosen per-frame by `should_raytrace(scene, plot)`:
#
#   - Trace path:   push to Hikari scene, BLAS/HWTLAS-traced.
#                   Returns NamedTuple (handle, mat_idx, material, instance_idx).
#   - Overlay path: rasterized on top of the rendered film via Lava graphics
#                   pipeline. Returns a LavaRenderObject.
#
# A single :trace_renderobject node delegates to:
#
#   mesh_trace_create!  / mesh_trace_update!     (trace path)
#   mesh_overlay_create! / mesh_overlay_update!  (overlay path)
#
# `last.trace_renderobject` carries enough information (LavaRenderObject vs
# NamedTuple with :handle) to detect a path switch and force a re-create.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    state = screen.state
    hikari_scene = state.hikari_scene

    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    register_computation!(attr,
        [:mesh, :positions_transformed_f32c, :faces, :normals,
         :texturecoordinates, :trace_color_tex, :model_f32c, :material],
        [:trace_renderobject]) do args, changed, last

        last_robj = isnothing(last) ? nothing : last.trace_renderobject

        if !should_raytrace(scene, plot) || isnothing(hikari_scene)
            return (mesh_overlay_dispatch!(screen, scene, plot, args, last_robj),)
        end

        return (mesh_trace_dispatch!(hikari_scene, state, plot, args, changed, last, last_robj),)
    end
end

# -----------------------------------------------------------------------------
# Trace path
# -----------------------------------------------------------------------------

# Returns true if `robj` was produced by the trace path (has a Hikari handle).
is_trace_robj(robj) = robj !== nothing && hasproperty(robj, :handle)

function mesh_trace_dispatch!(hikari_scene, state, plot, args, changed, last, last_robj)
    # Geometry only. `trace_color_tex` was in this set, so recolouring a mesh
    # tore down its BLAS and rebuilt it — the colour never reaches the geometry,
    # it only ever feeds `extract_material` in `push_to_scene_simple`.
    needs_rebuild = !is_trace_robj(last_robj) ||
                    changed.mesh || changed.positions_transformed_f32c ||
                    changed.faces || changed.normals ||
                    changed.texturecoordinates

    # A colour change is a material swap, with one catch: `MultiTypeSet.update!`
    # replaces in place and so requires the same CONCRETE type. Recolouring can
    # change it — a scalar `Kd` gives `Diffuse{RGBSpectrum}` where a texture
    # gives `Diffuse{Texture{...}}` — and that case still needs the re-push.
    # Decided here rather than in `mesh_trace_update!` because only this function
    # can fall back to a rebuild.
    recolor_material = nothing
    if !needs_rebuild && changed.trace_color_tex
        recolor_material = trace_material_for_color(plot, args)
        if recolor_material === nothing ||
                typeof(recolor_material) !== typeof(last_robj.material)
            needs_rebuild = true
        end
    end

    if needs_rebuild
        # Classify BEFORE rebuilding, and only for a mesh that already had a
        # BLAS — the first build is not something a refit could have avoided.
        if is_trace_robj(last_robj)
            # `changed.mesh` is deliberately NOT consulted: `:mesh` is the
            # container `register_mesh_decomposition!` decomposes, so replacing
            # `arg1` dirties it whatever the new mesh contains. The decomposed
            # nodes are the topology signal, and they are accurate — a mesh
            # rebuilt with equal faces reports `faces = false`.
            #
            # One trap in reading them: `ComputePipeline.is_same(::Array, ::Array)`
            # reports the SAME array object as CHANGED, because in-place mutation
            # between resolves is undetectable, and only compares by `isequal`
            # when the pointers differ. So handing back the identical `faces`
            # vector marks it dirty while handing back a copy does not.
            if (changed.positions_transformed_f32c || changed.normals) &&
                    !(changed.faces || changed.texturecoordinates)
                state.refit_eligible_rebuilds += 1
            else
                state.topology_rebuilds += 1
            end
        end
        # Drop the previous trace handle (if any) before rebuilding so
        # scene.materials / scene.media_interfaces stay bounded.
        is_trace_robj(last_robj) && delete_trace_handles!(hikari_scene, last_robj)
        reuse_mat_idx = reusable_material_idx(last)
        return mesh_trace_create!(hikari_scene, state, plot, args, reuse_mat_idx)
    end

    return mesh_trace_update!(hikari_scene, state, last_robj, args, changed, recolor_material)
end

"""
    trace_material_for_color(plot, args) -> Hikari.Material or nothing

The material `push_to_scene_simple` would build for the current colour, without
touching the geometry. `nothing` means "cannot be done without a rebuild".

Per-vertex colours are the reason this can fail: they are baked into a texture
against the mesh's vertex count, so `build_vertex_color_texture` needs the mesh.
`args.mesh` is a `MetaMesh` for glTF/OBJ content, whose embedded per-face
materials `push_to_scene` resolves through a different path entirely — that one
is left to the rebuild rather than reimplemented here.
"""
function trace_material_for_color(plot, args)
    color_tex = args.trace_color_tex
    if color_tex isa AbstractVector{<:Colorant}
        mesh_val = args.mesh
        mesh_val isa GeometryBasics.Mesh || return nothing
        color_tex = build_vertex_color_texture(color_tex, mesh_val)
    end
    return extract_material(plot, color_tex)
end

function mesh_trace_create!(hikari_scene, state, plot, args, reuse_mat_idx)
    transform = Mat4f(args.model_f32c)
    robj = push_to_scene(args.mesh, hikari_scene, plot, args.trace_color_tex,
                         args.positions_transformed_f32c, args.faces,
                         args.normals, args.texturecoordinates, transform,
                         reuse_mat_idx)
    state.needs_film_clear = true
    return robj
end

function mesh_trace_update!(hikari_scene, state, robj, args, changed, recolor_material = nothing)
    if changed.model_f32c
        update_trace_transform!(hikari_scene, state, robj, Mat4f(args.model_f32c))
    end
    if recolor_material !== nothing
        # Type-checked against the stored material by the caller, so this is the
        # in-place `MultiTypeSet.update!` and the BLAS is untouched. The robj
        # carries the material forward so the next colour change compares
        # against what is actually stored.
        update_trace_material!(hikari_scene, state, robj, recolor_material)
        robj = merge(robj, (material = recolor_material,))
    end
    if changed.material
        # Pass args.material raw (NOT through extract_material again).
        # extract_material can wrap Kr/Kt/index into `Texture{...}` when
        # Makie has since populated plot.color with a default, but the
        # initial push stored the material unwrapped.  MultiTypeSet.update!
        # requires matching concrete types, so we must preserve whatever
        # structure the user passed.
        update_trace_material!(hikari_scene, state, robj, args.material)
    end
    return robj
end

# -----------------------------------------------------------------------------
# Overlay path (2D mesh, rasterized via graphics pipeline)
# -----------------------------------------------------------------------------

function mesh_overlay_dispatch!(screen, scene, plot, args, last_robj)
    flat_positions, flat_colors = mesh_overlay_flat_arrays(plot, args)
    pv = Mat4f(scene.camera.projectionview[])
    model_mat = Mat4f(args.model_f32c)

    if last_robj isa LavaRenderObject
        return mesh_overlay_update!(last_robj, flat_positions, flat_colors, pv, model_mat)
    end
    return mesh_overlay_create!(screen, flat_positions, flat_colors, pv, model_mat)
end

# Build per-vertex (flat) position and color arrays for graphics pipeline.
# Faces are expanded into 3 vertices each so the pipeline can use a
# non-indexed draw.  Colors track the user's `plot.color` semantics:
# per-vertex, per-face/per-group, scalar Colorant, or a fallback.
function mesh_overlay_flat_arrays(plot, args)
    positions_3f = map(p -> Makie.to_ndim(Point3f, p, 0f0), args.positions_transformed_f32c)
    faces_val = args.faces
    n_verts = length(positions_3f)
    n_faces = length(faces_val)

    flat_positions = Vector{Vec3f}(undef, 3 * n_faces)
    @inbounds for (fi, f) in enumerate(faces_val), j in 1:3
        flat_positions[3 * (fi - 1) + j] = positions_3f[f[j]]
    end

    raw_color = to_value(plot.color)
    flat_colors = if raw_color isa AbstractVector{<:Colorant} && length(raw_color) == n_verts
        # Per-vertex
        out = Vector{Vec4f}(undef, 3 * n_faces)
        @inbounds for (fi, f) in enumerate(faces_val), j in 1:3
            c = RGBA{Float32}(raw_color[f[j]])
            out[3 * (fi - 1) + j] = Vec4f(c.r, c.g, c.b, c.alpha)
        end
        out
    elseif raw_color isa AbstractVector{<:Colorant} && !isempty(raw_color)
        # Per-face / per-group: distribute uniformly across faces
        nc = length(raw_color)
        faces_per_color = max(1, n_faces ÷ nc)
        out = Vector{Vec4f}(undef, 3 * n_faces)
        @inbounds for (fi, _) in enumerate(faces_val)
            ci = min(div(fi - 1, faces_per_color) + 1, nc)
            c = RGBA{Float32}(raw_color[ci])
            v = Vec4f(c.r, c.g, c.b, c.alpha)
            out[3 * (fi - 1) + 1] = v
            out[3 * (fi - 1) + 2] = v
            out[3 * (fi - 1) + 3] = v
        end
        out
    elseif raw_color isa Colorant
        c = RGBA{Float32}(raw_color)
        fill(Vec4f(c.r, c.g, c.b, c.alpha), 3 * n_faces)
    else
        c = mesh_overlay_color(plot, args.trace_color_tex)
        fill(Vec4f(c.r, c.g, c.b, c.alpha), 3 * n_faces)
    end

    return flat_positions, flat_colors
end

function mesh_overlay_create!(screen, flat_positions, flat_colors, pv, model_mat)
    pipeline = get_mesh_pipeline!(screen)
    backend = screen.config.device
    return LavaRenderObject(pipeline;
        backend,
        arg_names = (:positions, :colors, :projectionview, :model),
        buffers = Dict{Symbol, AbstractGPUArray}(
            :positions => Mantle.devicearray(backend, flat_positions),
            :colors => Mantle.devicearray(backend, flat_colors),
        ),
        uniforms = Dict{Symbol, Any}(
            :projectionview => pv,
            :model => model_mat,
        ),
        vertex_count = length(flat_positions),
        instances = 1,
    )
end

function mesh_overlay_update!(robj::LavaRenderObject, flat_positions, flat_colors, pv, model_mat)
    update_buffer!(robj, :positions, flat_positions)
    update_buffer!(robj, :colors, flat_colors)
    robj.uniforms[:projectionview] = pv
    robj.uniforms[:model] = model_mat
    robj.vertex_count = length(flat_positions)
    robj.visible = true
    return robj
end

# =============================================================================
# Material helpers — in-place swap on existing handle
# =============================================================================

"""
Swap the material of an existing mesh scene handle in place — no BLAS/HWTLAS
rebuild.  For a `MediumInterface`, unpack to surface + inside updates.
"""
function update_trace_material!(hikari_scene, state, robj, new_material)
    hikari_scene === nothing && return
    robj === nothing && return
    h = hasproperty(robj, :handle) ? robj.handle : return
    interface_idx = h isa Hikari.SceneHandle ? h.interface :
                    hasproperty(robj, :mat_idx) ? robj.mat_idx : return
    if new_material isa Hikari.MediumInterface
        Hikari.update_material!(hikari_scene, interface_idx, new_material.material)
        new_material.inside !== nothing &&
            Hikari.update_material!(hikari_scene, interface_idx, new_material.inside)
    elseif new_material isa Hikari.Material
        Hikari.update_material!(hikari_scene, interface_idx, new_material)
    end
    state.needs_film_clear = true
    return nothing
end

# =============================================================================
# push_to_scene dispatch
# =============================================================================

# Extract diffuse texture from a GLTF material dict
function extract_glb_diffuse_texture(mat_dict::Dict{String, Any})
    if haskey(mat_dict, "diffuse map")
        diffuse_map = mat_dict["diffuse map"]
        if haskey(diffuse_map, "image")
            return Hikari.Texture(to_spectrum(diffuse_map["image"]))
        end
    end
    diffuse = get(mat_dict, "diffuse", Vec3f(1, 1, 1))
    return Hikari.ConstTexture(to_spectrum(RGBf(diffuse[1], diffuse[2], diffuse[3])))
end

# Does the prior trace_renderobject carry a `mat_idx` we can recycle?
# Every rebuild that takes this path keeps `scene.materials` /
# `scene.media_interfaces` a fixed size, letting `Raycore.update!` re-use the
# backing GPU texture slot rather than growing it each frame.
function reusable_material_idx(last)
    last === nothing && return nothing
    last_robj = last.trace_renderobject
    last_robj === nothing && return nothing
    hasproperty(last_robj, :mat_idx) || return nothing
    return UInt32(last_robj.mat_idx)
end

# MetaMesh: multi-material.  Per-face materials don't currently share a slot
# with the prior render object (multi-mat rebuilds are rare), so the
# `reuse_mat_idx` argument is ignored — the normal push path runs.
function push_to_scene(mesh_val::GeometryBasics.MetaMesh, hikari_scene, plot, color_tex,
                       positions, faces, normals, uv, transform,
                       reuse_mat_idx::Union{Nothing, UInt32})
    has_embedded = haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
    if !has_embedded
        return push_to_scene_simple(mesh_val.mesh, hikari_scene, plot, color_tex, transform,
                                     reuse_mat_idx)
    end

    user_material = haskey(plot, :material) && !isnothing(to_value(plot.material)) ?
        to_value(plot.material) : nothing

    inner = mesh_val.mesh
    views = inner.views
    mat_names = mesh_val[:material_names]
    materials_dict = mesh_val[:materials]
    gb_faces = GeometryBasics.faces(inner)
    n_faces = length(gb_faces)

    per_face_materials = Vector{Hikari.Material}(undef, n_faces)
    mat_cache = Dict{String, Hikari.Material}()
    for (view_range, name) in zip(views, mat_names)
        mat = get!(mat_cache, name) do
            if haskey(materials_dict, name)
                mat_entry = materials_dict[name]
                if mat_entry isa Hikari.Material
                    mat_entry
                elseif !isnothing(user_material)
                    tex = extract_glb_diffuse_texture(mat_entry)
                    merge_color_with_material(tex, user_material)
                else
                    result = glb_material_to_hikari(mat_entry)
                    m = result.material
                    if !isnothing(result.emission)
                        m = Hikari.MediumInterface(m; emission=result.emission)
                    end
                    m
                end
            else
                extract_material(plot, color_tex)
            end
        end
        for fi in view_range
            per_face_materials[fi] = mat
        end
    end

    handle = push!(hikari_scene, inner, per_face_materials; transform=transform)
    return (handle=handle, instance_idx=Raycore.n_instances(hikari_scene.accel))
end

# Plain mesh: single material
function push_to_scene(mesh_val, hikari_scene, plot, color_tex,
                       positions, faces, normals_arg, uv, transform,
                       reuse_mat_idx::Union{Nothing, UInt32})
    push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform,
                          reuse_mat_idx;
                          positions=positions, faces=faces, normals=normals_arg, uv=uv)
end

# Internal: build GB.Mesh from decomposed data and push with single material.
# When `reuse_mat_idx` is given, the pre-existing material slot is refreshed
# via `Hikari.update_material!` and the mesh is pushed with that same idx,
# keeping `scene.materials` / `scene.media_interfaces` a fixed size across
# rebuilds.  `update_material!` reuses the GPU texture buffer through the
# `Raycore.update_item` / `Raycore.copyto_texture!` dispatch chain.
function push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform,
                               reuse_mat_idx::Union{Nothing, UInt32};
                               positions=nothing, faces=nothing, normals=nothing, uv=nothing)
    gb_mesh = if mesh_val isa GeometryBasics.Mesh
        mesh_val
    else
        kwargs = Dict{Symbol, Any}()
        !isnothing(normals) && (kwargs[:normal] = Vec3f.(normals))
        !isnothing(uv) && (kwargs[:uv] = Vec2f.(uv))
        m = GeometryBasics.Mesh(Point3f.(positions), faces; kwargs...)
        isnothing(normals) ? GeometryBasics.normal_mesh(m) : m
    end

    if color_tex isa AbstractVector{<:Colorant}
        color_tex = build_vertex_color_texture(color_tex, gb_mesh)
    end

    mat = extract_material(plot, color_tex)
    handle = if reuse_mat_idx === nothing
        push!(hikari_scene, gb_mesh, mat; transform=transform)
    else
        Hikari.update_material!(hikari_scene, reuse_mat_idx, mat)
        push!(hikari_scene, gb_mesh, reuse_mat_idx, mat; transform=transform)
    end
    state_instance_idx = Raycore.n_instances(hikari_scene.accel)
    return (handle=handle, mat_idx=handle.interface, material=mat, instance_idx=state_instance_idx)
end

# =============================================================================
# Handle management
# =============================================================================

function delete_trace_handles!(hikari_scene, robj)
    tlas = hikari_scene.accel
    if hasproperty(robj, :handles)
        for h in robj.handles
            actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
            delete!(tlas, actual_handle)
        end
    elseif hasproperty(robj, :handle)
        h = robj.handle
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        delete!(tlas, actual_handle)
    end
end

function update_trace_transform!(hikari_scene, state, robj, transform)
    tlas = hikari_scene.accel

    # `update_transform!(accel, handle, transform)` for BOTH shapes. The single
    # -handle branch used to take the index-based
    # `update_instance_transforms!(tlas, transforms, 1, idx)`, which only
    # `Raycore.TLAS` implements — `Mantle.HWTLAS` is batch/handle-addressed and has
    # no such method. So under `hw_accel = true` (the default) moving a `mesh!`
    # threw a MethodError that `poll_all_plots` logged and swallowed, and the
    # transform silently never applied. The multi-handle branch was already on
    # the handle API and worked, which is why meshscatter moved and mesh did not.
    #
    # A single mesh is a batch of one, and `update_transform!` sets every
    # instance in the batch, so this is the same operation without the
    # per-update `allocate` + `fill!` the index path needed.
    handles = hasproperty(robj, :handles) ? robj.handles : (robj.handle,)
    for h in handles
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        Raycore.update_transform!(tlas, actual_handle, transform)
    end
    state.needs_film_clear = true
end

# =============================================================================
# 2D mesh overlay color extraction (fallback when plot.color is unrecognized)
# =============================================================================

function mesh_overlay_color(plot, color_tex)
    c = to_value(plot.color)
    # White is the documented fallback for a colour Makie cannot convert, and
    # that is a legitimate outcome — but it is also what a genuinely broken
    # colour looks like, so it says which one happened rather than rendering
    # white and leaving the user to guess.
    try
        return RGBA{Float32}(Makie.to_color(c))
    catch e
        @warn "RayMakie: could not convert $(typeof(c)) to a colour; the 2D overlay will be white" exception = (e, catch_backtrace()) maxlog = 1
        return RGBA{Float32}(1f0, 1f0, 1f0, 1f0)
    end
end
