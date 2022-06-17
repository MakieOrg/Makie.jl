function parent_transform(x)
    p = parent(transformation(x))
    isnothing(p) ? Mat4f(I) : p.model[]
end

function boundingbox(x, exclude = (p)-> false)
    return parent_transform(x) * data_limits(x, exclude)
end

function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    return pr - zero
end

function rotate_bbox(bb::Rect3f, rot)
    points = decompose(Point3f, bb)
    Rect3f(Ref(rot) .* points)
end

function gl_bboxes(gl::GlyphCollection; height_insensitive::Bool)
    bbfunc = height_insensitive ? height_insensitive_boundingbox_with_advance : _inkboundingbox
    scales = gl.scales.sv isa Vec2f ? (gl.scales.sv for _ in gl.extents) : gl.scales.sv
    map(gl.extents, scales) do ext, scale
        hi_bb = bbfunc(ext)
        Rect2f(
            Makie.origin(hi_bb) * scale,
            widths(hi_bb) * scale
        )
    end
end

function height_insensitive_boundingbox(ext::GlyphExtent)
    l = ext.ink_bounding_box.origin[1]
    w = ext.ink_bounding_box.widths[1]
    b = ext.descender
    h = ext.ascender
    return Rect2f((l, b), (w, h - b))
end

function height_insensitive_boundingbox_with_advance(ext::GlyphExtent)
    l = 0f0
    r = ext.hadvance
    b = ext.descender
    h = ext.ascender
    return Rect2f((l, b), (r - l, h - b))
end

_inkboundingbox(ext::GlyphExtent) = ext.ink_bounding_box

function boundingbox(glyphcollection::GlyphCollection, position::Point3f, rotation::Quaternion; height_insensitive)

    if isempty(glyphcollection.glyphs)
        return Rect3f(position, Vec3f(0, 0, 0))
    end

    glyphorigins = glyphcollection.origins
    glyphbbs = gl_bboxes(glyphcollection; height_insensitive = height_insensitive)

    bb = Rect3f()
    for (charo, glyphbb) in zip(glyphorigins, glyphbbs)
        charbb = rotate_bbox(Rect3f(glyphbb), rotation) + charo + position
        if !isfinite_rect(bb)
            bb = charbb
        else
            bb = union(bb, charbb)
        end
    end
    !isfinite_rect(bb) && error("Invalid text boundingbox")
    bb
end

function boundingbox(layouts::AbstractArray{<:GlyphCollection}, positions, rotations; height_insensitive)

    if isempty(layouts)
        Rect3f((0, 0, 0), (0, 0, 0))
    else
        bb = Rect3f()
        broadcast_foreach(layouts, positions, rotations) do layout, pos, rot
            if !isfinite_rect(bb)
                bb = boundingbox(layout, pos, rot; height_insensitive = height_insensitive)
            else
                bb = union(bb, boundingbox(layout, pos, rot; height_insensitive = height_insensitive))
            end
        end
        !isfinite_rect(bb) && error("Invalid text boundingbox")
        bb
    end
end

function boundingbox(x::Text{<:Tuple{<:GlyphCollection}}; height_insensitive = true)
    boundingbox(
        x[1][],
        to_ndim(Point3f, x.position[], 0),
        to_rotation(x.rotation[]);
        height_insensitive = height_insensitive
    )
end

function boundingbox(x::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}}; height_insensitive = true)
    boundingbox(
        x[1][],
        to_ndim.(Point3f, x.position[], 0),
        to_rotation(x.rotation[]);
        height_insensitive = height_insensitive
    )
end

_is_latex_string(x::AbstractVector{<:LaTeXString}) = true 
_is_latex_string(x::LaTeXString) = true 
_is_latex_string(other) = false 

function boundingbox(x::Text; height_insensitive::Union{Bool, Nothing} = nothing)
    # use tight boundingbox for LaTeXString text because
    # they don't follow the normal text behavior anyway with differently
    # sized glyphs and weird placement

    # also, using underscore as a hline character etc. (the workaround to not
    # need extra linesegments which makes switching between LaTeXString and normal text harder)
    # messes up boundaries otherwise
    # for example when used as the top line of a square root there
    # really shouldn't be used any more space above.
    if haskey(x, :text) && _is_latex_string(x.text[])
        boundingbox(x.plots[1]; height_insensitive = height_insensitive === nothing ? false : height_insensitive)
    else
        boundingbox(x.plots[1]; height_insensitive = height_insensitive === nothing ? true : height_insensitive)
    end
end

function text_bb(str, font, size)
    rot = Quaternionf(0,0,0,1)
    layout = layout_text(
        str, size, font, Vec2f(0), rot, 0.5, 1.0,
        RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0), 0f0, 0f0)
    return boundingbox(layout, Point3f(0), rot; height_insensitive = false)
end

"""
Calculate an approximation of a tight rectangle around a 2D rectangle rotated by `angle` radians.
This is not perfect but works well enough. Check an A vs X to see the difference.
"""
function rotatedrect(rect::Rect{2, T}, angle)::Rect{2, T} where T
    ox, oy = rect.origin
    wx, wy = rect.widths
    points = Mat{2, 4, T}(
        ox, oy,
        ox, oy+wy,
        ox+wx, oy,
        ox+wx, oy+wy
    )
    mrot = Mat{2, 2, T}(
        cos(angle), -sin(angle),
        sin(angle), cos(angle)
    )
    rotated = mrot * points

    rmins = minimum(rotated; dims=2)
    rmaxs = maximum(rotated; dims=2)

    return Rect2(rmins..., (rmaxs .- rmins)...)
end
