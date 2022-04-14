function block_docs(::Type{Menu})
    Markdown.md"""
    A drop-down menu with multiple selectable options. You can pass options
    with the keyword argument `options`.
    
    Options are given as an iterable of elements.
    For each element, the option label in the menu is determined with `optionlabel(element)`
    and the option value with `optionvalue(element)`. These functions can be
    overloaded for custom types. The default is that tuples of two elements are expected to be label and value,
    where `string(label)` is used as the label, while for all other objects, label = `string(object)` and value = object.

    When an item is selected in the menu, the menu's `selection` attribute is set to
    `optionvalue(selected_element)`.

    ## Examples

    Menu with string entries:

    ```julia
    menu1 = Menu(scene, options = ["first", "second", "third"])
    ```

    Menu with two-element entries, label and function:

    ```julia
    funcs = [sin, cos, tan]
    labels = ["Sine", "Cosine", "Tangens"]

    menu2 = Menu(scene, options = zip(labels, funcs))
    ```

    Executing a function when a selection is made:

    ```julia
    on(menu2.selection) do selected_function
        # do something with the selected function
    end
    ```
    """
end


function initialize_block!(m::Menu)

    topscene = m.blockscene

    sceneheight = Observable(20.0)

    # the direction is auto-chosen as up if there is too little space below and if the space below
    # is smaller than above
    _direction = Observable{Symbol}()
    map!(_direction, m.layoutobservables.computedbbox, m.direction, sceneheight) do bb, dir, sh
        if dir == Makie.automatic
            pxa = pixelarea(topscene)[]
            if (sh > abs(bottom(pxa) - bottom(bb))) && (abs(bottom(pxa) - bottom(bb)) < abs(top(pxa) - top(bb)))
                return :up
            else
                return :down
            end
        else
            return dir::Symbol
        end
    end

    scenearea = lift(m.layoutobservables.computedbbox, sceneheight, _direction) do bbox, h, d
        round_to_IRect2D(BBox(
            left(bbox),
            right(bbox),
            d == :down ? top(bbox) - h : bottom(bbox),
            d == :down ? top(bbox) : bottom(bbox) + h))
    end

    scene = Scene(topscene, scenearea, camera = campixel!)
    translate!(scene, 0, 0, 21)

    contentgrid = GridLayout(
        bbox = lift(x -> Rect2f(Makie.zero_origin(x)), scenearea),
        valign = @lift($_direction == :down ? :top : :bottom))

    selectionrect = Box(scene, width = nothing, height = nothing,
        color = m.selection_cell_color_inactive[], strokewidth = 0)

    optionstrings = Ref{Vector{String}}(optionlabel.(m.options[]))

    selected_text = lift(m.prompt, m.i_selected) do prompt, i_selected
        if i_selected == 0
            prompt
        else
            optionstrings[][i_selected]
        end
    end

    selectiontext = Label(scene, selected_text, tellwidth = false, halign = :left,
        padding = m.textpadding, textsize = m.textsize, color = m.textcolor)

    allrects = Box[]
    alltexts = Label[]
    mouseeventhandles = MouseEventHandle[]

    on(m.options) do options
        # Make sure i_selected is on a valid index when the contentgrid updates
        old_selection = m.selection[]
        old_selected_text = selected_text[]
        should_search = m.i_selected[] > 0
        m.i_selected.val = 0

        # update string ref before reassembly
        optionstrings[] = optionlabel.(options)

        _reassemble_menu(
            m, scene, selectionrect, selectiontext,
            allrects, alltexts, mouseeventhandles,
            contentgrid, optionstrings
        )


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

    # reassemble for the first time
    _reassemble_menu(
        m, scene, selectionrect, selectiontext,
        allrects, alltexts, mouseeventhandles,
        contentgrid, optionstrings
    )


    dropdown_arrow = scatter!(scene,
        lift(x -> [Point2f(width(x) - 20, (top(x) + bottom(x)) / 2)], selectionrect.layoutobservables.computedbbox),
        marker = @lift($(m.is_open) ? '▴' : '▾'),
        markersize = m.dropdown_arrow_size,
        color = m.dropdown_arrow_color,
        strokecolor = :transparent,
        inspectable = false)
    translate!(dropdown_arrow, 0, 0, 1)


    onany(m.i_selected, m.is_open, contentgrid.layoutobservables.autosize) do i, open, gridautosize

        h = if i == 0
            selectiontext.layoutobservables.autosize[][2]
        else
            alltexts[i+1].layoutobservables.autosize[][2]
        end
        m.layoutobservables.autosize[] = (nothing, h)
        autosize = m.layoutobservables.autosize[]

        (isnothing(gridautosize[2]) || isnothing(autosize[2])) && return

        if open
            sceneheight[] = gridautosize[2]
        else
            sceneheight[] = alltexts[2].layoutobservables.autosize[][2]
        end
    end


    on(_direction) do d
        if d == :down
            contentgrid[:v] = allrects
            contentgrid[:v] = alltexts
        elseif d == :up
            contentgrid[:v] = vcat(allrects[2:end], allrects[1:1])
            contentgrid[:v] = vcat(alltexts[2:end], alltexts[1:1])
        else
            error("Invalid direction $d. Possible values are :up and :down.")
        end
    end

    # trigger size without triggering selection
    m.i_selected[] = m.i_selected[]
    m.is_open[] = m.is_open[]

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

    # close the menu if the user clicks somewhere else
    onmousedownoutside(addmouseevents!(scene, priority=Int8(61))) do events
        if m.is_open[]
            m.is_open[] = !m.is_open[]
        end
        return Consume(false)
    end

    # trigger bbox
    notify(m.layoutobservables.suggestedbbox)
    # notify(direction)

    return
end

function _reassemble_menu(
        m, scene, selectionrect, selectiontext,
        allrects, alltexts, mouseeventhandles,
        contentgrid, optionstrings
    )

    # Clear previous options plots
    for i in length(allrects):-1:2
        delete!(allrects[i])
        delete!(alltexts[i])
    end

    # remove all mouse actions previously connected to rects / texts
    foreach(clear!, mouseeventhandles)

    trim!(contentgrid)

    # Repopulate allrects and all alltexts
    resize!(allrects, length(m.options[])+1)
    resize!(alltexts, length(m.options[])+1)

    allrects[1] = selectionrect
    alltexts[1] = selectiontext

    for i in 1:length(m.options[])
        allrects[i+1] = Box(
            scene, width = nothing, height = nothing,
            color = iseven(i) ? m.cell_color_inactive_even[] : m.cell_color_inactive_odd[],
            strokewidth = 0, visible = m.is_open
        )

        alltexts[i+1] = Label(
            scene, optionstrings[][i], halign = :left, tellwidth = false,
            textsize = m.textsize, color = m.textcolor,
            padding = m.textpadding, visible = m.is_open
        )

        # translate dropdown elements in the foreground
        zshift!(allrects[i+1], 4)
        zshift!(alltexts[i+1], 4)
    end


    contentgrid[1:length(allrects), 1] = allrects
    contentgrid[1:length(alltexts), 1] = alltexts

    rowgap!(contentgrid, 0)

    resize!(mouseeventhandles, length(alltexts))
    map!(mouseeventhandles, eachindex(allrects), allrects) do i, r
        # Use base priority for [Menu   v] and high priority for the dropdown
        # elements that may overlap with out interactive blocks.
        addmouseevents!(
            scene, r.layoutobservables.computedbbox,
            priority = Int8(1) + (i != 1) * Int8(60)
        )
    end

    # create mouse events for each menu entry rect / text combo
    for (i, (mouseeventhandle, r, t)) in enumerate(zip(mouseeventhandles, allrects, alltexts))
        onmouseover(mouseeventhandle) do _
            r.visible[] || return Consume(false)
            (i == m.i_selected[]+1) && return Consume(false)
            r.color = m.cell_color_hover[]
            return Consume(false)
        end

        onmouseout(mouseeventhandle) do _
            r.visible[] || return Consume(false)
            # do nothing for selected items
            (i == m.i_selected[]+1) && return Consume(false)
            if i == 1
                r.color = m.selection_cell_color_inactive[]
            else
                i_option = i - 1
                r.color = iseven(i_option) ? m.cell_color_inactive_even[] : m.cell_color_inactive_odd[]
            end
            return Consume(false)
        end

        onmouseleftdown(mouseeventhandle) do _
            r.visible[] || return Consume(false)
            r.color = m.cell_color_active[]
            if m.is_open[]
                # first item is already selected
                if i > 1
                    # de-highlight previously selected
                    if m.i_selected[] != 0
                        allrects[m.i_selected[] + 1].color = m.cell_color_inactive_even[]
                    end
                    m.i_selected[] = i - 1
                end
            end
            m.is_open[] = !m.is_open[]
            return Consume(true)
        end
    end

    nothing
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
