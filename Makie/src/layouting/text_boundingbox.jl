function boundingbox(plot::Text, target_space::Symbol)
    # TODO:
    # This is temporary prep work for the future. We should actually consider
    # plot.space, markerspace, textsize, etc when computing the boundingbox in
    # the target_space given to the function.
    # We may also want a cheap version that only considers forward
    # transformations (i.e. drops textsize etc when markerspace is not part of
    # the plot.space -> target_space conversion chain)
    if target_space == plot.markerspace[]
        return full_boundingbox(plot, target_space)
    elseif Makie.is_data_space(target_space)
        return _project(plot.model[]::Mat4d, Rect3d(plot.positions_transformed[])::Rect3d)
    else
        error("`target_space = :$target_space` must be either :data or markerspace = :$(plot.markerspace[])")
    end
end

@deprecate string_boundingbox(plot::Text) full_boundingbox(plot::Text)

function gl_bboxes(glyphs, scales, extents)
    return broadcast(glyphs, extents, scales) do c, ext, scale
        hi_bb = height_insensitive_boundingbox_with_advance(ext)
        # TODO c != 0 filters out all non renderables, which is not always desired
        return Rect2d(origin(hi_bb) * scale, (c != 0) * widths(hi_bb) * scale)
    end
end

# tested but not used?
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
