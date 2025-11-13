# @deprecate string_boundingbox(plot::Text) full_boundingbox(plot::Text)
# # @deprecate unchecked_boundingbox string_boundingboxes

# Utility
# TODO: only used in axis3d for the width of some labels?
function text_bb(str, font, size)
    rot = Quaternionf(0, 0, 0, 1)
    glyphinfos = to_glyphinfos(
        str,
        font,
        size,
        (0.0f0, 0.0f0),
        0.0f0,
        0.0f0,
        -1,
        rot,
        RGBAf(0.0, 0.0, 0.0, 1.0),
        RGBAf(0.0, 0.0, 0.0, 1.0),
        0.0,
    )
    return unchecked_boundingbox(
        [i.glyph for i in glyphinfos], [i.origin for i in glyphinfos], size, [i.extent for i in glyphinfos], rot
    )
end

# TODO: deprecated and only used in text_bb
function unchecked_boundingbox(glyphs, origins, scales, extents, rotation)
    isempty(glyphs) && return Rect3d(Point3d(0), Vec3d(0))
    glyphbbs = gl_bboxes(glyphs, scales, extents)
    bb = Rect3d()
    broadcast_foreach(origins, glyphbbs, rotation) do charo, glyphbb, rotation
        glyphbb3 = Rect3d(to_ndim(Point3d, origin(glyphbb), 0), to_ndim(Point3d, widths(glyphbb), 0))
        charbb = rotate_bbox(glyphbb3, rotation) + charo
        if !isfinite_rect(bb)
            bb = charbb
        else
            bb = union(bb, charbb)
        end
    end
    return bb
end

function gl_bboxes(glyphs, scales, extents)
    return broadcast(glyphs, extents, scales) do c, ext, scale
        hi_bb = height_insensitive_boundingbox_with_advance(ext)
        # TODO c != 0 filters out all non renderables, which is not always desired
        return Rect2d(origin(hi_bb) * scale, (c != 0) * widths(hi_bb) * scale)
    end
end

# TODO: tested but not used?
function height_insensitive_boundingbox(ext::GlyphExtent)
    l = ext.ink_bounding_box.origin[1]
    w = ext.ink_bounding_box.widths[1]
    b = ext.descender
    h = ext.ascender
    return Rect2d((l, b), (w, h - b))
end

function height_insensitive_boundingbox_with_advance(ext::GlyphExtent)
    l = 0.0
    r = ext.hadvance
    b = ext.descender
    h = ext.ascender
    return Rect2d((l, b), (r - l, h - b))
end

function rotate_bbox(bb::Rect3{T}, rot) where {T <: Real}
    points = decompose(Point3{T}, bb)
    return Rect3{T}(Ref(rot) .* points)
end
