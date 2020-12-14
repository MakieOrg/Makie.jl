# struct LMenu <: LObject
#     scene::Scene
#     attributes::Attributes
#     layoutobservables::GridLayoutBase.LayoutObservables
#     decorations::Dict{Symbol, Any}
# end

function default_attributes(::Type{LMenu}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the menu."
        height = Auto()
        "The width setting of the menu."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the menu in its suggested bounding box."
        halign = :center
        "The vertical alignment of the menu in its suggested bounding box."
        valign = :center
        "The alignment of the menu in its suggested bounding box."
        alignmode = Inside()
        "Index of selected item"
        i_selected = 0
        "Selected item value"
        selection = nothing
        "Is the menu showing the available options"
        is_open = false
        "Cell color when hovered"
        cell_color_hover = COLOR_ACCENT_DIMMED[]
        "Cell color when active"
        cell_color_active = COLOR_ACCENT[]
        "Cell color when inactive even"
        cell_color_inactive_even = RGBf0(0.97, 0.97, 0.97)
        "Cell color when inactive odd"
        cell_color_inactive_odd = RGBf0(0.97, 0.97, 0.97)
        "Selection cell color when inactive"
        selection_cell_color_inactive = RGBf0(0.94, 0.94, 0.94)
        "Color of the dropdown arrow"
        dropdown_arrow_color = (:black, 0.2)
        "Size of the dropdown arrow"
        dropdown_arrow_size = 12px
        "The list of options selectable in the menu. This can be any iterable of a mixture of strings and containers with one string and one other value. If an entry is just a string, that string is both label and selection. If an entry is a container with one string and one other value, the string is the label and the other value is the selection."
        options = ["no options"]
        "Font size of the cell texts"
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Padding of entry texts"
        textpadding = (10, 10, 10, 10)
        "Color of entry texts"
        textcolor = :black
        "The opening direction of the menu (:up or :down)"
        direction = :down
        "The default message prompting a selection when i == 0"
        prompt = "Select..."
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
    LMenu(parent::Scene; bbox = nothing, kwargs...)

Create a drop-down menu with multiple selectable options. You can pass options
with the keyword argument `options`. Options are given as an iterable of elements.
For each element, the option label in the menu is determined with `optionlabel(element)`
and the option value with `optionvalue(element)`. These functions can be
overloaded for custom types. The default is that tuples of two elements are expected to be label and value,
where `string(label)` is used as the label, while for all other objects, label = `string(object)` and value = object.

When an item is selected in the menu, the menu's `selection` attribute is set to
`optionvalue(selected_element)`.

If the menu is located close to the lower scene border, you can change its open
direction to `direction = :up`.

# Example

Menu with string entries:

```julia
menu1 = LMenu(scene, options = ["first", "second", "third"])
```

Menu with two-element entries, label and function:

```julia
funcs = [sin, cos, tan]
labels = ["Sine", "Cosine", "Tangens"]

menu2 = LMenu(scene, options = zip(labels, funcs))
```

Lifting on the selection value:

```julia
on(menu2.selection) do func
    # do something with the selected function
end
```

LMenu has the following attributes:

$(let
    _, docs, defaults = default_attributes(LMenu, nothing)
    docvarstring(docs, defaults)
end)
"""
LMenu


function LMenu(fig_or_scene; bbox = nothing, kwargs...)

    topscene = get_topscene(fig_or_scene)

    default_attrs = default_attributes(LMenu, topscene).attributes
    theme_attrs = subtheme(topscene, :LMenu)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (halign, valign, i_selected, is_open, cell_color_hover,
        cell_color_inactive_even, cell_color_inactive_odd, dropdown_arrow_color,
        options, dropdown_arrow_size, textsize, selection, cell_color_active,
        textpadding, selection_cell_color_inactive, textcolor, direction, prompt)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables{LMenu}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight,
    halign, valign, attrs.alignmode; suggestedbbox = bbox)


    sceneheight = Node(20.0)



    scenearea = lift(layoutobservables.computedbbox, sceneheight, direction) do bbox, h, d
        round_to_IRect2D(BBox(
            left(bbox),
            right(bbox),
            d == :down ? top(bbox) - h : bottom(bbox),
            d == :down ? top(bbox) : bottom(bbox) + h))
    end

    scene = Scene(topscene, scenearea, raw = true, camera = campixel!)

    contentgrid = GridLayout(
        bbox = lift(x -> FRect2D(AbstractPlotting.zero_origin(x)), scenearea),
        valign = @lift($direction == :down ? :top : :bottom))

    selectionrect = LRect(scene, width = nothing, height = nothing,
        color = selection_cell_color_inactive[], strokewidth = 0)
    

    optionstrings = Ref{Vector{String}}(optionlabel.(options[]))

    selected_text = lift(prompt, i_selected) do prompt, i_selected
        if i_selected == 0
            prompt
        else
            optionstrings[][i_selected]
        end
    end


    selectiontext = LText(scene, selected_text, tellwidth = false, halign = :left,
        padding = textpadding, textsize = textsize, color = textcolor)


    rects = Ref{Vector{LRect}}([])
    texts = Ref{Vector{LText}}([])
    allrects = Ref{Vector{LRect}}([])
    alltexts = Ref{Vector{LText}}([])
    mouseeventhandles = Ref{Vector{MouseEventHandle}}([])

    function reassemble()
        foreach(delete!, rects[])
        foreach(delete!, texts[])
        # remove all mouse actions previously connected to rects / texts
        foreach(clear!, mouseeventhandles[])

        trim!(contentgrid)

        rects[] = [LRect(scene, width = nothing, height = nothing,
            color = iseven(i) ? cell_color_inactive_even[] : cell_color_inactive_odd[],
            strokewidth = 0)
            for i in 1:length(options[])]

        texts[] = [LText(scene, s, halign = :left, tellwidth = false,
            textsize = textsize, color = textcolor,
            padding = textpadding)
            for s in optionstrings[]]
    
        allrects[] = [selectionrect; rects[]]
        alltexts[] = [selectiontext; texts[]]

        contentgrid[1:length(allrects[]), 1] = allrects[]
        contentgrid[1:length(alltexts[]), 1] = alltexts[]

        rowgap!(contentgrid, 0)

        mouseeventhandles[] = [addmouseevents!(scene, r.elements[:rect], t.elements[:text]) for (r, t) in zip(allrects[], alltexts[])]

        # create mouse events for each menu entry rect / text combo
        for (i, (mouseeventhandle, r, t)) in enumerate(zip(mouseeventhandles[], allrects[], alltexts[]))
            onmouseover(mouseeventhandle) do _
                    r.color = cell_color_hover[]
            end

            onmouseout(mouseeventhandle) do _
                if i == 1
                    r.color = selection_cell_color_inactive[]
                else
                    i_option = i - 1
                    r.color = iseven(i_option) ? cell_color_inactive_even[] : cell_color_inactive_odd[]
                end
            end

            onmouseleftdown(mouseeventhandle) do _
                r.color = cell_color_active[]
                if is_open[]
                    # first item is already selected
                    if i > 1
                        i_selected[] = i - 1
                    end
                end
                is_open[] = !is_open[]
            end
        end

        nothing
    end

    on(options) do options

        # update string ref before reassembly
        optionstrings[] = optionlabel.(options)

        reassemble()

        new_i = 0 # default to nothing selected
        # if there is a current selection, check if it still exists in the new options
        if i_selected[] > 0
            for (i, o) in enumerate(options)
                # if one of the new options is equivalent to the old options, we choose it for continuity
                if selection[] == optionvalue(o) && selected_text[] == optionlabel(o)
                    new_i = i
                    break
                end
            end
        end

        # trigger eventual selection actions
        i_selected[] = new_i
    end

    # reassemble for the first time
    reassemble()

    
    dropdown_arrow = scatter!(scene,
        lift(x -> [Point2f0(width(x) - 20, (top(x) + bottom(x)) / 2)], selectionrect.layoutobservables.computedbbox),
        marker = @lift($is_open ? '▴' : '▾'),
        markersize = dropdown_arrow_size,
        color = dropdown_arrow_color,
        strokecolor = :transparent,
        raw = true)[end]
    translate!(dropdown_arrow, 0, 0, 1)


    onany(i_selected, is_open, contentgrid.layoutobservables.autosize) do i, open, gridautosize

        h = if i == 0
            selectiontext.layoutobservables.autosize[][2]
        else
            texts[][i].layoutobservables.autosize[][2]
        end
        layoutobservables.autosize[] = (nothing, h)
        autosize = layoutobservables.autosize[]

        (isnothing(gridautosize[2]) || isnothing(autosize[2])) && return

        if open
            sceneheight[] = gridautosize[2]

            # bring forward
            translate!(scene, 0, 0, 10)

        else
            sceneheight[] = texts[][1].layoutobservables.autosize[][2]

            # back to normal z
            translate!(scene, 0, 0, 0)
            # translate!(dropdown_arrow, 0, -top_border_offset, 1)
        end
    end


    on(direction) do d
        if d == :down
            contentgrid[:v] = allrects[]
            contentgrid[:v] = alltexts[]
        elseif d == :up
            contentgrid[:v] = reverse(allrects[])
            contentgrid[:v] = reverse(alltexts[])
        else
            error("Invalid direction $d. Possible values are :up and :down.")
        end
    end


    # trigger size without triggering selection
    i_selected[] = i_selected[]
    is_open[] = is_open[]

    on(i_selected) do i
        if i == 0
            selection[] = nothing
        else
            # collect in case options is a zip or other generator without indexing
            option = collect(options[])[i]

            # only update the selection value if the new value is actually different
            # this is because i_selected can also be changed when the options themselves
            # are mutated, and there could still be the same option in the list
            # just at a different place, so that should not trigger a selection
            newvalue = optionvalue(option)
            if selection[] != newvalue
                selection[] = newvalue
            end
        end
    end

    # close the menu if the user clicks somewhere else
    onmousedownoutside(addmouseevents!(scene)) do events
        if is_open[]
            is_open[] = !is_open[]
        end
    end

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LMenu(fig_or_scene, layoutobservables, attrs, decorations)
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
