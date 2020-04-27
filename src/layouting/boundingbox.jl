using FreeTypeAbstraction: height_insensitive_boundingbox

"""
Calculates the exact boundingbox of a Scene/Plot, without considering any transformation
"""
raw_boundingbox(x::Atomic) = data_limits(x)


rootparent(x) = rootparent(parent(x))
rootparent(x::Scene) = x

function raw_boundingbox(x::Annotations)
    bb = raw_boundingbox(x.plots)
    inv(modelmatrix(rootparent(x))) * bb
end

raw_boundingbox(x::Combined) = raw_boundingbox(x.plots)
boundingbox(x) = raw_boundingbox(x)

function combined_modelmatrix(x)
    m = Mat4f0(I)
    while true
        m = modelmatrix(x) * m
        if parent(x) !== nothing && parent(x) isa Combined
            x = parent(x)
        else
            break
        end
    end
    return m
end

function modelmatrix(x)
    t = transformation(x)
    transformationmatrix(t.translation[], t.scale[], t.rotation[])
end

function boundingbox(x::Atomic)
    bb = raw_boundingbox(x)
    return combined_modelmatrix(x) * bb
end

boundingbox(scene::Scene) = raw_boundingbox(scene)
function raw_boundingbox(scene::Scene)
    if scene[Axis] !== nothing
        return raw_boundingbox(scene[Axis])
    elseif scene.limits[] !== automatic
        return scene_limits(scene)
    elseif cameracontrols(scene) == EmptyCamera()
        # Empty camera means this is a parent scene that itself doesn't display anything
        return raw_boundingbox(scene.children)
    else
        plots = plots_from_camera(scene)
        children = filter(scene.children) do child
            child.camera == scene.camera
        end
        return raw_boundingbox([plots; children])
    end
end

function raw_boundingbox(plots::Vector)
    isempty(plots) && return FRect3D()
    plot_idx = iterate(plots)
    bb = FRect3D()
    while plot_idx !== nothing
        plot, idx = plot_idx
        plot_idx = iterate(plots, idx)
        # isvisible(plot) || continue
        bb2 = boundingbox(plot)
        isfinite(bb) || (bb = bb2)
        isfinite(bb2) || continue
        bb = union(bb, bb2)
    end
    return bb
end

function project_widths(matrix, vec)
    pr = project(matrix, vec)
    zero = project(matrix, zeros(typeof(vec)))
    return pr - zero
end

function boundingbox(x::Text, text::String)
    position = to_value(x[:position])
    @get_attribute x (textsize, font, align, rotation, justification, lineheight)
    pm = inv(transformationmatrix(parent(x))[])
    bb = boundingbox(text, position, textsize, font, align, rotation,
                     modelmatrix(x), justification, lineheight)
    # Annoyingly we combine different spaces in the textlayout
    # The start position is in modelspace (multiplied by modelmatrix, which also
    # contains the scaling from any parent scene)
    # But than, from that startposition, we substract the align - which is in
    # unscaled space... Also the boundingbox we get returned is unscaled
    # and the fonts are actually getting drawn unscaled... Buhut,
    # the boundingbox will get scaled when drawing, so we need to apply the
    # inverse transformation.
    pm = inv(transformationmatrix(parent(x))[])
    wh = widths(bb)
    whp = project_widths(pm, wh)
    aoffset = wh .* to_ndim(Vec3f0, align, 0f0)
    aoffsetp = whp .* to_ndim(Vec3f0, align, 0f0)
    return FRect3D(minimum(bb) .+ aoffset .- aoffsetp, whp)
end

boundingbox(x::Text) = boundingbox(x, to_value(x[1]))

function boundingbox(
        text::String, position, textsize;
        font = "default", align = (:left, :bottom), rotation = 0.0
    )
    return boundingbox(
        text, position, textsize,
        to_font(font), to_align(align), to_rotation(rotation)
    )
end

"""
Calculate an approximation of a tight rectangle around a 2D rectangle rotated by `angle` radians.
This is not perfect but works well enough. Check an A vs X to see the difference.
"""
function rotatedrect(rect::Rect{2}, angle)
    ox, oy = rect.origin
    wx, wy = rect.widths
    points = @SMatrix([
        ox oy;
        ox oy+wy;
        ox+wx oy;
        ox+wx oy+wy;
    ])
    mrot = @SMatrix([
        cos(angle) -sin(angle);
        sin(angle) cos(angle);
    ])
    rotated = mrot * points'

    rmins = minimum(rotated, dims = 2)
    rmaxs = maximum(rotated, dims = 2)

    return Rect2D(rmins..., (rmaxs .- rmins)...)
end

function quaternion_to_2d_angle(quat)
    # this assumes that the quaternion was calculated from a simple 2d rotation as well
    return 2acos(quat[4]) * (signbit(quat[1]) ? -1 : 1)
end

function boundingbox(
        text::String, position, textsize, font,
        align, rotation, model, justification, lineheight;
        # use the font's ascenders and descenders for the bounding box
        # this means that a string's boundingbox doesn't change in the vertical
        # dimension when characters change (for example numbers during an animation)
        # this is not wanted in most cases because of the jitter it creates when
        # the boundingbox slightly changes size in each frame (in MakieLayout mostly)
        use_vertical_dimensions_from_font = true
    )
    atlas = get_texture_atlas()
    N = length(text)
    ctext_state = iterate(text)
    ctext_state === nothing && return FRect3D()

    # call the layouting algorithm to find out where all the glyphs end up
    # this is kind of a doubling, maybe it could be avoided if at creation all
    # positions would be populated in the text object, but that seems convoluted
    if position isa VecTypes
        position = layout_text(text, position, textsize, font, align,
            rotation, model, justification, lineheight)
    end

    bbox = nothing

    broadcast_foreach(1:N, rotation, font, textsize) do i, rotation, font, scale
        c, text_state = ctext_state
        ctext_state = iterate(text, text_state)

        if !(c in ('\r', '\n'))
            bb_unitspace = if use_vertical_dimensions_from_font
                height_insensitive_boundingbox(
                    FreeTypeAbstraction.get_extent(font, c), font)
            else
                inkboundingbox(FreeTypeAbstraction.get_extent(font, c))
            end

            scaled_bb = bb_unitspace * scale

            # TODO this only works in 2d
            rot_2d_radians = quaternion_to_2d_angle(rotation)
            rotated_bb = rotatedrect(scaled_bb, rot_2d_radians)

            # bb = rectdiv(bb, 1.5)
            shifted_bb = FRect3D(rotated_bb) + position[i]
            if isnothing(bbox)
                bbox = shifted_bb
            else
                bbox = union(bbox, shifted_bb)
            end
        end
    end
    return bbox
end
