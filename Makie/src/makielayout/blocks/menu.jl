function initialize_block!(m::Menu; default = 1)
    blockscene = m.blockscene

    listheight = Observable(0.0; ignore_equal_values = true)
    # the direction is auto-chosen as up if there is too little space below and if the space below
    # is smaller than above
    _direction = Observable{Symbol}(:none; ignore_equal_values = true)

    map!(blockscene, _direction, m.layoutobservables.computedbbox, m.direction) do bb, dir
        if dir == Makie.automatic
            pxa = viewport(blockscene)[]
            bottomspace = abs(bottom(pxa) - bottom(bb))
            topspace = abs(top(pxa) - top(bb))
            # slight preference for down
            if bottomspace >= listheight[] || bottomspace > topspace
                return :down
            else
                return :up
            end
        else
            return dir::Symbol
        end
    end

    scenearea = Observable(Rect2i(0, 0, 0, 0), ignore_equal_values = true)
    map!(
        blockscene, scenearea, m.layoutobservables.computedbbox, listheight, _direction, m.is_open;
        update = true
    ) do bbox, h, d, open
        if open
            return round_to_IRect2D(
                BBox(
                    left(bbox),
                    right(bbox),
                    d === :down ? max(0, bottom(bbox) - h) : top(bbox),
                    d === :down ? bottom(bbox) : min(top(bbox) + h, top(blockscene.viewport[]))
                )
            )
        else
            # If the scene is not visible the scene placement and size does not
            # matter for rendering. We still need to set the size to 0 for
            # interactions though.
            return Rect2i(0, 0, 0, 0)
        end
    end

    menuscene = Scene(blockscene, scenearea, camera = campixel!, clear = true, visible = m.is_open)
    translate!(menuscene, 0, 0, 200)

    onany(blockscene, scenearea, listheight) do area, listheight
        t = translation(menuscene)[]
        y = t[2]
        new_y = max(min(0, y), height(area) - listheight)
        translate!(menuscene, t[1], new_y, t[3])
    end

    optionstrings = lift(o -> optionlabel.(o), blockscene, m.options; ignore_equal_values = true)

    selected_text = lift(blockscene, m.prompt, m.i_selected; ignore_equal_values = true) do prompt, i_selected
        if i_selected == 0
            prompt
        else
            optionstrings[][i_selected]
        end
    end

    selectionarea = Observable(Rect2d(0, 0, 0, 0); ignore_equal_values = true)

    selectionpoly = poly!(
        blockscene, selectionarea, color = m.selection_cell_color_inactive[];
        inspectable = false
    )
    selectiontextpos = Observable(Point2f(0, 0); ignore_equal_values = true)
    selectiontext = text!(
        blockscene, selectiontextpos, text = selected_text, align = (:left, :center),
        fontsize = m.fontsize, color = m.textcolor, markerspace = :data, inspectable = false
    )

    onany(blockscene, selected_text, m.fontsize, m.textpadding) do _, _, (l, r, b, t)
        bb = boundingbox(selectiontext, :data)
        m.layoutobservables.autosize[] = width(bb) + l + r, height(bb) + b + t
    end
    notify(selected_text)

    on(blockscene, m.layoutobservables.computedbbox) do cbb
        selectionarea[] = Rect2d(origin(cbb), widths(cbb))
        ch = height(cbb)
        selectiontextpos[] = cbb.origin + Point2f(m.textpadding[][1], ch / 2)
    end

    textpositions = Observable(zeros(Point2f, length(optionstrings[])); ignore_equal_values = true)

    optionrects = Observable([Rect2d(0, 0, 0, 0)]; ignore_equal_values = true)
    optionpolycolors = Observable(RGBAf[RGBAf(0.5, 0.5, 0.5, 1)]; ignore_equal_values = true)

    function update_option_colors!(hovered)
        n = length(optionstrings[])
        resize!(optionpolycolors.val, n)
        map!(optionpolycolors.val, 1:n) do idx
            if idx == m.i_selected[]
                return m.cell_color_active[]
            elseif idx == hovered
                return m.cell_color_hover[]
            else
                if iseven(idx)
                    to_color(m.cell_color_inactive_even[])
                else
                    to_color(m.cell_color_inactive_odd[])
                end
            end
        end
        return notify(optionpolycolors)
    end

    # the y boundaries of the list rectangles
    list_y_bounds = Ref(Float32[])

    optionpolys = poly!(menuscene, optionrects, color = optionpolycolors, inspectable = false)

    optiontexts = text!(
        menuscene, textpositions, text = optionstrings, align = (:left, :center),
        fontsize = m.fontsize, inspectable = false
    )

    # listheight needs to be up to date before showing the menuscene so that its
    # direction is correct
    gc_heights = map(blockscene, fast_string_boundingboxes_obs(optiontexts), m.textpadding) do bbs, pad
        heights = map(size -> size[2] + pad[3] + pad[4], widths.(bbs))
        h = sum(heights)
        listheight[] = h
        return (heights, h)
    end

    onany(blockscene, gc_heights, scenearea) do (heights, h), bbox
        # No need to update when the scene is hidden
        widths(bbox) == Vec2i(0) && return

        pad = m.textpadding[] # gc_heights triggers on padding, so we don't need to react to it
        # listheight[] = h

        heights_cumsum = [zero(eltype(heights)); cumsum(heights)]
        list_y_bounds[] = h .- heights_cumsum
        texts_y = @views h .- 0.5 .* (heights_cumsum[1:(end - 1)] .+ heights_cumsum[2:end])
        textpositions[] = Point2f.(pad[1], texts_y)
        w_bbox = width(bbox)
        # need to manipulate the vectors themselves, otherwise update errors when lengths change
        resize!(optionrects.val, length(heights))

        optionrects.val .= map(eachindex(heights)) do i
            BBox(0, w_bbox, h - heights_cumsum[i + 1], h - heights_cumsum[i])
        end

        update_option_colors!(0)
        notify(optionrects)
        return
    end
    notify(optionstrings)

    function pick_entry(y)
        # determine which rectangle in the list the mouse is in
        # we do this geometrically and not by picking because it's hard to calculate the index
        # of the text from the picking value returned
        # translation due to scrolling has to be removed first
        ytrans = y - translation(menuscene)[][2]
        return argmin(
            i -> abs(ytrans - 0.5 * (list_y_bounds[][i + 1] + list_y_bounds[][i])),
            1:(length(list_y_bounds[]) - 1)
        )
    end

    was_inside_options = false
    was_inside_button = false

    e = menuscene.events

    # Up events are notoriusly hard,
    # especially if we want to react only to presses that went down inside an element & went up inside
    # was pressed needs to be tracked per item, and also needs to be invalidated outside `mouse_up`
    # which makes the state handling especially annoying
    # TODO, move this back to mousestatemachine, which does exactly this
    was_pressed_options = Ref(false)
    was_pressed_button = Ref(false)
    function mouse_up(butt, was_pressed)
        if butt.button == Mouse.left
            if butt.action == Mouse.press
                was_pressed[] = true
                return false
            elseif butt.action == Mouse.release && was_pressed[]
                was_pressed[] = false
                return true
            end
        end
        was_pressed[] = false
        return false
    end

    onany(blockscene, e.mouseposition, e.mousebutton; priority = 64) do position, butt
        mp = screen_relative(menuscene, position)
        # track if we have been inside menu/options to clean up if we haven't been
        is_over_options = false
        is_over_button = false

        if Makie.is_mouseinside(menuscene) # the whole scene containing all options
            # Is inside the expanded menu selection (the polys cover the whole
            # selectable area and are in pixel space relative to menuscene)
            if any(r -> mp in r, optionpolys[1][])
                is_over_options = true
                was_inside_options = true
                # we either clicked on an item or hover it
                if mouse_up(butt, was_pressed_options) # PRESSED
                    i = pick_entry(mp[2])
                    m.i_selected[] = i
                    m.is_open[] = false
                else # HOVER
                    idx_hovered = pick_entry(mp[2])
                    update_option_colors!(idx_hovered)
                end
            else
                # If not inside anymore, invalidate was_pressed
                was_pressed_options[] = false
            end
            return Consume(true)
        else
            # If not inside menuscene, we check the state for the menu button
            # (use position because selectionpoly is in blockscene)
            if position in selectionpoly.converted[][1]
                # If over, we either click it to open/close the menu, or we just hover it
                is_over_button = true
                was_inside_button = true
                if mouse_up(butt, was_pressed_button) # PRESSED
                    m.is_open[] = !m.is_open[]
                    if m.is_open[]
                        t = translation(menuscene)[]
                        y_for_top_align = height(menuscene.viewport[]) - listheight[]
                        translate!(menuscene, t[1], y_for_top_align, t[3])
                    end
                    return Consume(true)
                else # HOVER
                    selectionpoly.color = m.cell_color_hover[]
                end
            else
                # If not inside anymore, invalidate was_pressed
                was_pressed_button[] = false
            end
        end
        # Make sure we clean up all was_pressed states, if mouse got released
        if butt.action == Mouse.release
            was_pressed_options[] = false
            was_pressed_button[] = false
        end

        # clean up hovers if we're outside
        if !is_over_options && was_inside_options # going from being inside to outside
            was_inside_options = false
            update_option_colors!(0)
        end
        if !is_over_button && was_inside_button
            was_inside_button = false
            selectionpoly.color = m.selection_cell_color_inactive[]
        end
        # if mouse got over anything else, we close the menu
        if !is_over_button && !is_over_options && butt.button == Mouse.left && butt.action == Mouse.press
            m.is_open[] = false
        end
        return Consume(false)
    end

    on(blockscene, menuscene.events.scroll; priority = 61) do (x, y)
        if is_mouseinside(menuscene)
            t = translation(menuscene)[]
            # Hack to differentiate mousewheel and trackpad scrolling
            step = m.scroll_speed[] * y
            new_y = max(min(t[2] - step, 0), height(menuscene.viewport[]) - listheight[])
            translate!(menuscene, t[1], new_y, t[3])
            return Consume(true)
        else
            return Consume(false)
        end
    end

    on(blockscene, m.options) do options
        # Make sure i_selected is on a valid index when the contentgrid updates
        old_selection = m.selection[]
        old_selected_text = selected_text[]
        should_search = m.i_selected[] > 0
        m.i_selected.val = 0

        new_i = 0 # default to nothing selected
        # if there is a current selection, check if it still exists in the new options
        if should_search
            for (i, o) in enumerate(options)
                # if one of the new options is equivalent to the old options, we choose it for continuity
                if old_selection == optionvalue(o) && old_selected_text == optionlabel(o)
                    new_i = i
                    break
                end
            end
        end

        # trigger eventual selection actions
        m.i_selected[] = new_i
    end
    symbol_pos = lift(blockscene, selectionarea, m.textpadding) do sa, tp
        return mean(rightline(sa)) - Point2f(tp[2], 0)
    end
    dropdown_arrow = scatter!(
        blockscene, symbol_pos;
        marker = lift(iso -> iso ? :utriangle : :dtriangle, blockscene, m.is_open),
        markersize = m.dropdown_arrow_size,
        color = m.dropdown_arrow_color,
        strokecolor = :transparent,
        inspectable = false
    )

    translate!(dropdown_arrow, 0, 0, 1)

    on(blockscene, m.i_selected) do i
        if i == 0
            m.selection[] = nothing
        else
            # collect in case options is a zip or other generator without indexing
            option = collect(m.options[])[i]

            # only update the selection value if the new value is actually different
            # this is because i_selected can also be changed when the options themselves
            # are mutated, and there could still be the same option in the list
            # just at a different place, so that should not trigger a selection
            newvalue = optionvalue(option)
            if m.selection[] != newvalue
                m.selection[] = newvalue
            end
        end
    end

    if default === nothing
        m.i_selected[] = 0
    elseif default isa Integer
        Base.checkbounds(optionstrings[], default)
        m.i_selected[] = default
    else
        i = findfirst(x -> x == default, optionstrings[])
        if i === nothing
            error("Initial menu selection was set to $(default) but that was not found in the option names.")
        end
        m.i_selected[] = i
    end
    notify(m.is_open)

    # trigger bbox
    notify(m.layoutobservables.suggestedbbox)

    return
end

function optionlabel(option)
    return string(option)
end

function optionlabel(option::Tuple{Any, Any})
    return string(option[1])
end

function optionvalue(option)
    return option
end

function optionvalue(option::Tuple{Any, Any})
    return option[2]
end
