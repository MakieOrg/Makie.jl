conversion_trait(::Type{<:Glyphs}) = PointBased()

function calculated_attributes!(::Type{Glyphs}, plot::Plot)
    attr = plot.attributes

    register_colormapping!(attr)
    add_computation!(attr, Val(:computed_color))

    add_constant!(attr, :sdf_marker_shape, Cint(DISTANCEFIELD))
    add_constant!(attr, :atlas, get_texture_atlas())

    map!(attr, [:atlas, :glyph_indices, :font], :sdf_uv) do atlas, gi, fonts
        return glyph_uv_width!.((atlas,), gi, fonts)
    end

    map!(
        attr, [:atlas, :glyph_indices, :font, :scale],
        [:quad_offset, :quad_scale]
    ) do atlas, gi, fonts, scale
        quad_offsets = Vec2f[]
        quad_scales = Vec2f[]
        pad = atlas.glyph_padding / atlas.pix_per_glyph
        for idx in eachindex(gi)
            fs = sv_getindex(scale, idx)
            bb = FreeTypeAbstraction.metrics_bb(gi[idx], fonts[idx], fs)[1]
            push!(quad_offsets, Vec2f(minimum(bb) .- fs .* pad))
            push!(quad_scales, Vec2f(widths(bb) .+ fs * 2pad))
        end
        return (quad_offsets, quad_scales)
    end

    # GL and WGL bind the stroke width to a uniform float, so a per-glyph one
    # collapses to the first value there. CairoMakie uses `strokewidth` per glyph.
    map!(attr, :strokewidth, :uniform_strokewidth) do strokewidth
        return Float32(isscalar(strokewidth) ? strokewidth : get(strokewidth, 1, 0.0f0))
    end

    register_position_transforms!(attr)

    map!(
        scatter_limits, attr,
        [:positions, :space, :markerspace, :quad_scale, :quad_offset, :rotation, :marker_offset],
        :data_limits
    )

    return
end
