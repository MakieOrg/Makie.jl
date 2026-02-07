# =============================================================================
# draw_atomic for Makie.Surface
# =============================================================================

function _build_surface_mesh(x, y, z, plot)
    function grid(x, y, z, trans)
        space = to_value(get(plot, :space, :data))
        g = map(CartesianIndices(z)) do i
            p = Point3f(Makie.get_dim(x, i, 1, size(z)), Makie.get_dim(y, i, 2, size(z)), z[i])
            return Makie.apply_transform(trans, p, space)
        end
        return vec(g)
    end

    trans = Makie.transform_func_obs(plot)[]
    positions = grid(x, y, z, trans)
    r = Tesselation(Rect2f((0, 0), (1, 1)), size(z))
    faces = decompose(GLTriangleFace, r)
    uv = decompose_uv(r)
    mesh = normal_mesh(GeometryBasics.Mesh(positions, faces, uv=uv))
    return Raycore.TriangleMesh(mesh)
end

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Surface)
    attr = plot.attributes
    hikari_scene = screen.state.hikari_scene
    state = screen.state

    # 1. Grid data → surface mesh (independent of color)
    register_computation!(attr, [:x, :y, :z], [:trace_surface_mesh]) do args, changed, last
        return (_build_surface_mesh(args.x, args.y, args.z, plot),)
    end

    # 2. Color → Hikari texture (independent of mesh geometry)
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 3. TLAS management: combine mesh, color, model
    register_computation!(attr, [:trace_surface_mesh, :trace_color_tex, :model], [:trace_renderobject]) do args, changed, last
        tmesh = args.trace_surface_mesh
        color_tex = args.trace_color_tex

        if isnothing(last) || isnothing(last.trace_renderobject)
            # First run: extract material, push to scene
            mat = extract_material(plot, color_tex)
            mat_idx = push!(hikari_scene, mat)
            # Surface uses identity transform (coordinates already in world space after transform_func)
            handle = push!(hikari_scene.accel, tmesh, mat_idx, Mat4f(I))
            state.needs_film_clear = true
            return ((handle=handle, mat_idx=mat_idx, material=mat, instance_idx=length(hikari_scene.accel.instances)),)
        end

        robj = last.trace_renderobject

        if changed.trace_surface_mesh
            # Grid changed → full rebuild
            delete!(hikari_scene.accel, robj.handle)
            mat = extract_material(plot, color_tex)
            mat_idx = push!(hikari_scene, mat)
            handle = push!(hikari_scene.accel, tmesh, mat_idx, Mat4f(I))
            state.needs_film_clear = true
            return ((handle=handle, mat_idx=mat_idx, material=mat, instance_idx=length(hikari_scene.accel.instances)),)
        end

        if changed.trace_color_tex
            # Color changed → update material texture in-place
            tex = _get_material_texture(robj.material)
            if !isnothing(tex)
                computed = Makie.compute_colors(plot.attributes)
                _update_texture!(tex, computed)
            end
            state.needs_film_clear = true
        end

        return (robj,)
    end
end
