# =============================================================================
# draw_atomic for Makie.Mesh
# =============================================================================

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Mesh)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Color → texture
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 2. Everything → push to scene via Hikari
    inputs = [:mesh, :positions_transformed_f32c, :faces, :normals,
              :texturecoordinates, :trace_color_tex, :model_f32c]
    # Include _resolved_materials from MetaMesh recipe if available
    if haskey(attr, :_resolved_materials)
        push!(inputs, :_resolved_materials)
    end

    register_computation!(attr, inputs, [:trace_renderobject]) do args, changed, last
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

        resolved = hasproperty(args, :_resolved_materials) ? args._resolved_materials : nothing

        if isnothing(last) || isnothing(last.trace_renderobject) ||
           changed.mesh || changed.positions_transformed_f32c || changed.faces ||
           changed.normals || changed.texturecoordinates || changed.trace_color_tex
            # Delete old handles if rebuilding
            !isnothing(last) && !isnothing(last.trace_renderobject) &&
                delete_trace_handles!(hikari_scene, last.trace_renderobject)

            robj = push_to_scene(args.mesh, hikari_scene, plot, color_tex,
                                  args.positions_transformed_f32c, args.faces,
                                  args.normals, args.texturecoordinates, transform,
                                  resolved)
            state.needs_film_clear = true
            return (robj,)
        end

        robj = last.trace_renderobject
        if changed.model_f32c
            update_trace_transform!(hikari_scene, state, robj, transform)
        end
        return (robj,)
    end
end

# =============================================================================
# Dispatch-based push_to_scene
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

# Expand resolved materials to per-face vector
function resolved_to_per_face(resolved, n_faces)
    per_face = Vector{Hikari.Material}(undef, n_faces)
    if hasproperty(resolved, :per_face) && resolved.per_face
        # Per-face indices + palette
        indices = resolved.indices
        palette = resolved.palette
        for fi in 1:n_faces
            per_face[fi] = palette[indices[fi]]
        end
    elseif hasproperty(resolved, :view_materials)
        # Per-view materials
        for (vr, mat) in zip(resolved.views, resolved.view_materials)
            for fi in vr
                per_face[fi] = mat
            end
        end
    end
    return per_face
end

# MetaMesh: multi-material
function push_to_scene(mesh_val::GeometryBasics.MetaMesh, hikari_scene, plot, color_tex,
                       positions, faces, normals, uv, transform, resolved)
    inner = mesh_val.mesh
    gb_faces = GeometryBasics.faces(inner)
    n_faces = length(gb_faces)

    # Path 1: Per-face or per-view resolved materials (from Makie recipe)
    if !isnothing(resolved) && (
        (hasproperty(resolved, :per_face) && resolved.per_face) ||
        hasproperty(resolved, :view_materials))
        per_face_materials = resolved_to_per_face(resolved, n_faces)
        handle = push!(hikari_scene, inner, per_face_materials; transform=transform)
        return (handle=handle, instance_idx=length(hikari_scene.accel.instances))
    end

    # Path 2: Legacy GLTF (resolved from recipe or directly from MetaMesh)
    has_legacy = !isnothing(resolved) && hasproperty(resolved, :legacy_gltf) && resolved.legacy_gltf
    if !has_legacy
        has_legacy = haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
    end

    if !has_legacy
        return push_to_scene_simple(inner, hikari_scene, plot, color_tex, transform)
    end

    # Check if user explicitly provided a material template
    user_material = haskey(plot, :material) && !isnothing(to_value(plot.material)) ?
        to_value(plot.material) : nothing

    views = inner.views
    mat_names = if !isnothing(resolved) && hasproperty(resolved, :legacy_gltf)
        resolved.names
    else
        mesh_val[:material_names]
    end
    materials_dict = if !isnothing(resolved) && hasproperty(resolved, :legacy_gltf)
        resolved.materials
    else
        mesh_val[:materials]
    end

    # Resolve per-face materials
    per_face_materials = Vector{Hikari.Material}(undef, n_faces)
    mat_cache = Dict{String, Hikari.Material}()
    for (view_range, name) in zip(views, mat_names)
        mat = get!(mat_cache, name) do
            if haskey(materials_dict, name)
                mat_entry = materials_dict[name]
                if mat_entry isa Hikari.Material
                    # Direct Hikari material (e.g. from user-constructed MetaMesh)
                    mat_entry
                elseif !isnothing(user_material)
                    # Merge GLTF diffuse texture into user's material type
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
    return (handle=handle, instance_idx=length(hikari_scene.accel.instances))
end

# Plain mesh: single material
function push_to_scene(mesh_val, hikari_scene, plot, color_tex,
                       positions, faces, normals_arg, uv, transform, resolved)
    push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform;
                          positions=positions, faces=faces, normals=normals_arg, uv=uv)
end

# Internal: build GB.Mesh from decomposed data and push with single material
function push_to_scene_simple(mesh_val, hikari_scene, plot, color_tex, transform;
                               positions=nothing, faces=nothing, normals=nothing, uv=nothing)
    # If mesh_val is already a GB.Mesh, use it directly; otherwise build from decomposed
    gb_mesh = if mesh_val isa GeometryBasics.Mesh
        mesh_val
    else
        # Build from decomposed arrays
        kwargs = Dict{Symbol, Any}()
        !isnothing(normals) && (kwargs[:normal] = Vec3f.(normals))
        !isnothing(uv) && (kwargs[:uv] = Vec2f.(uv))
        m = GeometryBasics.Mesh(Point3f.(positions), faces; kwargs...)
        isnothing(normals) ? GeometryBasics.normal_mesh(m) : m
    end

    # Convert per-vertex colors to VertexColorTexture
    if color_tex isa AbstractVector{<:Colorant}
        color_tex = build_vertex_color_texture(color_tex, gb_mesh)
    end

    mat = extract_material(plot, color_tex)
    handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
    state_instance_idx = length(hikari_scene.accel.instances)
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
        # SceneHandle wraps a TLASHandle in .geometry
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        delete!(tlas, actual_handle)
    end
end

function update_trace_transform!(hikari_scene, state, robj, transform)
    tlas = hikari_scene.accel
    backend = tlas.backend

    if hasproperty(robj, :handles)
        for h in robj.handles
            actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
            Raycore.update_transform!(tlas, actual_handle, transform)
        end
    else
        h = robj.handle
        actual_handle = h isa Hikari.SceneHandle ? h.geometry : h
        idx = robj.instance_idx
        transforms = KernelAbstractions.allocate(backend, Mat4f, 1)
        fill!(transforms, transform)
        Raycore.update_instance_transforms!(tlas, transforms, 1, idx)
    end
    state.needs_film_clear = true
end
