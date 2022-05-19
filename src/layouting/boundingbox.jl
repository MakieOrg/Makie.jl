using FreeTypeAbstraction: height_insensitive_boundingbox

function parent_transform(x)
    p = parent(transformation(x))
    isnothing(p) ? Mat4f(I) : p.model[]
end

function boundingbox(x, exclude = (p)-> false)
    return parent_transform(x) * data_limits(x, exclude=exclude)
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

function gl_bboxes(gl::GlyphCollection)
    scales = gl.scales.sv isa Vec2f ? (gl.scales.sv for _ in gl.extents) : gl.scales.sv
    map(gl.extents, gl.fonts, scales) do ext, font, scale
        unscaled_hi_bb = height_insensitive_boundingbox_with_advance(ext, font)
        hi_bb = Rect2f(
            Makie.origin(unscaled_hi_bb) * scale,
            widths(unscaled_hi_bb) * scale
        )
    end
end

function height_insensitive_boundingbox_with_advance(ext, font)
    l = 0f0
    r = FreeTypeAbstraction.hadvance(ext)
    b = FreeTypeAbstraction.descender(font)
    t = FreeTypeAbstraction.ascender(font)
    return Rect2f((l, b), (r - l, t - b))
end

function boundingbox(glyphcollection::GlyphCollection, position::Point3f, rotation::Quaternion)

    if isempty(glyphcollection.glyphs)
        return Rect3f(position, Vec3f(0, 0, 0))
    end

    chars = glyphcollection.glyphs
    glyphorigins = glyphcollection.origins
    glyphbbs = gl_bboxes(glyphcollection)

    bb = Rect3f()
    for (char, charo, glyphbb) in zip(chars, glyphorigins, glyphbbs)
        # ignore line breaks
        # char in ('\r', '\n') && continue

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

function boundingbox(layouts::AbstractArray{<:GlyphCollection}, positions, rotations)

    if isempty(layouts)
        Rect3f((0, 0, 0), (0, 0, 0))
    else
        bb = Rect3f()
        broadcast_foreach(layouts, positions, rotations) do layout, pos, rot
            if !isfinite_rect(bb)
                bb = boundingbox(layout, pos, rot)
            else
                bb = union(bb, boundingbox(layout, pos, rot))
            end
        end
        !isfinite_rect(bb) && error("Invalid text boundingbox")
        bb
    end
end

function boundingbox(x::Text)
    boundingbox(
        x[1][],
        to_ndim.(Point3f, x.position[], 0),
        to_rotation(x.rotation[])
    )
end

function text_bb(str, font, size)
    rot = Quaternionf(0,0,0,1)
    layout = layout_text(
        str, size, font, Vec2f(0), rot, 0.5, 1.0,
        RGBAf(0, 0, 0, 0), RGBAf(0, 0, 0, 0), 0f0, 0f0)
    return boundingbox(layout, Point3f(0), rot)
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
