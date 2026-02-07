# =============================================================================
# draw_atomic for Makie.Mesh
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Mesh → processed mesh data (only recomputes when mesh geometry changes)
    register_computation!(attr, [:mesh], [:trace_mesh_data]) do args, changed, last
        mesh_val = args.mesh
        if mesh_val isa GeometryBasics.MetaMesh
            return (_process_metamesh(mesh_val),)
        else
            return (Raycore.TriangleMesh(mesh_val),)
        end
    end

    # 2. Color → Hikari texture (independent of mesh geometry)
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 3. TLAS management: combine mesh data, color texture, model transform
    register_computation!(attr, [:trace_mesh_data, :trace_color_tex, :model], [:trace_renderobject]) do args, changed, last
        mesh_data = args.trace_mesh_data
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model)

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

        if changed.model
            _mesh_update_transform!(hikari_scene, state, robj, transform)
        end

        return (robj,)
    end
end

# --- Internal helpers ---

# Process MetaMesh into submeshes with material info
function _process_metamesh(mesh_val::GeometryBasics.MetaMesh)
    if haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
        submeshes = GeometryBasics.split_mesh(mesh_val.mesh)
        tmeshes = [Raycore.TriangleMesh(sm) for sm in submeshes]
        return (
            tmeshes=tmeshes,
            material_names=mesh_val[:material_names],
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
    mat = extract_material(plot, color_tex)
    mat_idx = push!(hikari_scene, mat)
    handle = push!(hikari_scene.accel, tmesh, mat_idx, transform)
    state.needs_film_clear = true
    return (handle=handle, mat_idx=mat_idx, material=mat, instance_idx=length(hikari_scene.accel.instances))
end

function _mesh_push_metamesh!(hikari_scene, state, plot, mesh_data, color_tex, transform)
    handles = Raycore.TLASHandle[]
    mat_indices = UInt32[]
    materials = Hikari.Material[]
    instance_indices = Int[]

    hikari_materials = Dict{String, Any}()
    default_mat = nothing

    for (name, tmesh) in zip(mesh_data.material_names, mesh_data.tmeshes)
        mat = get!(hikari_materials, name) do
            if haskey(mesh_data.materials_dict, name)
                glb_material_to_hikari(mesh_data.materials_dict[name])
            else
                if isnothing(default_mat)
                    default_mat = extract_material(plot, color_tex)
                end
                default_mat
            end
        end

        mat_idx = push!(hikari_scene, mat)
        handle = push!(hikari_scene.accel, tmesh, mat_idx, transform)
        push!(handles, handle)
        push!(mat_indices, mat_idx)
        push!(materials, mat)
        push!(instance_indices, length(hikari_scene.accel.instances))
    end

    state.needs_film_clear = true
    return (handles=handles, mat_indices=mat_indices, materials=materials, instance_indices=instance_indices)
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
    backend = KernelAbstractions.get_backend(tlas.instances.transform)

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
