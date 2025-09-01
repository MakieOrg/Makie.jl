"""
    tooltip(positions, string)
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
    backgroundcolor = :white
    "Sets the size of the triangle pointing at `position`."
    triangle_size = 10

    # Outline
    "Sets the color of the tooltip outline."
    outline_color = :black
    "Sets the linewidth of the tooltip outline."
    outline_linewidth = 2.0f0
    "Sets the linestyle of the tooltip outline."
    outline_linestyle = nothing

    mixin_generic_plot_attributes()...
    inspectable = false
    "If true the tooltip will be rendered at maximum z."
    draw_on_top = false

    # Only used for DataInspector
    _formatter = nothing
end

function convert_arguments(::Type{<:Tooltip}, xy, str::AbstractString)
    return (convert_arguments(PointBased(), xy)[1], [str])
end

function convert_arguments(::Type{<:Tooltip}, x, y, str::AbstractString)
    return (convert_arguments(PointBased(), x, y)[1], [str])
end

function convert_arguments(::Type{<:Tooltip}, x, y, z, str::AbstractString)
    return (convert_arguments(PointBased(), x, y, z)[1], [str])
end

function convert_arguments(::Type{<:Tooltip}, xy, str::AbstractArray{<:AbstractString})
    return (convert_arguments(PointBased(), xy)[1], str)
end

function convert_arguments(::Type{<:Tooltip}, x, y, str::AbstractArray{<:AbstractString})
    return (convert_arguments(PointBased(), x, y)[1], str)
end

function convert_arguments(::Type{<:Tooltip}, x, y, z, str::AbstractArray{<:AbstractString})
    return (convert_arguments(PointBased(), x, y, z)[1], str)
end

convert_arguments(::Type{<:Tooltip}, args...) = convert_arguments(PointBased(), args...)

struct ToolTipShape
    placement::Symbol
    align::Float32
    triangle_size::Float32
end

function (tt::ToolTipShape)(origin::VecTypes{2}, size::VecTypes{2})
    l, b = origin
    w, h = size
    r, t = (l, b) .+ (w, h)
    s = tt.triangle_size

    # tt.placement refers to the tooltip relative to the pointed at position
    # i.e. left means that the tooltip is to the left, with the triangle pointing right
    if tt.placement === :left
        return Point2f[
            (l, b), (l, t), (r, t),
            (r, b + tt.align * h + 0.5s),
            (r + s, b + tt.align * h),
            (r, b + tt.align * h - 0.5s),
            (r, b), (l, b),
        ]
    elseif tt.placement === :right
        return Point2f[
            (l, b),
            (l, b + tt.align * h - 0.5s),
            (l - s, b + tt.align * h),
            (l, b + tt.align * h + 0.5s),
            (l, t), (r, t), (r, b), (l, b),
        ]
    elseif tt.placement in (:below, :down, :bottom)
        return Point2f[
            (l, b), (l, t),
            (l + tt.align * w - 0.5s, t),
            (l + tt.align * w, t + s),
            (l + tt.align * w + 0.5s, t),
            (r, t), (r, b), (l, b),
        ]
    elseif tt.placement in (:above, :up, :top)
        return Point2f[
            (l, b), (l, t), (r, t), (r, b),
            (l + tt.align * w + 0.5s, b),
            (l + tt.align * w, b - s),
            (l + tt.align * w - 0.5s, b),
            (l, b),
        ]
    else
        @error "Tooltip placement $placement invalid. Assuming :above"
        return Point2f[
            (l, b), (l, t), (r, t), (r, b),
            (l + tt.align * w + 0.5s, b),
            (l + tt.align * w, b - s),
            (l + tt.align * w - 0.5s, b),
            (l, b),
        ]
    end
end


function plot!(p::Tooltip)

    map!(p, [:converted, :text], [:positions, :extracted_text]) do args, text
        if args isa Tuple{<:AbstractArray{<:VecTypes}, <:AbstractArray{<:AbstractString}}
            return args
        else
            return args[1], text
        end
    end

    map!(ToolTipShape, p, [:placement, :align, :triangle_size], :shape)

    map!(p, [:placement, :align], :text_align) do placement, align
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

    map!(to_lrbt_padding, p, [:textpadding], :text_padding)

    map!(p, [:offset, :textpadding, :triangle_size, :placement, :align], :text_offset) do o, pad, ts, placement, align
        l, r, b, t = pad

        if placement === :left
            return Vec2f(-o - r - ts, b - align * (b + t))
        elseif placement === :right
            return Vec2f(o + l + ts, b - align * (b + t))
        elseif placement in (:below, :down, :bottom)
            return Vec2f(l - align * (l + r), -o - t - ts)
        elseif placement in (:above, :up, :top)
            return Vec2f(l - align * (l + r), o + b + ts)
        else
            @error "Tooltip placement $placement invalid. Assuming :above"
            return Vec2f(0, o + b + ts)
        end
    end

    p = textlabel!(
        p, p.positions,
        text = p.extracted_text, shape = p.shape,

        padding = p.text_padding, justification = p.justification, text_align = p.text_align,
        offset = p.text_offset, fontsize = p.fontsize, font = p.font,

        draw_on_top = p.draw_on_top,

        text_color = p.textcolor,
        text_strokewidth = p.strokewidth,
        text_strokecolor = p.strokecolor,

        background_color = p.backgroundcolor,
        strokewidth = p.outline_linewidth,
        strokecolor = p.outline_color,
        linestyle = p.outline_linestyle,
        miter_limit = pi / 18,

        transparency = p.transparency, visible = p.visible,
        overdraw = p.overdraw, depth_shift = p.depth_shift,
        inspectable = p.inspectable,
    )

    return p
end
