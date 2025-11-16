function initialize_block!(sl::Slider)

    topscene = sl.blockscene

    sliderrange = sl.range

    onany(sl.linewidth, sl.horizontal) do lw, horizontal
        if horizontal
            sl.layoutobservables.autosize[] = (nothing, Float32(lw))
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
            [
                Point2f(left(bb) + h / 2, y),
                Point2f(right(bb) - h / 2, y),
            ]
        else
            x = left(bb) + w / 2
            [
                Point2f(x, bottom(bb) + w / 2),
                Point2f(x, top(bb) - w / 2),
            ]
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
    selected_index[] = closest_index(sliderrange[], sl.startvalue[] === automatic ? zero(eltype(sliderrange[])) : sl.startvalue[])

    middlepoint = lift(topscene, endpoints, displayed_sliderfraction) do ep, sf
        Point2f(ep[1] .+ sf .* (ep[2] .- ep[1]))
    end

    linepoints = lift(topscene, endpoints, middlepoint) do eps, middle
        [eps[1], middle, middle, eps[2]]
    end

    linecolors = lift(topscene, sl.color_active_dimmed, sl.color_inactive) do ca, ci
        [ca, ci]
    end

    endbuttons = scatter!(
        topscene, endpoints, color = linecolors,
        markersize = sl.linewidth, strokewidth = 0, inspectable = false, marker = Circle
    )

    linesegs = linesegments!(
        topscene, linepoints, color = linecolors,
        linewidth = sl.linewidth, inspectable = false
    )

    button_magnification = Observable(1.0)
    buttonsize = lift(*, topscene, sl.linewidth, button_magnification)
    button = scatter!(
        topscene, middlepoint, color = sl.color_active, strokewidth = 0,
        markersize = buttonsize, inspectable = false, marker = Circle
    )

    mouseevents = addmouseevents!(topscene, sl.layoutobservables.computedbbox)

    onmouseleftdrag(mouseevents) do event
        dragging[] = true
        dif = event.px - event.prev_px
        fraction = clamp(
            if sl.horizontal[]
                (event.px[1] - endpoints[][1][1]) / (endpoints[][2][1] - endpoints[][1][1])
            else
                (event.px[2] - endpoints[][1][2]) / (endpoints[][2][2] - endpoints[][1][2])
            end, 0, 1
        )

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
        selected_index[] = closest_index(sliderrange[], sl.startvalue[] === automatic ? zero(eltype(sliderrange[])) : sl.startvalue[])
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
    return sl
end

function valueindex(sliderrange, value)
    for (i, val) in enumerate(sliderrange)
        if val == value
            return i
        end
    end
    return nothing
end

function closest_fractionindex(sliderrange, fraction)
    n = length(sliderrange)
    onestepfrac = 1 / (n - 1)
    i = round(Int, fraction / onestepfrac) + 1
    return min(max(i, 1), n)
end

function closest_index(sliderrange, value)
    for (i, val) in enumerate(sliderrange)
        if val == value
            return i
        end
    end
    # if the value wasn't found this way try inexact
    return closest_index_inexact(sliderrange, value)
end

function closest_index_inexact(sliderrange, value::Number)
    _, selected_i = findmin(sliderrange) do val
        abs(val - value)
    end
    return selected_i
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
    return slider.range[][closest]
end
