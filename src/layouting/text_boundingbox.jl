function boundingbox(plot::Text)
    @warn """
    `boundingbox(::Text)` has been deprecated in favor of `Makie.text_boundingbox(::Text)`.
    In the future `boundingbox(::Text)` will be adjusted to match the other
    `boundingbox(plot)` functions. The new functionality is currently available
    as `Makie._boundingbox(plot::Text)`.
    """
    return text_boundingbox(plot)
end

# TODO: Naming: not px, it's whatever markerspace is...
function text_boundingbox(plot::Text)
    bb = Rect3d()
    for p in plot.plots
        _bb = text_boundingbox(p)
        if !isfinite_rect(bb)
            bb = _bb
        elseif isfinite_rect(_bb)
            bb = union(bb, _bb)
        end
    end
    return bb
end

function text_boundingbox(x::Text{<:Tuple{<:GlyphCollection}})
    if x.space[] == x.markerspace[]
        pos = to_ndim(Point3d, x.position[], 0)
    else
        cam = parent_scene(x).camera
        transformed = apply_transform(x.transformation.transform_func[], x.position[])
        pos = Makie.project(cam, x.space[], x.markerspace[], transformed)
    end
    return text_boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function text_boundingbox(x::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}})
    if x.space[] == x.markerspace[]
        pos = to_ndim.(Point3d, x.position[], 0)
    else
        cam = (parent_scene(x).camera,)
        transformed = apply_transform(x.transformation.transform_func[], x.position[])
        pos = Makie.project.(cam, x.space[], x.markerspace[], transformed) # TODO: vectorized project
    end
    return text_boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function text_boundingbox(x::Union{GlyphCollection,AbstractArray{<:GlyphCollection}}, args...)
    bb = unchecked_boundingbox(x, args...)
    isfinite_rect(bb) || error("Invalid text boundingbox")
    return bb
end

# Utility
function text_bb(str, font, size)
    rot = Quaternionf(0,0,0,1)
    fonts = nothing # TODO: remove the arg if possible
    layout = layout_text(
        str, size, font, fonts, Vec2f(0), rot, 0.5, 1.0,
        RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0), 0f0, 0f0)
    return text_boundingbox(layout, Point3d(0), rot)
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
        charbb = rotate_bbox(Rect3d(glyphbb), rotation) + charo
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
            bb = text_boundingbox(layout, pos, rot)
        else
            bb = union(bb, text_boundingbox(layout, pos, rot))
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