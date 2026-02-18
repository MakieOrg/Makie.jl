# =============================================================================
# draw_atomic for Makie.Surface
# =============================================================================

function build_surface_mesh(positions::AbstractMatrix{<:Point3f})
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(positions))
    faces = decompose(GLTriangleFace, r)
    # Tessellation UV has u=row_idx, v=col_idx, but Hikari's texture sampling
    # maps (u,v) → data[1+(M-1)*(1-v), 1+(N-1)*u]. To get data[i,j] for
    # vertex at grid position (i,j), we need u=(j-1)/(N-1) and v=(M-i)/(M-1),
    # i.e. swap and flip: (u_old, v_old) → (v_old, 1-u_old).
    uv = map(u -> Vec2f(1f0-u[2], 1f0 - u[1]), decompose_uv(r))
    return normal_mesh(GeometryBasics.Mesh(vec(positions), faces, uv=uv))
end

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Surface)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # Register Makie's surface position pipeline (transform_func + model + f32c)
    Makie.add_computation!(attr, scene, Val(:surface_transform))

    # 1. Pre-transformed positions → surface mesh (GB.Mesh)
    register_computation!(attr, [:positions_transformed_f32c], [:trace_surface_mesh]) do args, changed, last
        return (build_surface_mesh(args.positions_transformed_f32c),)
    end

    # 2. Color → Hikari texture (independent of mesh geometry)
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 3. TLAS management: combine mesh, color, model_f32c
    register_computation!(attr, [:trace_surface_mesh, :trace_color_tex, :model_f32c], [:trace_renderobject]) do args, changed, last
        gb_mesh = args.trace_surface_mesh
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

        if isnothing(last) || isnothing(last.trace_renderobject)
            mat = extract_material(plot, color_tex)
            handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
            state.needs_film_clear = true
            return ((handle=handle, material=mat, instance_idx=length(hikari_scene.accel.instances)),)
        end

        robj = last.trace_renderobject

        if changed.trace_surface_mesh
            delete_trace_handles!(hikari_scene, robj)
            mat = extract_material(plot, color_tex)
            handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
            state.needs_film_clear = true
            return ((handle=handle, material=mat, instance_idx=length(hikari_scene.accel.instances)),)
        end

        if changed.trace_color_tex
            tex = get_material_texture(robj.material)
            if !isnothing(tex)
                computed = Makie.compute_colors(plot.attributes)
                update_texture!(tex, computed)
            end
            state.needs_film_clear = true
        end

        if changed.model_f32c
            update_trace_transform!(hikari_scene, state, robj, transform)
        end

        return (robj,)
    end
end
