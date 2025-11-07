struct GlyphInfo
    glyph::Int
    font::FreeTypeAbstraction.FTFont
    origin::Point2f
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
end