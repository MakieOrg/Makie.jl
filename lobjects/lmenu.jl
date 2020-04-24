struct LMenu <: LObject
    scene::Scene
    attributes::Attributes
    layoutobservables::GridLayoutBase.LayoutObservables
    decorations::Dict{Symbol, Any}
end

function default_attributes(::Type{LMenu}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the menu."
        height = Auto(true)
        "The width setting of the menu."
        width = nothing
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
        cell_color_inactive_even = RGBf0(0.95, 0.95, 0.95)
        "Cell color when inactive odd"
        cell_color_inactive_odd = RGBf0(0.95, 0.95, 0.95)
        "Color of the dropdown arrow"
        dropdown_arrow_color = (:black, 0.3)
        "Size of the dropdown arrow"
        dropdown_arrow_size = 12px
        "The list of options selectable in the menu. This can be any iterable of a mixture of strings and containers with one string and one other value. If an entry is just a string, that string is both label and selection. If an entry is a container with one string and one other value, the string is the label and the other value is the selection."
        options = ["no options"]
        "Font size of the cell texts"
        textsize = 20
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LMenu
LMenu has the following attributes:

$(let
    _, docs, defaults = default_attributes(LMenu, nothing)
    docvarstring(docs, defaults)
end)
"""
LMenu


function LMenu(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(
        Attributes(kwargs),
        default_attributes(LMenu, parent).attributes)

    @extract attrs (halign, valign, i_selected, is_open, cell_color_hover,
        cell_color_inactive_even, cell_color_inactive_odd, dropdown_arrow_color,
        options, dropdown_arrow_size, textsize, selection, cell_color_active)

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LMenu, attrs.width, attrs.height,
    halign, valign, attrs.alignmode; suggestedbbox = bbox)


    sceneheight = Node(20.0)



    scenearea = lift(layoutobservables.computedbbox, sceneheight) do bbox, h
        IRect2D_rounded(BBox(left(bbox), right(bbox), top(bbox) - h, top(bbox)))
    end

    scene = Scene(parent, scenearea, raw = true, camera = campixel!)

    contentgrid = GridLayout(
        bbox = lift(x -> FRect2D(AbstractPlotting.zero_origin(x)), scenearea),
        valign = :top)

    on(is_open) do open
        if open
            sceneheight[] = contentgrid.layoutobservables.autosize[][2]
        else
            sceneheight[] = layoutobservables.autosize[][2]
        end
    end

    rects = [LRect(scene, width = nothing, height = nothing,
        color = iseven(i) ? cell_color_inactive_even[] : cell_color_inactive_odd[], strokewidth = 0) for i in 1:length(options[])]

    strings = optionlabel.(options[])

    texts = [LText(scene, s, halign = :left, width = Auto(false),
        textsize = textsize,
        padding = (10, 10, 10, 10)) for s in strings]

    contentgrid[:v] = rects
    contentgrid[:v] = texts

    onany(i_selected, textsize) do i, args...
        h = texts[i].layoutobservables.autosize[][2]
        layoutobservables.autosize[] = (nothing, h)
    end

    i_selected[] = i_selected[]
    is_open[] = is_open[]

    on(i_selected) do i
        # collect in case options is a zip or other generator without indexing
        option = collect(options[])[i]
        selection[] = optionvalue(option)
    end

    rowgap!(contentgrid, 0)

    mousestates = [addmousestate!(scene, r.rect, t.textobject) for (r, t) in zip(rects, texts)]

    for (i, (mousestate, r, t)) in enumerate(zip(mousestates, rects, texts))
        onmouseleftclick(mousestate) do state
            if is_open[]
                i_selected[] = i
                menuheight = height(contentgrid.layoutobservables.computedbbox[])
                top_border_offset = top(r.layoutobservables.computedbbox[])
                # shift selected cell into view
                translate!(scene, 0, menuheight - top_border_offset, 0)
                translate!(dropdown_arrow, 0, -(menuheight - top_border_offset), 1)
            else
                # reset vertically and bring forward
                translate!(scene, 0, 0, 10)
            end
            is_open[] = !is_open[]
        end

        onmouseover(mousestate) do state
            r.color = cell_color_hover[]
        end

        onmouseout(mousestate) do state
            r.color = iseven(i) ? cell_color_inactive_even[] : cell_color_inactive_odd[]
        end
        onmouseleftdown(mousestate) do state
            r.color = cell_color_active[]
        end
    end

    dropdown_arrow = scatter!(scene,
        lift(x -> [Point2f0(width(x) - 20, height(x) / 2)], scenearea),
        marker = '▼',
        markersize = dropdown_arrow_size,
        visible = @lift(!$is_open),
        color = dropdown_arrow_color,
        raw = true)[end]
    translate!(dropdown_arrow, 0, 0, 1)

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
