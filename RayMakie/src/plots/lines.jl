# =============================================================================
# draw_atomic for Lines and LineSegments — GLMakie-style graphics pipeline
# =============================================================================
# Uses register_computation! to create LavaRenderObject once, update on changes.
# No compute shaders — vertex/geometry/fragment pipeline only.
# Matching GLMakie's plot-primitives.jl data flow exactly.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.lines})
    attr = plot.attributes

    # Reuse Makie's built-in computations (same as GLMakie)
    Makie.add_computation!(attr, :gl_miter_limit)

    # Generate adjacency indices + valid_vertex (CPU, reuse arrays across updates)
    register_computation!(
        attr, [:positions_transformed_f32c], [:trace_gl_indices, :trace_gl_valid_vertex]
    ) do (positions,), changed, cached
        if isnothing(cached)
            indices = UInt32[]
            valid = Float32[]
        else
            indices = empty!(cached.trace_gl_indices)
            valid = cached.trace_gl_valid_vertex
        end
        ps = positions
        lines_generate_indices(ps, indices, valid)
        return (indices, valid)
    end

    # Cumulative screen-space lengths for pattern UV
    register_computation!(
        attr, [:positions_transformed_f32c, :resolution], [:trace_gl_lastlen]
    ) do (positions, resolution), changed, cached
        return (lines_sumlengths(positions, resolution),)
    end

    # Build LavaRenderObject: create once, update buffers on changes
    register_computation!(
        attr,
        [:positions_transformed_f32c, :trace_gl_indices, :trace_gl_valid_vertex,
         :trace_gl_lastlen, :color, :linewidth, :model_f32c,
         :projectionview, :resolution, :gl_miter_limit,
         :linecap, :joinstyle, :linestyle],
        [:trace_renderobject]
    ) do args, changed, cached
        n = length(args.positions_transformed_f32c)
        n < 2 && return (nothing,)
        indices = args.trace_gl_indices
        isempty(indices) && return (nothing,)

        # Uniforms (cheap — always compute)
        pv = Mat4f(args.projectionview)
        model = Mat4f(args.model_f32c)
        res = Vec2f(Float32.(args.resolution)...)
        ml_angle = Float32(args.gl_miter_limit)
        ml = Float32(cos(Float64(pi) - Float64(ml_angle)))
        js = to_value(args.joinstyle)
        lc = to_value(args.linecap)
        joinstyle_i = js === :miter ? Int32(0) : js === :bevel ? Int32(3) : js === :round ? Int32(2) : Int32(0)
        linecap_i = if lc isa Tuple
            lc[1] === :butt ? Int32(0) : lc[1] === :square ? Int32(1) : lc[1] === :round ? Int32(2) : Int32(0)
        else
            lc === :butt ? Int32(0) : lc === :square ? Int32(1) : lc === :round ? Int32(2) : Int32(0)
        end
        linestyle = to_value(args.linestyle)
        pat_length = 0f0

        if !isnothing(cached) && cached.trace_renderobject isa LavaRenderObject
            robj = cached.trace_renderobject
            # Only re-upload buffers when data inputs changed (not just camera)
            data_changed = changed.positions_transformed_f32c ||
                           changed.trace_gl_indices || changed.trace_gl_valid_vertex ||
                           changed.trace_gl_lastlen || changed.color || changed.linewidth
            if data_changed
                vertex_data = Vec3f[Makie.to_ndim(Point3f, p, 0f0) for p in args.positions_transformed_f32c]
                color_data = lines_resolve_colors(plot, n)
                thickness_data = lines_resolve_thickness(plot, n)
                valid_data = Float32.(args.trace_gl_valid_vertex)
                lastlen_data = Float32.(args.trace_gl_lastlen)
                update_buffer!(robj, :vertex, vertex_data)
                update_buffer!(robj, :color, color_data)
                update_buffer!(robj, :lastlen, lastlen_data)
                update_buffer!(robj, :valid_vertex, valid_data)
                update_buffer!(robj, :thickness, thickness_data)
                robj.buffers[:indices] = Lava.alloc_index_buffer(UInt32.(indices))
                robj.vertex_count = length(indices)
            end
            # Always update uniforms (cheap)
            robj.uniforms[:projectionview] = pv
            robj.uniforms[:model] = model
            robj.uniforms[:resolution] = res
            robj.uniforms[:linecap] = linecap_i
            robj.uniforms[:joinstyle] = joinstyle_i
            robj.uniforms[:miter_limit] = ml
            robj.uniforms[:pattern_length] = pat_length
            robj.visible = true
            if changed.linestyle && linestyle !== nothing
                ls = linestyle isa AbstractVector ? linestyle : Makie.to_linestyle(linestyle)
                sdf_data = Float32.(Makie.linestyle_to_sdf(ls))
                pat_length = Float32(last(ls) - first(ls))
                robj.uniforms[:pattern_length] = pat_length
                sdf_2d = reshape(sdf_data, 1, length(sdf_data))
                update_texture!(robj, sdf_2d; filter=:linear, wrap=:repeat)
            end
            return (robj,)
        end

        # FIRST TIME — compute all per-vertex arrays
        positions = args.positions_transformed_f32c
        valid = args.trace_gl_valid_vertex
        lastlen = args.trace_gl_lastlen
        vertex_data = Vec3f[Makie.to_ndim(Point3f, p, 0f0) for p in positions]
        color_data = lines_resolve_colors(plot, n)
        thickness_data = lines_resolve_thickness(plot, n)
        valid_data = Float32.(valid)
        lastlen_data = Float32.(lastlen)

        # CREATE new render object
        pipeline = get_lines_pipeline!(screen)
        robj = LavaRenderObject(pipeline;
            arg_names = (:vertex, :color, :lastlen, :valid_vertex, :thickness,
                         :projectionview, :model, :px_per_unit, :depth_shift,
                         :resolution, :scene_origin, :linecap, :joinstyle, :miter_limit, :pattern_length),
            buffers = Dict{Symbol, Lava.LavaArray}(
                :vertex => Lava.LavaArray(vertex_data),
                :color => Lava.LavaArray(color_data),
                :lastlen => Lava.LavaArray(lastlen_data),
                :valid_vertex => Lava.LavaArray(valid_data),
                :thickness => Lava.LavaArray(thickness_data),
                :indices => Lava.alloc_index_buffer(UInt32.(indices)),
            ),
            uniforms = Dict{Symbol, Any}(
                :projectionview => pv,
                :model => model,
                :px_per_unit => 1f0,
                :depth_shift => 0f0,
                :resolution => res,
                :scene_origin => Vec2f(0f0, 0f0),
                :linecap => linecap_i,
                :joinstyle => joinstyle_i,
                :miter_limit => ml,
                :pattern_length => pat_length,
            ),
            vertex_count = length(indices),
            instances = 1,
        )

        # Pattern texture (or dummy)
        if linestyle !== nothing
            ls = linestyle isa AbstractVector ? linestyle : Makie.to_linestyle(linestyle)
            sdf_data = Float32.(Makie.linestyle_to_sdf(ls))
            pat_length = Float32(last(ls) - first(ls))
            robj.uniforms[:pattern_length] = pat_length
            sdf_2d = reshape(sdf_data, 1, length(sdf_data))
            update_texture!(robj, sdf_2d; filter=:linear, wrap=:repeat)
        else
            # Dummy texture — fragment shader always references binding 0
            update_texture!(robj, reshape(Float32[-1], 1, 1); filter=:linear, wrap=:repeat)
        end

        return (robj,)
    end
end

# LineSegments: same pipeline but simpler — no joints, GL_LINES topology
# TODO: implement line_segment.vert/geom matching GLMakie exactly
# For now, reuse Lines pipeline by generating adjacency indices from pairs
function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.linesegments})
    attr = plot.attributes

    # Generate pair-wise adjacency indices for segments (each pair becomes a 4-vertex adjacency primitive)
    register_computation!(
        attr, [:positions_transformed_f32c], [:trace_gl_indices, :trace_gl_valid_vertex]
    ) do (positions,), changed, cached
        n = length(positions)
        n_segs = n ÷ 2
        # For line segments, generate adjacency: prev=p1, p1, p2, next=p2
        indices = UInt32[]
        valid = fill(1f0, n)
        sizehint!(indices, n_segs * 4)
        for s in 0:(n_segs-1)
            i1 = s * 2      # 0-based
            i2 = s * 2 + 1  # 0-based
            push!(indices, UInt32(i1), UInt32(i1), UInt32(i2), UInt32(i2))
        end
        return (indices, valid)
    end

    # No cumulative lengths needed for segments (each resets)
    register_computation!(
        attr, [:positions_transformed_f32c], [:trace_gl_lastlen]
    ) do (positions,), changed, cached
        return (zeros(Float32, length(positions)),)
    end

    # Build LavaRenderObject (same pattern as Lines)
    register_computation!(
        attr,
        [:positions_transformed_f32c, :trace_gl_indices, :trace_gl_valid_vertex,
         :trace_gl_lastlen, :color, :linewidth, :model_f32c,
         :projectionview, :resolution, :linecap, :linestyle],
        [:trace_renderobject]
    ) do args, changed, cached
        positions = args.positions_transformed_f32c
        n = length(positions)
        n < 2 && return (nothing,)

        indices = args.trace_gl_indices
        isempty(indices) && return (nothing,)

        vertex_data = Vec3f[Makie.to_ndim(Point3f, p, 0f0) for p in positions]
        color_data = lines_resolve_colors(plot, n)
        thickness_data = lines_resolve_thickness(plot, n)
        valid_data = Float32.(args.trace_gl_valid_vertex)
        lastlen_data = Float32.(args.trace_gl_lastlen)

        pv = Mat4f(args.projectionview)
        model = Mat4f(args.model_f32c)
        res = Vec2f(Float32.(args.resolution)...)

        lc = to_value(args.linecap)
        linecap_i = if lc isa Tuple
            lc[1] === :butt ? Int32(0) : lc[1] === :square ? Int32(1) : lc[1] === :round ? Int32(2) : Int32(0)
        else
            lc === :butt ? Int32(0) : lc === :square ? Int32(1) : lc === :round ? Int32(2) : Int32(0)
        end

        if !isnothing(cached) && cached.trace_renderobject isa LavaRenderObject
            robj = cached.trace_renderobject
            update_buffer!(robj, :vertex, vertex_data)
            update_buffer!(robj, :color, color_data)
            update_buffer!(robj, :lastlen, lastlen_data)
            update_buffer!(robj, :valid_vertex, valid_data)
            update_buffer!(robj, :thickness, thickness_data)
            robj.buffers[:indices] = Lava.alloc_index_buffer(UInt32.(indices))
            robj.uniforms[:projectionview] = pv
            robj.uniforms[:model] = model
            robj.uniforms[:resolution] = res
            robj.uniforms[:linecap] = linecap_i
            robj.vertex_count = length(indices)
            robj.visible = true
            return (robj,)
        end

        pipeline = get_lines_pipeline!(screen)
        robj = LavaRenderObject(pipeline;
            arg_names = (:vertex, :color, :lastlen, :valid_vertex, :thickness,
                         :projectionview, :model, :px_per_unit, :depth_shift,
                         :resolution, :scene_origin, :linecap, :joinstyle, :miter_limit, :pattern_length),
            buffers = Dict{Symbol, Lava.LavaArray}(
                :vertex => Lava.LavaArray(vertex_data),
                :color => Lava.LavaArray(color_data),
                :lastlen => Lava.LavaArray(lastlen_data),
                :valid_vertex => Lava.LavaArray(valid_data),
                :thickness => Lava.LavaArray(thickness_data),
                :indices => Lava.alloc_index_buffer(UInt32.(indices)),
            ),
            uniforms = Dict{Symbol, Any}(
                :projectionview => pv,
                :model => model,
                :px_per_unit => 1f0,
                :depth_shift => 0f0,
                :resolution => res,
                :scene_origin => Vec2f(0f0, 0f0),
                :linecap => linecap_i,
                :joinstyle => Int32(0),  # no joints for segments
                :miter_limit => 0f0,
                :pattern_length => 0f0,
            ),
            vertex_count = length(indices),
            instances = 1,
        )
        update_texture!(robj, reshape(Float32[-1], 1, 1); filter=:linear, wrap=:repeat)
        return (robj,)
    end
end
