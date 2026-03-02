# =============================================================================
# draw_atomic for Makie.text (overlay plot)
# =============================================================================
# Produces :sprite trace_renderobjects matching the unified sprite pipeline.
# Each glyph becomes a DISTANCEFIELD sprite, matching GLMakie's text rendering
# through sprites.vert → sprites.geom → distance_shape.frag.

function draw_atomic(screen::Screen, scene::Scene, plot::Makie.Plot{Makie.text})
    attr = plot.attributes
    state = screen.state
    backend = screen.config.device

    # Text plots must have sdf_uv (computed by register_text_computations!)
    if !haskey(attr, :sdf_uv)
        return nothing
    end

    # Register f32c_scale (same as scatter)
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))

    deps = [
        :per_char_positions_transformed_f32c,
        :quad_offset, :quad_scale,
        :marker_offset,
        :text_rotation,
        :text_color,
        :sdf_uv,
        :model_f32c, :f32c_scale, :transform_marker,
    ]

    register_computation!(attr, deps, [:trace_renderobject]) do args, changed, last
        positions_raw = args.per_char_positions_transformed_f32c
        n = length(positions_raw)
        n == 0 && return (nothing,)

        # Per-element positions (handle both Point2f and Point3f)
        positions = [Makie.to_ndim(Point3f, p, 0f0) for p in positions_raw]

        # Per-element quad geometry
        quad_offsets = _sprite_broadcast_vec2f(args.quad_offset, n)
        quad_scales = _sprite_broadcast_vec2f(args.quad_scale, n)

        # Per-element marker offset
        marker_offsets = _sprite_broadcast_vec3f(args.marker_offset, n)

        # Per-element rotation (Quaternionf → Vec4f)
        rotations = _sprite_broadcast_rotation(args.text_rotation, n)

        # Per-element colors (text_color is already per-glyph)
        colors = _text_resolve_colors(args.text_color, n)

        # Per-element SDF UV
        uv_rects = _sprite_broadcast_vec4f(args.sdf_uv, n)

        # Shape = DISTANCEFIELD for all text glyphs
        shapes = fill(UInt8(3), n)  # Overlay.DISTANCEFIELD

        # Uniforms
        is_transform_marker = args.transform_marker isa Bool ? args.transform_marker : false
        model = Mat4f(args.model_f32c)

        # Billboard flag: match GLMakie (billboard = markerspace == :pixel)
        # Data markerspace (e.g. 3D LScene axis text) needs billboard=false
        ms = haskey(plot, :markerspace) ? plot[:markerspace][] : :pixel
        is_billboard = ms === :pixel

        state.needs_film_clear = true
        return ((
            type = :sprite,
            positions = Adapt.adapt(backend, positions),
            quad_offsets = Adapt.adapt(backend, quad_offsets),
            quad_scales = Adapt.adapt(backend, quad_scales),
            marker_offsets = Adapt.adapt(backend, marker_offsets),
            rotations = Adapt.adapt(backend, rotations),
            colors = Adapt.adapt(backend, colors),
            uv_rects = Adapt.adapt(backend, uv_rects),
            shapes = Adapt.adapt(backend, shapes),
            billboard = is_billboard,
            scale_primitive = is_transform_marker,
            model = model,
        ),)
    end
end

# =============================================================================
# Text color helper
# =============================================================================

function _text_resolve_colors(text_color, n::Int)
    if text_color isa AbstractVector
        return [RGBA{Float32}(c) for c in text_color]
    elseif text_color isa Colorant
        return fill(RGBA{Float32}(text_color), n)
    else
        return fill(RGBA{Float32}(0f0, 0f0, 0f0, 1f0), n)
    end
end
