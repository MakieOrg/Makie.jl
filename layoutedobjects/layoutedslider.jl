function LayoutedSlider(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedSlider))

    decorations = Dict{Symbol, Any}()

    @extract attrs (
        alignment, linewidth, buttonradius_inactive, horizontal,
        buttonradius_active, startvalue, value, color_active, color_inactive,
        color_active, buttonstrokewidth, buttoncolor_inactive
    )

    sliderrange = attrs.range
    heightnode = attrs.height
    widthnode = attrs.width

    bboxnode = Node(BBox(0, 100, 0, 100))

    scenearea = Node(IRect(0, 0, 100, 100))

    connect_scenearea_and_bbox_colorbar!(scenearea, bboxnode, widthnode, heightnode, alignment)

    endpoints = lift(bboxnode, horizontal) do bb, horizontal

        if horizontal
            y = bottom(bb) + height(bb) / 2
            [Point2f0(left(bb), y),
            Point2f0(right(bb), y)]
        else
            x = left(bb) + width(bb) / 2
            [Point2f0(x, bottom(bb)),
            Point2f0(x, top(bb))]
        end
    end

    selected_index = Node(1)

    # the fraction on the slider corresponding to the selected_index
    # this is only used after dragging
    sliderfraction = lift(selected_index, sliderrange) do i, r
        (i - 1) / (length(r) - 1)
    end

    dragging = Node(false)

    # what the slider actually displays
    displayed_sliderfraction = Node(0.0)

    on(sliderfraction) do frac
        # only update displayed fraction through sliderfraction if not dragging
        # dragging overrides the value so there is clear mouse interaction
        if !dragging[]
            displayed_sliderfraction[] = frac
        end
    end

    on(selected_index) do i
        value[] = sliderrange[][i]
    end

    # initialize slider value with closest from range
    selected_index[] = closest_index(sliderrange[], startvalue[])

    buttonpoint = lift(bboxnode, horizontal, displayed_sliderfraction) do bb, horizontal, sf
        if horizontal
            [Point2f0(left(bb) + width(bb) * sf, bottom(bb) + height(bb) / 2)]
        else
            [Point2f0(left(bb) + 0.5f0 * width(bb), bottom(bb) + sf * height(bb))]
        end
    end

    line1points = lift(endpoints, buttonpoint) do eps, bp
        [eps[1], bp[1]]
    end
    line2points = lift(endpoints, buttonpoint) do eps, bp
        [bp[1], eps[2]]
    end

    lines!(parent, line1points, color = color_active, linewidth = linewidth, raw = true)
    lines!(parent, line2points, color = color_inactive, linewidth = linewidth, raw = true)

    bsize = Node{Float32}(buttonradius_inactive[] * 2f0)

    bcolor = Node{Any}(buttoncolor_inactive[])
    button = scatter!(parent, buttonpoint, markersize = bsize, color = bcolor,
        strokewidth = buttonstrokewidth, strokecolor = color_active, raw = true)[end]

    buttonstate = addmousestate!(parent, button)

    on(buttonstate) do state
        typ = typeof(state.typ)
        if typ in (MouseDown, MouseDrag, MouseDragStart, MouseDragStop)
            bcolor[] = color_active[]
        end
    end

    onmouseover(buttonstate) do state
        bsize[] = buttonradius_active[] * 2f0
    end

    onmouseout(buttonstate) do state
        bsize[] = buttonradius_inactive[] * 2f0
        bcolor[] = buttoncolor_inactive[]
    end

    onmousedrag(buttonstate) do state
        dragging[] = true
        dif = state.pos - state.prev
        fraction = if horizontal[]
            dif[1] / width(bboxnode[])
        else
            dif[2] / height(bboxnode[])
        end
        if fraction != 0.0f0
            newfraction = min(max(displayed_sliderfraction[] + fraction, 0f0), 1f0)
            displayed_sliderfraction[] = newfraction

            newindex = closest_fractionindex(sliderrange[], newfraction)
            if selected_index[] != newindex
                selected_index[] = newindex
            end
        end
    end

    onmousedragstop(buttonstate) do state
        dragging[] = false
        # adjust slider to closest legal value
        sliderfraction[] = sliderfraction[]
    end

    LayoutedSlider(parent, bboxnode, attrs, decorations)
end

function valueindex(sliderrange, value)
    for (i, val) in enumerate(sliderrange)
        if val == value
            return i
        end
    end
    nothing
end

function closest_fractionindex(sliderrange, fraction)
    n = length(sliderrange)
    onestepfrac = 1 / (n - 1)
    i = round(Int, fraction / onestepfrac) + 1
    min(max(i, 1), n)
end

function closest_index(sliderrange, value)
    distance = Inf
    selected_i = 0
    for (i, val) in enumerate(sliderrange)
        newdist = abs(val - value)
        if newdist < distance
            distance = newdist
            selected_i = i
        end
    end
    selected_i
end

function align_to_bbox!(ls::LayoutedSlider, bbox)
    ls.bboxnode[] = bbox
end

function widthnode(ls::LayoutedSlider)
    node = Node{Union{Nothing, Float32}}(sizenodecontent(ls.attributes.width[]))
    on(ls.attributes.width) do w
        node[] = sizenodecontent(w)
    end
    node
end

function heightnode(ls::LayoutedSlider)
    node = Node{Union{Nothing, Float32}}(sizenodecontent(ls.attributes.height[]))
    on(ls.attributes.height) do h
        node[] = sizenodecontent(h)
    end
    node
end

function protrusionnode(ls::LayoutedSlider)
    br = ls.attributes.buttonradius_active
    node = if ls.horizontal[]
        Node{Union{Nothing, RectSides{Float32}}}(RectSides{Float32}(br[], br[], 0, 0))
    else
        Node{Union{Nothing, RectSides{Float32}}}(RectSides{Float32}(0, 0, br[], br[]))
    end
    onany(br, ls.horizontal) do br, horizontal
        if horizontal
            node[] = RectSides{Float32}(br, br, 0, 0)
        else
            node[] = RectSides{Float32}(0, 0, br, br)
        end
    end
    node
end

defaultlayout(ls::LayoutedSlider) = ProtrusionLayout(ls)

function Base.getproperty(ls::LayoutedSlider, s::Symbol)
    if s in fieldnames(LayoutedSlider)
        getfield(ls, s)
    else
        ls.attributes[s]
    end
end
function Base.propertynames(ls::LayoutedSlider)
    [fieldnames(LayoutedSlider)..., keys(ls.attributes)...]
end
