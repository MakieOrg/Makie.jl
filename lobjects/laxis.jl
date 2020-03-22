"""
    LAxis(parent::Scene; bbox = nothing, kwargs...)

Creates an `LAxis` object in the parent `Scene` which consists of a child scene
with orthographic projection for 2D plots and axis decorations that live in the
parent.
"""
function LAxis(parent::Scene; bbox = nothing, kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LAxis, parent))

    @extract attrs (
        title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        xlabel, ylabel, xlabelcolor, ylabelcolor, xlabelsize, ylabelsize,
        xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible,
        xticklabelspace, yticklabelspace, xticklabelpad, yticklabelpad,
        xticklabelrotation, yticklabelrotation, xticklabelalign, yticklabelalign,
        xtickalign, ytickalign, xtickwidth, ytickwidth, xtickcolor, ytickcolor,
        xpanlock, ypanlock, xzoomlock, yzoomlock,
        spinewidth, xtrimspine, ytrimspine,
        xgridvisible, ygridvisible, xgridwidth, ygridwidth, xgridcolor, ygridcolor,
        xgridstyle, ygridstyle,
        aspect, halign, valign, maxsize, xticks, yticks, panbutton,
        xpankey, ypankey, xzoomkey, yzoomkey,
        xaxisposition, yaxisposition,
        bottomspinevisible, leftspinevisible, topspinevisible, rightspinevisible,
        bottomspinecolor, leftspinecolor, topspinecolor, rightspinecolor,
        backgroundcolor,
        xlabelfont, ylabelfont, xticklabelfont, yticklabelfont,
        flip_ylabel
    )

    decorations = Dict{Symbol, Any}()

    layoutobservables = LayoutObservables(LAxis, attrs.width, attrs.height, halign, valign; suggestedbbox = bbox)

    limits = Node(FRect(0, 0, 100, 100))

    scenearea = sceneareanode!(layoutobservables.computedbbox, limits, aspect)

    scene = Scene(parent, scenearea, raw = true)

    background = poly!(parent, scenearea, color = backgroundcolor, strokewidth = 0, raw = true)[end]
    translate!(background, 0, 0, -100)

    block_limit_linking = Node(false)

    xaxislinks = LAxis[]
    yaxislinks = LAxis[]

    campixel!(scene)

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        parent, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor, linestyle = xgridstyle,
    )[end]
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    decorations[:xgridlines] = xgridlines

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        parent, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor, linestyle = ygridstyle,
    )[end]
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    decorations[:ygridlines] = ygridlines



    on(limits) do lims

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = lims.origin
        limw, limh = lims.widths

        projection = AbstractPlotting.orthographicprojection(
            limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection
    end

    latest_tlimits = Ref(limits[])
    isupdating = Ref(false)
    missedupdate = Ref(false)

    on(attrs.targetlimits) do tlims
        latest_tlimits[] = tlims

        if !isupdating[]
            @async begin
                isupdating[] = true
                while true
                    missedupdate[] = false
                    update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, latest_tlimits[])
                    if !missedupdate[]
                        # the limit updating happens in async so there could be
                        # a new set of limits once that's done, in that case just
                        # do another update
                        break
                    end
                end
                isupdating[] = false
            end
        else
            # this means that the limits will be updated once more
            missedupdate[] = true
        end
    end

    xaxis_endpoints = lift(xaxisposition, scene.px_area) do xaxisposition, area
        if xaxisposition == :bottom
            bottomline(BBox(area))
        elseif xaxisposition == :top
            topline(BBox(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    yaxis_endpoints = lift(yaxisposition, scene.px_area) do yaxisposition, area
        if yaxisposition == :left
            leftline(BBox(area))
        elseif yaxisposition == :right
            rightline(BBox(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    xaxis_flipped = lift(x->x == :top, xaxisposition)
    yaxis_flipped = lift(x->x == :right, yaxisposition)

    xspinevisible = lift(xaxis_flipped, bottomspinevisible, topspinevisible) do xflip, bv, tv
        xflip ? tv : bv
    end
    xoppositespinevisible = lift(xaxis_flipped, bottomspinevisible, topspinevisible) do xflip, bv, tv
        xflip ? bv : tv
    end
    yspinevisible = lift(yaxis_flipped, leftspinevisible, rightspinevisible) do yflip, lv, rv
        yflip ? rv : lv
    end
    yoppositespinevisible = lift(yaxis_flipped, leftspinevisible, rightspinevisible) do yflip, lv, rv
        yflip ? lv : rv
    end
    xspinecolor = lift(xaxis_flipped, bottomspinecolor, topspinecolor) do xflip, bc, tc
        xflip ? tc : bc
    end
    xoppositespinecolor = lift(xaxis_flipped, bottomspinecolor, topspinecolor) do xflip, bc, tc
        xflip ? bc : tc
    end
    yspinecolor = lift(yaxis_flipped, leftspinecolor, rightspinecolor) do yflip, lc, rc
        yflip ? rc : lc
    end
    yoppositespinecolor = lift(yaxis_flipped, leftspinecolor, rightspinecolor) do yflip, lc, rc
        yflip ? lc : rc
    end

    xaxis = LineAxis(parent, endpoints = xaxis_endpoints, limits = lift(xlimits, limits),
        flipped = xaxis_flipped, ticklabelrotation = xticklabelrotation,
        ticklabelalign = xticklabelalign, labelsize = xlabelsize,
        labelpadding = xlabelpadding, ticklabelpad = xticklabelpad, labelvisible = xlabelvisible,
        label = xlabel, labelfont = xlabelfont, ticklabelfont = xticklabelfont, labelcolor = xlabelcolor, tickalign = xtickalign,
        ticklabelspace = xticklabelspace, ticks = xticks, ticklabelsvisible = xticklabelsvisible,
        ticksvisible = xticksvisible, spinevisible = xspinevisible, spinecolor = xspinecolor,
        ticklabelsize = xticklabelsize, trimspine = xtrimspine, ticksize = xticksize)
    decorations[:xaxis] = xaxis

    yaxis  =  LineAxis(parent, endpoints = yaxis_endpoints, limits = lift(ylimits, limits),
        flipped = yaxis_flipped, ticklabelrotation = yticklabelrotation,
        ticklabelalign = yticklabelalign, labelsize = ylabelsize,
        labelpadding = ylabelpadding, ticklabelpad = yticklabelpad, labelvisible = ylabelvisible,
        label = ylabel, labelfont = ylabelfont, ticklabelfont = yticklabelfont, labelcolor = ylabelcolor, tickalign = ytickalign,
        ticklabelspace = yticklabelspace, ticks = yticks, ticklabelsvisible = yticklabelsvisible,
        ticksvisible = yticksvisible, spinevisible = yspinevisible, spinecolor = yspinecolor,
        trimspine = ytrimspine, ticklabelsize = yticklabelsize, ticksize = yticksize, flip_vertical_label = flip_ylabel)
    decorations[:yaxis] = yaxis

    xoppositelinepoints = lift(scene.px_area, spinewidth, xaxisposition) do r, sw, xaxpos
        if xaxpos == :top
            y = bottom(r) - 0.5f0 * sw
            p1 = Point2(left(r) - sw, y)
            p2 = Point2(right(r) + sw, y)
            [p1, p2]
        else
            y = top(r) + 0.5f0 * sw
            p1 = Point2(left(r) - sw, y)
            p2 = Point2(right(r) + sw, y)
            [p1, p2]
        end
    end

    yoppositelinepoints = lift(scene.px_area, spinewidth, yaxisposition) do r, sw, yaxpos
        if yaxpos == :right
            x = left(r) - 0.5f0 * sw
            p1 = Point2(x, bottom(r) - sw)
            p2 = Point2(x, top(r) + sw)
            [p1, p2]
        else
            x = right(r) + 0.5f0 * sw
            p1 = Point2(x, bottom(r) - sw)
            p2 = Point2(x, top(r) + sw)
            [p1, p2]
        end
    end

    xoppositeline = lines!(parent, xoppositelinepoints, linewidth = spinewidth,
        visible = xoppositespinevisible, color = xoppositespinecolor)
    decorations[:xoppositeline] = xoppositeline
    yoppositeline = lines!(parent, yoppositelinepoints, linewidth = spinewidth,
        visible = yoppositespinevisible, color = yoppositespinecolor)
    decorations[:yoppositeline] = yoppositeline

    on(xaxis.tickpositions) do tickpos
        pxheight = height(scene.px_area[])
        offset = xaxisposition[] == :bottom ? pxheight : -pxheight
        opposite_tickpos = tickpos .+ Ref(Point2f0(0, offset))
        xgridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    on(yaxis.tickpositions) do tickpos
        pxwidth = width(scene.px_area[])
        offset = yaxisposition[] == :left ? pxwidth : -pxwidth
        opposite_tickpos = tickpos .+ Ref(Point2f0(offset, 0))
        ygridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    titlepos = lift(scene.px_area, titlegap, titlealign, xaxisposition, xaxis.protrusion) do a,
            titlegap, align, xaxisposition, xaxisprotrusion

        x = if align == :center
            a.origin[1] + a.widths[1] / 2
        elseif align == :left
            a.origin[1]
        elseif align == :right
            a.origin[1] + a.widths[1]
        else
            error("Title align $align not supported.")
        end

        yoffset = top(a) + titlegap + (xaxisposition == :top ? xaxisprotrusion : 0f0)

        Point2(x, yoffset)
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

    function compute_protrusions(title, titlesize, titlegap, titlevisible, spinewidth,
                xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition)

        top = if !titlevisible || iswhitespace(title)
            0f0
        else
            boundingbox(titlet).widths[2] + titlegap
        end

        bottom = spinewidth

        if xaxisposition == :bottom
            bottom += xaxisprotrusion
        else
            top += xaxisprotrusion
        end

        left = spinewidth

        right = spinewidth

        if yaxisposition == :left
            left += yaxisprotrusion
        else
            right += yaxisprotrusion
        end

        GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    onany(title, titlesize, titlegap, titlevisible, spinewidth,
            xaxis.protrusion, yaxis.protrusion, xaxisposition, yaxisposition) do args...
        layoutobservables.protrusions[] = compute_protrusions(args...)
    end

    # trigger first protrusions with one of the observables
    title[] = title[]

    # trigger a layout update whenever the protrusions change
    # on(protrusions) do prot
    #     needs_update[] = true
    # end

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    layoutobservables.suggestedbbox[] = layoutobservables.suggestedbbox[]

    la = LAxis(parent, scene, xaxislinks, yaxislinks, limits,
        layoutobservables, attrs, block_limit_linking, decorations)

    # add action that resets limits on ctrl + click
    add_reset_limits!(la)
    # add action that allows zooming using mouse scrolling
    add_zoom!(la)
    # add action that allows panning using a mouse button
    add_pan!(la)


    # compute limits that adhere to the limit aspect ratio whenever the targeted
    # limits or the scene size change, because both influence the displayed ratio
    onany(scene.px_area, la.targetlimits) do pxa, lims
        adjustlimits!(la)
    end

    la
end

"""
AutoLinearTicks with ideally a number of `n_ideal` tick marks.
"""
function AutoLinearTicks(n_ideal::Int)
    if n_ideal <= 0
        error("Ideal number of ticks can't be smaller than 0, but is $ideal_pixel_spacing")
    end
    AutoLinearTicks{Int}(n_ideal)
end

"""
AutoLinearTicks with ticks ideally spaced `ideal_pixel_spacing` pixels apart.
"""
function AutoLinearTicks(ideal_pixel_spacing::Real)
    if ideal_pixel_spacing <= 0
        error("Ideal pixel spacing can't be smaller than 0, but is $ideal_pixel_spacing")
    end
    AutoLinearTicks{Float32}(ideal_pixel_spacing)
end

function compute_tick_values(ticks::T, vmin, vmax, pxwidth) where T
    error("No behavior implemented for ticks of type $T")
end

function compute_tick_values(ticks::AutoLinearTicks{Float32}, vmin, vmax, pxwidth)
    locateticks(vmin, vmax, pxwidth, ticks.target)
end

function compute_tick_values(ticks::AutoLinearTicks{Int}, vmin, vmax, pxwidth)
    locateticks(vmin, vmax, ticks.target)
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

get_tick_labels(ticks::AutoLinearTicks, tickvalues) = linearly_spaced_tick_labels(tickvalues)


function linearly_spaced_tick_labels(tickvalues)

    if length(tickvalues) == 1
        return Formatting.format.(tickvalues)
    end

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
        la::LAxis, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(la.scene, P, attributes, args...; kw_attributes...)[end]

    autolimits!(la)
    plot
end

function bboxunion(bb1, bb2)

    o1 = bb1.origin
    o2 = bb2.origin
    e1 = bb1.origin + bb1.widths
    e2 = bb2.origin + bb2.widths

    o = min.(o1, o2)
    e = max.(e1, e2)

    BBox(o[1], e[1], o[2], e[2])
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

function getlimits(la::LAxis, dim)

    plots_with_autolimits = if dim == 1
        filter(p -> !haskey(p.attributes, :xautolimits) || p.attributes.xautolimits[], la.scene.plots)
    elseif dim == 2
        filter(p -> !haskey(p.attributes, :yautolimits) || p.attributes.yautolimits[], la.scene.plots)
    end

    lim = if length(plots_with_autolimits) > 0
        bbox = BBox(AbstractPlotting.data_limits(plots_with_autolimits[1]))
        templim = (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim])
        for p in plots_with_autolimits[2:end]
            bbox = BBox(AbstractPlotting.data_limits(p))
            templim = limitunion(templim, (bbox.origin[dim], bbox.origin[dim] + bbox.widths[dim]))
        end
        templim
    else
        nothing
    end
end

getxlimits(la::LAxis) = getlimits(la, 1)
getylimits(la::LAxis) = getlimits(la, 2)

function update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, tlims)

    thisxlims = xlimits(tlims)
    thisylims = ylimits(tlims)

    # only change linked axis if not prohibited from doing so because
    # we're currently being updated by another axis' link
    if !block_limit_linking[]

        bothlinks = intersect(xaxislinks, yaxislinks)
        xlinks = setdiff(xaxislinks, yaxislinks)
        ylinks = setdiff(yaxislinks, xaxislinks)

        for link in bothlinks
            otherlims = link.targetlimits[]
            if tlims != otherlims
                link.block_limit_linking[] = true
                link.targetlimits[] = tlims
                link.block_limit_linking[] = false
            end
        end

        for xlink in xlinks
            otherlims = xlink.targetlimits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisxlims != otherxlims
                xlink.block_limit_linking[] = true
                xlink.targetlimits[] = BBox(thisxlims[1], thisxlims[2], otherylims[1], otherylims[2])
                xlink.block_limit_linking[] = false
            end
        end

        for ylink in ylinks
            otherlims = ylink.targetlimits[]
            otherylims = (otherlims.origin[2], otherlims.origin[2] + otherlims.widths[2])
            otherxlims = (otherlims.origin[1], otherlims.origin[1] + otherlims.widths[1])
            if thisylims != otherylims
                ylink.block_limit_linking[] = true
                ylink.targetlimits[] = BBox(otherxlims[1], otherxlims[2], thisylims[1], thisylims[2])
                ylink.block_limit_linking[] = false
            end
        end
    end
end


function autolimits!(la::LAxis)

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
        xlims = (la.targetlimits[].origin[1], la.targetlimits[].origin[1] + la.targetlimits[].widths[1])
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
        ylims = (la.targetlimits[].origin[2], la.targetlimits[].origin[2] + la.targetlimits[].widths[2])
    else
        ylims = expandlimits(ylims,
            la.attributes.yautolimitmargin[][1],
            la.attributes.yautolimitmargin[][2])
    end


    bbox = BBox(xlims[1], xlims[2], ylims[1], ylims[2])
    # la.limits[] = bbox
    la.targetlimits[] = bbox
end

function linkaxes!(a::LAxis, others...)
    linkxaxes!(a, others...)
    linkyaxes!(a, others...)
end


function adjustlimits!(la)
    asp = la.autolimitaspect[]
    target = la.targetlimits[]

    if isnothing(asp)
        la.limits[] = target
        return
    end

    area = la.scene.px_area[]
    xlims = (left(target), right(target))
    ylims = (bottom(target), top(target))

    size_aspect = width(area) / height(area)
    data_aspect = (xlims[2] - xlims[1]) / (ylims[2] - ylims[1])

    aspect_ratio = data_aspect / size_aspect

    correction_factor = asp / aspect_ratio

    if correction_factor > 1
        # need to go wider

        marginsum = sum(la.xautolimitmargin[])
        ratios = if marginsum == 0
            (0.5, 0.5)
        else
            (la.xautolimitmargin[] ./ marginsum)
        end

        xlims = expandlimits(xlims, ((correction_factor - 1) .* ratios)...)
    elseif correction_factor < 1
        # need to go taller

        marginsum = sum(la.yautolimitmargin[])
        ratios = if marginsum == 0
            (0.5, 0.5)
        else
            (la.yautolimitmargin[] ./ marginsum)
        end
        ylims = expandlimits(ylims, (((1 / correction_factor) - 1) .* ratios)...)
    end

    bbox = BBox(xlims[1], xlims[2], ylims[1], ylims[2])

    la.limits[] = bbox
end

function linkxaxes!(a::LAxis, others...)
    axes = LAxis[a; others...]

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

function linkyaxes!(a::LAxis, others...)
    axes = LAxis[a; others...]

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

function add_pan!(ax::LAxis)

    tlimits = ax.targetlimits
    xpanlock = ax.xpanlock
    ypanlock = ax.ypanlock
    xpankey = ax.xpankey
    ypankey = ax.ypankey
    panbutton = ax.panbutton

    scene = ax.scene

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

                diff_limits = diff_fraction .* widths(tlimits[])

                xori, yori = Vec2f0(tlimits[].origin) .+ Vec2f0(diff_limits)

                if xpanlock[] || ispressed(scene, ypankey[])
                    xori = tlimits[].origin[1]
                end

                if ypanlock[] || ispressed(scene, xpankey[])
                    yori = tlimits[].origin[2]
                end

                tlimits[] = FRect(Vec2f0(xori, yori), widths(tlimits[]))
            end
        end
        return
    end
end

function add_zoom!(ax::LAxis)

    tlimits = ax.targetlimits
    xzoomlock = ax.xzoomlock
    yzoomlock = ax.yzoomlock
    xzoomkey = ax.xzoomkey
    yzoomkey = ax.yzoomkey

    scene = ax.scene

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

            mp_data = tlimits[].origin .+ mp_fraction .* tlimits[].widths

            xorigin = tlimits[].origin[1]
            yorigin = tlimits[].origin[2]

            xwidth = tlimits[].widths[1]
            ywidth = tlimits[].widths[2]

            newxwidth = xzoomlock[] ? xwidth : xwidth * z
            newywidth = yzoomlock[] ? ywidth : ywidth * z

            newxorigin = xzoomlock[] ? xorigin : xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yzoomlock[] ? yorigin : yorigin + mp_fraction[2] * (ywidth - newywidth)

            if AbstractPlotting.ispressed(scene, xzoomkey[])
                tlimits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, yzoomkey[])
                tlimits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                tlimits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end
end

function add_reset_limits!(la::LAxis)
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

function hidexdecorations!(la::LAxis)
    la.xlabelvisible = false
    la.xticklabelsvisible = false
    la.xticksvisible = false
end

function hideydecorations!(la::LAxis)
    la.ylabelvisible = false
    la.yticklabelsvisible = false
    la.yticksvisible = false
end


function tight_yticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.decorations[:yaxis])
end

function tight_xticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.decorations[:xaxis])
end

function tight_ticklabel_spacing!(la::LAxis)
    tight_xticklabel_spacing!(la)
    tight_yticklabel_spacing!(la)
end

function Base.show(io::IO, ::MIME"text/plain", ax::LAxis)
    nplots = length(ax.scene.plots)
    println(io, "LAxis with $nplots plots:")

    for (i, p) in enumerate(ax.scene.plots)
        println(io, (i == nplots ? " ┗━ " : " ┣━ ") * string(typeof(p)))
    end
end

function Base.show(io::IO, ax::LAxis)
    nplots = length(ax.scene.plots)
    print(io, "LAxis ($nplots plots)")
end


function AbstractPlotting.xlims!(ax::LAxis, xlims::Tuple{Real, Real})
	lims = ax.targetlimits[]
	newlims = FRect2D((xlims[1], lims.origin[2]), (xlims[2] - xlims[1], lims.widths[2]))
	ax.targetlimits[] = newlims
end

AbstractPlotting.xlims!(ax::LAxis, lims::Real...) = xlims!(ax, lims)

function AbstractPlotting.ylims!(ax::LAxis, ylims::Tuple{Real, Real})
	lims = ax.targetlimits[]
	newlims = FRect2D((lims.origin[1], ylims[1]), (lims.widths[1], ylims[2] - ylims[1]))
	ax.targetlimits[] = newlims
end

AbstractPlotting.ylims!(ax::LAxis, lims::Real...) = ylims!(ax, lims)
