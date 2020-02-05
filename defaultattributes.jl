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
    Attributes(
        xlabel = " ",
        ylabel = " ",
        title = " ",
        titlefont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        titlesize = lift_parent_attribute(scene, :fontsize, 20f0),
        titlegap = 10f0,
        titlevisible = true,
        titlealign = :center,
        xlabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        ylabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        xlabelcolor = RGBf0(0, 0, 0),
        ylabelcolor = RGBf0(0, 0, 0),
        xlabelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        ylabelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        xlabelvisible = true,
        ylabelvisible = true,
        xlabelpadding = 10f0,
        ylabelpadding = 15f0, # because of boundingbox inaccuracies of ticklabels
        xticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        yticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        xticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        yticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        xticklabelsvisible = true,
        yticklabelsvisible = true,
        xticklabelspace = 20f0,
        yticklabelspace = 50f0,
        xticklabelpad = 5f0,
        yticklabelpad = 5f0,
        xticklabelrotation = 0f0,
        yticklabelrotation = 0f0,
        xticklabelalign = (:center, :top),
        yticklabelalign = (:right, :center),
        xticksize = 10f0,
        yticksize = 10f0,
        xticksvisible = true,
        yticksvisible = true,
        xtickalign = 0f0,
        ytickalign = 0f0,
        xtickwidth = 1f0,
        ytickwidth = 1f0,
        xtickcolor = RGBf0(0, 0, 0),
        ytickcolor = RGBf0(0, 0, 0),
        xpanlock = false,
        ypanlock = false,
        xzoomlock = false,
        yzoomlock = false,
        spinewidth = 1f0,
        xgridvisible = true,
        ygridvisible = true,
        xgridwidth = 1f0,
        ygridwidth = 1f0,
        xgridcolor = RGBAf0(0, 0, 0, 0.1),
        ygridcolor = RGBAf0(0, 0, 0, 0.1),
        xgridstyle = nothing,
        ygridstyle = nothing,
        bottomspinevisible = true,
        leftspinevisible = true,
        topspinevisible = true,
        rightspinevisible = true,
        bottomspinecolor = :black,
        leftspinecolor = :black,
        topspinecolor = :black,
        rightspinecolor = :black,
        aspect = nothing,
        valign = :center,
        halign = :center,
        width = nothing,
        height = nothing,
        maxsize = (Inf32, Inf32),
        xautolimitmargin = (0.05f0, 0.05f0),
        yautolimitmargin = (0.05f0, 0.05f0),
        xticks = AutoLinearTicks(80f0),
        yticks = AutoLinearTicks(60f0),
        panbutton = AbstractPlotting.Mouse.right,
        xpankey = AbstractPlotting.Keyboard.x,
        ypankey = AbstractPlotting.Keyboard.y,
        xzoomkey = AbstractPlotting.Keyboard.x,
        yzoomkey = AbstractPlotting.Keyboard.y,
        xaxisposition = :bottom,
        yaxisposition = :left,
        xtrimspine = false,
        ytrimspine = false,
        backgroundcolor = :white,
    )
end

function default_attributes(::Type{LColorbar}, scene)
    Attributes(
        label = " ",
        labelcolor = RGBf0(0, 0, 0),
        labelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        labelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        labelvisible = true,
        labelpadding = 5f0,
        ticklabelfont = lift_parent_attribute(scene, :font, "DejaVu Sans"),
        ticklabelsize = lift_parent_attribute(scene, :fontsize, 20f0),
        ticklabelsvisible = true,
        ticksize = 10f0,
        ticksvisible = true,
        ticks = AutoLinearTicks(100f0),
        ticklabelspace = 30f0,
        ticklabelpad = 5f0,
        tickalign = 0f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        ticklabelalign = (:left, :center),
        spinewidth = 1f0,
        idealtickdistance = 100f0,
        topspinevisible = true,
        rightspinevisible = true,
        leftspinevisible = true,
        bottomspinevisible = true,
        topspinecolor = RGBf0(0, 0, 0),
        leftspinecolor = RGBf0(0, 0, 0),
        rightspinecolor = RGBf0(0, 0, 0),
        bottomspinecolor = RGBf0(0, 0, 0),
        valign = :center,
        halign = :center,
        vertical = true,
        flipaxisposition = true,
        width = nothing,
        height = nothing,
        colormap = :viridis,
        limits = (0f0, 1f0),
    )
end

function default_attributes(::Type{LText})
    Attributes(
        text = "Text",
        visible = true,
        color = RGBf0(0, 0, 0),
        textsize = 20f0,
        font = "Dejavu Sans",
        valign = :center,
        halign = :center,
        rotation = 0f0,
        padding = (0f0, 0f0, 0f0, 0f0),
        height = Auto(),
        width = Auto(),
    )
end

function default_attributes(::Type{LRect})
    Attributes(
        visible = true,
        color = RGBf0(0.9, 0.9, 0.9),
        valign = :center,
        halign = :center,
        padding = (0f0, 0f0, 0f0, 0f0),
        strokewidth = 2f0,
        strokevisible = true,
        strokecolor = RGBf0(0, 0, 0),
        width = nothing,
        height = nothing,
    )
end

function default_attributes(::Type{LButton})
    Attributes(
        halign = :center,
        valign = :center,
        padding = (10f0, 10f0, 10f0, 10f0),
        textsize = 20f0,
        label = "Button",
        font = "Dejavu Sans",
        width = Auto(true),
        height = Auto(true),
        cornerradius = 4,
        cornersegments = 10,
        strokewidth = 2f0,
        strokecolor = :transparent,
        buttoncolor = RGBf0(0.9, 0.9, 0.9),
        labelcolor = :black,
        labelcolor_hover = :black,
        labelcolor_active = :white,
        buttoncolor_active = COLOR_ACCENT[],
        # buttoncolor_hover = RGBf0(0.8, 0.8, 0.8),
        buttoncolor_hover = COLOR_ACCENT_DIMMED[],
        clicks = 0,
    )
end

function default_attributes(::Type{LineAxis})
    Attributes(
        endpoints = (Point2f0(0, 0), Point2f0(100, 0)),
        trimspine = false,
        limits = (0f0, 100f0),
        flipped = false,
        ticksize = 10f0,
        tickwidth = 1f0,
        tickcolor = RGBf0(0, 0, 0),
        tickalign = 0f0,
        ticks = AutoLinearTicks(100f0),
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
        ticklabelspace = 30f0,
        ticklabelpad = 5f0,
        labelpadding = 10f0,
    )
end

function default_attributes(::Type{LSlider})
    Attributes(
        linewidth = 4f0,
        halign = :center,
        valign = :center,
        # vertical = true,
        width = nothing,
        height = Auto(true),
        range = 0:10,
        buttonradius = 7f0,
        startvalue = 0,
        value = 0,
        color_active_dimmed = COLOR_ACCENT_DIMMED[],
        color_active = COLOR_ACCENT[],
        color_inactive = RGBf0(0.9, 0.9, 0.9),
        buttoncolor_inactive = RGBf0(1, 1, 1),
        horizontal = true,
        buttonstrokewidth = 4f0,
    )
end

function default_attributes(::Type{LToggle})
    Attributes(
        halign = :center,
        valign = :center,
        width = 60,
        height = 30,
        cornersegments = 10,
        # strokewidth = 2f0,
        # strokecolor = :transparent,
        framecolor_inactive = RGBf0(0.9, 0.9, 0.9),
        framecolor_active = COLOR_ACCENT[],
        # buttoncolor = RGBf0(0.2, 0.2, 0.2),
        buttoncolor = RGBf0(1, 1, 1),
        active = false,
        toggleduration = 0.2,
        rimfraction = 0.25,
    )
end


function default_attributes(::Type{LLegend})
    Attributes(
        halign = :center,
        valign = :center,
        width = Auto(true),
        height = Auto(false),
        title = "Legend",
        titlefont = "Dejavu Sans",
        titlesize = 20f0,
        titlealign = :center,
        titlevisible = true,
        labelsize = 20f0,
        labelfont = "Dejavu Sans",
        labelcolor = :black,
        labelhalign = :left,
        labelvalign = :center,
        padding = (10f0, 10f0, 10f0, 10f0),
        margin = (0f0, 0f0, 0f0, 0f0),
        bgcolor = :white,
        strokecolor = :black,
        strokewidth = 1f0,
        patchsize = (40f0, 40f0),
        patchstrokecolor = :transparent,
        patchstrokewidth = 1f0,
        patchcolor = RGBf0(0.97, 0.97, 0.97),
        label = "undefined",
        ncols = 1,
        colgap = 20,
        rowgap = 4,
        patchlabelgap = 5,
        linepoints = [Point2f0(0, 0.5), Point2f0(1, 0.5)],
        linewidth = 3,
        markerpoints = [Point2f0(0.5, 0.5)],
        markersize = 16,
        markerstrokewidth = 2,
        polypoints = [Point2f0(0.2, 0.2), Point2f0(0.8, 0.2), Point2f0(0.8, 0.8), Point2f0(0.2, 0.8)],
        polystrokewidth = 2,
    )
end


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
    Attributes(
        height = nothing,
        width = nothing,
        halign = :center,
        valign = :center,
    )
end
