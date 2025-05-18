function initialize_block!(sl::Slider)

    topscene = sl.blockscene
    #why name this?
    sliderrange = sl.range

    #=onany(f, args...; weak::Bool = false, priority::Int = 0, update::Bool = false)
    Calls f on updates to any observable refs in args. args may contain any number of Observable objects. f will
    be passed the values contained in the refs as the respective argument. All other objects in args are passed
    as-is.=#
    onany(sl.linewidth, sl.horizontal) do lw, horizontal
        if horizontal
            sl.layoutobservables.autosize[] = (nothing, Float32(lw)) #What is sl.layoutobservables.autosize[]? It is not in the list of attributes in the macro
        else
            sl.layoutobservables.autosize[] = (Float32(lw), nothing)
        end
    end

    sliderbox = lift(identity, topscene, sl.layoutobservables.computedbbox)

    endpoints = lift(topscene, sliderbox, sl.horizontal) do bb, horizontal

        h = height(bb)
        w = width(bb)

        if horizontal
            y = bottom(bb) + h / 2
            [Point2f(left(bb) + h/2, y),
             Point2f(right(bb) - h/2, y)]
        else
            x = left(bb) + w / 2
            [Point2f(x, bottom(bb) + w/2),
             Point2f(x, top(bb) - w/2)]
        end
    end

    # this is the index of the selected value in the slider's range
    selected_index = Observable(1)
    setfield!(sl, :selected_index, selected_index)

    # the fraction on the slider corresponding to the selected_index
    # this is only used after dragging
    sliderfraction = lift(topscene, selected_index, sliderrange) do i, r
        (i - 1) / (length(r) - 1)
    end

    dragging = Observable(false)

    # what the slider actually displays currently (also during dragging when
    # the slider position is in an "invalid" position given the slider's range)
    displayed_sliderfraction = Observable(0.0)

    on(topscene, sliderfraction) do frac
        # only update displayed fraction through sliderfraction if not dragging
        # dragging overrides the value so there is clear mouse interaction
        if !dragging[]
            displayed_sliderfraction[] = frac
        end
    end

    # when the range is changed, switch to closest value
    on(topscene, sliderrange) do rng
        selected_index[] = closest_index(rng, sl.value[])
    end

    onany(topscene, selected_index, dragging) do i, dragging
        new_val = get(sliderrange[], i, nothing)
        has_value = !isnothing(new_val)
        has_changed = sl.value[] != new_val
        drag_updates = sl.update_while_dragging[] || !dragging[]
        if has_value && has_changed && drag_updates
            sl.value[] = new_val
        end
    end
    sl.value[] = sliderrange[][selected_index[]]
    # initialize slider value with closest from range
    selected_index[] = closest_index(sliderrange[], sl.startvalue[])

    middlepoint = lift(topscene, endpoints, displayed_sliderfraction) do ep, sf
        Point2f(ep[1] .+ sf .* (ep[2] .- ep[1]))
    end

    linepoints = lift(topscene, endpoints, middlepoint) do eps, middle
        [eps[1], middle, middle, eps[2]]
    end

    linecolors = lift(topscene, sl.color_active_dimmed, sl.color_inactive) do ca, ci
        [ca, ci]
    end

    endbuttons = scatter!(topscene, endpoints, color = linecolors,
        markersize = sl.linewidth, strokewidth = 0, inspectable = false, marker=Circle)

    linesegs = linesegments!(topscene, linepoints, color = linecolors,
        linewidth = sl.linewidth, inspectable = false)

    button_magnification = Observable(1.0)
    buttonsize = lift(*, topscene, sl.linewidth, button_magnification)
    button = scatter!(topscene, middlepoint, color = sl.color_active, strokewidth = 0,
        markersize = buttonsize, inspectable = false, marker=Circle)

    mouseevents = addmouseevents!(topscene, sl.layoutobservables.computedbbox)

    onmouseleftdrag(mouseevents) do event
        dragging[] = true
        dif = event.px - event.prev_px
        fraction = clamp(if sl.horizontal[]
            (event.px[1] - endpoints[][1][1]) / (endpoints[][2][1] - endpoints[][1][1])
        else
            (event.px[2] - endpoints[][1][2]) / (endpoints[][2][2] - endpoints[][1][2])
        end, 0, 1)

        newindex = closest_fractionindex(sliderrange[], fraction)
        if sl.snap[]
            fraction = (newindex - 1) / (length(sliderrange[]) - 1)
        end
        displayed_sliderfraction[] = fraction

        if selected_index[] != newindex
            selected_index[] = newindex
        end

        return Consume(true)
    end

    onmouseleftdragstop(mouseevents) do event
        dragging[] = false
        # adjust slider to closest legal value
        sliderfraction[] = sliderfraction[]
        linecolors[] = [sl.color_active_dimmed[], sl.color_inactive[]]
        return Consume(true)
    end

    onmouseleftdown(mouseevents) do event
        pos = event.px
        dim = sl.horizontal[] ? 1 : 2
        frac = (pos[dim] - endpoints[][1][dim]) / (endpoints[][2][dim] - endpoints[][1][dim])
        selected_index[] = closest_fractionindex(sliderrange[], frac)
        # linecolors[] = [color_active[], color_inactive[]]
        return Consume(true)
    end

    onmouseleftdoubleclick(mouseevents) do event
        selected_index[] = closest_index(sliderrange[], sl.startvalue[])
        return Consume(true)
    end

    onmouseenter(mouseevents) do event
        button_magnification[] = 1.25
        return Consume(false)
    end

    onmouseout(mouseevents) do event
        button_magnification[] = 1.0
        linecolors[] = [sl.color_active_dimmed[], sl.color_inactive[]]
        return Consume(false)
    end

    # trigger autosize through linewidth for first layout
    notify(sl.linewidth)
    sl
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
    for (i, val) in enumerate(sliderrange)
        if val == value
            return i
        end
    end
    # if the value wasn't found this way try inexact
    closest_index_inexact(sliderrange, value)
end

function closest_index_inexact(sliderrange, value)
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

"""
    set_close_to!(slider, value) -> closest_value

Set the `slider` to the value in the slider's range that is closest to `value` and return this value.
This function should be used to set a slider to a value programmatically, rather than
mutating its value observable directly, which doesn't update the slider visually.
"""
function set_close_to!(slider::Slider, value)
    closest = closest_index(slider.range[], value)
    slider.selected_index = closest
    slider.range[][closest]
end

function initialize_block!(sl::Slider2)
    topscene = sl.blockscene
    xrange, yrange = sl.xrange[], sl.yrange[]

    selected_indices = Observable((1, 1))
    setfield!(sl, :selected_indices, selected_indices)

    dragging = Observable(false)
    displayed_fraction = Observable((0.0, 0.0))

    sliderfraction = lift(topscene, selected_indices, sl.xrange, sl.yrange) do (ix, iy), xr, yr
        fx = (ix - 1) / (length(xr) - 1)
        fy = (iy - 1) / (length(yr) - 1)
        (fx, fy)
    end

    on(topscene, sliderfraction) do frac
        if !dragging[]
            displayed_fraction[] = frac
        end
    end

    on(topscene, sl.xrange) do xr
        selected_indices[] = (closest_index(xr, sl.value[][1]), selected_indices[][2])
    end
    on(topscene, sl.yrange) do yr
        selected_indices[] = (selected_indices[][1], closest_index(yr, sl.value[][2]))
    end

    onany(topscene, selected_indices, dragging) do (ix, iy), dragging
        new_val = (get(sl.xrange[], ix, nothing), get(sl.yrange[], iy, nothing))
        has_changed = sl.value[] != new_val
        drag_updates = sl.update_while_dragging[] || !dragging[]
        if !isnothing(new_val[1]) && !isnothing(new_val[2]) && has_changed && drag_updates
            sl.value[] = new_val
        end
    end

    sl.value[] = (xrange[selected_indices[][1]], yrange[selected_indices[][2]])
    selected_indices[] = (closest_index(xrange, sl.startvalue[][1]),
                          closest_index(yrange, sl.startvalue[][2]))

    bbox = lift(identity, topscene, sl.layoutobservables.computedbbox)
    trackpoint = lift(topscene, bbox, displayed_fraction) do bb, (fx, fy)
        x = left(bb) + fx * width(bb)
        y = bottom(bb) + fy * height(bb)
        Point2f(x, y)
    end

    background = lift(topscene, bbox) do bb
        # Return a polygon representing the full bounding rectangle
        [
            Point2f(left(bb), bottom(bb)),
            Point2f(left(bb), top(bb)),
            Point2f(right(bb), top(bb)),
            Point2f(right(bb), bottom(bb))
        ]
    end

    poly!(topscene, background, color = sl.color_inactive)

    cross = lift(topscene, bbox, trackpoint) do bb, p
        [
            Point2f(left(bb), p[2]), Point2f(right(bb), p[2]),
            Point2f(p[1], bottom(bb)), Point2f(p[1], top(bb))
        ]
    end

    linesegments!(topscene, cross, color = sl.color_active_dimmed, linewidth = 2)

    hovered = Observable(false)

    scatter!(
        topscene, lift(p -> [p], trackpoint),
        color = sl.color_active,
        markersize = lift(hovered) do h
            h ? 20.0 : 12.0
        end,
    )


    mouseevents = addmouseevents!(topscene, sl.layoutobservables.computedbbox)

    onmouseleftdrag(mouseevents) do event
        dragging[] = true
        bb = bbox[]
        fx = clamp((event.px[1] - left(bb)) / width(bb), 0, 1)
        fy = clamp((event.px[2] - bottom(bb)) / height(bb), 0, 1)

        newx = closest_fractionindex(sl.xrange[], fx)
        newy = closest_fractionindex(sl.yrange[], fy)
        if sl.snap[]
            fx = (newx - 1) / (length(sl.xrange[]) - 1)
            fy = (newy - 1) / (length(sl.yrange[]) - 1)
        end
        displayed_fraction[] = (fx, fy)

        if selected_indices[] != (newx, newy)
            selected_indices[] = (newx, newy)
        end

        return Consume(true)
    end

    onmouseleftdragstop(mouseevents) do event
        dragging[] = false
        sliderfraction[] = sliderfraction[]
        return Consume(true)
    end

    onmouseleftdoubleclick(mouseevents) do event
        selected_indices[] = (closest_index(sl.xrange[], sl.startvalue[][1]),
                              closest_index(sl.yrange[], sl.startvalue[][2]))
        return Consume(true)
    end

    onmouseleftclick(mouseevents) do event
        bb = bbox[]
        fx = clamp((event.px[1] - left(bb)) / width(bb), 0, 1)
        fy = clamp((event.px[2] - bottom(bb)) / height(bb), 0, 1)

        newx = closest_fractionindex(sl.xrange[], fx)
        newy = closest_fractionindex(sl.yrange[], fy)

        if sl.snap[]
            fx = (newx - 1) / (length(sl.xrange[]) - 1)
            fy = (newy - 1) / (length(sl.yrange[]) - 1)
        end

        displayed_fraction[] = (fx, fy)

        if selected_indices[] != (newx, newy)
            selected_indices[] = (newx, newy)
        end

        return Consume(true)
    end


    onmouseover(mouseevents) do event
        hovered[] = true
        return Consume(false)
    end

    onmouseout(mouseevents) do event
        hovered[] = false
        return Consume(false)
    end

    sl
end

