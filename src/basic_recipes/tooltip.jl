"""
    tooltip(position, string)
    tooltip(x, y, string)

Creates a tooltip pointing at `position` displaying the given `string
"""
@recipe Tooltip begin
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
    backgroundcolor = (:white, 0.9)
    "Sets the size of the triangle pointing at `position`."
    triangle_size = 10

    # Outline
    "Sets the color of the tooltip outline."
    outline_color = (:black, 0.5)
    "Sets the linewidth of the tooltip outline."
    outline_linewidth = 2f0
    "Sets the linestyle of the tooltip outline."
    outline_linestyle = nothing

    mixin_generic_plot_attributes()...
    transparency = true

    inspectable = false
end

function convert_arguments(::Type{<: Tooltip}, x::Real, y::Real, str::AbstractString)
    return (Point2{float_type(x, y)}(x, y), str)
end
function convert_arguments(::Type{<: Tooltip}, x::Real, y::Real)
    return (Point2{float_type(x, y)}(x, y),)
end

function plot!(plot::Tooltip{<:Tuple{<:VecTypes, <:AbstractString}})
    tooltip!(plot, Attributes(plot), plot[1]; text = plot[2])
    plot
end

struct ToolTipShape
    placement::Symbol
    align::Float32
    triangle_size::Float32
end


function rounded_corner(center::Tuple, r, start_angle, end_angle, steps=4)
    angles = range(start_angle, stop=end_angle, length=steps)
    return [Vec2f(center) .+ r .* Vec2f(cos(a), sin(a)) for a in angles]
end

function (tt::ToolTipShape)(origin::Vec2, size::Vec2)
    l, b = origin
    w, h = size
    r, t = (l, b) .+ (w, h)
    s = tt.triangle_size
    cr = 5  # Default to 0 if not specified

    # Helper function to create rounded corner points
    function rounded_corner(center_x, center_y, radius, start_angle, end_angle, num_points=8)
        if radius <= 0
            return Point2f[(center_x, center_y)]
        end
        angles = range(start_angle, end_angle, length=num_points)
        return [Point2f(center_x + radius * cos(a), center_y + radius * sin(a)) for a in angles]
    end

    # tt.placement refers to the tooltip relative to the pointed at position
    # i.e. left means that the tooltip is to the left, with the triangle pointing right
    if tt.placement === :left
        points = Point2f[]

        # Bottom-left corner
        append!(points, rounded_corner(l + cr, b + cr, cr, π, 3π/2))

        # Bottom edge to triangle start
        push!(points, Point2f(r, b))
        push!(points, Point2f(r, b + tt.align * h - 0.5s))

        # Triangle
        push!(points, Point2f(r + s, b + tt.align * h))
        push!(points, Point2f(r, b + tt.align * h + 0.5s))

        # Continue to top-right corner
        push!(points, Point2f(r, t - cr))
        append!(points, rounded_corner(r - cr, t - cr, cr, 0, π/2))

        # Top edge
        push!(points, Point2f(l + cr, t))

        # Top-left corner
        append!(points, rounded_corner(l + cr, t - cr, cr, π/2, π))

        # Left edge back to start
        push!(points, Point2f(l, b + cr))

        return points

    elseif tt.placement === :right
        points = Point2f[]

        # Start at bottom-left, after corner
        push!(points, Point2f(l, b + cr))

        # Bottom-left corner
        append!(points, rounded_corner(l + cr, b + cr, cr, π, 3π/2))

        # Bottom edge
        push!(points, Point2f(r - cr, b))

        # Bottom-right corner
        append!(points, rounded_corner(r - cr, b + cr, cr, 3π/2, 2π))

        # Right edge to triangle
        push!(points, Point2f(r, b + tt.align * h - 0.5s))

        # Triangle
        push!(points, Point2f(r + s, b + tt.align * h))
        push!(points, Point2f(r, b + tt.align * h + 0.5s))

        # Continue right edge
        push!(points, Point2f(r, t - cr))

        # Top-right corner
        append!(points, rounded_corner(r - cr, t - cr, cr, 0, π/2))

        # Top edge
        push!(points, Point2f(l + cr, t))

        # Top-left corner
        append!(points, rounded_corner(l + cr, t - cr, cr, π/2, π))

        return points

    elseif tt.placement in (:below, :down, :bottom)
        points = Point2f[]

        # Start at bottom-left corner
        push!(points, Point2f(l, b + cr))
        append!(points, rounded_corner(l + cr, b + cr, cr, π, 3π/2))

        # Bottom edge
        push!(points, Point2f(r - cr, b))

        # Bottom-right corner
        append!(points, rounded_corner(r - cr, b + cr, cr, 3π/2, 2π))

        # Right edge
        push!(points, Point2f(r, t - cr))

        # Top-right corner
        append!(points, rounded_corner(r - cr, t - cr, cr, 0, π/2))

        # Top edge to triangle
        push!(points, Point2f(l + tt.align * w + 0.5s, t))

        # Triangle
        push!(points, Point2f(l + tt.align * w, t + s))
        push!(points, Point2f(l + tt.align * w - 0.5s, t))

        # Continue top edge
        push!(points, Point2f(l + cr, t))

        # Top-left corner
        append!(points, rounded_corner(l + cr, t - cr, cr, π/2, π))

        return points

    elseif tt.placement in (:above, :up, :top)
        points = Point2f[]

        # Start at bottom-left after triangle
        push!(points, Point2f(l, b + cr))

        # Bottom-left corner
        append!(points, rounded_corner(l + cr, b + cr, cr, π, 3π/2))

        # Bottom edge to triangle
        push!(points, Point2f(l + tt.align * w - 0.5s, b))

        # Triangle
        push!(points, Point2f(l + tt.align * w, b - s))
        push!(points, Point2f(l + tt.align * w + 0.5s, b))

        # Continue bottom edge
        push!(points, Point2f(r - cr, b))

        # Bottom-right corner
        append!(points, rounded_corner(r - cr, b + cr, cr, 3π/2, 2π))

        # Right edge
        push!(points, Point2f(r, t - cr))

        # Top-right corner
        append!(points, rounded_corner(r - cr, t - cr, cr, 0, π/2))

        # Top edge
        push!(points, Point2f(l + cr, t))

        # Top-left corner
        append!(points, rounded_corner(l + cr, t - cr, cr, π/2, π))

        return points

    else
        @error "Tooltip placement $(tt.placement) invalid. Assuming :above"
        # Default to :above case with rounded corners
        points = Point2f[]

        push!(points, Point2f(l, b + cr))
        append!(points, rounded_corner(l + cr, b + cr, cr, π, 3π/2))
        push!(points, Point2f(l + tt.align * w - 0.5s, b))
        push!(points, Point2f(l + tt.align * w, b - s))
        push!(points, Point2f(l + tt.align * w + 0.5s, b))
        push!(points, Point2f(r - cr, b))
        append!(points, rounded_corner(r - cr, b + cr, cr, 3π/2, 2π))
        push!(points, Point2f(r, t - cr))
        append!(points, rounded_corner(r - cr, t - cr, cr, 0, π/2))
        push!(points, Point2f(l + cr, t))
        append!(points, rounded_corner(l + cr, t - cr, cr, π/2, π))

        return points
    end
end

function plot!(p::Tooltip{<:Tuple{<:VecTypes}})

    shape = map(ToolTipShape, p, p.placement, p.align, p.triangle_size)

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

    textpadding = map(to_lrbt_padding, p, p.textpadding)

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
    p = textlabel!(
        p, p[1], p.text, shape = shape,

        padding = textpadding, justification = p.justification, text_align = text_align,
        offset = text_offset, fontsize = p.fontsize, font = p.font,

        draw_on_top = false,

        text_color = p.textcolor,
        text_strokewidth = p.strokewidth,
        text_strokecolor = p.strokecolor,

        background_color = p.backgroundcolor,
        strokewidth = p.outline_linewidth,
        strokecolor = p.outline_color,
        linestyle = p.outline_linestyle,
        miter_limit = pi/18,

        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable,
    )

    return p
end
