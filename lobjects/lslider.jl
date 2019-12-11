function LSlider(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LSlider))

    decorations = Dict{Symbol, Any}()

    @extract attrs (
        halign, valign, linewidth, buttonradius_inactive, horizontal,
        buttonradius_active, startvalue, value, color_active, color_inactive,
        color_active, buttonstrokewidth, buttoncolor_inactive
    )

    sliderrange = attrs.range

    sizeattrs = sizenode!(attrs.width, attrs.height)
    alignment = lift(tuple, halign, valign)

    suggestedbbox = create_suggested_bboxnode(bbox)

    computedsize = computedsizenode!(sizeattrs)

    finalbbox = alignedbboxnode!(suggestedbbox, computedsize, alignment, sizeattrs)

    endpoints = lift(finalbbox, horizontal) do bb, horizontal

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

    buttonpoint = lift(finalbbox, horizontal, displayed_sliderfraction) do bb, horizontal, sf
        if horizontal
            [Point2f0(left(bb) + width(bb) * sf, bottom(bb) + height(bb) / 2)]
        else
            [Point2f0(left(bb) + 0.5f0 * width(bb), bottom(bb) + sf * height(bb))]
        end
    end

    linepoints = lift(endpoints, buttonpoint) do eps, bp
        [eps[1], bp[1], bp[1], eps[2]]
    end

    linecolors = lift(color_active, color_inactive) do ca, ci
        [ca, ci]
    end

    linesegs = linesegments!(parent, linepoints, color = linecolors, linewidth = linewidth, raw = true)[end]

    linestate = addmousestate!(parent, linesegs)

    onmouseclick(linestate) do state
        pos = state.pos
        dim = horizontal[] ? 1 : 2
        frac = (pos[dim] - endpoints[][1][dim]) / (endpoints[][2][dim] - endpoints[][1][dim])
        selected_index[] = closest_fractionindex(sliderrange[], frac)
    end

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
            dif[1] / width(finalbbox[])
        else
            dif[2] / height(finalbbox[])
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

    onmousedoubleclick(buttonstate) do state
        selected_index[] = closest_index(sliderrange[], startvalue[])
    end

    protrusions = lift(buttonradius_active, horizontal) do br, horizontal
        if horizontal
            RectSides{Float32}(br, br, 0, 0)
        else
            RectSides{Float32}(0, 0, br, br)
        end
    end

    layoutnodes = LayoutNodes(suggestedbbox, protrusions, computedsize, finalbbox)

    # trigger bbox
    suggestedbbox[] = suggestedbbox[]

    LSlider(parent, layoutnodes, attrs, decorations)
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
