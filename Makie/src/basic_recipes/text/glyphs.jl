struct GlyphInfo
    glyph::Int
    font::FreeTypeAbstraction.FTFont
    origin::Point3f
    extent::GlyphExtent
    size::Vec2f
    rotation::Quaternion
    color::RGBAf
    strokecolor::RGBAf
    strokewidth::Float32
end

# Copy constructor, to overwrite a field
function GlyphInfo(
        gi::GlyphInfo;
        glyph = gi.glyph,
        font = gi.font,
        origin = gi.origin,
        extent = gi.extent,
        size = gi.size,
        rotation = gi.rotation,
        color = gi.color,
        strokecolor = gi.strokecolor,
        strokewidth = gi.strokewidth
    )

    return GlyphInfo(
        glyph,
        font,
        origin,
        extent,
        size,
        rotation,
        color,
        strokecolor,
        strokewidth
    )
end

function calculated_attributes!(::Type{Glyphs}, plot::Plot)
    attr = plot.attributes

    add_constant!(attr, :sdf_marker_shape, Cint(DISTANCEFIELD))
    add_constant!(attr, :atlas, get_texture_atlas())

    map!(attr, [:atlas, :glyphinfos], :sdf_uv) do atlas, gi
        [glyph_uv_width!(atlas, i.glyph, i.font) for i in gi]
    end

    map!(attr, [:glyphinfos, :position], :marker_offset) do gi, position
        return Point3f[i.origin + position for i in gi]
    end

    map!(
        attr, [:atlas, :glyphinfos],
        [:quad_offset, :quad_scale]
    ) do atlas, gi

        quad_offsets = Vec2f[]
        quad_scales = Vec2f[]
        pad = atlas.glyph_padding / atlas.pix_per_glyph
        for i in gi
            i.glyph, i.font, i.size
            # These are tight to the glyph. They do not fill the full space
            # a glyph takes within a string/layout.
            bb = FreeTypeAbstraction.metrics_bb(i.glyph, i.font, i.size)[1]
            quad_offset = Vec2f(minimum(bb) .- i.size .* pad)
            quad_scale = Vec2f(widths(bb) .+ i.size * 2pad)
            push!(quad_offsets, quad_offset)
            push!(quad_scales, quad_scale)
        end

        return (quad_offsets, quad_scales)
    end
    # TODO: remapping positions to be per glyph first generates quite a few
    # redundant transform applications and projections in CairoMakie
    register_position_transforms!(attr, input_name = :position, transformed_name = :position_transformed)
end