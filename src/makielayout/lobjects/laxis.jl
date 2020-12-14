"""
    LAxis(fig_or_scene; bbox = nothing, kwargs...)

Creates an `LAxis` object in the parent `fig_or_scene` which consists of a child scene
with orthographic projection for 2D plots and axis decorations that live in the
parent.
"""
function LAxis(fig_or_scene; bbox = nothing, kwargs...)

    topscene = get_topscene(fig_or_scene)

    default_attrs = default_attributes(LAxis, topscene).attributes
    theme_attrs = subtheme(topscene, :LAxis)
    attrs = merge!(merge!(Attributes(kwargs), theme_attrs), default_attrs)

    @extract attrs (
        title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        xlabel, ylabel, xlabelcolor, ylabelcolor, xlabelsize, ylabelsize,
        xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, xticklabelcolor, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible,
        xticklabelspace, yticklabelspace, yticklabelcolor, xticklabelpad, yticklabelpad,
        xticklabelrotation, yticklabelrotation, xticklabelalign, yticklabelalign,
        xtickalign, ytickalign, xtickwidth, ytickwidth, xtickcolor, ytickcolor,
        xpanlock, ypanlock, xzoomlock, yzoomlock,
        spinewidth, xtrimspine, ytrimspine,
        xgridvisible, ygridvisible, xgridwidth, ygridwidth, xgridcolor, ygridcolor,
        xgridstyle, ygridstyle,
        aspect, halign, valign, xticks, yticks, xtickformat, ytickformat, panbutton,
        xpankey, ypankey, xzoomkey, yzoomkey,
        xaxisposition, yaxisposition,
        bottomspinevisible, leftspinevisible, topspinevisible, rightspinevisible,
        bottomspinecolor, leftspinecolor, topspinecolor, rightspinecolor,
        backgroundcolor,
        xlabelfont, ylabelfont, xticklabelfont, yticklabelfont,
        flip_ylabel, xreversed, yreversed,
    )

    decorations = Dict{Symbol, Any}()

    protrusions = Node(GridLayoutBase.RectSides{Float32}(0,0,0,0))
    layoutobservables = LayoutObservables{LAxis}(attrs.width, attrs.height, attrs.tellwidth, attrs.tellheight, halign, valign, attrs.alignmode;
        suggestedbbox = bbox, protrusions = protrusions)

    limits = Node(FRect(0, 0, 100, 100))

    scenearea = sceneareanode!(layoutobservables.computedbbox, limits, aspect)

    scene = Scene(topscene, scenearea, raw = true)

    background = poly!(topscene, scenearea, color = backgroundcolor, strokewidth = 0, raw = true)[end]
    translate!(background, 0, 0, -100)
    decorations[:background] = background

    block_limit_linking = Node(false)

    xaxislinks = LAxis[]
    yaxislinks = LAxis[]

    campixel!(scene)

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        topscene, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor, linestyle = xgridstyle,
    )[end]
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    decorations[:xgridlines] = xgridlines

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        topscene, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor, linestyle = ygridstyle,
    )[end]
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    decorations[:ygridlines] = ygridlines



    onany(limits, xreversed, yreversed) do lims, xrev, yrev

        nearclip = -10_000f0
        farclip = 10_000f0

        left, bottom = minimum(lims)
        right, top = maximum(lims)

        leftright = xrev ? (right, left) : (left, right)
        bottomtop = yrev ? (top, bottom) : (bottom, top)

        projection = AbstractPlotting.orthographicprojection(
            leftright..., bottomtop..., nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection
    end

    on(attrs.targetlimits) do tlims
        update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, tlims)
    end

    xaxis_endpoints = lift(xaxisposition, scene.px_area) do xaxisposition, area
        if xaxisposition == :bottom
            bottomline(FRect2D(area))
        elseif xaxisposition == :top
            topline(FRect2D(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    yaxis_endpoints = lift(yaxisposition, scene.px_area) do yaxisposition, area
        if yaxisposition == :left
            leftline(FRect2D(area))
        elseif yaxisposition == :right
            rightline(FRect2D(area))
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

    xaxis = LineAxis(topscene, endpoints = xaxis_endpoints, limits = lift(xlimits, limits),
        flipped = xaxis_flipped, ticklabelrotation = xticklabelrotation,
        ticklabelalign = xticklabelalign, labelsize = xlabelsize,
        labelpadding = xlabelpadding, ticklabelpad = xticklabelpad, labelvisible = xlabelvisible,
        label = xlabel, labelfont = xlabelfont, ticklabelfont = xticklabelfont, ticklabelcolor = xticklabelcolor, labelcolor = xlabelcolor, tickalign = xtickalign,
        ticklabelspace = xticklabelspace, ticks = xticks, tickformat = xtickformat, ticklabelsvisible = xticklabelsvisible,
        ticksvisible = xticksvisible, spinevisible = xspinevisible, spinecolor = xspinecolor, spinewidth = spinewidth,
        ticklabelsize = xticklabelsize, trimspine = xtrimspine, ticksize = xticksize,
        reversed = xreversed, tickwidth = xtickwidth)
    decorations[:xaxis] = xaxis

    yaxis  =  LineAxis(topscene, endpoints = yaxis_endpoints, limits = lift(ylimits, limits),
        flipped = yaxis_flipped, ticklabelrotation = yticklabelrotation,
        ticklabelalign = yticklabelalign, labelsize = ylabelsize,
        labelpadding = ylabelpadding, ticklabelpad = yticklabelpad, labelvisible = ylabelvisible,
        label = ylabel, labelfont = ylabelfont, ticklabelfont = yticklabelfont, ticklabelcolor = yticklabelcolor, labelcolor = ylabelcolor, tickalign = ytickalign,
        ticklabelspace = yticklabelspace, ticks = yticks, tickformat = ytickformat, ticklabelsvisible = yticklabelsvisible,
        ticksvisible = yticksvisible, spinevisible = yspinevisible, spinecolor = yspinecolor, spinewidth = spinewidth,
        trimspine = ytrimspine, ticklabelsize = yticklabelsize, ticksize = yticksize, flip_vertical_label = flip_ylabel, reversed = yreversed, tickwidth = ytickwidth)
    decorations[:yaxis] = yaxis

    xoppositelinepoints = lift(scene.px_area, spinewidth, xaxisposition) do r, sw, xaxpos
        if xaxpos == :top
            y = bottom(r)
            p1 = Point2(left(r) - 0.5sw, y)
            p2 = Point2(right(r) + 0.5sw, y)
            [p1, p2]
        else
            y = top(r)
            p1 = Point2(left(r) - 0.5sw, y)
            p2 = Point2(right(r) + 0.5sw, y)
            [p1, p2]
        end
    end

    yoppositelinepoints = lift(scene.px_area, spinewidth, yaxisposition) do r, sw, yaxpos
        if yaxpos == :right
            x = left(r)
            p1 = Point2(x, bottom(r) - 0.5sw)
            p2 = Point2(x, top(r) + 0.5sw)
            [p1, p2]
        else
            x = right(r)
            p1 = Point2(x, bottom(r) - 0.5sw)
            p2 = Point2(x, top(r) + 0.5sw)
            [p1, p2]
        end
    end

    xoppositeline = lines!(topscene, xoppositelinepoints, linewidth = spinewidth,
        visible = xoppositespinevisible, color = xoppositespinecolor)[end]
    decorations[:xoppositeline] = xoppositeline
    yoppositeline = lines!(topscene, yoppositelinepoints, linewidth = spinewidth,
        visible = yoppositespinevisible, color = yoppositespinecolor)[end]
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
        topscene, title,
        position = titlepos,
        visible = titlevisible,
        textsize = titlesize,
        align = titlealignnode,
        font = titlefont,
        show_axis=false)[end]
    decorations[:title] = titlet

    function compute_protrusions(title, titlesize, titlegap, titlevisible, spinewidth,
                topspinevisible, bottomspinevisible, leftspinevisible, rightspinevisible,
                xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition)

        left, right, bottom, top = 0f0, 0f0, 0f0, 0f0

        if xaxisposition == :bottom
            bottom = xaxisprotrusion
        else
            top = xaxisprotrusion
        end

        titlespace = if !titlevisible || iswhitespace(title) || isempty(title)
            0f0
        else
            boundingbox(titlet).widths[2] + titlegap
        end
        top += titlespace

        if yaxisposition == :left
            left = yaxisprotrusion
        else
            right = yaxisprotrusion
        end

        GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
    end

    onany(title, titlesize, titlegap, titlevisible, spinewidth,
            topspinevisible, bottomspinevisible, leftspinevisible, rightspinevisible,
            xaxis.protrusion, yaxis.protrusion, xaxisposition, yaxisposition) do args...
        protrusions[] = compute_protrusions(args...)
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

    mouseeventhandle = addmouseevents!(scene)
    scrollevents = Node(ScrollEvent(0, 0))
    keysevents = Node(KeysEvent(Set()))

    on(scene.events.scroll) do s
        if is_mouseinside(scene)
            scrollevents[] = ScrollEvent(s[1], s[2])
        end
    end

    on(scene.events.keyboardbuttons) do buttons
        keysevents[] = KeysEvent(buttons)
    end

    interactions = Dict{Symbol, Tuple{Bool, Any}}()

    la = LAxis(fig_or_scene, layoutobservables, attrs, decorations, scene,
        xaxislinks, yaxislinks, limits, block_limit_linking,
        mouseeventhandle, scrollevents, keysevents, interactions)


    function process_event(event)
        for (active, interaction) in values(la.interactions)
            active && process_interaction(interaction, event, la)
        end
    end

    on(process_event, mouseeventhandle.obs)
    on(process_event, scrollevents)
    on(process_event, keysevents)

    register_interaction!(la,
        :rectanglezoom,
        RectangleZoom(false, false, false, nothing, nothing, Node(FRect2D(0, 0, 1, 1)), []))

    register_interaction!(la,
        :limitreset,
        LimitReset())

    register_interaction!(la,
        :scrollzoom,
        ScrollZoom(0.1, Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))

    register_interaction!(la,
        :dragpan,
        DragPan(Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))

    # compute limits that adhere to the limit aspect ratio whenever the targeted
    # limits or the scene size change, because both influence the displayed ratio
    onany(scene.px_area, la.targetlimits) do pxa, lims
        adjustlimits!(la)
    end

    la
end


function AbstractPlotting.plot!(
        la::LAxis, P::AbstractPlotting.PlotFunc,
        attributes::AbstractPlotting.Attributes, args...;
        kw_attributes...)

    plot = AbstractPlotting.plot!(la.scene, P, attributes, args...; kw_attributes...)[end]

    # some area-like plots basically always look better if they cover the whole plot area.
    # adjust the limit margins in those cases automatically.
    has_tight_limit_trait(P) && tightlimits!(la)

    autolimits!(la)
    plot
end

function AbstractPlotting.plot!(P::AbstractPlotting.PlotFunc, ax::LAxis, args...; kw_attributes...)
    attributes = AbstractPlotting.Attributes(kw_attributes)
    AbstractPlotting.plot!(ax, P, attributes, args...)
end

has_tight_limit_trait(@nospecialize any) = false
has_tight_limit_trait(::Type{<:Union{Heatmap, Image, Contourf}}) = true

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
    else
        error("Dimension $dim not allowed. Only 1 or 2.")
    end

    visible_plots = filter(
        p -> !haskey(p.attributes, :visible) || p.attributes.visible[],
        plots_with_autolimits)

    bboxes = [FRect2D(AbstractPlotting.data_limits(p)) for p in visible_plots]
    finite_bboxes = filter(isfinite, bboxes)

    isempty(finite_bboxes) && return nothing

    templim = (finite_bboxes[1].origin[dim], finite_bboxes[1].origin[dim] + finite_bboxes[1].widths[dim])

    for bb in finite_bboxes[2:end]
        templim = limitunion(templim, (bb.origin[dim], bb.origin[dim] + bb.widths[dim]))
    end

    templim
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

"""
    autolimits!(la::LAxis)

Set the target limits of `la` to an automatically determined rectangle, that depends
on the data limits of all plot objects in the axis, as well as the autolimit margins
for x and y axis.
"""
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

"""
    linkaxes!(a::LAxis, others...)

Link both x and y axes of all given `LAxis` so that they stay synchronized.
"""
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

"""
    linkxaxes!(a::LAxis, others...)

Link the x axes of all given `LAxis` so that they stay synchronized.
"""
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
    # update limits because users will expect to see the effect
    autolimits!(a)
end

"""
    linkyaxes!(a::LAxis, others...)

Link the y axes of all given `LAxis` so that they stay synchronized.
"""
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
    # update limits because users will expect to see the effect
    autolimits!(a)
end


"""
Keeps the ticklabelspace static for a short duration and then resets it to its previous
value. If that value is AbstractPlotting.automatic, the reset will trigger new
protrusions for the axis and the layout will adjust. This is so the layout doesn't
immediately readjust during interaction, which would let the whole layout jitter around.
"""
function timed_ticklabelspace_reset(ax::LAxis, reset_timer::Ref,
        prev_xticklabelspace::Ref, prev_yticklabelspace::Ref, threshold_sec::Real)

    if !isnothing(reset_timer[])
        close(reset_timer[])
    else
        prev_xticklabelspace[] = ax.xticklabelspace[]
        prev_yticklabelspace[] = ax.yticklabelspace[]

        ax.xticklabelspace = ax.elements[:xaxis].attributes.actual_ticklabelspace[]
        ax.yticklabelspace = ax.elements[:yaxis].attributes.actual_ticklabelspace[]
    end

    reset_timer[] = Timer(threshold_sec) do t
        reset_timer[] = nothing

        ax.xticklabelspace = prev_xticklabelspace[]
        ax.yticklabelspace = prev_yticklabelspace[]
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

"""
    hidexdecorations!(la::LAxis; label = true, ticklabels = true, ticks = true, grid = true)

Hide decorations of the x-axis: label, ticklabels, ticks and grid.
"""
function hidexdecorations!(la::LAxis; label = true, ticklabels = true, ticks = true, grid = true)
    if label
        la.xlabelvisible = false
    end
    if ticklabels
        la.xticklabelsvisible = false
    end
    if ticks
        la.xticksvisible = false
    end
    if grid
        la.xgridvisible = false
    end
end

"""
    hideydecorations!(la::LAxis; label = true, ticklabels = true, ticks = true, grid = true)

Hide decorations of the y-axis: label, ticklabels, ticks and grid.
"""
function hideydecorations!(la::LAxis; label = true, ticklabels = true, ticks = true, grid = true)
    if label
        la.ylabelvisible = false
    end
    if ticklabels
        la.yticklabelsvisible = false
    end
    if ticks
        la.yticksvisible = false
    end
    if grid
        la.ygridvisible = false
    end
end

"""
    hidedecorations!(la::LAxis)

Hide decorations of both x and y-axis: label, ticklabels, ticks and grid.
"""
function hidedecorations!(la::LAxis; label = true, ticklabels = true, ticks = true, grid = true)
    hidexdecorations!(la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid)
    hideydecorations!(la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid)
end

"""
    hidespines!(la::LAxis, spines::Symbol... = (:l, :r, :b, :t)...)

Hide all specified axis spines. Hides all spines by default, otherwise choose
with the symbols :l, :r, :b and :t.
"""
function hidespines!(la::LAxis, spines::Symbol... = (:l, :r, :b, :t)...)
    for s in spines
        @match s begin
            :l => (la.leftspinevisible = false)
            :r => (la.rightspinevisible = false)
            :b => (la.bottomspinevisible = false)
            :t => (la.topspinevisible = false)
            x => error("Invalid spine identifier $x. Valid options are :l, :r, :b and :t.")
        end
    end
end


function tight_yticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.elements[:yaxis])
end

function tight_xticklabel_spacing!(la::LAxis)
    tight_ticklabel_spacing!(la.elements[:xaxis])
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


function AbstractPlotting.xlims!(ax::LAxis, xlims)
    if xlims[1] == xlims[2]
        error("Can't set x limits to the same value $(xlims[1]).")
    elseif xlims[1] > xlims[2]
        xlims = reverse(xlims)
        ax.xreversed[] = true
    else
        ax.xreversed[] = false
    end

	lims = ax.targetlimits[]
	newlims = FRect2D((xlims[1], lims.origin[2]), (xlims[2] - xlims[1], lims.widths[2]))
	ax.targetlimits[] = newlims
    nothing
end

AbstractPlotting.xlims!(ax::LAxis, x1, x2) = xlims!(ax, (x1, x2))

function AbstractPlotting.ylims!(ax::LAxis, ylims)
    if ylims[1] == ylims[2]
        error("Can't set y limits to the same value $(ylims[1]).")
    elseif ylims[1] > ylims[2]
        ylims = reverse(ylims)
        ax.yreversed[] = true
    else
        ax.yreversed[] = false
    end

	lims = ax.targetlimits[]
	newlims = FRect2D((lims.origin[1], ylims[1]), (lims.widths[1], ylims[2] - ylims[1]))
	ax.targetlimits[] = newlims
    nothing
end

AbstractPlotting.ylims!(ax::LAxis, y1, y2) = ylims!(ax, (y1, y2))

"""
    limits!(ax::LAxis, xlims, ylims)

Set the axis limits to `xlims` and `ylims`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::LAxis, xlims, ylims)
    xlims!(ax, xlims)
    ylims!(ax, ylims)
end

"""
    limits!(ax::LAxis, x1, x2, y1, y2)

Set the axis x-limits to `x1` and `x2` and the y-limits to `y1` and `y2`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::LAxis, x1, x2, y1, y2)
    xlims!(ax, x1, x2)
    ylims!(ax, y1, y2)
end

"""
    limits!(ax::LAxis, rect::Rect2D)

Set the axis limits to `rect`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::LAxis, rect::Rect2D)
    xmin, ymin = minimum(rect)
    xmax, ymax = maximum(rect)
    xlims!(ax, xmin, xmax)
    ylims!(ax, ymin, ymax)
end
