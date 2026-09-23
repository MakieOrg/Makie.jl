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

    # Register Makie's surface position pipeline (transform_func + model + f32c).
    # No `scene` argument: `add_computation!(attr, ::Val{:surface_transform})`
    # takes the attributes alone, and passing a scene picked no method at all —
    # so every `surface!` in a RayMakie scene died with a MethodError.
    Makie.add_computation!(attr, Val(:surface_transform))

    # 1. Pre-transformed positions → surface mesh (GB.Mesh).
    #
    # `:z` is an input because `positions_transformed_f32c` is a FLAT vector and
    # carries no grid shape — Makie's own `add_computation!(::Val{:surface_as_mesh})`
    # reshapes it the same way, via `surface2mesh(pos, size(z))`. Passing the
    # vector straight through gave `MethodError: no method matching
    # build_surface_mesh(::Vector{Point{3, Float32}})`.
    register_computation!(attr, [:positions_transformed_f32c, :z], [:trace_surface_mesh]) do args, changed, last
        return (build_surface_mesh(reshape(args.positions_transformed_f32c, size(args.z))),)
    end

    # 2. Color → Hikari texture (independent of mesh geometry)
    register_computation!(attr, [:color], [:trace_color_tex]) do args, changed, last
        return (color_to_texture(args.color, plot),)
    end

    # 3. HWTLAS management: combine mesh, color, model_f32c
    register_computation!(attr, [:trace_surface_mesh, :trace_color_tex, :model_f32c], [:trace_renderobject]) do args, changed, last
        gb_mesh = args.trace_surface_mesh
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

        # RASTER first, for a scene that is not ray-traced. `mesh!` has had this
        # fork since the beginning and `surface!` had only the traced half, so it
        # pushed into a `hikari_scene` that is `nothing` — `MethodError:
        # push!(::Nothing, …)`, which the compute graph reports as "this plot
        # will not be drawn", i.e. a blank axis and no stack trace. Two ordinary
        # calls land here: `surface!` into a 2D `Axis`, and any surface whose
        # scene has no 3D camera — `surface(fill(3f0, 20, 20))` gets an
        # `EmptyCamera`, because a flat one gives `LScene` nothing to fit.
        if !should_raytrace(screen, scene, plot) || isnothing(hikari_scene)
            last_robj = isnothing(last) ? nothing : last.trace_renderobject
            return (surface_overlay_dispatch!(screen, scene, plot, args, last_robj),)
        end

        if isnothing(last) || isnothing(last.trace_renderobject)
            mat = extract_material(plot, color_tex)
            handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
            state.needs_film_clear = true
            return ((handle=handle, material=mat, instance_idx=Raycore.n_instances(hikari_scene.accel)),)
        end

        robj = last.trace_renderobject

        if changed.trace_surface_mesh
            delete_trace_handles!(hikari_scene, robj)
            mat = extract_material(plot, color_tex)
            handle = push!(hikari_scene, gb_mesh, mat; transform=transform)
            state.needs_film_clear = true
            return ((handle=handle, material=mat, instance_idx=Raycore.n_instances(hikari_scene.accel)),)
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


# =============================================================================
# The raster path
# =============================================================================
#
# A surface IS a mesh, so this hands the same flat vertex arrays to the same
# pipeline `mesh!` uses rather than growing a second one. The mesh's vertices
# are `vec(positions)` over the z grid, so a colour array of the grid's shape
# indexes them one for one.

"""Per-vertex RGBA for the raster path, expanded over `faces`."""
function surface_overlay_colors(plot, faces, nverts)
    out = Vector{Vec4f}(undef, 3 * length(faces))
    computed = Makie.compute_colors(plot.attributes)
    if computed isa AbstractArray{<:Colorant} && length(computed) == nverts
        flat = vec(computed)
        @inbounds for (fi, f) in enumerate(faces), j in 1:3
            c = RGBA{Float32}(flat[f[j]])
            out[3 * (fi - 1) + j] = Vec4f(c.r, c.g, c.b, c.alpha)
        end
        return out
    end
    # One colour for the whole surface: either the user set a scalar, or the
    # colormapping produced something this path cannot index per vertex.
    raw = to_value(plot.color)
    c = raw isa Colorant ? RGBA{Float32}(raw) :
        computed isa Colorant ? RGBA{Float32}(computed) : RGBA{Float32}(0.5, 0.5, 0.5, 1)
    fill!(out, Vec4f(c.r, c.g, c.b, c.alpha))
    return out
end

"""Draw a surface with the graphics pipeline, for a scene that is not traced."""
function surface_overlay_dispatch!(screen, scene, plot, args, last_robj)
    gb_mesh = args.trace_surface_mesh
    positions = GeometryBasics.coordinates(gb_mesh)
    faces = GeometryBasics.faces(gb_mesh)

    flat_positions = Vector{Vec3f}(undef, 3 * length(faces))
    @inbounds for (fi, f) in enumerate(faces), j in 1:3
        p = positions[f[j]]
        flat_positions[3 * (fi - 1) + j] = Vec3f(p[1], p[2], p[3])
    end
    flat_colors = surface_overlay_colors(plot, faces, length(positions))

    pv = plot_clip_matrix(plot)
    model_mat = Mat4f(args.model_f32c)
    if last_robj isa RenderObject
        return mesh_overlay_update!(last_robj, flat_positions, flat_colors, pv, model_mat)
    end
    return mesh_overlay_create!(screen, flat_positions, flat_colors, pv, model_mat)
end
