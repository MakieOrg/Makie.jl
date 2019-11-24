function LayoutedAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedAxis))

    @extract attrs (
        xlabel, ylabel, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        xlabelcolor, ylabelcolor, xlabelsize, sidelabel, sidelabelsize, sidelabelgap,
        sidelabelvisible, sidelabelalign, sidelabelfont, sidelabelrotation,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelspace,
        yticklabelspace, xticklabelpad, yticklabelpad, xticklabelrotation, yticklabelrotation, xticklabelalign,
        yticklabelalign, xtickalign, ytickalign, xtickwidth, ytickwidth, xtickcolor,
        ytickcolor, xpanlock, ypanlock, xzoomlock, yzoomlock, spinewidth, xgridvisible, ygridvisible,
        xgridwidth, ygridwidth, xgridcolor, ygridcolor, topspinevisible, rightspinevisible, leftspinevisible,
        bottomspinevisible, topspinecolor, leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, alignment, maxsize, xticks, yticks, panbutton, xpankey, ypankey, xzoomkey, yzoomkey
    )

    decorations = Dict{Symbol, Any}()

    bboxnode = Node(BBox(0, 100, 100, 0))

    scenearea = Node(IRect(0, 0, 100, 100))

    scene = Scene(parent, scenearea, raw = true)
    limits = Node(FRect(0, 0, 100, 100))

    block_limit_linking = Node(false)

    connect_scenearea_and_bbox!(scenearea, bboxnode, limits, aspect, alignment, maxsize)

    plots = AbstractPlot[]

    xaxislinks = LayoutedAxis[]
    yaxislinks = LayoutedAxis[]

    add_pan!(scene, limits, xpanlock, ypanlock, panbutton, xpankey, ypankey)
    add_zoom!(scene, limits, xzoomlock, yzoomlock, xzoomkey, yzoomkey)

    campixel!(scene)

    # set up empty nodes for ticks and their labels
    xticksnode = Node(Point2f0[])
    xticklines = linesegments!(
        parent, xticksnode, linewidth = xtickwidth, color = xtickcolor,
        show_axis = false, visible = xticksvisible
    )[end]
    decorations[:xticklines] = xticklines

    yticksnode = Node(Point2f0[])
    yticklines = linesegments!(
        parent, yticksnode, linewidth = ytickwidth, color = ytickcolor,
        show_axis = false, visible = yticksvisible
    )[end]
    decorations[:yticklines] = xticklines

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        parent, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor
    )[end]
    decorations[:xgridlines] = xgridlines

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        parent, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor
    )[end]
    decorations[:ygridlines] = yticklines

    nmaxticks = 20

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            xticklabelnodes[i],
            position = xticklabelposnodes[i],
            align = xticklabelalign,
            rotation = xticklabelrotation,
            textsize = xticklabelsize,
            show_axis = false,
            visible = xticklabelsvisible
        )[end]
    end
    decorations[:xticklabels] = xticklabels

    yticklabelnodes = [Node("0") for i in 1:nmaxticks]
    yticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    yticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            yticklabelnodes[i],
            position = yticklabelposnodes[i],
            align = yticklabelalign,
            rotation = yticklabelrotation,
            textsize = yticklabelsize,
            show_axis = false,
            visible = yticklabelsvisible
        )[end]
    end
    decorations[:yticklabels] = yticklabels

    xlabelpos = lift(scene.px_area, xlabelvisible, xticklabelsvisible,
        xticklabelspace, xticklabelpad, xticklabelsize, xlabelpadding, spinewidth, xticksvisible,
        xticksize, xtickalign) do a, xlabelvisible, xticklabelsvisible,
                xticklabelspace, xticklabelpad, xticklabelsize, xlabelpadding, spinewidth, xticksvisible,
                xticksize, xtickalign

        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0

        labelgap = spinewidth +
            xtickspace +
            (xticklabelsvisible ? xticklabelspace + xticklabelpad : 0f0) +
            xlabelpadding

        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area, ylabelvisible, yticklabelsvisible,
        yticklabelspace, yticklabelpad, yticklabelsize, ylabelpadding, spinewidth, yticksvisible,
        yticksize, ytickalign) do a, ylabelvisible, yticklabelsvisible,
                yticklabelspace, yticklabelpad, yticklabelsize, ylabelpadding, spinewidth, yticksvisible,
                yticksize, ytickalign

        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0

        labelgap = spinewidth +
            ytickspace +
            (yticklabelsvisible ? yticklabelspace + yticklabelpad : 0f0) +
            ylabelpadding

        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    xlabeltext = text!(
        parent, xlabel, textsize = xlabelsize, color = xlabelcolor,
        position = xlabelpos, show_axis = false, visible = xlabelvisible,
        align = (:center, :top)
    )[end]
    decorations[:xlabeltext] = xlabeltext

    ylabeltext = text!(
        parent, ylabel, textsize = ylabelsize, color = ylabelcolor,
        position = ylabelpos, rotation = pi/2, show_axis = false,
        visible = ylabelvisible, align = (:center, :bottom)
    )[end]
    decorations[:ylabeltext] = ylabeltext

    titlepos = lift(scene.px_area, titlegap, titlealign) do a, titlegap, align
        x = if align == :center
            a.origin[1] + a.widths[1] / 2
        elseif align == :left
            a.origin[1]
        elseif align == :right
            a.origin[1] + a.widths[1]
        else
            error("Title align $align not supported.")
        end

        Point2(x, a.origin[2] + a.widths[2] + titlegap)
    end

    titlealignnode = lift(titlealign) do align
        (align, :bottom)
    end

    titlet = text!(
        parent, title,
        position = titlepos,
        visible = titlevisible,
        textsize = titlesize,
        align = titlealignnode,
        font = titlefont,
        show_axis=false)[end]
    decorations[:title] = titlet


    sidelabelbb = Node(BBox(0, 100, 100, 0))

    sidelabelpos = lift(scene.px_area, sidelabelgap, sidelabelalign, sidelabelbb) do a, sidelabelgap, align, sidelabelbb
        y = if align == :center
            a.origin[2] + a.widths[2] / 2
        elseif align == :bottom
            a.origin[2] + sidelabelbb.widths[2] / 2
        elseif align == :top
            a.origin[2] + a.widths[2] - sidelabelbb.widths[2] / 2
        else
            error("Title align $align not supported.")
        end

        Point2f0(a.origin[1] + a.widths[1] + sidelabelgap + sidelabelbb.widths[1] / 2, y)
    end

    sidelabelt = text!(
        parent, sidelabel,
        position = sidelabelpos,
        visible = sidelabelvisible,
        textsize = sidelabelsize,
        align = (:center, :center),
        font = sidelabelfont,
        rotation = sidelabelrotation,
        show_axis=false)[end]
    decorations[:sidelabel] = sidelabelt

    onany(sidelabelfont, sidelabelsize) do sidelabelfont, sidelabelsize
        sidelabelbb[] = BBox(boundingbox(sidelabelt))
    end

    # trigger the sidelabelsize observable already because otherwise the bounding
    # box further up will not be updated and the text will be in the wrong position
    sidelabelsize[] = sidelabelsize[]

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    xtickvalues = Node(Float32[])
    ytickvalues = Node(Float32[])

    # connect camera, plot size or limit changes to the axis decorations

    onany(pixelarea(scene), limits) do pxa, lims

        px_ox, px_oy = pxa.origin
        px_w, px_h = pxa.widths

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = lims.origin
        limw, limh = lims.widths

        projection = AbstractPlotting.orthographicprojection(
            limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection

        thisxlims = (limox, limox + limw)
        thisylims = (limoy, limoy + limh)


        # only change linked axis if not prohibited from doing so because
        # we're currently being updated by another axis' link
        if !block_limit_linking[]

            bothlinks = intersect(xaxislinks, yaxislinks)
            xlinks = setdiff(xaxislinks, yaxislinks)
            ylinks = setdiff(yaxislinks, xaxislinks)

            for link in bothlinks
                otherlims = link.limits[]
                if lims != otherlims
                    link.block_limit_linking[] = true
                    link.limits[] = lims
                    link.block_limit_linking[] = false
                end
            end

            for xlink in xlinks
                otherlims = xlink.limits[]
                otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
                otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
                if thisxlims != otherxlims
                    xlink.block_limit_linking[] = true
                    xlink.limits[] = BBox(thisxlims[1], thisxlims[2], otherylims[2], otherylims[1])
                    xlink.block_limit_linking[] = false
                end
            end

            for ylink in ylinks
                otherlims = ylink.limits[]
                otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
                otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
                if thisylims != otherylims
                    ylink.block_limit_linking[] = true
                    ylink.limits[] = BBox(otherxlims[1], otherxlims[2], thisylims[2], thisylims[1])
                    ylink.block_limit_linking[] = false
                end
            end
        end
    end

    # change tick values with scene, limits and tick distance preference

    onany(pixelarea(scene), limits, xticks) do pxa, limits, xticks
        limox = limits.origin[1]
        limw = limits.widths[1]
        px_w = pxa.widths[1]

        xtickvalues[] = compute_tick_values(xticks, limox, limox + limw, px_w)
    end

    onany(pixelarea(scene), limits, yticks) do pxa, limits, yticks
        limoy = limits.origin[2]
        limh = limits.widths[2]
        px_h = pxa.widths[2]

        ytickvalues[] = compute_tick_values(yticks, limoy, limoy + limh, px_h)
    end

    xtickpositions = Node(Point2f0[])
    xtickstrings = Node(String[])

    # change tick positions when tick values change, also update grid and tick strings

    on(xtickvalues) do xtickvalues
        limox = limits[].origin[1]
        limw = limits[].widths[1]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        xfractions = (xtickvalues .- limox) ./ limw
        xticks_scene = px_ox .+ px_w .* xfractions

        xtickpos = [Point(x, px_oy) for x in xticks_scene]
        topxtickpositions = [xtp + Point2f0(0, px_h) for xtp in xtickpos]

        xgridnode[] = interleave_vectors(xtickpos, topxtickpositions)

        # now trigger updates
        xtickpositions[] = xtickpos

        xtickstrings[] = get_tick_labels(xticks[], xtickvalues)
    end

    ytickpositions = Node(Point2f0[])
    ytickstrings = Node(String[])

    on(ytickvalues) do ytickvalues
        limoy = limits[].origin[2]
        limh = limits[].widths[2]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        yfractions = (ytickvalues .- limoy) ./ limh
        yticks_scene = px_oy .+ px_h .* yfractions

        ytickpos = [Point(px_ox, y) for y in yticks_scene]
        rightytickpositions = [ytp + Point2f0(px_w, 0) for ytp in ytickpos]

        ygridnode[] = interleave_vectors(ytickpos, rightytickpositions)

        # now trigger updates
        ytickpositions[] = ytickpos

        ytickstrings[] = get_tick_labels(yticks[], ytickvalues)
    end

    # update tick labels when strings or properties change


    onany(xtickstrings, xticklabelpad, spinewidth, xticklabelsvisible, xticksize, xtickalign, xticksvisible) do xtickstrings,
            xticklabelpad, spinewidth, xticklabelsvisible, xticksize, xtickalign, xticksvisible

        nxticks = length(xtickvalues[])

        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0

        for i in 1:length(xticklabels)
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]

                xticklabelgap = spinewidth + xtickspace + xticklabelpad

                xticklabelposnodes[i][] = xtickpositions[][i] +
                    Point(0f0, -xticklabelgap)
                xticklabels[i].visible = true && xticklabelsvisible
            else
                xticklabels[i].visible = false
            end
        end
    end

    onany(ytickstrings, yticklabelpad, spinewidth, yticklabelsvisible, yticksize, ytickalign, yticksvisible) do ytickstrings,
            yticklabelpad, spinewidth, yticklabelsvisible, yticksize, ytickalign, yticksvisible

        nyticks = length(ytickvalues[])

        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0

        for i in 1:length(yticklabels)
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]

                yticklabelgap = spinewidth + ytickspace + yticklabelpad

                yticklabelposnodes[i][] = ytickpositions[][i] +
                    Point(-yticklabelgap, 0f0)
                yticklabels[i].visible = true && yticklabelsvisible
            else
                yticklabels[i].visible = false
            end
        end
    end

    # update tick geometry when positions or parameters change

    onany(xtickpositions, xtickalign, xticksize, spinewidth) do xtickpositions,
            xtickalign, xticksize, spinewidth

        xtickstarts = [xtp + Point(0f0, xtickalign * xticksize - 0.5f0 * spinewidth) for xtp in xtickpositions]
        xtickends = [t + Point(0f0, -xticksize) for t in xtickstarts]

        xticksnode[] = interleave_vectors(xtickstarts, xtickends)
    end

    onany(ytickpositions, ytickalign, yticksize, spinewidth) do ytickpositions,
            ytickalign, yticksize, spinewidth

        ytickstarts = [ytp + Point(ytickalign * yticksize - 0.5f0 * spinewidth, 0f0) for ytp in ytickpositions]
        ytickends = [t + Point(-yticksize, 0f0) for t in ytickstarts]

        yticksnode[] = interleave_vectors(ytickstarts, ytickends)
    end



    function compute_protrusions(xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
                ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding,
                ylabelpadding, xticklabelsize, yticklabelsize, xticklabelsvisible,
                yticklabelsvisible, xticksize, yticksize, xticksvisible, yticksvisible,
                xticklabelspace, yticklabelspace, xticklabelpad, yticklabelpad, xtickalign, ytickalign, spinewidth,
                sidelabel, sidelabelsize, sidelabelgap, sidelabelvisible, sidelabelrotation)

        top = titlevisible ? boundingbox(titlet).widths[2] + titlegap : 0f0

        xlabelspace = xlabelvisible ? boundingbox(xlabeltext).widths[2] + xlabelpadding : 0f0
        xspinespace = spinewidth
        xtickspace = xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0
        xticklabelgap = xticklabelsvisible ? xticklabelspace + xticklabelpad : 0f0

        bottom = xspinespace + xtickspace + xticklabelgap + xlabelspace

        ylabelspace = ylabelvisible ? boundingbox(ylabeltext).widths[1] + ylabelpadding : 0f0
        yspinespace = spinewidth
        ytickspace = yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0
        yticklabelgap = yticklabelsvisible ? yticklabelspace + yticklabelpad : 0f0

        left = yspinespace + ytickspace + yticklabelgap + ylabelspace

        right = sidelabelvisible ? boundingbox(sidelabelt).widths[1] + sidelabelgap : 0f0

        (left, right, top, bottom)
    end

    protrusions = lift(compute_protrusions,
        xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelspace,
        yticklabelspace, xticklabelpad, yticklabelpad, xtickalign, ytickalign, spinewidth,
        sidelabel, sidelabelsize, sidelabelgap, sidelabelvisible, sidelabelrotation)

    needs_update = Node(true)

    # trigger a layout update whenever the protrusions change
    on(protrusions) do prot
        needs_update[] = true
    end

    la = LayoutedAxis(parent, scene, plots, xaxislinks, yaxislinks, bboxnode, limits,
        protrusions, needs_update, attrs, block_limit_linking, decorations)

    add_reset_limits!(la)

    la
end

function compute_tick_values(ticks::T, vmin, vmax, pxwidth) where T
    error("No behavior implemented for ticks of type $T")
end

function compute_tick_values(ticks::AutoLinearTicks, vmin, vmax, pxwidth)
    locateticks(vmin, vmax, pxwidth, ticks.idealtickdistance)
end

function compute_tick_values(ticks::ManualTicks, vmin, vmax, pxwidth)
    # only show manual ticks that fit in the value range
    filter(ticks.values) do v
        vmin <= v <= vmax
    end
end

function get_tick_labels(ticks::T, tickvalues) where T
    error("No behavior implemented for ticks of type $T")
end

function get_tick_labels(ticks::AutoLinearTicks, tickvalues)

    # take difference of first two values (they are equally spaced anyway)
    dif = diff(view(tickvalues, 1:2))[1]
    # whats the exponent of the difference?
    expo = log10(dif)

    # all difs bigger than one should be integers with the normal step sizes
    dif_is_integer = dif > 0.99999
    # this condition means that the exponent is close to an integer, so the numbers
    # would have a trailing zero with the safety applied
    exp_is_integer = isapprox(abs(expo) % 1 - 1, 0, atol=1e-6)

    safety_expo_int = if dif_is_integer || exp_is_integer
        Int(round(expo))
    else
        safety_expo_int = Int(round(expo)) - 1
    end
    # for e.g. 1.32 we want 2 significant digits, so we invert the exponent
    # and set precision to 0 for everything that is an integer
    sigdigits = max(0, -safety_expo_int)

    strings = map(tickvalues) do v
        Formatting.format(v, precision=sigdigits)
    end
end

function get_tick_labels(ticks::ManualTicks, tickvalues)
    # remove labels of ticks that are not shown because the limits cut them off
    String[ticks.labels[findfirst(x -> x == tv, ticks.values)] for tv in tickvalues]
end

function AbstractPlotting.plot!(
        la::LayoutedAxis, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(la.scene, P, attributes, args...; kw_attributes...)[end]

    # axiscontent = AxisContent(plot, xautolimit=xautolimit, yautolimit=yautolimit)
    axiscontent = AxisContent(plot)
    push!(la.plots, axiscontent)
    autolimits!(la)
    plot

end

function align_to_bbox!(la::LayoutedAxis, bb::BBox)
    la.bboxnode[] = bb
end

function protrusionnode(la::LayoutedAxis)
    # work around the new optional protrusions
    node = Node{Union{Nothing, NTuple{4, Float32}}}(la.protrusions[])
    on(la.protrusions) do p
        node[] = p
    end
    node
end

function bboxunion(bb1, bb2)

    o1 = bb1.origin
    o2 = bb2.origin
    e1 = bb1.origin + bb1.widths
    e2 = bb2.origin + bb2.widths

    o = min.(o1, o2)
    e = max.(e1, e2)

    BBox(o[1], e[1], e[2], o[2])
end

function expandbboxwithfractionalmargins(bb, margins)
    newwidths = bb.widths .* (1f0 .+ margins)
    diffs = newwidths .- bb.widths
    neworigin = bb.origin .- (0.5f0 .* diffs)
    FRect2D(neworigin, newwidths)
end

function limitunion(lims1, lims2)
    (min(lims1..., lims2...), max(lims1..., lims2...))
end

function expandlimits(lims, marginleft, marginright)
    limsordered = (min(lims[1], lims[2]), max(lims[1], lims[2]))
    w = limsordered[2] - limsordered[1]
    dleft = w * marginleft
    dright = w * marginright
    lims = (limsordered[1] - dleft, limsordered[2] + dright)

    # guard against singular limits from something like a vline or hline
    if lims[2] - lims[1] == 0
        lims = lims .+ (-10, 10)
    end
    lims
end

function getlimits(la::LayoutedAxis, dim)

    limitables = if dim == 1
        filter(p -> p.attributes.xautolimit[], la.plots)
    elseif dim == 2
        filter(p -> p.attributes.yautolimit[], la.plots)
    end

    lim = if length(limitables) > 0
        bbox = BBox(boundingbox(limitables[1].content))
        templim = (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim])
        for p in limitables[2:end]
            bbox = BBox(boundingbox(p.content))
            templim = limitunion(templim, (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim]))
        end
        templim
    else
        nothing
    end
end

getxlimits(la::LayoutedAxis) = getlimits(la, 1)
getylimits(la::LayoutedAxis) = getlimits(la, 2)


function autolimits!(la::LayoutedAxis)

    xlims = getxlimits(la)
    for link in la.xaxislinks
        if isnothing(xlims)
            xlims = getxlimits(link)
        else
            newxlims = getxlimits(link)
            if !isnothing(newxlims)
                xlims = limitunion(xlims, newxlims)
            end
        end
    end
    if isnothing(xlims)
        xlims = (la.limits[].origin[1], la.limits[].origin[1] + la.limits[].widths[1])
    else
        xlims = expandlimits(xlims,
            la.attributes.xautolimitmargin[][1],
            la.attributes.xautolimitmargin[][2])
    end

    ylims = getylimits(la)
    for link in la.yaxislinks
        if isnothing(ylims)
            ylims = getylimits(link)
        else
            newylims = getylimits(link)
            if !isnothing(newylims)
                ylims = limitunion(ylims, newylims)
            end
        end
    end
    if isnothing(ylims)
        ylims = (la.limits[].origin[2], la.limits[].origin[2] + la.limits[].widths[2])
    else
        ylims = expandlimits(ylims,
            la.attributes.yautolimitmargin[][1],
            la.attributes.yautolimitmargin[][2])
    end

    bbox = BBox(xlims[1], xlims[2], ylims[2], ylims[1])
    la.limits[] = bbox
end

function linkxaxes!(a::LayoutedAxis, others...)
    axes = LayoutedAxis[a; others...]

    for i in 1:length(axes)-1
        for j in i+1:length(axes)
            axa = axes[i]
            axb = axes[j]

            if axa ∉ axb.xaxislinks
                push!(axb.xaxislinks, axa)
            end
            if axb ∉ axa.xaxislinks
                push!(axa.xaxislinks, axb)
            end
        end
    end
end

function linkyaxes!(a::LayoutedAxis, others...)
    axes = LayoutedAxis[a; others...]

    for i in 1:length(axes)-1
        for j in i+1:length(axes)
            axa = axes[i]
            axb = axes[j]

            if axa ∉ axb.yaxislinks
                push!(axb.yaxislinks, axa)
            end
            if axb ∉ axa.yaxislinks
                push!(axa.yaxislinks, axb)
            end
        end
    end
end

function add_pan!(scene::SceneLike, limits, xpanlock, ypanlock, panbutton, xpankey, ypankey)
    startpos = Base.RefValue((0.0, 0.0))
    e = events(scene)
    on(
        camera(scene),
        # Node.((scene, cam, startpos))...,
        Node.((scene, startpos))...,
        e.mousedrag
    ) do scene, startpos, dragging
        mp = e.mouseposition[]
        if ispressed(scene, panbutton[]) && is_mouseinside(scene)
            window_area = pixelarea(scene)[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, panbutton[])
                diff = startpos[] .- mp
                startpos[] = mp
                pxa = scene.px_area[]
                diff_fraction = Vec2f0(diff) ./ Vec2f0(widths(pxa))

                diff_limits = diff_fraction .* widths(limits[])

                xori, yori = Vec2f0(limits[].origin) .+ Vec2f0(diff_limits)

                if xpanlock[] || ispressed(scene, ypankey[])
                    xori = limits[].origin[1]
                end

                if ypanlock[] || ispressed(scene, xpankey[])
                    yori = limits[].origin[2]
                end

                limits[] = FRect(Vec2f0(xori, yori), widths(limits[]))
            end
        end
        return
    end
end

function add_zoom!(scene::SceneLike, limits, xzoomlock, yzoomlock, xzoomkey, yzoomkey)

    e = events(scene)
    cam = camera(scene)
    on(cam, e.scroll) do x
        # @extractvalue cam (zoomspeed, zoombutton, area)
        zoomspeed = 0.10f0
        zoombutton = nothing
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) && AbstractPlotting.is_mouseinside(scene)
            pa = pixelarea(scene)[]

            # don't let z go negative
            z = max(0.1f0, 1f0 + (zoom * zoomspeed))

            # limits[] = FRect(limits[].origin..., (limits[].widths .* 0.99)...)
            mp_fraction = (Vec2f0(e.mouseposition[]) - minimum(pa)) ./ widths(pa)

            mp_data = limits[].origin .+ mp_fraction .* limits[].widths

            xorigin = limits[].origin[1]
            yorigin = limits[].origin[2]

            xwidth = limits[].widths[1]
            ywidth = limits[].widths[2]

            newxwidth = xzoomlock[] ? xwidth : xwidth * z
            newywidth = yzoomlock[] ? ywidth : ywidth * z

            newxorigin = xzoomlock[] ? xorigin : xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yzoomlock[] ? yorigin : yorigin + mp_fraction[2] * (ywidth - newywidth)

            if AbstractPlotting.ispressed(scene, xzoomkey[])
                limits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, yzoomkey[])
                limits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                limits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end
end

function add_reset_limits!(la::LayoutedAxis)
    scene = la.scene
    e = events(scene)
    cam = camera(scene)
    on(cam, e.mousebuttons) do buttons
        if ispressed(scene, AbstractPlotting.Mouse.left) && AbstractPlotting.is_mouseinside(scene)
            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.left_control)
                autolimits!(la)
            end
        end
        return
    end
end

function Base.getproperty(la::LayoutedAxis, s::Symbol)
    if s in fieldnames(LayoutedAxis)
        getfield(la, s)
    else
        la.attributes[s]
    end
end

function Base.setproperty!(la::LayoutedAxis, s::Symbol, value)
    if s in fieldnames(LayoutedAxis)
        setfield!(la, s, value)
    else
        la.attributes[s][] = value
    end
end

function Base.propertynames(la::LayoutedAxis)
    [fieldnames(LayoutedAxis)..., keys(la.attributes)...]
end

defaultlayout(la::LayoutedAxis) = ProtrusionLayout(la)

function hidexdecorations!(la::LayoutedAxis)
    la.xlabelvisible = false
    la.xticklabelsvisible = false
    la.xticksvisible = false
end

function hideydecorations!(la::LayoutedAxis)
    la.ylabelvisible = false
    la.yticklabelsvisible = false
    la.yticksvisible = false
end


function tight_yticklabel_spacing!(la::LayoutedAxis)
    maxwidth = maximum(la.decorations[:yticklabels]) do yt
        boundingbox(yt).widths[1]
    end
    la.yticklabelspace = maxwidth
end

function tight_xticklabel_spacing!(la::LayoutedAxis)
    maxheight = maximum(la.decorations[:xticklabels]) do xt
        boundingbox(xt).widths[2]
    end
    la.xticklabelspace = maxheight
end

function tight_ticklabel_spacing!(la::LayoutedAxis)
    tight_xticklabel_spacing!(la)
    tight_yticklabel_spacing!(la)
end

function AxisContent(plot; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(AxisContent))

    AxisContent(plot, attrs)
end
