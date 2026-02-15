# =============================================================================
# draw_atomic for Makie.Mesh
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Mesh → processed mesh data
    # Use positions_transformed_f32c (which has model+f32c applied as needed) + decomposed
    # topology from the mesh. For MetaMesh (defensive, normally split by recipe), use raw mesh.
    register_computation!(attr, [:mesh, :positions_transformed_f32c, :faces, :normals, :texturecoordinates], [:trace_mesh_data]) do args, changed, last
        mesh_val = args.mesh
        if mesh_val isa GeometryBasics.MetaMesh
            return (_process_metamesh(mesh_val),)
        else
            return (_build_mesh_from_decomposed(
                args.positions_transformed_f32c, args.faces,
                args.normals, args.texturecoordinates),)
        end
    end

    # 2. Color → Hikari texture (independent of mesh geometry)
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 3. TLAS management: combine mesh data, color texture, model_f32c transform
    # model_f32c is identity when model was baked into positions, otherwise the full model.
    register_computation!(attr, [:trace_mesh_data, :trace_color_tex, :model_f32c], [:trace_renderobject]) do args, changed, last
        mesh_data = args.trace_mesh_data
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

        if isnothing(last) || isnothing(last.trace_renderobject)
            # First run: create and push to scene
            return (_mesh_push!(hikari_scene, state, plot, mesh_data, color_tex, transform),)
        end

        robj = last.trace_renderobject

        if changed.trace_mesh_data
            # Mesh geometry changed — full rebuild
            _mesh_delete_handles!(hikari_scene, robj)
            return (_mesh_push!(hikari_scene, state, plot, mesh_data, color_tex, transform),)
        end

        if changed.trace_color_tex
            # Color changed → update material textures in-place
            if hasproperty(robj, :material)
                tex = _get_material_texture(robj.material)
                if !isnothing(tex)
                    computed = Makie.compute_colors(plot.attributes)
                    _update_texture!(tex, computed)
                end
            end
            state.needs_film_clear = true
        end

        if changed.model_f32c
            _mesh_update_transform!(hikari_scene, state, robj, transform)
        end

        return (robj,)
    end
end

# --- Internal helpers ---

# Build a TriangleMesh from decomposed arrays (pre-transformed positions + original topology)
function _build_mesh_from_decomposed(positions, faces, normals, texturecoordinates)
    kwargs = Dict{Symbol, Any}()
    if !isnothing(normals)
        kwargs[:normal] = Vec3f.(normals)
    end
    if !isnothing(texturecoordinates)
        kwargs[:uv] = Vec2f.(texturecoordinates)
    end
    mesh = GeometryBasics.Mesh(Point3f.(positions), faces; kwargs...)
    if isnothing(normals)
        mesh = GeometryBasics.normal_mesh(mesh)
    end
    return Raycore.TriangleMesh(mesh)
end

# Process MetaMesh into a single TriangleMesh with per-face material name mapping.
# Uses the MetaMesh's view ranges directly (no split_mesh) to build per-face
# material assignment. Actual scene material indices are set in _mesh_push_metamesh!.
function _process_metamesh(mesh_val::GeometryBasics.MetaMesh)
    if haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
        inner_mesh = mesh_val.mesh
        views = inner_mesh.views
        mat_names = mesh_val[:material_names]

        # Build per-face material name vector from view ranges (no split_mesh!)
        n_faces = length(GeometryBasics.faces(inner_mesh))
        per_face_mat_names = Vector{String}(undef, n_faces)
        for (view_range, name) in zip(views, mat_names)
            per_face_mat_names[view_range] .= name
        end

        # Convert the already-merged inner mesh directly to TriangleMesh
        tmesh = Raycore.TriangleMesh(inner_mesh)

        return (
            tmesh=tmesh,
            per_face_mat_names=per_face_mat_names,
            materials_dict=mesh_val[:materials],
            is_metamesh=true,
        )
    else
        return Raycore.TriangleMesh(mesh_val.mesh)
    end
end

# Push mesh(es) to scene, creating materials
function _mesh_push!(hikari_scene, state, plot, mesh_data, color_tex, transform)
    if mesh_data isa NamedTuple && hasproperty(mesh_data, :is_metamesh)
        return _mesh_push_metamesh!(hikari_scene, state, plot, mesh_data, color_tex, transform)
    else
        return _mesh_push_single!(hikari_scene, state, plot, mesh_data, color_tex, transform)
    end
end

function _mesh_push_single!(hikari_scene, state, plot, tmesh, color_tex, transform)
    # Convert per-vertex color vectors to VertexColorTexture using mesh topology
    if color_tex isa AbstractVector{<:Colorant}
        color_tex = build_vertex_color_texture(color_tex, tmesh)
    end
    mat = extract_material(plot, color_tex)
    mat_idx = push!(hikari_scene, mat)
    handle = push!(hikari_scene.accel, tmesh, mat_idx, transform)
    state.needs_film_clear = true
    return (handle=handle, mat_idx=mat_idx, material=mat, instance_idx=length(hikari_scene.accel.instances))
end

function _mesh_push_metamesh!(hikari_scene, state, plot, mesh_data, color_tex, transform)
    # 1. Create materials for each unique name and get scene indices
    unique_names = unique(mesh_data.per_face_mat_names)
    name_to_idx = Dict{String, UInt32}()
    materials = Hikari.Material[]
    default_mat = nothing

    for name in unique_names
        mat = if haskey(mesh_data.materials_dict, name)
            glb_material_to_hikari(mesh_data.materials_dict[name])
        else
            if isnothing(default_mat)
                default_mat = extract_material(plot, color_tex)
            end
            default_mat
        end
        mat_idx = push!(hikari_scene, mat)
        name_to_idx[name] = mat_idx
        push!(materials, mat)
    end

    # 2. Build per-face material index vector (UInt32 scene indices)
    material_indices = UInt32[name_to_idx[name] for name in mesh_data.per_face_mat_names]

    # 3. Create TriangleMesh with per-face material indices baked in
    tmesh = mesh_data.tmesh
    tmesh_with_mats = Raycore.TriangleMesh(
        tmesh.vertices, tmesh.indices, tmesh.normals,
        tmesh.tangents, tmesh.uv, material_indices
    )

    # 4. Push single mesh — push! reads material_indices per-face
    handle = push!(hikari_scene.accel, tmesh_with_mats, first(values(name_to_idx)), transform)

    state.needs_film_clear = true
    return (handle=handle, materials=materials, instance_idx=length(hikari_scene.accel.instances))
end

function _mesh_delete_handles!(hikari_scene, robj)
    tlas = hikari_scene.accel
    if hasproperty(robj, :handles)
        for h in robj.handles
            delete!(tlas, h)
        end
    elseif hasproperty(robj, :handle)
        delete!(tlas, robj.handle)
    end
end

function _mesh_update_transform!(hikari_scene, state, robj, transform)
    tlas = hikari_scene.accel
    backend = tlas.backend

    if hasproperty(robj, :handles)
        for idx in robj.instance_indices
            t = KernelAbstractions.allocate(backend, Mat4f, 1)
            fill!(t, transform)
            Raycore.update_instance_transforms!(tlas, t, 1, idx)
        end
    else
        transforms = KernelAbstractions.allocate(backend, Mat4f, 1)
        fill!(transforms, transform)
        Raycore.update_instance_transforms!(tlas, transforms, 1, robj.instance_idx)
    end
    state.needs_film_clear = true
end
