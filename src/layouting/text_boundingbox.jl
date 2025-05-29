@deprecate boundingbox(plot::Text) boundingbox(plot, plot.markerspace[])

function boundingbox(plot::Text, target_space::Symbol)
    # TODO:
    # This is temporary prep work for the future. We should actually consider
    # plot.space, markerspace, textsize, etc when computing the boundingbox in
    # the target_space given to the function.
    # We may also want a cheap version that only considers forward
    # transformations (i.e. drops textsize etc when markerspace is not part of
    # the plot.space -> target_space conversion chain)
    if Makie.is_data_space(target_space)
        # This also transforms string boundingboxes if space == markerspace
        return apply_transform_and_model(plot, data_limits(plot))
    elseif target_space == plot.markerspace[]
        return string_boundingbox(plot)
    else
        error("`target_space = :$target_space` must be either :data or markerspace = :$(plot.markerspace[])")
    end
end


# TODO: Naming: not px, it's whatever markerspace is...
function string_boundingbox(plot::Text)
    bb = Rect3d()
    for p in plot.plots
        _bb = string_boundingbox(p)
        if !isfinite_rect(bb)
            bb = _bb
        elseif isfinite_rect(_bb)
            bb = union(bb, _bb)
        end
    end
    return bb
end

# Text can contain linesegments. Use data_limits to avoid transformations as
# they are already in markerspace
string_boundingbox(x::LineSegments) = data_limits(x)

function string_boundingbox(x::Text{<:Tuple{<:GlyphCollection}})
    if x.space[] == x.markerspace[]
        pos = to_ndim(Point3d, x.position[], 0)
    else
        cam = parent_scene(x).camera
        transformed = apply_transform_and_model(x, x.position[])
        pos = Makie.project(cam, x.space[], x.markerspace[], transformed)
    end
    return string_boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function string_boundingbox(x::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}})
    if x.space[] == x.markerspace[]
        pos = to_ndim.(Point3d, x.position[], 0)
    else
        cam = (parent_scene(x).camera,)
        transformed = apply_transform_and_model(x, x.position[])
        pos = Makie.project.(cam, x.space[], x.markerspace[], transformed) # TODO: vectorized project
    end
    return string_boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function string_boundingbox(x::Union{GlyphCollection,AbstractArray{<:GlyphCollection}}, args...)
    bb = unchecked_boundingbox(x, args...)
    isfinite_rect(bb) || error("Invalid text boundingbox $bb")
    return bb
end

# Utility
function text_bb(str, font, size)
    rot = Quaternionf(0,0,0,1)
    fonts = nothing # TODO: remove the arg if possible
    layout = layout_text(
        str, size, font, fonts, Vec2f(0), rot, 0.5, 1.0,
        RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0), 0f0, 0f0)
    return string_boundingbox(layout, Point3d(0), rot)
end


################################################################################

function unchecked_boundingbox(glyphcollection::GlyphCollection, position::Point3, rotation::Quaternion)
    return unchecked_boundingbox(glyphcollection, rotation) + position
end

function unchecked_boundingbox(glyphcollection::GlyphCollection, rotation::Quaternion)
    isempty(glyphcollection.glyphs) && return Rect3d(Point3d(0), Vec3d(0))

    glyphorigins = glyphcollection.origins
    glyphbbs = gl_bboxes(glyphcollection)

    bb = Rect3d()
    for (charo, glyphbb) in zip(glyphorigins, glyphbbs)
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

function unchecked_boundingbox(layouts::AbstractArray{<:GlyphCollection}, positions, rotations)
    isempty(layouts) && return Rect3d((0, 0, 0), (0, 0, 0))

    bb = Rect3d()
    broadcast_foreach(layouts, positions, rotations) do layout, pos, rot
        if !isfinite_rect(bb)
            bb = string_boundingbox(layout, pos, rot)
        else
            bb = union(bb, string_boundingbox(layout, pos, rot))
        end
    end
    return bb
end


################################################################################

# used

function gl_bboxes(gl::GlyphCollection)
    scales = gl.scales.sv isa Vec2 ? (gl.scales.sv for _ in gl.extents) : gl.scales.sv
    map(gl.glyphs, gl.extents, scales) do c, ext, scale
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