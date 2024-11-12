"""
    tooltip(position, string)
    tooltip(x, y, string)

Creates a tooltip pointing at `position` displaying the given `string
"""
@recipe Tooltip (position,) begin
    # General
    text = ""
    "Sets the offset between the given `position` and the tip of the triangle pointing at that position."
    offset = 10
    "Sets where the tooltip should be placed relative to `position`. Can be `:above`, `:below`, `:left`, `:right`."
    placement = :above
    "Sets the alignment of the tooltip relative `position`. With `align = 0.5` the tooltip is centered above/below/left/right the `position`."
    align = 0.5
    xautolimits = false
    yautolimits = false
    zautolimits = false

    # Text
    "Sets the padding around text in the tooltip. This is given as `(left, right, bottom, top)` offsets."
    textpadding = (4, 4, 4, 4) # LRBT
    "Sets the text color."
    textcolor = @inherit textcolor
    "Sets the text size in screen units."
    fontsize = 16
    "Sets the font."
    font = @inherit font
    "Gives text an outline if set to a positive value."
    strokewidth = 0
    "Sets the text outline color."
    strokecolor = :white
    "Sets whether text is aligned to the `:left`, `:center` or `:right` within its bounding box."
    justification = :left

    # Background
    "Sets the background color of the tooltip."
    backgroundcolor = :white
    "Sets the size of the triangle pointing at `position`."
    triangle_size = 10

    # Outline
    "Sets the color of the tooltip outline."
    outline_color = :black
    "Sets the linewidth of the tooltip outline."
    outline_linewidth = 2f0
    "Sets the linestyle of the tooltip outline."
    outline_linestyle = nothing

    MakieCore.mixin_generic_plot_attributes()...
    inspectable = false
end

function convert_arguments(::Type{<: Tooltip}, x::Real, y::Real, str::AbstractString)
    return (Point2{float_type(x, y)}(x, y), str)
end
function convert_arguments(::Type{<: Tooltip}, x::Real, y::Real)
    return (Point2{float_type(x, y)}(x, y),)
end

function plot!(plot::Tooltip{<:Tuple{<:VecTypes, <:AbstractString}})
    plot.attributes[:text]  = plot[2]
    tooltip!(plot, plot[1]; plot.attributes...)
    plot
end


function plot!(p::Tooltip{<:Tuple{<:VecTypes}})
    # TODO align
    scene = parent_scene(p)
    px_pos = map(
            p, p[1], scene.camera.projectionview, p.model, transform_func(p),
            p.space, scene.viewport) do pos, _, model, tf, space, viewport

        # Adjusted from error_and_rangebars
        spvm = clip_to_space(scene.camera, :pixel) * space_to_clip(scene.camera, space) * model
        transformed = apply_transform(tf, pos, space)
        p4d = spvm * to_ndim(Point4f, to_ndim(Point3f, transformed, 0), 1)
        return Point3f(p4d) / p4d[4]
    end

    # Text

    textpadding = map(p, p.textpadding) do pad
        if pad isa Real
            return (pad, pad, pad, pad)
        elseif length(pad) == 4
            return pad
        else
            @error "Failed to parse $pad as (left, right, bottom, top). Using defaults"
            return (4, 4, 4, 4)
        end
    end

    text_offset = map(p, p.offset, textpadding, p.triangle_size, p.placement, p.align) do o, pad, ts, placement, align
        l, r, b, t = pad

        if placement === :left
            return Vec2f(-o - r - ts, b - align * (b + t))
        elseif placement === :right
            return Vec2f( o + l + ts, b - align * (b + t))
        elseif placement in (:below, :down, :bottom)
            return Vec2f(l - align * (l + r), -o - t - ts)
        elseif placement in (:above, :up, :top)
            return Vec2f(l - align * (l + r),  o + b + ts)
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return Vec2f(0, o + b + ts)
        end
    end

    text_align = map(p, p.placement, p.align) do placement, align
        if placement === :left
            return (1.0, align)
        elseif placement === :right
            return (0.0, align)
        elseif placement in (:below, :down, :bottom)
            return (align, 1.0)
        elseif placement in (:above, :up, :top)
            return (align, 0.0)
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return (align, 0.0)
        end
    end

    tp = text!(
        p, px_pos, text = p.text, justification = p.justification,
        align = text_align, offset = text_offset, fontsize = p.fontsize,
        color = p.textcolor, font = p.font, fxaa = false,
        strokewidth = p.strokewidth, strokecolor = p.strokecolor,
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable, space = :pixel, transformation = Transformation()
    )
    translate!(tp, 0, 0, 0.01) # must be larger than eps(1f4) to prevent float precision issues

    # TODO react to glyphcollection instead
    bbox = map(
            p, px_pos, p.text, text_align, text_offset, textpadding, p.align
        ) do p, s, _, o, pad, align
        bb = string_boundingbox(tp) + to_ndim(Vec3f, o, 0)
        l, r, b, t = pad
        return Rect3f(origin(bb) .- (l, b, 0), widths(bb) .+ (l+r, b+t, 0))
    end

    # Text background mesh

    mesh!(
        p, bbox, shading = NoShading, space = :pixel,
        color = p.backgroundcolor, fxaa = false,
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable, transformation = Transformation()
    )

    # Triangle mesh

    tri_points = map(p, bbox, p.triangle_size, p.placement, p.align) do bb, s, placement, align
        l, b, z = origin(bb); w, h, _ = widths(bb)
        r, t = (l, b) .+ (w, h)
        if placement === :left
            return Point3f[
                (r,     b + align * h + 0.5s, z),
                (r + s, b + align * h,        z),
                (r,     b + align * h - 0.5s, z),
            ]
        elseif placement === :right
            return Point3f[
                (l,   b + align * h - 0.5s, z),
                (l-s, b + align * h,        z),
                (l,   b + align * h + 0.5s, z),
            ]
        elseif placement in (:below, :down, :bottom)
            return Point3f[
                (l + align * w - 0.5s, t,   z),
                (l + align * w,        t+s, z),
                (l + align * w + 0.5s, t,   z),
            ]
        elseif placement in (:above, :up, :top)
            return Point3f[
                (l + align * w + 0.5s, b,   z),
                (l + align * w,        b-s, z),
                (l + align * w - 0.5s, b,   z),
            ]
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return Point3f[
                (l + align * w + 0.5s, b,   z),
                (l + align * w,        b-s, z),
                (l + align * w - 0.5s, b,   z),
            ]
        end
    end

    mesh!(
        p, tri_points, [1 2 3], shading = NoShading, space = :pixel,
        color = p.backgroundcolor, fxaa = false, 
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable, transformation = Transformation()
    )

    # Outline

    outline = map(p, bbox, p.triangle_size, p.placement, p.align) do bb, s, placement, align
        l, b, z = origin(bb); w, h, _ = widths(bb)
        r, t = (l, b) .+ (w, h)

        # We start/end at half width/height here to avoid corners like this:
        #     ______
        #   _|
        #  |    ____
        #  |   |

        shift = if placement === :left
            Vec2f[
                (l, b), (l, t), (r, t),
                (r,     b + align * h + 0.5s),
                (r + s, b + align * h),
                (r,     b + align * h - 0.5s),
                (r, b), (l, b)
            ]
        elseif placement === :right
            Vec2f[
                (r, b), (l, b),
                (l,   b + align * h - 0.5s),
                (l-s, b + align * h),
                (l,   b + align * h + 0.5s),
                (l, t), (r, t), (r, b)
            ]
        elseif placement in (:below, :down, :bottom)
            Vec2f[
                (l, b), (l, t),
                (l + align * w - 0.5s, t),
                (l + align * w,        t+s),
                (l + align * w + 0.5s, t),
                (r, t), (r, b), (l, b)
            ]
        elseif placement in (:above, :up, :top)
            Vec2f[
                (l, b), (l, t), (r, t), (r, b),
                (l + align * w + 0.5s, b),
                (l + align * w,        b-s),
                (l + align * w - 0.5s, b),
                (l, b)
            ]
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            Vec2f[
                (l, b), (l, t), (r, t), (r, b),
                (l + align * w + 0.5s, b),
                (l + align * w,        b-s),
                (l + align * w - 0.5s, b),
                (l, b)
            ]
        end

        return to_ndim.(Vec3f, shift, z)
    end

    lp = lines!(
        p, outline,
        color = p.outline_color, space = :pixel, miter_limit = pi/18,
        linewidth = p.outline_linewidth, linestyle = p.outline_linestyle,
        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable, transformation = Transformation()
    )
    translate!(lp, 0, 0, 0.01)

    notify(p[1])

    return p
end
