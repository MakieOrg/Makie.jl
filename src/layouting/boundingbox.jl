function parent_transform(x)
    p = parent(transformation(x))
    isnothing(p) ? Mat4{Float64}(I) : Mat4{Float64}(p.model[])
end

function boundingbox(x, exclude = (p)-> false)
    return parent_transform(x) * data_limits(x, exclude)
end

function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    return pr - zero
end

function rotate_bbox(bb::Rect3, rot)
    points = decompose(Point3e, bb)
    Rect3{Float64}(Ref(rot) .* points)
end

function gl_bboxes(gl::GlyphCollection)
    scales = gl.scales.sv isa Vec2f ? (gl.scales.sv for _ in gl.extents) : gl.scales.sv
    map(gl.glyphs, gl.extents, scales) do c, ext, scale
        hi_bb = height_insensitive_boundingbox_with_advance(ext)
        # TODO c != 0 filters out all non renderables, which is not always desired
        o = Makie.origin(hi_bb) * scale
        w = (c != 0) * widths(hi_bb) * scale
        Rect3{Float64}(Point3{Float64}(o[1], o[2], 0.0), Vec3{Float64}(w[1], w[2], 0))
    end
end

function height_insensitive_boundingbox(ext::GlyphExtent)
    l = ext.ink_bounding_box.origin[1]
    w = ext.ink_bounding_box.widths[1]
    b = ext.descender
    h = ext.ascender
    return Rect2{Float64}((l, b), (w, h - b))
end

function height_insensitive_boundingbox_with_advance(ext::GlyphExtent)
    l = 0f0
    r = ext.hadvance
    b = ext.descender
    h = ext.ascender
    return Rect2{Float64}((l, b), (r - l, h - b))
end

_inkboundingbox(ext::GlyphExtent) = ext.ink_bounding_box

function boundingbox(glyphcollection::GlyphCollection, position::Point3, rotation::Quaternion)
    return boundingbox(glyphcollection, rotation) + position
end

function boundingbox(glyphcollection::GlyphCollection, rotation::Quaternion)
    if isempty(glyphcollection.glyphs)
        return Rect3(Point3e(0), Vec3e(0))
    end

    glyphorigins = glyphcollection.origins
    glyphbbs = gl_bboxes(glyphcollection)

    bb = Rect3{Float64}()
    for (charo, glyphbb) in zip(glyphorigins, glyphbbs)
        charbb = rotate_bbox(Rect3{Float64}(glyphbb), rotation) + charo
        if !isfinite_rect(bb)
            bb = charbb
        else
            bb = union(bb, charbb)
        end
    end
    !isfinite_rect(bb) && error("Invalid text boundingbox")
    return bb
end

function boundingbox(layouts::AbstractArray{<:GlyphCollection}, positions, rotations)
    if isempty(layouts)
        return Rect3{Float64}((0, 0, 0), (0, 0, 0))
    else
        bb = Rect3{Float64}()
        broadcast_foreach(layouts, positions, rotations) do layout, pos, rot
            if !isfinite_rect(bb)
                bb = boundingbox(layout, pos, rot)
            else
                bb = union(bb, boundingbox(layout, pos, rot))
            end
        end
        !isfinite_rect(bb) && error("Invalid text boundingbox")
        return bb
    end
end

function boundingbox(x::Text{<:Tuple{<:GlyphCollection}})
    if x.space[] == x.markerspace[]
        pos = to_ndim(Point3e, x.position[], 0)
    else
        cam = parent_scene(x).camera
        transformed = apply_transform(x.transformation.transform_func[], x.position[])
        pos = Makie.project(cam, x.space[], x.markerspace[], transformed)
    end
    return boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function boundingbox(x::Text{<:Tuple{<:AbstractArray{<:GlyphCollection}}})
    if x.space[] == x.markerspace[]
        pos = to_ndim.(Point3e, x.position[], 0)
    else
        cam = (parent_scene(x).camera,)
        transformed = apply_transform(x.transformation.transform_func[], x.position[])
        pos = Makie.project.(cam, x.space[], x.markerspace[], transformed)
    end
    return boundingbox(x[1][], pos, to_rotation(x.rotation[]))
end

function boundingbox(plot::Text)
    bb = Rect3{Float64}()
    for p in plot.plots
        _bb = boundingbox(p)
        if !isfinite_rect(bb)
            bb = _bb
        elseif isfinite_rect(_bb)
            bb = union(bb, _bb)
        end
    end
    return bb
end

_is_latex_string(x::AbstractVector{<:LaTeXString}) = true
_is_latex_string(x::LaTeXString) = true
_is_latex_string(other) = false

function text_bb(str, font, size)
    rot = Quaternionf(0,0,0,1)
    fonts = nothing # TODO: remove the arg if possible
    layout = layout_text(
        str, size, font, fonts, Vec2f(0), rot, 0.5, 1.0,
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
