# draw_atomic for text — uses same scatter pipeline with text-specific conversions

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.text})
    attr = plot.attributes
    haskey(attr, :sdf_uv) || return nothing

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    # ── Text-specific conversions to vk_* names (same targets as scatter) ──

    # per_char_positions → vk_positions (element-wise via register_computation!)
    Makie.ComputePipeline.register_computation!(attr,
        [:per_char_positions_transformed_f32c], [:vk_positions]
    ) do (pos,), changed, cached
        return ([Vec3f(Makie.to_ndim(Point3f, p, 0f0)) for p in pos],)
    end

    # text_color → vk_colors
    Makie.ComputePipeline.register_computation!(attr,
        [:text_color], [:vk_colors]
    ) do (tc,), changed, cached
        if tc isa AbstractVector
            return ([Vec4f(RGBA{Float32}(c).r, RGBA{Float32}(c).g, RGBA{Float32}(c).b, RGBA{Float32}(c).alpha) for c in tc],)
        else
            c = RGBA{Float32}(tc)
            return ([Vec4f(c.r, c.g, c.b, c.alpha)],)
        end
    end

    # text_rotation → vk_rotation (Vec4f from Quaternion)
    haskey(attr, :vk_rotation) || Makie.ComputePipeline.register_computation!(attr,
        [:text_rotation], [:vk_rotation]
    ) do (rot,), changed, cached
        if rot isa AbstractVector
            return ([Vec4f(r[1], r[2], r[3], r[4]) for r in rot],)
        else
            q = Makie.to_rotation(rot)
            return (Vec4f(q[1], q[2], q[3], q[4]),)
        end
    end

    # stroke/glow from plot attrs → vk_stroke_color, vk_glow_color
    Makie.ComputePipeline.register_computation!(attr,
        [:per_char_positions_transformed_f32c], [:vk_stroke_color, :vk_glow_color]
    ) do (pos,), changed, cached
        n = length(pos)
        sc = haskey(plot, :text_strokecolor) ? to_value(plot.text_strokecolor) : RGBAf(0,0,0,0)
        sc_c = sc isa Colorant ? RGBA{Float32}(sc) : RGBA{Float32}(0,0,0,0)
        gc = haskey(plot, :glowcolor) ? to_value(plot.glowcolor) : RGBAf(0,0,0,0)
        gc_c = gc isa Colorant ? RGBA{Float32}(gc) : RGBA{Float32}(0,0,0,0)
        return (fill(Vec4f(sc_c.r, sc_c.g, sc_c.b, sc_c.alpha), n),
                fill(Vec4f(gc_c.r, gc_c.g, gc_c.b, gc_c.alpha), n))
    end

    # Constants
    haskey(attr, :sdf_marker_shape) || Makie.ComputePipeline.add_constant!(attr, :sdf_marker_shape, Cint(3))
    haskey(attr, :billboard) || Makie.ComputePipeline.add_constant!(attr, :billboard, true)
    haskey(attr, :transform_marker) || Makie.ComputePipeline.add_constant!(attr, :transform_marker, false)

    # Scalar conversions to vk_* (Int32)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : false), attr, :transform_marker, :vk_transform_marker)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : true), attr, :billboard, :vk_billboard)
    Makie.ComputePipeline.map!(x -> Int32(x), attr, :sdf_marker_shape, :vk_sdf_marker_shape)

    # Constants
    haskey(attr, :vk_stroke_width) || Makie.ComputePipeline.add_constant!(attr, :vk_stroke_width,
        Float32(haskey(plot, :strokewidth) ? to_value(plot.strokewidth) : 0f0))
    haskey(attr, :vk_glow_width) || Makie.ComputePipeline.add_constant!(attr, :vk_glow_width, 0f0)
    haskey(attr, :depth_shift) || Makie.ComputePipeline.add_constant!(attr, :depth_shift, 0f0)
    haskey(attr, :px_per_unit) || Makie.ComputePipeline.add_constant!(attr, :px_per_unit, 1f0)

    atlas = Makie.get_texture_atlas()
    haskey(attr, :vk_atlas_width) || Makie.ComputePipeline.add_constant!(attr, :vk_atlas_width, Float32(size(atlas.data, 1)))

    # ── Final robj — same pattern as scatter ──
    deps = collect(SCATTER_ARG_NAMES)

    register_computation!(attr, deps, [:trace_renderobject]) do args, changed, cached
        n = length(args.vk_positions)
        n == 0 && return (nothing,)

        if !isnothing(cached) && cached.trace_renderobject isa LavaRenderObject
            robj = cached.trace_renderobject
            update_robj!(robj, args, changed)
            robj.vertex_count = n
            robj.visible = true
            return (robj,)
        end

        robj = construct_robj(get_scatter_pipeline!(screen), args, SCATTER_ARG_NAMES;
                                      backend=screen.config.device, vertex_count=n)
        robj.bindings = get_atlas_bindings(screen)
        return (robj,)
    end
end
