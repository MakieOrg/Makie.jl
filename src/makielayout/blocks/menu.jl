function block_docs(::Type{Menu})
    """
    A drop-down menu with multiple selectable options. You can pass options
    with the keyword argument `options`.

    Options are given as an iterable of elements.
    For each element, the option label in the menu is determined with `optionlabel(element)`
    and the option value with `optionvalue(element)`. These functions can be
    overloaded for custom types. The default is that tuples of two elements are expected to be label and value,
    where `string(label)` is used as the label, while for all other objects, label = `string(object)` and value = object.

    When an item is selected in the menu, the menu's `selection` attribute is set to
    `optionvalue(selected_element)`. When nothing is selected, that value is `nothing`.

    You can set the initial selection by passing one of the labels with the `default` keyword.

    ## Constructors

    ```julia
    Menu(fig_or_scene; default = nothing, kwargs...)
    ```

    ## Examples

    Menu with string entries, second preselected:

    ```julia
    menu1 = Menu(fig[1, 1], options = ["first", "second", "third"], default = "second")
    ```

    Menu with two-element entries, label and function:

    ```julia
    funcs = [sin, cos, tan]
    labels = ["Sine", "Cosine", "Tangens"]

    menu2 = Menu(fig[1, 1], options = zip(labels, funcs))
    ```

    Executing a function when a selection is made:

    ```julia
    on(menu2.selection) do selected_function
        # do something with the selected function
    end
    ```
    """
end


function initialize_block!(m::Menu; default = nothing)
    blockscene = m.blockscene

    listheight = Observable(0.0)

    # the direction is auto-chosen as up if there is too little space below and if the space below
    # is smaller than above
    _direction = Observable{Symbol}()
    map!(_direction, m.layoutobservables.computedbbox, m.direction) do bb, dir
        if dir == Makie.automatic
            pxa = pixelarea(blockscene)[]
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

    scenearea = lift(m.layoutobservables.computedbbox, listheight, _direction, m.is_open) do bbox, h, d, open
        !open ?
            round_to_IRect2D(BBox(left(bbox), right(bbox), 0, 0)) :
            round_to_IRect2D(BBox(
                left(bbox),
                right(bbox),
                d == :down ? max(0, bottom(bbox) - h) : top(bbox),
                d == :down ? bottom(bbox) : min(top(bbox) + h, top(blockscene.px_area[]))))
    end

    menuscene = Scene(blockscene, scenearea, camera = campixel!)
    translate!(menuscene, 0, 0, 21)

    onany(scenearea, listheight) do area, listheight
        t = translation(menuscene)[]
        y = t[2]
        new_y = max(min(0, y), height(area) - listheight)
        translate!(menuscene, t[1], new_y, t[3])
    end

    optionstrings = lift(o -> optionlabel.(o), m.options)

    selected_text = lift(m.prompt, m.i_selected) do prompt, i_selected
        if i_selected == 0
            prompt
        else
            optionstrings[][i_selected]
        end
    end

    selectionarea = Observable(Rect2f(0, 0, 0, 0))

    selectionpoly = poly!(
        blockscene, selectionarea, color = m.selection_cell_color_inactive[];
        inspectable = false
    )

    selectiontextpos = Observable(Point2f(0, 0))
    selectiontext = text!(
        blockscene, selectiontextpos, text = selected_text, align = (:left, :center),
        textsize = m.textsize, color = m.textcolor, markerspace = :data, inspectable = false
    )

    onany(selected_text, m.textsize, m.textpadding) do _, _, (l, r, b, t)
        bb = boundingbox(selectiontext)
        m.layoutobservables.autosize[] = width(bb) + l + r, height(bb) + b + t
    end
    notify(selected_text)

    on(m.layoutobservables.computedbbox) do cbb
        selectionarea[] = cbb
        ch = height(cbb)
        selectiontextpos[] = cbb.origin + Point2f(m.textpadding[][1], ch/2)
    end

    textpositions = Observable(zeros(Point2f, length(optionstrings[])))
    
    me_selection = addmouseevents!(blockscene, selectiontext, selectionpoly)
    onmouseleftclick(me_selection) do me
        m.is_open[] = !m.is_open[]
        if m.is_open[]
            t = translation(menuscene)[]
            y_for_top_align = height(menuscene.px_area[]) - listheight[]
            translate!(menuscene, t[1], y_for_top_align, t[3])
        end
        return Consume(true)
    end

    onmouseover(me_selection) do me
        selectionpoly.color = m.cell_color_hover[]
        return Consume(false)
    end

    onmouseout(me_selection) do me
        selectionpoly.color = m.selection_cell_color_inactive[]
        return Consume(false)
    end

    optionrects = Observable([Rect2f(0, 0, 0, 0)])
    optionpolycolors = Observable(RGBAf[RGBAf(0.5, 0.5, 0.5, 1)])

    # the y boundaries of the list rectangles
    list_y_bounds = Ref(Float32[])

    optionpolys = poly!(menuscene, optionrects, color = optionpolycolors, inspectable = false)
    optiontexts = text!(menuscene, textpositions, text = optionstrings, align = (:left, :center),
        textsize = m.textsize, inspectable = false)

    onany(optionstrings, m.textpadding, m.layoutobservables.computedbbox) do _, pad, bbox
        gcs = optiontexts.plots[1][1][]::Vector{GlyphCollection}
        bbs = map(x -> boundingbox(x, zero(Point3f), Quaternion(0, 0, 0, 0)), gcs)
        heights = map(bb -> height(bb) + pad[3] + pad[4], bbs)
        heights_cumsum = [zero(eltype(heights)); cumsum(heights)]
        h = sum(heights)
        list_y_bounds[] = h .- heights_cumsum
        texts_y = @views h .- 0.5 .* (heights_cumsum[1:end-1] .+ heights_cumsum[2:end])
        textpositions[] = Point2f.(pad[1], texts_y)
        listheight[] = h
        w_bbox = width(bbox)
        # need to manipulate the vectors themselves, otherwise update errors when lengths change
        resize!(optionpolycolors.val, length(bbs))
        resize!(optionrects.val, length(bbs))
        optionpolycolors.val .= map(eachindex(bbs)) do i
            i == m.i_selected[] ? m.cell_color_active[] :
            iseven(i) ? to_color(m.cell_color_inactive_even[]) :
                to_color(m.cell_color_inactive_odd[]) 
        end
        optionrects.val .= map(eachindex(bbs)) do i
            BBox(0, w_bbox, h - heights_cumsum[i+1], h - heights_cumsum[i])
        end
        
        notify(optionrects)
    end
    notify(optionstrings)

    mouseevents = addmouseevents!(menuscene, optionpolys, optiontexts, priority = 61)

    function pick_entry(me)
        # determine which rectangle in the list the mouse is in
        # we do this geometrically and not by picking because it's hard to calculate the index
        # of the text from the picking value returned
        y = me.px[2]
        # translation due to scrolling has to be removed first
        ytrans = y - translation(menuscene)[][2]
        i = argmin(
            i -> abs(ytrans - 0.5 * (list_y_bounds[][i+1] + list_y_bounds[][i])),
            1:length(list_y_bounds[])-1
        )
    end

    onmouseover(mouseevents) do me
        i = pick_entry(me)
        optionpolycolors[] = map(eachindex(optionstrings[])) do j
            j == m.i_selected[] ? m.cell_color_active[] :
            i == j ? m.cell_color_hover[] :
                iseven(i) ? to_color(m.cell_color_inactive_even[]) :
                to_color(m.cell_color_inactive_odd[]) 
        end
        return Consume(false)
    end

    onmouseout(mouseevents) do me
        optionpolycolors[] = map(eachindex(optionstrings[])) do i
            i == m.i_selected[] ? m.cell_color_active[] :
            iseven(i) ? to_color(m.cell_color_inactive_even[]) :
                to_color(m.cell_color_inactive_odd[]) 
        end
        return Consume(false)
    end

    onmouseleftclick(mouseevents) do me
        i = pick_entry(me)
        m.i_selected[] = i
        m.is_open[] = false
        return Consume(true)
    end

    # To stop other things from triggering on left down inside the dropdown menu
    onmouseleftdown(_ -> Consume(true), mouseevents)

    # close the menu if the user clicks somewhere else
    # the logic is a bit convoluted because menuscene and selection poly have to be checked at the same time
    on(blockscene.events.mousebutton, priority=61) do butt
        if butt.action === Mouse.release && !is_mouseinside(menuscene) && !(mouseposition_px(blockscene) in selectionarea[])
            m.is_open[] = false
        end
        return Consume(false)
    end

    on(menuscene.events.scroll, priority=61) do (x, y)
        if is_mouseinside(menuscene)
            t = translation(menuscene)[]
            new_y = max(min(t[2] - y, 0), height(menuscene.px_area[]) - listheight[])
            translate!(menuscene, t[1], new_y, t[3])
            return Consume(true)
        else
            return Consume(false)
        end
    end

    on(m.options) do options
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

    dropdown_arrow = scatter!(
        blockscene,
        @lift(mean(rightline($selectionarea)) - Point2f($(m.textpadding)[2], 0)),
        marker = @lift($(m.is_open) ? '▴' : '▾'),
        markersize = m.dropdown_arrow_size,
        color = m.dropdown_arrow_color,
        strokecolor = :transparent,
        inspectable = false)
    translate!(dropdown_arrow, 0, 0, 1)

    on(m.i_selected) do i
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

    m.i_selected[] = if default === nothing
        0
    else
        i = findfirst(x -> x == default, optionstrings[])
        if i === nothing
            error("Initial menu selection was set to $(default) but that was not found in the option names.")
        end
        i
    end
    m.is_open[] = m.is_open[]

    # trigger bbox
    notify(m.layoutobservables.suggestedbbox)

    return
end

function optionlabel(option)
    string(option)
end

function optionlabel(option::Tuple{Any, Any})
    string(option[1])
end

function optionvalue(option)
    option
end

function optionvalue(option::Tuple{Any, Any})
    option[2]
end
