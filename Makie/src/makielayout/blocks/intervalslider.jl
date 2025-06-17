function initialize_block!(isl::IntervalSlider)

    blockscene = isl.blockscene

    onany(isl.linewidth, isl.horizontal) do lw, horizontal
        if horizontal
            isl.layoutobservables.autosize[] = (nothing, Float32(lw))
        else
            isl.layoutobservables.autosize[] = (Float32(lw), nothing)
        end
    end

    sliderbox = lift(identity, isl.layoutobservables.computedbbox)

    endpoints = lift(sliderbox, isl.horizontal) do bb, horizontal

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
    selected_indices = Observable((1, 1))
    setfield!(isl, :selected_indices, selected_indices)

    # the fraction on the slider corresponding to the selected_indices
    # this is only used after dragging
    sliderfractions = lift(isl.selected_indices, isl.range) do is, r
        map(is) do i
            (i - 1) / (length(r) - 1)
        end
    end

    dragging = Observable(false)

    # what the slider actually displays currently (also during dragging when
    # the slider position is in an "invalid" position given the slider's range)
    displayed_sliderfractions = Observable((0.0, 0.0))
    setfield!(isl, :displayed_sliderfractions, displayed_sliderfractions)

    on(sliderfractions) do fracs
        # only update displayed fraction through sliderfraction if not dragging
        # dragging overrides the value so there is clear mouse interaction
        if !dragging[]
            displayed_sliderfractions[] = fracs
        end
    end

    # when the range is changed, switch to closest interval
    on(isl.range) do rng
        isl.selected_indices[] = closest_index.(Ref(rng), isl.interval[])
    end

    on(isl.selected_indices) do is
        isl.interval[] = getindex.(Ref(isl.range[]), is)
    end

    # initialize slider value with closest from range
    isl.selected_indices[] = if isl.startvalues[] === Makie.automatic
        (1, lastindex(isl.range[]))
    else
        closest_index.(Ref(isl.range[]), isl.startvalues[])
    end

    middlepoints = lift(endpoints, displayed_sliderfractions) do ep, sfs
        [Point2f(ep[1] .+ sf .* (ep[2] .- ep[1])) for sf in sfs]
    end

    linepoints = lift(endpoints, middlepoints) do eps, middles
        [eps[1], middles[1], middles[1], middles[2], middles[2], eps[2]]
    end

    linecolors = lift(isl.color_active_dimmed, isl.color_inactive) do ca, ci
        [ci, ca, ci]
    end

    endbuttoncolors = lift(isl.color_active_dimmed, isl.color_inactive) do ca, ci
        [ci, ci]
    end

    endbuttons = scatter!(
        blockscene, endpoints, color = endbuttoncolors,
        markersize = isl.linewidth, strokewidth = 0, inspectable = false, marker = Circle
    )

    linesegs = linesegments!(
        blockscene, linepoints, color = linecolors,
        linewidth = isl.linewidth, inspectable = false
    )

    state = Observable(:none)
    button_magnifications = lift(state) do state
        if state === :none
            [1.0, 1.0]
        elseif state === :min
            [1.25, 1.0]
        elseif state === :both
            [1.25, 1.25]
        else
            [1.0, 1.25]
        end
    end
    buttonsizes = @lift($(isl.linewidth) .* $button_magnifications)
    buttons = scatter!(
        blockscene, middlepoints, color = isl.color_active, strokewidth = 0,
        markersize = buttonsizes, inspectable = false, marker = Circle
    )

    mouseevents = addmouseevents!(blockscene, isl.layoutobservables.computedbbox)

    # we need to record where a drag started for the case where the center of the
    # range is shifted, because the difference in indices always needs to stay the same
    # and the slider is moved relative to this start position
    startfraction = Ref(0.0)
    start_disp_fractions = Ref((0.0, 0.0))
    startindices = Ref((1, 1))

    onmouseleftdrag(mouseevents) do event

        dragging[] = true
        fraction = if isl.horizontal[]
            (event.px[1] - endpoints[][1][1]) / (endpoints[][2][1] - endpoints[][1][1])
        else
            (event.px[2] - endpoints[][1][2]) / (endpoints[][2][2] - endpoints[][1][2])
        end
        fraction = clamp(fraction, 0, 1)

        if state[] in (:min, :max)
            if isl.snap[]
                snapindex = closest_fractionindex(isl.range[], fraction)
                fraction = (snapindex - 1) / (length(isl.range[]) - 1)
            end
            if state[] === :min
                # if the mouse crosses over the current max, reverse
                if fraction > displayed_sliderfractions[][2]
                    state[] = :max
                    displayed_sliderfractions[] = (displayed_sliderfractions[][2], fraction)
                else
                    displayed_sliderfractions[] = (fraction, displayed_sliderfractions[][2])
                end
            else
                # if the mouse crosses over the current min, reverse
                if fraction < displayed_sliderfractions[][1]
                    state[] = :min
                    displayed_sliderfractions[] = (fraction, displayed_sliderfractions[][1])
                else
                    displayed_sliderfractions[] = (displayed_sliderfractions[][1], fraction)
                end
            end
            newindices = closest_fractionindex.(Ref(isl.range[]), displayed_sliderfractions[])

            if isl.selected_indices[] != newindices
                isl.selected_indices[] = newindices
            end
        elseif state[] === :both
            fracdif = fraction - startfraction[]

            clamped_fracdif = clamp(fracdif, -start_disp_fractions[][1], 1 - start_disp_fractions[][2])

            ntarget = round(Int, length(isl.range[]) * clamped_fracdif)

            nlow = -startindices[][1] + 1
            nhigh = length(isl.range[]) - startindices[][2]
            nchange = clamp(ntarget, nlow, nhigh)

            newindices = startindices[] .+ nchange

            displayed_sliderfractions[] = if isl.snap[]
                (newindices .- 1) ./ (length(isl.range[]) - 1)
            else
                start_disp_fractions[] .+ clamped_fracdif
            end

            if isl.selected_indices[] != newindices
                isl.selected_indices[] = newindices
            end
        end

        return Consume(true)
    end

    onmouseleftdragstop(mouseevents) do event
        dragging[] = false
        # adjust slider to closest legal value
        sliderfractions[] = sliderfractions[]
        return Consume(true)
    end

    onmouseleftdown(mouseevents) do event

        pos = event.px

        dim = isl.horizontal[] ? 1 : 2
        frac = clamp(
            (pos[dim] - endpoints[][1][dim]) / (endpoints[][2][dim] - endpoints[][1][dim]),
            0, 1
        )

        startfraction[] = frac
        startindices[] = isl.selected_indices[]
        start_disp_fractions[] = displayed_sliderfractions[]

        if state[] in (:both, :none)
            return Consume(true)
        end

        newindex = closest_fractionindex(isl.range[], frac)
        if abs(newindex - isl.selected_indices[][1]) < abs(newindex - isl.selected_indices[][2])
            isl.selected_indices[] = (newindex, isl.selected_indices[][2])
        else
            isl.selected_indices[] = (isl.selected_indices[][1], newindex)
        end
        # linecolors[] = [color_active[], color_inactive[]]

        return Consume(true)
    end

    onmouseleftdoubleclick(mouseevents) do event
        isl.selected_indices[] = isl.selected_indices[] = if isl.startvalues[] === Makie.automatic
            (1, lastindex(isl.range[]))
        else
            closest_index.(Ref(isl.range[]), isl.startvalues[])
        end

        return Consume(true)
    end

    onmouseover(mouseevents) do event
        fraction = if isl.horizontal[]
            (event.px[1] - endpoints[][1][1]) / (endpoints[][2][1] - endpoints[][1][1])
        else
            (event.px[2] - endpoints[][1][2]) / (endpoints[][2][2] - endpoints[][1][2])
        end
        fraction = clamp(fraction, 0, 1)

        buttondistance = displayed_sliderfractions[][2] - displayed_sliderfractions[][1]

        state[] = if fraction < displayed_sliderfractions[][1] + 0.25 * buttondistance
            :min
        elseif fraction < displayed_sliderfractions[][1] + 0.75 * buttondistance
            :both
        else
            :max
        end

        return Consume(false)
    end

    onmouseout(mouseevents) do event
        state[] = :none
        return Consume(false)
    end

    # trigger autosize through linewidth for first layout
    isl.linewidth[] = isl.linewidth[]

    return
end


"""
Set the `slider` to the values in the slider's range that are closest to `v1` and `v2`, and return those values ordered min, misl.
"""
function set_close_to!(intervalslider::IntervalSlider, v1, v2)
    mima = minmax(v1, v2)
    indices = closest_index.(Ref(intervalslider.range[]), mima)
    intervalslider.selected_indices[] = indices
    return getindex.(Ref(intervalslider.range[]), indices)
end
