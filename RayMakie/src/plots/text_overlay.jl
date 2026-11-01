# Glyphs is the atomic child of Text; use the shared sprite pipeline.

"""
Is `r` the one rotation that means "not rotated"?

A VECTOR of rotations is never it, even if every entry is the identity: a plot
that gives a rotation per character is asking for oriented glyphs, which is the
case `billboard` has to yield to.
"""
function identity_rotation(r)
    r isa AbstractVector && return false
    q = Makie.to_rotation(r)
    return q[1] == 0 && q[2] == 0 && q[3] == 0 && q[4] == 1
end

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Glyphs)
    attr = plot.attributes
    haskey(attr, :sdf_uv) || return nothing

    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    # ── Text-specific conversions to gpu_* names (same targets as scatter) ──

    # positions → gpu_positions (element-wise via register_computation!)
    Makie.ComputePipeline.register_computation!(
        attr,
        [:positions_transformed_f32c], [:gpu_positions]
    ) do (pos,), changed, cached
        return ([Vec3f(Makie.to_ndim(Point3f, p, 0.0f0)) for p in pos],)
    end

    # computed_color → gpu_colors
    Makie.ComputePipeline.register_computation!(
        attr,
        [:computed_color], [:gpu_colors]
    ) do (tc,), changed, cached
        if tc isa AbstractVector
            return ([Vec4f(RGBA{Float32}(c).r, RGBA{Float32}(c).g, RGBA{Float32}(c).b, RGBA{Float32}(c).alpha) for c in tc],)
        else
            c = RGBA{Float32}(tc)
            return ([Vec4f(c.r, c.g, c.b, c.alpha)],)
        end
    end

    # rotation → gpu_rotation (Vec4f from Quaternion)
    haskey(attr, :gpu_rotation) || Makie.ComputePipeline.register_computation!(
        attr,
        [:rotation], [:gpu_rotation]
    ) do (rot,), changed, cached
        if rot isa AbstractVector
            return ([Vec4f(r[1], r[2], r[3], r[4]) for r in rot],)
        else
            q = Makie.to_rotation(rot)
            return (Vec4f(q[1], q[2], q[3], q[4]),)
        end
    end

    # Glyph stroke colors can vary per glyph, just like their fill colors.
    Makie.ComputePipeline.register_computation!(
        attr,
        [:positions_transformed_f32c, :strokecolor, :glowcolor], [:gpu_stroke_color, :gpu_glow_color]
    ) do (pos, stroke, glow), changed, cached
        n = length(pos)
        rgba(c) = Vec4f(RGBA{Float32}(c).r, RGBA{Float32}(c).g, RGBA{Float32}(c).b, RGBA{Float32}(c).alpha)
        colors(c) = c isa AbstractVector ? rgba.(c) : fill(rgba(c), n)
        return (colors(stroke), colors(glow))
    end

    # Constants
    haskey(attr, :sdf_marker_shape) || Makie.ComputePipeline.add_constant!(attr, :sdf_marker_shape, Cint(3))
    # `billboard` FOLLOWS THE ROTATION, the way GLMakie's default does
    # (`billboard = rotation == Vec4f(0, 0, 0, 1)`, with the comment "rotation and
    # billboard don't go along"). The sprite shader picks `projection` over
    # `projection * view` for a billboard, because a camera-facing quad's offsets
    # are in VIEW space — so a quad that carries a real rotation must take the
    # other branch or it is built in the wrong basis.
    #
    # Hardcoded `true` was right for exactly one case and wrong for the other: a
    # 2D axis's tick labels have `markerspace = :pixel` and an identity rotation,
    # and pixel space has an identity `view`, so both branches agree and every
    # test passed. `Axis3D`'s labels are per-character rotations onto the axis
    # planes in DATA markerspace, where `view` is the real 3D one — dropping it
    # smeared every glyph quad into a band across the whole figure, which is what
    # `surface(rand(20, 20))` looked like.
    haskey(attr, :billboard) || Makie.ComputePipeline.map!(
        identity_rotation, attr, :rotation, :billboard
    )
    haskey(attr, :transform_marker) || Makie.ComputePipeline.add_constant!(attr, :transform_marker, false)

    # Scalar conversions to gpu_* (Int32)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : false), attr, :transform_marker, :gpu_transform_marker)
    Makie.ComputePipeline.map!(x -> Int32(x isa Bool ? x : true), attr, :billboard, :gpu_billboard)
    Makie.ComputePipeline.map!(x -> Int32(x), attr, :sdf_marker_shape, :gpu_sdf_marker_shape)

    # Constants
    Makie.ComputePipeline.map!(Float32, attr, :uniform_strokewidth, :gpu_stroke_width)
    Makie.ComputePipeline.map!(Float32, attr, :glowwidth, :gpu_glow_width)
    haskey(attr, :depth_shift) || Makie.ComputePipeline.add_constant!(attr, :depth_shift, 0.0f0)
    haskey(attr, :px_per_unit) || Makie.ComputePipeline.add_constant!(attr, :px_per_unit, screen.px_per_unit)

    atlas = Makie.get_texture_atlas()
    haskey(attr, :gpu_atlas_width) || Makie.ComputePipeline.add_constant!(attr, :gpu_atlas_width, Float32(size(atlas.data, 1)))

    # ── Final robj — same pattern as scatter ──
    deps = collect(SCATTER_GRAPH_ARGS)

    return register_computation!(attr, deps, [:trace_renderobject]) do args, changed, cached
        n = length(args.gpu_positions)
        n == 0 && return (nothing,)

        if !isnothing(cached) && cached.trace_renderobject isa RenderObject
            robj = cached.trace_renderobject
            update_robj!(robj, args, changed)
            robj.vertex_count = n
            # Re-read: the atlas may have gained a glyph since this object was
            # built, and a robj that keeps its first bindings draws the new
            # glyph blank. Cheap — `get_atlas_bindings` returns the cached
            # object untouched unless the atlas is dirty.
            robj.bindings = get_atlas_bindings(screen)
            robj.visible = true
            return (robj,)
        end

        robj = construct_robj(
            get_scatter_pipeline!(screen), args, SCATTER_ARG_NAMES;
            backend = screen.config.device, fxaa = plot_fxaa(plot),
            vertex_count = n
        )
        robj.bindings = get_atlas_bindings(screen)
        return (robj,)
    end
end
