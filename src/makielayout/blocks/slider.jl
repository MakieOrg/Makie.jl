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
            sl.layoutobservables.autosize[] = (nothing, Float32(lw)) #What is sl.layoutobservables.autosize[]? It is not in the list of attributes in the
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


    endbuttons = scatter!(topscene, endpoints,
        markersize = sl.linewidth, strokewidth = 0, inspectable = false, marker=Circle)

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
    println("hello")
    topscene = sl.blockscene 

    sliderxrange = sl.xrange
    slideryrange = sl.yrange

    #what does this do? assigns an autosize. Why onany()?
    onany(sl.linewidth) do lw
        sl.layoutobservables.autosize[] = (Float32(lw), Float32(lw))
    end

    sliderbox = lift(identity, topscene, sl.layoutobservables.computedbbox)

    #what will endpoints be used for? We need 4 corners instead?
    endpoints = lift(topscene, sliderbox) do bb
        h = height(bb)
        w = width(bb)

        ###################
        #debugging
        println(bb)
        println("w = $w")
        println("h = $h")
        bbtop = top(bb)
        bbbottom = bottom(bb)
        bbleft = left(bb)
        bbright = right(bb)
        println("top = $bbtop")
        println("bottom = $bbbottom")
        println("right = $bbright")
        println("left = $bbleft")
        ###################

        y = bottom(bb) + h / 2
        [Point2f(left(bb) + h/2, y),
            Point2f(right(bb) - h/2, y)]
    end

    println(endpoints)

    # this is the index of the selected value in the slider's range
    selected_indices = Observable((1, 1))
    setfield!(sl, :selected_indices, selected_indices)

    # the fraction on the slider corresponding to the selected_indices
    # this is only used after dragging
    sliderfractions = lift(sl.selected_indices, sliderxrange, slideryrange) do is, xr, yr
        xfrac = (is[1] - 1) / (length(xr) - 1)
        yfrac = (is[2] - 1) / (length(yr) - 1)
        return (xfrac,yfrac)
    end

    dragging = Observable(false)

    # when the range is changed, switch to closest value
    on(topscene, sliderxrange) do rng
        selected_indices[][1] = closest_index(rng, sl.value[][1])
    end

    on(topscene, slideryrange) do rng
        selected_indices[][2] = closest_index(rng, sl.value[][2])
    end
    
    #worried about observable nonsense in here
    onany(topscene, selected_indices, dragging) do i, dragging
        new_xval = get(sliderxrange[], i[][1], nothing)
        new_yval = get(slideryrange[], i[][2], nothing)

        has_xvalue = !isnothing(new_xval)
        has_yvalue = !isnothing(new_yval)

        has_changed = sl.value[] != (new_xval,new_yval)
        drag_updates = sl.update_while_dragging[] || !dragging[]

        if has_xvalue && has_yvalue && has_changed && drag_updates
            sl.value[] = (new_xval,new_yval)
        end
    end
    
    sl.value[] = (sliderxrange[][selected_indices[][1]],slideryrange[][selected_indices[][2]])

    # initialize slider values with closest from ranges
    selxidx = closest_index(sliderxrange[], sl.startvalue[][1])
    selyidx = closest_index(slideryrange[], sl.startvalue[][2])
    println("x_idx = $selxidx")
    println("y_idx = $selyidx")
    println(selected_indices)
    #selected_indices[] = (selxidx,selyidx) #this throws an error from calling getindex on a tuple(Int,Int) with no index, and I can't figure out where this is happening.

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