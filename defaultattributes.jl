macro documented_attributes(exp)
    if exp.head != :block
        error("Not a block")
    end

    expressions = filter(x -> !(x isa LineNumberNode), exp.args)

    vars_and_exps = map(expressions) do e
        if e.head == :macrocall && e.args[1] == GlobalRef(Core, Symbol("@doc"))
            varname = e.args[4].args[1]
            var_exp = e.args[4].args[2]
            str_exp = e.args[3]
        elseif e.head == Symbol("=")
            varname = e.args[1]
            var_exp = e.args[2]
            str_exp = "no description"
        else
            error("Neither docstringed variable nor normal variable: $e")
        end
        varname, var_exp, str_exp
    end

    # make a dictionary of :variable_name => docstring_expression
    exp_docdict = Expr(:call, :Dict,
        (Expr(:call, Symbol("=>"), QuoteNode(name), strexp)
            for (name, _, strexp) in vars_and_exps)...)

    # make a dictionary of :variable_name => docstring_expression
    defaults_dict = Expr(:call, :Dict,
        (Expr(:call, Symbol("=>"), QuoteNode(name), string(exp))
            for (name, exp, _) in vars_and_exps)...)

    # make an Attributes instance with of variable_name = variable_expression
    exp_attrs = Expr(:call, :Attributes,
        (Expr(:kw, name, exp)
            for (name, exp, _) in vars_and_exps)...)

    esc(quote
        ($exp_attrs, $exp_docdict, $defaults_dict)
    end)
end

function lift_parent_attribute(scene, attr::Symbol, default_value)
    if haskey(scene.attributes, attr)
        lift(identity, scene[attr])
    else
        lift_parent_attribute(scene.parent, attr, default_value)
    end
end

function lift_parent_attribute(::Nothing, attr::Symbol, default_value)
    default_value
end


function default_attributes(::Type{LAxis}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The xlabel string"
        xlabel = " "
        "The ylabel string"
        ylabel = " "
        "The axis title string"
        title = " "
        "The font family of the title"
        titlefont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The title's font size"
        titlesize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The gap between axis and title"
        titlegap = 10f0
        "Controls if the title is visible"
        titlevisible = true
        "The horizontal alignment of the title"
        titlealign = :center
        "The font family of the xlabel"
        xlabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font family of the ylabel"
        ylabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The color of the xlabel"
        xlabelcolor = RGBf0(0, 0, 0)
        "The color of the ylabel"
        ylabelcolor = RGBf0(0, 0, 0)
        "The font size of the xlabel"
        xlabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font size of the ylabel"
        ylabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the xlabel is visible"
        xlabelvisible = true
        "Controls if the ylabel is visible"
        ylabelvisible = true
        "The padding between the xlabel and the ticks or axis"
        xlabelpadding = 15f0
        "The padding between the ylabel and the ticks or axis"
        ylabelpadding = 15f0 # because of boundingbox inaccuracies of ticklabels
        "The font family of the xticklabels"
        xticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font family of the yticklabels"
        yticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font size of the xticklabels"
        xticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font size of the yticklabels"
        yticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the xticklabels are visible"
        xticklabelsvisible = true
        "Controls if the yticklabels are visible"
        yticklabelsvisible = true
        "The space reserved for the xticklabels"
        xticklabelspace = AbstractPlotting.automatic
        "The space reserved for the yticklabels"
        yticklabelspace = AbstractPlotting.automatic
        "The space between xticks and xticklabels"
        xticklabelpad = 5f0
        "The space between yticks and yticklabels"
        yticklabelpad = 5f0
        "The rotation of the xticklabels in radians"
        xticklabelrotation = 0f0
        "The rotation of the yticklabels in radians"
        yticklabelrotation = 0f0
        "The horizontal and vertical alignment of the xticklabels"
        xticklabelalign = (:center, :top)
        "The horizontal and vertical alignment of the yticklabels"
        yticklabelalign = (:right, :center)
        "The size of the xtick marks"
        xticksize = 10f0
        "The size of the ytick marks"
        yticksize = 10f0
        "Controls if the xtick marks are visible"
        xticksvisible = true
        "Controls if the ytick marks are visible"
        yticksvisible = true
        "The alignment of the xtick marks relative to the axis spine (0 = out, 1 = in)"
        xtickalign = 0f0
        "The alignment of the ytick marks relative to the axis spine (0 = out, 1 = in)"
        ytickalign = 0f0
        "The width of the xtick marks"
        xtickwidth = 1f0
        "The width of the ytick marks"
        ytickwidth = 1f0
        "The color of the xtick marks"
        xtickcolor = RGBf0(0, 0, 0)
        "The color of the ytick marks"
        ytickcolor = RGBf0(0, 0, 0)
        "Locks interactive panning in the x direction"
        xpanlock = false
        "Locks interactive panning in the y direction"
        ypanlock = false
        "Locks interactive zooming in the x direction"
        xzoomlock = false
        "Locks interactive zooming in the y direction"
        yzoomlock = false
        "The width of the axis spines"
        spinewidth = 1f0
        "Controls if the x grid lines are visible"
        xgridvisible = true
        "Controls if the y grid lines are visible"
        ygridvisible = true
        "The width of the x grid lines"
        xgridwidth = 1f0
        "The width of the y grid lines"
        ygridwidth = 1f0
        "The color of the x grid lines"
        xgridcolor = RGBAf0(0, 0, 0, 0.1)
        "The color of the y grid lines"
        ygridcolor = RGBAf0(0, 0, 0, 0.1)
        "The linestyle of the x grid lines"
        xgridstyle = nothing
        "The linestyle of the y grid lines"
        ygridstyle = nothing
        "Controls if the bottom axis spine is visible"
        bottomspinevisible = true
        "Controls if the left axis spine is visible"
        leftspinevisible = true
        "Controls if the top axis spine is visible"
        topspinevisible = true
        "Controls if the right axis spine is visible"
        rightspinevisible = true
        "The color of the bottom axis spine"
        bottomspinecolor = :black
        "The color of the left axis spine"
        leftspinecolor = :black
        "The color of the top axis spine"
        topspinecolor = :black
        "The color of the right axis spine"
        rightspinecolor = :black
        "The forced aspect ratio of the axis. `nothing` leaves the axis unconstrained, `DataAspect()` forces the same ratio as the ratio in data limits between x and y axis, `AxisAspect(ratio)` sets a manual ratio."
        aspect = nothing
        "The vertical alignment of the axis within its suggested bounding box"
        valign = :center
        "The horizontal alignment of the axis within its suggested bounding box"
        halign = :center
        "The width of the axis"
        width = nothing
        "The height of the axis"
        height = nothing
        maxsize = (Inf32, Inf32)
        "The relative margins added to the autolimits in x direction"
        xautolimitmargin = (0.05f0, 0.05f0)
        "The relative margins added to the autolimits in y direction"
        yautolimitmargin = (0.05f0, 0.05f0)
        "The xticks tick object"
        xticks = AutoLinearTicks(5)
        "The yticks tick object"
        yticks = AutoLinearTicks(5)
        "The button for panning"
        panbutton = AbstractPlotting.Mouse.right
        "The key for limiting panning to the x direction"
        xpankey = AbstractPlotting.Keyboard.x
        "The key for limiting panning to the y direction"
        ypankey = AbstractPlotting.Keyboard.y
        "The key for limiting zooming to the x direction"
        xzoomkey = AbstractPlotting.Keyboard.x
        "The key for limiting zooming to the y direction"
        yzoomkey = AbstractPlotting.Keyboard.y
        "The position of the x axis (`:bottom` or `:top`)"
        xaxisposition = :bottom
        "The position of the y axis (`:left` or `:right`)"
        yaxisposition = :left
        "Controls if the x spine is limited to the furthest tick marks or not"
        xtrimspine = false
        "Controls if the y spine is limited to the furthest tick marks or not"
        ytrimspine = false
        "The background color of the axis"
        backgroundcolor = :white
        "Controls if the ylabel's rotation is flipped"
        flip_ylabel = false
        "Constrains the data aspect ratio (`nothing` leaves the ratio unconstrained)"
        autolimitaspect = nothing
        targetlimits = BBox(0, 100, 0, 100)
        "The align mode of the axis in its parent GridLayout"
        alignmode = Inside()
    end

    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

function docvarstring(docdict, defaultdict)
    buffer = IOBuffer()
    maxwidth = maximum(length ∘ string, keys(docdict))
    for (var, doc) in sort(pairs(docdict))
        print(buffer, "`$var`\\\nDefault: `$(defaultdict[var])`\\\n$doc\n\n")
    end
    String(take!(buffer))
end

@doc """
LAxis has the following attributes:

$(let
    _, docs, defaults = default_attributes(LAxis, nothing)
    docvarstring(docs, defaults)
end)
"""
LAxis

function default_attributes(::Type{LColorbar}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        label = " "
        labelcolor = RGBf0(0, 0, 0)
        labelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        labelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        labelvisible = true
        labelpadding = 15f0
        ticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        ticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        ticklabelsvisible = true
        ticksize = 10f0
        ticksvisible = true
        ticks = AutoLinearTicks(5)
        ticklabelspace = AbstractPlotting.automatic
        ticklabelpad = 5f0
        tickalign = 0f0
        tickwidth = 1f0
        tickcolor = RGBf0(0, 0, 0)
        ticklabelalign = (:left, :center)
        spinewidth = 1f0
        topspinevisible = true
        rightspinevisible = true
        leftspinevisible = true
        bottomspinevisible = true
        topspinecolor = RGBf0(0, 0, 0)
        leftspinecolor = RGBf0(0, 0, 0)
        rightspinecolor = RGBf0(0, 0, 0)
        bottomspinecolor = RGBf0(0, 0, 0)
        valign = :center
        halign = :center
        vertical = true
        flipaxisposition = true
        flip_vertical_label = false
        width = nothing
        height = nothing
        colormap = :viridis
        limits = (0f0, 1f0)
        alignmode = Inside()
        nsteps = 100
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LColorbar has the following attributes:

$(let
    _, docs, defaults = default_attributes(LColorbar, nothing)
    docvarstring(docs, defaults)
end)
"""
LColorbar

function default_attributes(::Type{LText}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        text = "Text"
        visible = true
        color = RGBf0(0, 0, 0)
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        valign = :center
        halign = :center
        rotation = 0f0
        padding = (0f0, 0f0, 0f0, 0f0)
        height = Auto()
        width = Auto()
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LText has the following attributes:

$(let
    _, docs, defaults = default_attributes(LText, nothing)
    docvarstring(docs, defaults)
end)
"""
LText

function default_attributes(::Type{LRect}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        visible = true
        color = RGBf0(0.9, 0.9, 0.9)
        valign = :center
        halign = :center
        padding = (0f0, 0f0, 0f0, 0f0)
        strokewidth = 2f0
        strokevisible = true
        strokecolor = RGBf0(0, 0, 0)
        width = nothing
        height = nothing
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LRect has the following attributes:

$(let
    _, docs, defaults = default_attributes(LRect, nothing)
    docvarstring(docs, defaults)
end)
"""
LRect

function default_attributes(::Type{LButton}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        halign = :center
        valign = :center
        padding = (10f0, 10f0, 10f0, 10f0)
        textsize = 20f0
        label = "Button"
        font = "Dejavu Sans"
        width = Auto(true)
        height = Auto(true)
        cornerradius = 4
        cornersegments = 10
        strokewidth = 2f0
        strokecolor = :transparent
        buttoncolor = RGBf0(0.9, 0.9, 0.9)
        labelcolor = :black
        labelcolor_hover = :black
        labelcolor_active = :white
        buttoncolor_active = COLOR_ACCENT[]
        # buttoncolor_hover = RGBf0(0.8, 0.8, 0.8)
        buttoncolor_hover = COLOR_ACCENT_DIMMED[]
        clicks = 0
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LButton has the following attributes:

$(let
    _, docs, defaults = default_attributes(LButton, nothing)
    docvarstring(docs, defaults)
end)
"""
LButton

function default_attributes(::Type{LineAxis})
    Attributes(
        endpoints = (Point2f0(0, 0), Point2f0(100, 0)),
        trimspine = false,
        limits = (0f0, 100f0),
        flipped = false,
        flip_vertical_label = false,
        ticksize = 10f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        tickalign = 0f0,
        ticks = AutoLinearTicks(5),
        ticklabelalign = (:center, :top),
        ticksvisible = true,
        ticklabelrotation = 0f0,
        ticklabelsize = 20f0,
        ticklabelsvisible = true,
        spinewidth = 1f0,
        label = "label",
        labelsize = 20f0,
        labelcolor = RGBf0(0, 0, 0),
        labelvisible = true,
        ticklabelspace = AbstractPlotting.automatic,
        ticklabelpad = 5f0,
        labelpadding = 15f0,
    )
end

function default_attributes(::Type{LSlider}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        linewidth = 4f0
        halign = :center
        valign = :center
        # vertical = true
        width = nothing
        height = Auto(true)
        range = 0:10
        buttonradius = 7f0
        startvalue = 0
        value = 0
        color_active_dimmed = COLOR_ACCENT_DIMMED[]
        color_active = COLOR_ACCENT[]
        color_inactive = RGBf0(0.9, 0.9, 0.9)
        buttoncolor_inactive = RGBf0(1, 1, 1)
        horizontal = true
        buttonstrokewidth = 4f0
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LSlider has the following attributes:

$(let
    _, docs, defaults = default_attributes(LSlider, nothing)
    docvarstring(docs, defaults)
end)
"""
LSlider

function default_attributes(::Type{LToggle}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        halign = :center
        valign = :center
        width = 60
        height = 30
        cornersegments = 10
        # strokewidth = 2f0
        # strokecolor = :transparent
        framecolor_inactive = RGBf0(0.9, 0.9, 0.9)
        framecolor_active = COLOR_ACCENT[]
        # buttoncolor = RGBf0(0.2, 0.2, 0.2)
        buttoncolor = RGBf0(1, 1, 1)
        active = false
        toggleduration = 0.2
        rimfraction = 0.25
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LToggle has the following attributes:

$(let
    _, docs, defaults = default_attributes(LToggle, nothing)
    docvarstring(docs, defaults)
end)
"""
LToggle


function default_attributes(::Type{LLegend}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        halign = :center
        valign = :center
        width = Auto(true)
        height = Auto(false)
        titlefont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        titlesize = lift_parent_attribute(scene, :fontsize, 20f0)
        titlehalign = :center
        titlevalign = :center
        titlevisible = true
        titleposition = :top
        labelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        labelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        labelcolor = :black
        labelhalign = :left
        labelvalign = :center
        padding = (10f0, 10f0, 10f0, 10f0)
        margin = (0f0, 0f0, 0f0, 0f0)
        bgcolor = :white
        framecolor = :black
        framewidth = 1f0
        framevisible = true
        patchsize = (20f0, 20f0)
        patchstrokecolor = :transparent
        patchstrokewidth = 1f0
        patchcolor = :transparent
        label = "undefined"
        nbanks = 1
        colgap = 20
        rowgap = 4
        patchlabelgap = 5
        linepoints = [Point2f0(0, 0.5), Point2f0(1, 0.5)]
        linewidth = 3
        markerpoints = [Point2f0(0.5, 0.5)]
        markersize = 12
        markerstrokewidth = 2
        polypoints = [Point2f0(0, 0), Point2f0(1, 0), Point2f0(1, 1), Point2f0(0, 1)]
        polystrokewidth = 2
        orientation = :vertical
        titlegap = 15
        groupgap = 30
        gridshalign = :center
        gridsvalign = :center
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LLegend has the following attributes:

$(let
    _, docs, defaults = default_attributes(LLegend, nothing)
    docvarstring(docs, defaults)
end)
"""
LLegend

function attributenames(::Type{LegendEntry})
    (:label, :labelsize, :labelfont, :labelcolor, :labelhalign, :labelvalign,
        :patchsize, :patchstrokecolor, :patchstrokewidth, :patchcolor,
        :linepoints, :markerpoints, :markersize, :markerstrokewidth, :linewidth,
        :polypoints, :polystrokewidth)
end

function extractattributes(attributes::Attributes, typ::Type)
    extracted = Attributes()
    for name in attributenames(typ)
        if haskey(attributes, name)
            extracted[name] = attributes[name]
        end
    end
    extracted
end

function default_attributes(::Type{GridLayout})
    Attributes(
        halign = :center,
        valign = :center,
        width = Auto(),
        height = Auto(),
    )
end

function default_attributes(::Type{LScene}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        height = nothing
        width = nothing
        halign = :center
        valign = :center
        alignmode = Inside()
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
LScene has the following attributes:

$(let
    _, docs, defaults = default_attributes(LScene, nothing)
    docvarstring(docs, defaults)
end)
"""
LScene
