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

    # Makie's surface as a mesh: the transformed grid (transform_func + model +
    # f32c) and the faces, UVs and normals of its triangulation, as WGLMakie
    # draws it. The raster path hands exactly these to the mesh shader. No
    # `scene` argument: this method takes the attributes alone, and passing a
    # scene picked no method at all.
    Makie.add_computation!(attr, Val(:surface_as_mesh))

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

    # Which renderer draws it. The mode is one of the nodes' INPUTS, as for
    # `mesh!`: `setrasterize!` drops both render objects and this input, and the
    # nodes rebuild down the other path. Reading the screen's config instead made
    # the switch invisible to a surface, which stayed traced. Two slots rather
    # than one holding either kind, because a compute node's slot takes its type
    # from the first value it holds; see `plots/mesh.jl`.
    #
    # RASTER also for a scene that is not traced: `surface!` into a 2D `Axis`, or
    # any surface whose scene has no 3D camera (`surface(fill(3f0, 20, 20))` gets
    # an `EmptyCamera`). Tracing those pushed into a `hikari_scene` that is
    # `nothing`, and the compute graph reported "this plot will not be drawn".
    haskey(attr, :rasterize) || add_input!(attr, :rasterize, screen.rasterize)

    # 3. HWTLAS management: combine mesh, color, model_f32c
    register_computation!(attr, [:trace_surface_mesh, :trace_color_tex, :model_f32c, :rasterize],
                          [:trace_renderobject]) do args, changed, last
        (args.rasterize || !should_raytrace(scene, plot) || isnothing(hikari_scene)) &&
            return (nothing,)
        gb_mesh = args.trace_surface_mesh
        color_tex = args.trace_color_tex
        transform = Mat4f(args.model_f32c)

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

    # RASTER: the mesh shader, as for `mesh!`. What a surface lacks of its
    # inputs: the stroke's edge data for the `surface_as_mesh` triangles (Makie
    # packs per triangle from those in `register_stroke_data!`), a uv transform,
    # and the vertex-colour flag, which a grid colour never reads.
    Makie.register_surface_stroke!(attr)
    haskey(attr, :pattern_uv_transform) || Makie.add_computation!(attr, scene, Val(:pattern_uv_transform))
    haskey(attr, :raster_uv_transform) ||
        map!(surface_uv_transform, attr, [:pattern_uv_transform, :z, :fetch_pixel], :raster_uv_transform)
    Makie.ComputePipeline.add_constant!(attr, :interpolate_in_fragment_shader, true)
    register_raster_renderobject!(screen, scene, plot)
end

# The surface's uv transform composed with the shift that puts each vertex on the
# CENTRE of its texel, as WGLMakie does and GLMakie's surface.vert computes: the
# triangulation's UVs run 0..1 over the grid, so without it a colour matrix of the
# grid's size is stretched by half a texel at every edge. A pattern is sampled in
# screen space and keeps its transform as it is.
function surface_uv_transform(uvt, z, is_pattern)
    is_pattern && return Makie.uv_transform(uvt)
    s = Vec2f(size(z))
    return Makie.uv_transform(uvt) * Makie.uv_transform(0.5f0 ./ s, (s .- 1f0) ./ s)
end
