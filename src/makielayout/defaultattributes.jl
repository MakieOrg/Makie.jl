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
        "The xlabel string."
        xlabel = " "
        "The ylabel string."
        ylabel = " "
        "The axis title string."
        title = " "
        "The font family of the title."
        titlefont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The title's font size."
        titlesize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The gap between axis and title."
        titlegap = 10f0
        "Controls if the title is visible."
        titlevisible = true
        "The horizontal alignment of the title."
        titlealign = :center
        "The font family of the xlabel."
        xlabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font family of the ylabel."
        ylabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The color of the xlabel."
        xlabelcolor = RGBf0(0, 0, 0)
        "The color of the ylabel."
        ylabelcolor = RGBf0(0, 0, 0)
        "The font size of the xlabel."
        xlabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font size of the ylabel."
        ylabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the xlabel is visible."
        xlabelvisible = true
        "Controls if the ylabel is visible."
        ylabelvisible = true
        "The padding between the xlabel and the ticks or axis."
        xlabelpadding = 15f0
        "The padding between the ylabel and the ticks or axis."
        ylabelpadding = 15f0 # because of boundingbox inaccuracies of ticklabels
        "The font family of the xticklabels."
        xticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font family of the yticklabels."
        yticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The color of xticklabels."
        xticklabelcolor = RGBf0(0, 0, 0)
        "The color of yticklabels."
        yticklabelcolor = RGBf0(0, 0, 0)
        "The font size of the xticklabels."
        xticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font size of the yticklabels."
        yticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the xticklabels are visible."
        xticklabelsvisible = true
        "Controls if the yticklabels are visible."
        yticklabelsvisible = true
        "The space reserved for the xticklabels."
        xticklabelspace = AbstractPlotting.automatic
        "The space reserved for the yticklabels."
        yticklabelspace = AbstractPlotting.automatic
        "The space between xticks and xticklabels."
        xticklabelpad = 5f0
        "The space between yticks and yticklabels."
        yticklabelpad = 5f0
        "The counterclockwise rotation of the xticklabels in radians."
        xticklabelrotation = 0f0
        "The counterclockwise rotation of the yticklabels in radians."
        yticklabelrotation = 0f0
        "The horizontal and vertical alignment of the xticklabels."
        xticklabelalign = (:center, :top)
        "The horizontal and vertical alignment of the yticklabels."
        yticklabelalign = (:right, :center)
        "The size of the xtick marks."
        xticksize = 10f0
        "The size of the ytick marks."
        yticksize = 10f0
        "Controls if the xtick marks are visible."
        xticksvisible = true
        "Controls if the ytick marks are visible."
        yticksvisible = true
        "The alignment of the xtick marks relative to the axis spine (0 = out, 1 = in)."
        xtickalign = 0f0
        "The alignment of the ytick marks relative to the axis spine (0 = out, 1 = in)."
        ytickalign = 0f0
        "The width of the xtick marks."
        xtickwidth = 1f0
        "The width of the ytick marks."
        ytickwidth = 1f0
        "The color of the xtick marks."
        xtickcolor = RGBf0(0, 0, 0)
        "The color of the ytick marks."
        ytickcolor = RGBf0(0, 0, 0)
        "Locks interactive panning in the x direction."
        xpanlock = false
        "Locks interactive panning in the y direction."
        ypanlock = false
        "Locks interactive zooming in the x direction."
        xzoomlock = false
        "Locks interactive zooming in the y direction."
        yzoomlock = false
        "The width of the axis spines."
        spinewidth = 1f0
        "Controls if the x grid lines are visible."
        xgridvisible = true
        "Controls if the y grid lines are visible."
        ygridvisible = true
        "The width of the x grid lines."
        xgridwidth = 1f0
        "The width of the y grid lines."
        ygridwidth = 1f0
        "The color of the x grid lines."
        xgridcolor = RGBAf0(0, 0, 0, 0.1)
        "The color of the y grid lines."
        ygridcolor = RGBAf0(0, 0, 0, 0.1)
        "The linestyle of the x grid lines."
        xgridstyle = nothing
        "The linestyle of the y grid lines."
        ygridstyle = nothing
        "Controls if the bottom axis spine is visible."
        bottomspinevisible = true
        "Controls if the left axis spine is visible."
        leftspinevisible = true
        "Controls if the top axis spine is visible."
        topspinevisible = true
        "Controls if the right axis spine is visible."
        rightspinevisible = true
        "The color of the bottom axis spine."
        bottomspinecolor = :black
        "The color of the left axis spine."
        leftspinecolor = :black
        "The color of the top axis spine."
        topspinecolor = :black
        "The color of the right axis spine."
        rightspinecolor = :black
        "The forced aspect ratio of the axis. `nothing` leaves the axis unconstrained, `DataAspect()` forces the same ratio as the ratio in data limits between x and y axis, `AxisAspect(ratio)` sets a manual ratio."
        aspect = nothing
        "The vertical alignment of the axis within its suggested bounding box."
        valign = :center
        "The horizontal alignment of the axis within its suggested bounding box."
        halign = :center
        "The width of the axis."
        width = nothing
        "The height of the axis."
        height = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The relative margins added to the autolimits in x direction."
        xautolimitmargin = (0.05f0, 0.05f0)
        "The relative margins added to the autolimits in y direction."
        yautolimitmargin = (0.05f0, 0.05f0)
        "The xticks."
        xticks = AbstractPlotting.automatic
        "Format for xticks."
        xtickformat = AbstractPlotting.automatic
        "The yticks."
        yticks = AbstractPlotting.automatic
        "Format for yticks."
        ytickformat = AbstractPlotting.automatic
        "The button for panning."
        panbutton = AbstractPlotting.Mouse.right
        "The key for limiting panning to the x direction."
        xpankey = AbstractPlotting.Keyboard.x
        "The key for limiting panning to the y direction."
        ypankey = AbstractPlotting.Keyboard.y
        "The key for limiting zooming to the x direction."
        xzoomkey = AbstractPlotting.Keyboard.x
        "The key for limiting zooming to the y direction."
        yzoomkey = AbstractPlotting.Keyboard.y
        "The position of the x axis (`:bottom` or `:top`)."
        xaxisposition = :bottom
        "The position of the y axis (`:left` or `:right`)."
        yaxisposition = :left
        "Controls if the x spine is limited to the furthest tick marks or not."
        xtrimspine = false
        "Controls if the y spine is limited to the furthest tick marks or not."
        ytrimspine = false
        "The background color of the axis."
        backgroundcolor = :white
        "Controls if the ylabel's rotation is flipped."
        flip_ylabel = false
        "Constrains the data aspect ratio (`nothing` leaves the ratio unconstrained)."
        autolimitaspect = nothing
        targetlimits = BBox(0, 100, 0, 100)
        "The align mode of the axis in its parent GridLayout."
        alignmode = Inside()
        "Controls if the y axis goes upwards (false) or downwards (true)"
        yreversed = false
        "Controls if the x axis goes rightwards (false) or leftwards (true)"
        xreversed = false
    end

    (attributes = attrs, documentation = docdict, defaults = defaultdict)
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
        "The color bar label string."
        label = " "
        "The label color."
        labelcolor = RGBf0(0, 0, 0)
        "The label font family."
        labelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The label font size."
        labelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the label is visible."
        labelvisible = true
        "The gap between the label and the ticks."
        labelpadding = 15f0
        "The font family of the tick labels."
        ticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font size of the tick labels."
        ticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Controls if the tick labels are visible."
        ticklabelsvisible = true
        "The color of the tick labels."
        ticklabelcolor = RGBf0(0, 0, 0)
        "The size of the tick marks."
        ticksize = 10f0
        "Controls if the tick marks are visible."
        ticksvisible = true
        "The ticks."
        ticks = AbstractPlotting.automatic
        "Format for ticks."
        tickformat = AbstractPlotting.automatic
        "The space reserved for the tick labels."
        ticklabelspace = AbstractPlotting.automatic
        "The gap between tick labels and tick marks."
        ticklabelpad = 5f0
        "The alignment of the tick marks relative to the axis spine (0 = out, 1 = in)."
        tickalign = 0f0
        "The line width of the tick marks."
        tickwidth = 1f0
        "The color of the tick marks."
        tickcolor = RGBf0(0, 0, 0)
        "The horizontal and vertical alignment of the tick labels."
        ticklabelalign = (:left, :center)
        "The line width of the spines."
        spinewidth = 1f0
        "Controls if the top spine is visible."
        topspinevisible = true
        "Controls if the right spine is visible."
        rightspinevisible = true
        "Controls if the left spine is visible."
        leftspinevisible = true
        "Controls if the bottom spine is visible."
        bottomspinevisible = true
        "The color of the top spine."
        topspinecolor = RGBf0(0, 0, 0)
        "The color of the left spine."
        leftspinecolor = RGBf0(0, 0, 0)
        "The color of the right spine."
        rightspinecolor = RGBf0(0, 0, 0)
        "The color of the bottom spine."
        bottomspinecolor = RGBf0(0, 0, 0)
        "The vertical alignment of the colorbar in its suggested bounding box."
        valign = :center
        "The horizontal alignment of the colorbar in its suggested bounding box."
        halign = :center
        "Controls if the colorbar is oriented vertically."
        vertical = true
        "Flips the axis to the right if vertical and to the top if horizontal."
        flipaxisposition = true
        "Flips the colorbar label if the axis is vertical."
        flip_vertical_label = false
        "The width setting of the colorbar."
        width = nothing
        "The height setting of the colorbar."
        height = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The colormap that the colorbar uses."
        colormap = :viridis
        "The range of values depicted in the colorbar."
        limits = (0f0, 1f0)
        "The align mode of the colorbar in its parent GridLayout."
        alignmode = Inside()
        "The number of steps in the heatmap underlying the colorbar gradient."
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
        "The displayed text string."
        text = "Text"
        "Controls if the text is visible."
        visible = true
        "The color of the text."
        color = RGBf0(0, 0, 0)
        "The font size of the text."
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font family of the text."
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The vertical alignment of the text in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the text in its suggested boundingbox"
        halign = :center
        "The counterclockwise rotation of the text in radians."
        rotation = 0f0
        "The extra space added to the sides of the text boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The height setting of the text."
        height = Auto()
        "The width setting of the text."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The align mode of the text in its parent GridLayout."
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
        "Controls if the rectangle is visible."
        visible = true
        "The color of the rectangle."
        color = RGBf0(0.9, 0.9, 0.9)
        "The vertical alignment of the rectangle in its suggested boundingbox"
        valign = :center
        "The horizontal alignment of the rectangle in its suggested boundingbox"
        halign = :center
        "The extra space added to the sides of the rectangle boundingbox."
        padding = (0f0, 0f0, 0f0, 0f0)
        "The line width of the rectangle's border."
        strokewidth = 1f0
        "Controls if the border of the rectangle is visible."
        strokevisible = true
        "The color of the border."
        strokecolor = RGBf0(0, 0, 0)
        "The width setting of the rectangle."
        width = nothing
        "The height setting of the rectangle."
        height = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The align mode of the rectangle in its parent GridLayout."
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
        "The horizontal alignment of the button in its suggested boundingbox"
        halign = :center
        "The vertical alignment of the button in its suggested boundingbox"
        valign = :center
        "The extra space added to the sides of the button label's boundingbox."
        padding = (10f0, 10f0, 10f0, 10f0)
        "The font size of the button label."
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The text of the button label."
        label = "Button"
        "The font family of the button label."
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The width setting of the button."
        width = Auto()
        "The height setting of the button."
        height = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The radius of the rounded corners of the button."
        cornerradius = 4
        "The number of poly segments used for each rounded corner."
        cornersegments = 10
        "The line width of the button border."
        strokewidth = 2f0
        "The color of the button border."
        strokecolor = :transparent
        "The color of the button."
        buttoncolor = RGBf0(0.9, 0.9, 0.9)
        "The color of the label."
        labelcolor = :black
        "The color of the label when the mouse hovers over the button."
        labelcolor_hover = :black
        "The color of the label when the mouse clicks the button."
        labelcolor_active = :white
        "The color of the button when the mouse clicks the button."
        buttoncolor_active = COLOR_ACCENT[]
        "The color of the button when the mouse hovers over the button."
        buttoncolor_hover = COLOR_ACCENT_DIMMED[]
        "The number of clicks that have been registered by the button."
        clicks = 0
        "The align mode of the button in its parent GridLayout."
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
        ticks = AbstractPlotting.automatic,
        tickformat = AbstractPlotting.automatic,
        ticklabelalign = (:center, :top),
        ticksvisible = true,
        ticklabelrotation = 0f0,
        ticklabelsize = 20f0,
        ticklabelcolor = RGBf0(0, 0, 0),
        ticklabelsvisible = true,
        spinewidth = 1f0,
        label = "label",
        labelsize = 20f0,
        labelcolor = RGBf0(0, 0, 0),
        labelvisible = true,
        ticklabelspace = AbstractPlotting.automatic,
        ticklabelpad = 5f0,
        labelpadding = 15f0,
        reversed = false,
    )
end

function default_attributes(::Type{LSlider}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The line width of the main slider line."
        linewidth = 4f0
        "The horizontal alignment of the slider in its suggested bounding box."
        halign = :center
        "The vertical alignment of the slider in its suggested bounding box."
        valign = :center
        "The width setting of the slider."
        width = nothing
        "The height setting of the slider."
        height = Auto()
        "The range of values that the slider can pick from."
        range = 0:10
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The radius of the slider button."
        buttonradius = 9f0
        "The start value of the slider or the value that is closest in the slider range."
        startvalue = 0
        "The current value of the slider."
        value = 0
        "The color of the slider when the mouse hovers over it."
        color_active_dimmed = COLOR_ACCENT_DIMMED[]
        "The color of the slider when the mouse clicks and drags the slider."
        color_active = COLOR_ACCENT[]
        "The color of the slider when it is not interacted with."
        color_inactive = RGBf0(0.9, 0.9, 0.9)
        "The color of the button when it is not interacted with."
        buttoncolor_inactive = RGBf0(1, 1, 1)
        "Controls if the slider has a horizontal orientation or not."
        horizontal = true
        "The line width of the slider button's border."
        buttonstrokewidth = 4f0
        "The align mode of the slider in its parent GridLayout."
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
        "The horizontal alignment of the toggle in its suggested bounding box."
        halign = :center
        "The vertical alignment of the toggle in its suggested bounding box."
        valign = :center
        "The width of the toggle."
        width = 60
        "The height of the toggle."
        height = 30
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The number of poly segments in each rounded corner."
        cornersegments = 10
        # strokewidth = 2f0
        # strokecolor = :transparent
        "The color of the border when the toggle is inactive."
        framecolor_inactive = RGBf0(0.9, 0.9, 0.9)
        "The color of the border when the toggle is active."
        framecolor_active = COLOR_ACCENT[]
        # buttoncolor = RGBf0(0.2, 0.2, 0.2)
        "The color of the toggle button."
        buttoncolor = RGBf0(1, 1, 1)
        "Indicates if the toggle is active or not."
        active = false
        "The duration of the toggle animation."
        toggleduration = 0.2
        "The border width as a fraction of the toggle height "
        rimfraction = 0.25
        "The align mode of the toggle in its parent GridLayout."
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
        "The horizontal alignment of the legend in its suggested bounding box."
        halign = :center
        "The vertical alignment of the legend in its suggested bounding box."
        valign = :center
        "The width setting of the legend."
        width = Auto()
        "The height setting of the legend."
        height = Auto()
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = false
        "The font family of the legend group titles."
        titlefont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The font size of the legend group titles."
        titlesize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The horizontal alignment of the legend group titles."
        titlehalign = :center
        "The vertical alignment of the legend group titles."
        titlevalign = :center
        "Controls if the legend titles are visible."
        titlevisible = true
        "The group title positions relative to their groups. Can be `:top` or `:left`."
        titleposition = :top
        "The font size of the entry labels."
        labelsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "The font family of the entry labels."
        labelfont = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "The color of the entry labels."
        labelcolor = :black
        "The horizontal alignment of the entry labels."
        labelhalign = :left
        "The vertical alignment of the entry labels."
        labelvalign = :center
        "The additional space between the legend content and the border."
        padding = (10f0, 10f0, 10f0, 10f0)
        "The additional space between the legend and its suggested boundingbox."
        margin = (0f0, 0f0, 0f0, 0f0)
        "The background color of the legend."
        bgcolor = :white
        "The color of the legend border."
        framecolor = :black
        "The line width of the legend border."
        framewidth = 1f0
        "Controls if the legend border is visible."
        framevisible = true
        "The size of the rectangles containing the legend markers."
        patchsize = (20f0, 20f0)
        "The color of the border of the patches containing the legend markers."
        patchstrokecolor = :transparent
        "The line width of the border of the patches containing the legend markers."
        patchstrokewidth = 1f0
        "The color of the patches containing the legend markers."
        patchcolor = :transparent
        "The default entry label."
        label = "undefined"
        "The number of banks in which the legend entries are grouped. Columns if the legend is vertically oriented, otherwise rows."
        nbanks = 1
        "The gap between the label of one legend entry and the patch of the next."
        colgap = 20
        "The gap between the entry rows."
        rowgap = 4
        "The gap between the patch and the label of each legend entry."
        patchlabelgap = 5
        "The default points used for LineElements in normalized coordinates relative to each label patch."
        linepoints = [Point2f0(0, 0.5), Point2f0(1, 0.5)]
        "The default line width used for LineElements."
        linewidth = 3
        "The default marker points used for MarkerElements in normalized coordinates relative to each label patch."
        markerpoints = [Point2f0(0.5, 0.5)]
        "The default marker size used for MarkerElements."
        markersize = 12
        "The default marker stroke width used for MarkerElements."
        markerstrokewidth = 1
        "The default poly points used for PolyElements in normalized coordinates relative to each label patch."
        polypoints = [Point2f0(0, 0), Point2f0(1, 0), Point2f0(1, 1), Point2f0(0, 1)]
        "The default poly stroke width used for PolyElements."
        polystrokewidth = 1
        "The orientation of the legend (:horizontal or :vertical)."
        orientation = :vertical
        "The gap between each group title and its group."
        titlegap = 15
        "The gap between each group and the next."
        groupgap = 30
        "The horizontal alignment of entry groups in their parent GridLayout."
        gridshalign = :center
        "The vertical alignment of entry groups in their parent GridLayout."
        gridsvalign = :center
        "The align mode of the legend in its parent GridLayout."
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


function default_attributes(::Type{LScene}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the scene."
        height = nothing
        "The width setting of the scene."
        width = nothing
        "Controls if the parent layout can adjust to this element's width"
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height"
        tellheight = true
        "The horizontal alignment of the scene in its suggested bounding box."
        halign = :center
        "The vertical alignment of the scene in its suggested bounding box."
        valign = :center
        "The alignment of the scene in its suggested bounding box."
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




function default_attributes(::Type{LTextbox}, scene)
    attrs, docdict, defaultdict = @documented_attributes begin
        "The height setting of the textbox."
        height = Auto()
        "The width setting of the textbox."
        width = Auto()
        "Controls if the parent layout can adjust to this element's width."
        tellwidth = true
        "Controls if the parent layout can adjust to this element's height."
        tellheight = true
        "The horizontal alignment of the textbox in its suggested bounding box."
        halign = :center
        "The vertical alignment of the textbox in its suggested bounding box."
        valign = :center
        "The alignment of the textbox in its suggested bounding box."
        alignmode = Inside()
        "A placeholder text that is displayed when the saved string is nothing."
        placeholder = "Click to edit..."
        "The currently stored string."
        stored_string = nothing
        "The currently displayed string (for internal use)."
        displayed_string = nothing
        "Controls if the displayed text is reset to the stored text when defocusing the textbox without submitting."
        reset_on_defocus = false
        "Controls if the textbox is defocused when a string is submitted."
        defocus_on_submit = true
        "Text size."
        textsize = lift_parent_attribute(scene, :fontsize, 20f0)
        "Text color."
        textcolor = :black
        "Text color for the placeholder."
        textcolor_placeholder = RGBf0(0.5, 0.5, 0.5)
        "Font family."
        font = lift_parent_attribute(scene, :font, "DejaVu Sans")
        "Color of the box."
        boxcolor = :transparent
        "Color of the box when focused."
        boxcolor_focused = :transparent
        "Color of the box when focused."
        boxcolor_focused_invalid = RGBAf0(1, 0, 0, 0.3)
        "Color of the box when hovered."
        boxcolor_hover = :transparent
        "Color of the box border."
        bordercolor = RGBf0(0.80, 0.80, 0.80)
        "Color of the box border when hovered."
        bordercolor_hover = COLOR_ACCENT_DIMMED[]
        "Color of the box border when focused."
        bordercolor_focused = COLOR_ACCENT[]
        "Color of the box border when focused and invalid."
        bordercolor_focused_invalid = RGBf0(1, 0, 0)
        "Width of the box border."
        borderwidth = 2f0
        "Padding of the text against the box."
        textpadding = (10, 10, 10, 10)
        "If the textbox is focused and receives text input."
        focused = false
        "Corner radius of text box."
        cornerradius = 8
        "Corner segments of one rounded corner."
        cornersegments = 20
        "Validator that is called with validate_textbox(string, validator) to determine if the current string is valid. Can by default be a RegEx that needs to match the complete string, or a function taking a string as input and returning a Bool. If the validator is a type T (for example Float64), validation will be `tryparse(string, T)`."
        validator = str -> true
        "Restricts the allowed unicode input via is_allowed(char, restriction)."
        restriction = nothing
        "The color of the cursor."
        cursorcolor = :transparent
    end
    (attributes = attrs, documentation = docdict, defaults = defaultdict)
end

@doc """
    LTextbox(parent::Scene; bbox = nothing, kwargs...)
LTextbox has the following attributes:
$(let
    _, docs, defaults = default_attributes(LTextbox, nothing)
    docvarstring(docs, defaults)
end)
"""
LTextbox