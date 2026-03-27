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

    # 2. Everything → push to scene via Hikari (or overlay for 2D in overlay-only mode)
    register_computation!(attr, [:mesh, :positions_transformed_f32c, :faces, :normals,
                                  :texturecoordinates, :trace_color_tex, :model_f32c],
                          [:trace_renderobject]) do args, changed, last
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

        # Render as overlay if the scene/plot shouldn't be raytraced (2D cameras, 2D meshes)
        if !should_raytrace(scene, plot) || isnothing(hikari_scene)
            positions_3f = Vec3f[Makie.to_ndim(Point3f, p, 0f0) for p in args.positions_transformed_f32c]
            faces_val = args.faces
            pv = Mat4f(scene.camera.projectionview[])
            model_mat = Mat4f(args.model_f32c)

            # Flatten indexed mesh to per-vertex for non-indexed draw
            flat_positions = Vec3f[positions_3f[f[j]] for f in faces_val for j in 1:3]

            # Resolve per-vertex colors
            raw_color = to_value(plot.color)
            n_verts = length(positions_3f)
            n_faces = length(faces_val)
            flat_colors = if raw_color isa AbstractVector{<:Colorant}
                if length(raw_color) == n_verts
                    # Per-vertex colors — index by vertex
                    Vec4f[let c = RGBA{Float32}(raw_color[f[j]])
                        Vec4f(c.r, c.g, c.b, c.alpha)
                    end for f in faces_val for j in 1:3]
                else
                    # Per-face/per-group colors — distribute across faces
                    nc = length(raw_color)
                    faces_per_color = max(1, n_faces ÷ nc)
                    Vec4f[let ci = min(div(fi - 1, faces_per_color) + 1, nc)
                        c = RGBA{Float32}(raw_color[ci])
                        Vec4f(c.r, c.g, c.b, c.alpha)
                    end for (fi, f) in enumerate(faces_val) for j in 1:3]
                end
            elseif raw_color isa Colorant
                c = RGBA{Float32}(raw_color)
                fill(Vec4f(c.r, c.g, c.b, c.alpha), length(flat_positions))
            else
                # Fallback: try mesh_overlay_color
                c = mesh_overlay_color(plot, color_tex)
                fill(Vec4f(c.r, c.g, c.b, c.alpha), length(flat_positions))
            end

            if !isnothing(last) && last.trace_renderobject isa LavaRenderObject
                robj = last.trace_renderobject
                update_buffer!(robj, :positions, flat_positions)
                update_buffer!(robj, :colors, flat_colors)
                robj.uniforms[:projectionview] = pv
                robj.uniforms[:model] = model_mat
                robj.vertex_count = length(flat_positions)
                robj.visible = true
                return (robj,)
            end

            pipeline = get_mesh_pipeline!(screen)
            robj = LavaRenderObject(pipeline;
                arg_names = (:positions, :colors, :projectionview, :model),
                buffers = Dict{Symbol, Lava.LavaArray}(
                    :positions => Lava.LavaArray(flat_positions),
                    :colors => Lava.LavaArray(flat_colors),
                ),
                uniforms = Dict{Symbol, Any}(
                    :projectionview => pv,
                    :model => model_mat,
                ),
                vertex_count = length(flat_positions),
                instances = 1,
            )
            return (robj,)
        end

        if isnothing(last) || isnothing(last.trace_renderobject) ||
           changed.mesh || changed.positions_transformed_f32c || changed.faces ||
           changed.normals || changed.texturecoordinates || changed.trace_color_tex
            # Delete old handles if rebuilding
            !isnothing(last) && !isnothing(last.trace_renderobject) &&
                delete_trace_handles!(hikari_scene, last.trace_renderobject)

            robj = push_to_scene(args.mesh, hikari_scene, plot, color_tex,
                                  args.positions_transformed_f32c, args.faces,
                                  args.normals, args.texturecoordinates, transform)
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

# MetaMesh: multi-material
function push_to_scene(mesh_val::GeometryBasics.MetaMesh, hikari_scene, plot, color_tex,
                       positions, faces, normals, uv, transform)
    has_embedded = haskey(mesh_val, :material_names) && haskey(mesh_val, :materials)
    if !has_embedded
        return push_to_scene_simple(mesh_val.mesh, hikari_scene, plot, color_tex, transform)
    end

    # Check if user explicitly provided a material template
    user_material = haskey(plot, :material) && !isnothing(to_value(plot.material)) ?
        to_value(plot.material) : nothing

    inner = mesh_val.mesh
    views = inner.views
    mat_names = mesh_val[:material_names]
    materials_dict = mesh_val[:materials]
    gb_faces = GeometryBasics.faces(inner)
    n_faces = length(gb_faces)

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
                       positions, faces, normals_arg, uv, transform)
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

# =============================================================================
# 2D mesh overlay color extraction
# =============================================================================

function mesh_overlay_color(plot, color_tex)
    c = to_value(plot.color)
    try
        return RGBA{Float32}(Makie.to_color(c))
    catch
        return RGBA{Float32}(1f0, 1f0, 1f0, 1f0)
    end
end
