# `hovered` is an index into the VISIBLE (filtered) options; `m.i_selected` always
# references the ORIGINAL options, so the selection highlight maps through
# `filtered_indices` (search support, API as in MakieOrg/Makie.jl#5642).
function _update_option_colors!(hovered, optionstrings, optionpolycolors, optiontextcolors, m,
                                filtered_indices)
    n = length(optionstrings[])
    resize!(optionpolycolors.val, n)
    resize!(optiontextcolors.val, n)
    base_textcolor = to_color(m.textcolor[])
    active_textcolor = to_color(m.textcolor_active[])
    for idx in 1:n
        global_idx = idx <= length(filtered_indices[]) ? filtered_indices[][idx] : idx
        if global_idx == m.i_selected[]
            optionpolycolors.val[idx] = m.cell_color_active[]
            optiontextcolors.val[idx] = active_textcolor
        elseif idx == hovered
            optionpolycolors.val[idx] = m.cell_color_hover[]
            optiontextcolors.val[idx] = base_textcolor
        else
            optionpolycolors.val[idx] = iseven(idx) ?
                to_color(m.cell_color_inactive_even[]) :
                to_color(m.cell_color_inactive_odd[])
            optiontextcolors.val[idx] = base_textcolor
        end
    end
    notify(optionpolycolors)
    notify(optiontextcolors)
    return
end

function _pick_entry(y, menuscene, list_y_bounds)
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

function _mouse_up(butt, was_pressed)
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

block_kwargs(::Type{Menu}) = Set([:default])
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

    # search support (API of MakieOrg/Makie.jl#5642): typing while the dropdown
    # is open filters the VISIBLE options; `i_selected`/`selection` always refer
    # to the original options via `filtered_indices`.
    is_searchable = m.searchable[]
    search_text = Observable(""; ignore_equal_values = true)
    optionstrings_all = lift(o -> optionlabel.(o), blockscene, m.options; ignore_equal_values = true)
    filtered_indices = lift(blockscene, optionstrings_all, search_text, m.filter;
                            ignore_equal_values = true) do strings, query, filter_fn
        isempty(query) ? collect(eachindex(strings)) :
            [i for (i, s) in enumerate(strings) if filter_fn(query, s)]
    end
    optionstrings = lift(blockscene, optionstrings_all, filtered_indices) do strings, idx
        strings[idx]
    end

    selected_text = lift(blockscene, m.prompt, m.i_selected, search_text, m.is_open;
                         ignore_equal_values = true) do prompt, i_selected, query, open
        if open && is_searchable
            isempty(query) ? m.search_placeholder[] : query * "▏"
        elseif i_selected == 0
            prompt
        else
            optionstrings_all[][i_selected]
        end
    end

    if is_searchable
        # typing goes into the query while the dropdown is open; keys are consumed
        # so application shortcuts (single-letter editor keys!) don't fire mid-search
        on(blockscene, blockscene.events.unicode_input) do chars
            (m.is_open[] && Makie.receives_events(blockscene)) || return Consume(false)
            s = chars isa AbstractVector ? String(collect(chars)) : string(chars)
            isempty(s) && return Consume(false)
            search_text[] = search_text[] * s
            return Consume(true)
        end
        on(blockscene, blockscene.events.keyboardbutton; priority = 10) do ev
            (m.is_open[] && Makie.receives_events(blockscene)) || return Consume(false)
            ev.action in (Keyboard.press, Keyboard.repeat) || return Consume(false)
            if ev.key == Keyboard.backspace
                isempty(search_text[]) || (search_text[] = String(chop(search_text[])))
                return Consume(true)
            elseif ev.key == Keyboard.enter
                idx = filtered_indices[]
                isempty(idx) || (m.i_selected[] = first(idx))
                m.is_open[] = false
                return Consume(true)
            elseif ev.key == Keyboard.escape
                m.is_open[] = false
                return Consume(true)
            end
            # swallow plain typing keys (they arrive as unicode_input); modified
            # chords (Ctrl+…) stay application shortcuts
            mods = blockscene.events.keyboardstate
            ctrl = Keyboard.left_control in mods || Keyboard.right_control in mods
            return Consume(!ctrl)
        end
        on(blockscene, m.is_open) do open
            open || (search_text[] = "")
            return
        end
    end

    selectionarea = Observable(Rect2d(0, 0, 0, 0); ignore_equal_values = true)

    button_hovered = Observable(false)
    selectionpoly_color = lift(
        blockscene, button_hovered, m.selection_cell_color_inactive,
        m.cell_color_hover
    ) do hovered, inactive, hover
        hovered ? to_color(hover) : to_color(inactive)
    end
    selectionpoly = poly!(
        blockscene, selectionarea, color = selectionpoly_color;
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

    # band-aid fix for resizing before display
    on(optionstrings) do strings
        N = length(strings)
        if N != length(textpositions[])
            resize!(textpositions[], N)
            notify(textpositions)
        end
        return
    end

    optionrects = Observable([Rect2d(0, 0, 0, 0)]; ignore_equal_values = true)
    optionpolycolors = Observable(RGBAf[RGBAf(0.5, 0.5, 0.5, 1)]; ignore_equal_values = true)
    optiontextcolors = Observable(fill(to_color(m.textcolor[]), length(optionstrings[])); ignore_equal_values = true)

    # the y boundaries of the list rectangles
    list_y_bounds = Ref(Float32[])

    optionpolys = poly!(menuscene, optionrects, color = optionpolycolors, inspectable = false)

    optiontexts = text!(
        menuscene, textpositions, text = optionstrings, align = (:left, :center),
        fontsize = m.fontsize, color = optiontextcolors, inspectable = false
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

        pad = m.textpadding[]
        # campixel is absolute, so anchor the list at the menuscene viewport
        # origin. `list_y_bounds` are likewise in absolute window y.
        ox, oy = Float32(left(bbox)), Float32(bottom(bbox))
        heights_cumsum = [zero(eltype(heights)); cumsum(heights)]
        list_y_bounds[] = oy .+ (h .- heights_cumsum)
        texts_y = @views h .- 0.5 .* (heights_cumsum[1:(end - 1)] .+ heights_cumsum[2:end])
        textpositions[] = Point2f.(ox + pad[1], oy .+ texts_y)
        w_bbox = width(bbox)
        resize!(optionrects.val, length(heights))

        optionrects.val .= map(eachindex(heights)) do i
            BBox(ox, ox + w_bbox, oy + h - heights_cumsum[i + 1], oy + h - heights_cumsum[i])
        end

        _update_option_colors!(0, optionstrings, optionpolycolors, optiontextcolors, m, filtered_indices)
        notify(optionrects)
        return
    end
    notify(optionstrings)


    was_inside_options = Ref(false)
    was_inside_button = Ref(false)

    e = menuscene.events

    # Up events are notoriusly hard,
    # especially if we want to react only to presses that went down inside an element & went up inside
    # was pressed needs to be tracked per item, and also needs to be invalidated outside `mouse_up`
    # which makes the state handling especially annoying
    # TODO, move this back to mousestatemachine, which does exactly this
    was_pressed_options = Ref(false)
    was_pressed_button = Ref(false)

    onany(blockscene, e.mouseposition, e.mousebutton; priority = 64) do position, butt
        # Inert when hidden or when another scene covers the pointer.
        Makie.receives_events(blockscene) || return Consume(false)
        # optionrects and list_y_bounds are in absolute window coords (campixel
        # is absolute); offset by the menuscene's translation for the scroll
        # state when hit-testing.
        mp = Point2f(position) .- Vec2f(translation(menuscene)[][1], translation(menuscene)[][2])
        is_over_options = false
        is_over_button = false

        if Makie.is_mouseinside(menuscene) # the whole scene containing all options
            # We entered the dropdown — the button cleanup below is short-circuited
            # by the early return, so reset the button's hover indicator here.
            if was_inside_button[]
                was_inside_button[] = false
                button_hovered[] = false
            end
            # Is inside the expanded menu selection (optionrects cover the whole
            # selectable area, hit-tested with the translation-adjusted `mp`)
            if any(r -> mp in r, optionpolys[1][])
                is_over_options = true
                was_inside_options[] = true
                if _mouse_up(butt, was_pressed_options) # PRESSED
                    picked = _pick_entry(position[2], menuscene, list_y_bounds)
                    # the picked row is a VISIBLE index — map to the original option
                    if picked in eachindex(filtered_indices[])
                        m.i_selected[] = filtered_indices[][picked]
                    end
                    m.is_open[] = false
                else # HOVER
                    idx_hovered = _pick_entry(position[2], menuscene, list_y_bounds)
                    _update_option_colors!(idx_hovered, optionstrings, optionpolycolors, optiontextcolors, m, filtered_indices)
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
                was_inside_button[] = true
                if _mouse_up(butt, was_pressed_button) # PRESSED
                    m.is_open[] = !m.is_open[]
                    if m.is_open[]
                        t = translation(menuscene)[]
                        y_for_top_align = height(menuscene.viewport[]) - listheight[]
                        translate!(menuscene, t[1], y_for_top_align, t[3])
                    end
                    return Consume(true)
                else # HOVER
                    button_hovered[] = true
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
        if !is_over_options && was_inside_options[] # going from being inside to outside
            was_inside_options[] = false
            _update_option_colors!(0, optionstrings, optionpolycolors, optiontextcolors, m, filtered_indices)
        end
        if !is_over_button && was_inside_button[]
            was_inside_button[] = false
            button_hovered[] = false
        end
        # if mouse got over anything else, we close the menu
        if !is_over_button && !is_over_options && butt.button == Mouse.left && butt.action == Mouse.press
            m.is_open[] = false
        end
        return Consume(false)
    end

    on(blockscene, menuscene.events.scroll; priority = 61) do (x, y)
        Makie.receives_events(blockscene) || return Consume(false)
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

        # if there is a current selection, check if it still exists in the new options
        if should_search
            new_i = 0 # default to nothing selected

            for (i, o) in enumerate(options)
                # if one of the new options is equivalent to the old options, we choose it for continuity
                if old_selection == optionvalue(o) && old_selected_text == optionlabel(o)
                    new_i = i
                    break
                end
            end

            # trigger eventual selection actions
            m.i_selected = new_i
        end
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
    notify(ComputePipeline.get_observable!(m.is_open))

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
