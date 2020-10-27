struct LMenu <: LObject
    scene::Scene
    attributes::Attributes
    layoutobservables::GridLayoutBase.LayoutObservables
    decorations::Dict{Symbol, Any}
end

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
        i_selected = 1
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
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
    LMenu(parent::Scene; bbox = nothing, kwargs...)

Create a drop-down menu with multiple selectable options. You can pass options
with the keyword argument `options`. Options are given as an iterable of elements.
For each element, the option label in the menu is determined with `optionstring(element)`
and the option value with `optionvalue(element)`. These functions can be
overloaded for custom types. The default is that elements which are `AbstractStrings`
are both label and value, and all other elements are expected to have two entries,
where the first is the label and the second is the value.

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


function LMenu(parent::Scene; bbox = nothing, kwargs...)

    default_attrs = default_attributes(LMenu, parent).attributes
    theme_attrs = subtheme(parent, :LMenu)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (halign, valign, i_selected, is_open, cell_color_hover,
        cell_color_inactive_even, cell_color_inactive_odd, dropdown_arrow_color,
        options, dropdown_arrow_size, textsize, selection, cell_color_active,
        textpadding, selection_cell_color_inactive, textcolor, direction)

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

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    contentgrid = GridLayout(
        bbox = lift(x -> FRect2D(AbstractPlotting.zero_origin(x)), scenearea),
        valign = @lift($direction == :down ? :top : :bottom))

    selectionrect = LRect(scene, width = nothing, height = nothing,
        color = selection_cell_color_inactive[], strokewidth = 0)
    selectiontext = LText(scene, "Select...", tellwidth = false, halign = :left,
        padding = textpadding, textsize = textsize, color = textcolor)


    rects = [LRect(scene, width = nothing, height = nothing,
        color = iseven(i) ? cell_color_inactive_even[] : cell_color_inactive_odd[], strokewidth = 0) for i in 1:length(options[])]

    strings = optionlabel.(options[])

    texts = [LText(scene, s, halign = :left, tellwidth = false,
        textsize = textsize, color = textcolor,
        padding = textpadding) for s in strings]


    allrects = [selectionrect; rects]
    alltexts = [selectiontext; texts]


    dropdown_arrow = scatter!(scene,
        lift(x -> [Point2f0(width(x) - 20, (top(x) + bottom(x)) / 2)], selectionrect.layoutobservables.computedbbox),
        marker = @lift($is_open ? '▴' : '▾'),
        markersize = dropdown_arrow_size,
        color = dropdown_arrow_color,
        strokecolor = :transparent,
        raw = true)[end]
    translate!(dropdown_arrow, 0, 0, 1)


    onany(i_selected, is_open, contentgrid.layoutobservables.autosize) do i, open, gridautosize

        h = texts[i].layoutobservables.autosize[][2]
        layoutobservables.autosize[] = (nothing, h)
        autosize = layoutobservables.autosize[]

        (isnothing(gridautosize[2]) || isnothing(autosize[2])) && return

        if open
            sceneheight[] = gridautosize[2]

            # bring forward
            translate!(scene, 0, 0, 10)

        else
            sceneheight[] = texts[1].layoutobservables.autosize[][2]

            # back to normal z
            translate!(scene, 0, 0, 0)
            # translate!(dropdown_arrow, 0, -top_border_offset, 1)
        end
    end

    contentgrid[:v] = allrects
    contentgrid[:v] = alltexts

    on(direction) do d
        if d == :down
            contentgrid[:v] = allrects
            contentgrid[:v] = alltexts
        elseif d == :up
            contentgrid[:v] = reverse(allrects)
            contentgrid[:v] = reverse(alltexts)
        else
            error("Invalid direction $d. Possible values are :up and :down.")
        end
    end

    on(i_selected) do i
        h = selectiontext.layoutobservables.autosize[][2]
        layoutobservables.autosize[] = (nothing, h)
    end

    # trigger size without triggering selection
    i_selected[] = i_selected[]
    is_open[] = is_open[]

    on(i_selected) do i
        # collect in case options is a zip or other generator without indexing
        selectiontext.text = strings[i]
        option = collect(options[])[i]
        selection[] = optionvalue(option)
    end

    rowgap!(contentgrid, 0)

    mousestates = [addmouseevents!(scene, r.rect, t.textobject) for (r, t) in zip(allrects, alltexts)]

    for (i, (mousestate, r, t)) in enumerate(zip(mousestates, allrects, alltexts))
        onmouseover(mousestate) do state
            r.color = cell_color_hover[]
        end

        onmouseout(mousestate) do state
            if i == 1
                r.color = selection_cell_color_inactive[]
            else
                i_option = i - 1
                r.color = iseven(i_option) ? cell_color_inactive_even[] : cell_color_inactive_odd[]
            end
        end

        onmouseleftdown(mousestate) do state
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

    # close the menu if the user clicks somewhere else
    onmousedownoutside(addmouseevents!(scene)) do state
        if is_open[]
            is_open[] = !is_open[]
        end
    end

    # trigger bbox
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    LMenu(scene, attrs, layoutobservables, decorations)
end


function optionlabel(option::AbstractString)
    string(option)
end

function optionlabel(option)
    string(option[1])
end

function optionvalue(option::AbstractString)
    option
end

function optionvalue(option)
    option[2]
end
