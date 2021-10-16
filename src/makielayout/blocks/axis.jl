function initialize_block!(ax::Axis)

    # initialize either with user limits, or pick defaults based on scales
    # so that we don't immediately error
    targetlimits = Node{Rect2f}(defaultlimits(ax.limits[], ax.xscale[], ax.yscale[]))
    setfield!(ax, :targetlimits, targetlimits)
    finallimits = Node{Rect2f}(ax.targetlimits[])
    setfield!(ax, :finallimits, finallimits)

    # the first thing to do when setting a new scale is
    # resetting the limits because simply through expanding they might be invalid for log
    onany(ax.xscale, ax.yscale) do _, _
        reset_limits!(ax)
    end

    on(ax.targetlimits) do lims
        # this should validate the targetlimits before anything else happens with them
        # so there should be nothing before this lifting `targetlimits`
        # we don't use finallimits because that's one step later and you
        # already shouldn't set invalid targetlimits (even if they could
        # theoretically be adjusted to fit somehow later?)
        # and this way we can error pretty early
        validate_limits_for_scales(lims, ax.xscale[], ax.yscale[])
    end

    scenearea = sceneareanode!(ax.layoutobservables.computedbbox, ax.finallimits, ax.aspect)

    scene = Scene(ax.blockscene, scenearea, raw = true)
    ax.scene = scene

    background = poly!(ax.blockscene, scenearea, color = ax.backgroundcolor,
        strokewidth = 0,inspectable = false)
    translate!(background, 0, 0, -100)
    # decorations[:background] = background

    setfield!(ax, :block_limit_linking, Observable(false))

    ax.xaxislinks = Axis[]
    ax.yaxislinks = Axis[]

    ax.cycler = Cycler()
    ax.palette = copy(Makie.default_palettes)

    campixel!(scene)

    xgridnode = Node(Point2f[])
    xgridlines = linesegments!(
        ax.blockscene, xgridnode, linewidth = ax.xgridwidth, show_axis = false, visible = ax.xgridvisible,
        color = ax.xgridcolor, linestyle = ax.xgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    # decorations[:xgridlines] = xgridlines


    xminorgridnode = Node(Point2f[])
    xminorgridlines = linesegments!(
        ax.blockscene, xminorgridnode, linewidth = ax.xminorgridwidth,
        show_axis = false, visible = ax.xminorgridvisible,
        color = ax.xminorgridcolor, linestyle = ax.xminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xminorgridlines, 0, 0, -10)
    # decorations[:xminorgridlines] = xminorgridlines

    ygridnode = Node(Point2f[])
    ygridlines = linesegments!(
        ax.blockscene, ygridnode, linewidth = ax.ygridwidth, show_axis = false,
        visible = ax.ygridvisible,
        color = ax.ygridcolor, linestyle = ax.ygridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    # decorations[:ygridlines] = ygridlines

    yminorgridnode = Node(Point2f[])
    yminorgridlines = linesegments!(
        ax.blockscene, yminorgridnode, linewidth = ax.yminorgridwidth,
        show_axis = false, visible = ax.yminorgridvisible,
        color = ax.yminorgridcolor, linestyle = ax.yminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(yminorgridlines, 0, 0, -10)
    # decorations[:yminorgridlines] = yminorgridlines


    onany(finallimits, ax.xreversed, ax.yreversed, ax.xscale, ax.yscale) do lims, xrev, yrev, xsc, ysc

        nearclip = -10_000f0
        farclip = 10_000f0

        left, bottom = minimum(lims)
        right, top = maximum(lims)

        leftright = xrev ? (right, left) : (left, right)
        bottomtop = yrev ? (top, bottom) : (bottom, top)

        projection = Makie.orthographicprojection(
            xsc.(leftright)...,
            ysc.(bottomtop)..., nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection
    end

    onany(ax.xscale, ax.yscale) do xsc, ysc
        scene.transformation.transform_func[] = (xsc, ysc)
    end

    notify(ax.xscale)


    xaxis_flipped = lift(x->x == :top, ax.xaxisposition)
    yaxis_flipped = lift(x->x == :right, ax.yaxisposition)
    
    xoppositespinevisible = lift(xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible) do xflip, bv, tv
        xflip ? bv : tv
    end
    
    yoppositespinevisible = lift(yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible) do yflip, lv, rv
        yflip ? lv : rv
    end
    
    xoppositespinecolor = lift(xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor) do xflip, bc, tc
        xflip ? bc : tc
    end
    
    yoppositespinecolor = lift(yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor) do yflip, lc, rc
        yflip ? lc : rc
    end

    xlims = Node(xlimits(finallimits[]))
    ylims = Node(ylimits(finallimits[]))

    on(finallimits) do lims
        nxl = xlimits(lims)
        nyl = ylimits(lims)

        if nxl != xlims[]
            xlims[] = nxl
        end
        if nyl != ylims[]
            ylims[] = nyl
        end
    end

    add_xaxis!(ax, xaxis_flipped, xlims)
    add_yaxis!(ax, yaxis_flipped, ylims)

    # decorations[:yaxis] = yaxis

    xoppositelinepoints = lift(scene.px_area, ax.spinewidth, ax.xaxisposition) do r, sw, xaxpos
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

    yoppositelinepoints = lift(scene.px_area, ax.spinewidth, ax.yaxisposition) do r, sw, yaxpos
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

    xoppositeline = lines!(ax.blockscene, xoppositelinepoints, linewidth = ax.spinewidth,
        visible = xoppositespinevisible, color = xoppositespinecolor, inspectable = false,
        linestyle = nothing)
    # decorations[:xoppositeline] = xoppositeline
    translate!(xoppositeline, 0, 0, 20)
    yoppositeline = lines!(ax.blockscene, yoppositelinepoints, linewidth = ax.spinewidth,
        visible = yoppositespinevisible, color = yoppositespinecolor, inspectable = false,
        linestyle = nothing)
    # decorations[:yoppositeline] = yoppositeline
    translate!(yoppositeline, 0, 0, 20)


    on(ax.xaxis.tickpositions) do tickpos
        pxheight = height(scene.px_area[])
        offset = ax.xaxisposition[] == :bottom ? pxheight : -pxheight
        opposite_tickpos = tickpos .+ Ref(Point2f(0, offset))
        xgridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    on(ax.yaxis.tickpositions) do tickpos
        pxwidth = width(scene.px_area[])
        offset = ax.yaxisposition[] == :left ? pxwidth : -pxwidth
        opposite_tickpos = tickpos .+ Ref(Point2f(offset, 0))
        ygridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    on(ax.xaxis.minortickpositions) do tickpos
        pxheight = height(scene.px_area[])
        offset = ax.xaxisposition[] == :bottom ? pxheight : -pxheight
        opposite_tickpos = tickpos .+ Ref(Point2f(0, offset))
        xminorgridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    on(ax.yaxis.minortickpositions) do tickpos
        pxwidth = width(scene.px_area[])
        offset = ax.yaxisposition[] == :left ? pxwidth : -pxwidth
        opposite_tickpos = tickpos .+ Ref(Point2f(offset, 0))
        yminorgridnode[] = interleave_vectors(tickpos, opposite_tickpos)
    end

    titlepos = lift(scene.px_area, ax.titlegap, ax.titlealign, ax.xaxisposition, ax.xaxis.protrusion) do a,
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

    titlealignnode = lift(ax.titlealign) do align
        (align, :bottom)
    end

    titlet = text!(
        ax.blockscene, ax.title,
        position = titlepos,
        visible = ax.titlevisible,
        textsize = ax.titlesize,
        align = titlealignnode,
        font = ax.titlefont,
        color = ax.titlecolor,
        space = :data,
        show_axis=false,
        inspectable = false)
    # # decorations[:title] = titlet

    function compute_protrusions(title, titlesize, titlegap, titlevisible, spinewidth,
                topspinevisible, bottomspinevisible, leftspinevisible, rightspinevisible,
                xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition)

        left, right, bottom, top = 0f0, 0f0, 0f0, 0f0

        if xaxisposition == :bottom
            bottom = xaxisprotrusion
        else
            top = xaxisprotrusion
        end

        titlespace = if !titlevisible || iswhitespace(title)
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

    onany(ax.title, ax.titlesize, ax.titlegap, ax.titlevisible, ax.spinewidth,
            ax.topspinevisible, ax.bottomspinevisible, ax.leftspinevisible, ax.rightspinevisible,
            ax.xaxis.protrusion, ax.yaxis.protrusion, ax.xaxisposition, ax.yaxisposition) do args...
        ax.layoutobservables.protrusions[] = compute_protrusions(args...)
    end

    # # trigger first protrusions with one of the observables
    notify(ax.title)

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    notify(ax.layoutobservables.suggestedbbox)



    mouseeventhandle = addmouseevents!(scene)
    scrollevents = Node(ScrollEvent(0, 0))
    keysevents = Node(KeysEvent(Set()))

    on(scene.events.scroll) do s
        if is_mouseinside(scene)
            scrollevents[] = ScrollEvent(s[1], s[2])
            return Consume(true)
        end
        return Consume(false)
    end

    # TODO this should probably just forward KeyEvent from Makie
    on(scene.events.keyboardbutton) do e
        keysevents[] = KeysEvent(scene.events.keyboardstate)
        return Consume(false)
    end

    ax.interactions = Dict{Symbol, Tuple{Bool, Any}}()

    # ax = Axis(fig_or_scene, layoutobservables, attrs, decorations, scene,
    #     xaxislinks, yaxislinks, targetlimits, finallimits, block_limit_linking,
    #     mouseeventhandle, scrollevents, keysevents, interactions, Cycler())
    # this_axis[] = ax

    function process_event(event)
        for (active, interaction) in values(ax.interactions)
            if active
                maybe_consume = process_interaction(interaction, event, ax)
                maybe_consume == Consume(true) && return Consume(true)
            end
        end
        return Consume(false)
    end

    on(process_event, mouseeventhandle.obs)
    on(process_event, scrollevents)
    on(process_event, keysevents)

    register_interaction!(ax, :rectanglezoom, RectangleZoom(ax))

    register_interaction!(ax, :limitreset, LimitReset())

    register_interaction!(ax,
        :scrollzoom,
        ScrollZoom(0.1, Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))

    register_interaction!(ax,
        :dragpan,
        DragPan(Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))


    # these are the user defined limits
    on(ax.limits) do mlims
        reset_limits!(ax)
    end

    # # these are the limits that we try to target, but they can be changed for correct aspects
    on(targetlimits) do tlims
        update_linked_limits!(ax.block_limit_linking, ax.xaxislinks, ax.yaxislinks, tlims)
    end

    # compute limits that adhere to the limit aspect ratio whenever the targeted
    # limits or the scene size change, because both influence the displayed ratio
    onany(scene.px_area, targetlimits) do pxa, lims
        adjustlimits!(ax)
    end

    # trigger limit pipeline once, with manual finallimits if they haven't changed from
    # their initial value as they need to be triggered at least once to correctly set up
    # projection matrices etc.
    fl = finallimits[]
    notify(ax.limits)
    if fl == finallimits[]
        notify(finallimits)
    end
    
    ax
end


function apply_meta_kwarg!(ax, ::Val{:hide_axis}, v::Bool, dict)
    if v
        hidespines!(ax)
        hidedecorations!(ax)
    end
end

function apply_meta_kwarg!(ax, ::Val{:xlims}, lims, dict)
    xlims!(ax, lims)
end

function apply_meta_kwarg!(ax, ::Val{:ylims}, lims, dict)
    ylims!(ax, lims)
end

function add_xaxis!(ax, xaxis_flipped, xlims)

    xspinevisible = lift(xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible) do xflip, bv, tv
        xflip ? tv : bv
    end

    xspinecolor = lift(xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor) do xflip, bc, tc
        xflip ? tc : bc
    end

    xaxis_endpoints = lift(ax.xaxisposition, ax.scene.px_area) do xaxisposition, area
        if xaxisposition == :bottom
            bottomline(Rect2f(area))
        elseif xaxisposition == :top
            topline(Rect2f(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    xaxis = LineAxis(
        ax.blockscene,
        endpoints = xaxis_endpoints,
        flipped = xaxis_flipped,
        label = ax.xlabel,
        labelcolor = ax.xlabelcolor,
        labelfont = ax.xlabelfont,
        labelpadding = ax.xlabelpadding,
        labelsize = ax.xlabelsize,
        labelvisible = ax.xlabelvisible,
        limits = xlims,
        minortickalign = ax.xminortickalign,
        minortickcolor = ax.xminortickcolor,
        minorticks = ax.xminorticks,
        minorticksize = ax.xminorticksize,
        minorticksvisible = ax.xminorticksvisible,
        minortickwidth = ax.xminortickwidth,
        reversed = ax.xreversed,
        scale = ax.xscale,
        spinecolor = xspinecolor,
        spinevisible = xspinevisible,
        spinewidth = ax.spinewidth,
        tickalign = ax.xtickalign,
        tickcolor = ax.xtickcolor,
        tickformat = ax.xtickformat,
        ticklabelalign = ax.xticklabelalign,
        ticklabelcolor = ax.xticklabelcolor,
        ticklabelfont = ax.xticklabelfont,
        ticklabelpad = ax.xticklabelpad,
        ticklabelrotation = ax.xticklabelrotation,
        ticklabelsize = ax.xticklabelsize,
        ticklabelspace = ax.xticklabelspace,
        ticklabelsvisible = ax.xticklabelsvisible,
        ticks = ax.xticks,
        ticksize = ax.xticksize,
        ticksvisible = ax.xticksvisible,
        tickwidth = ax.xtickwidth,
        trimspine = ax.xtrimspine,
    )

    ax.xaxis = xaxis
    return
end


function add_yaxis!(ax, yaxis_flipped, ylims)

    yspinecolor = lift(yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor) do yflip, lc, rc
        yflip ? rc : lc
    end

    yspinevisible = lift(yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible) do yflip, lv, rv
        yflip ? rv : lv
    end

    yaxis_endpoints = lift(ax.yaxisposition, ax.scene.px_area) do yaxisposition, area
        if yaxisposition == :left
            leftline(Rect2f(area))
        elseif yaxisposition == :right
            rightline(Rect2f(area))
        else
            error("Invalid yaxisposition $yaxisposition")
        end
    end

    yaxis  =  LineAxis(
        ax.blockscene,
        endpoints = yaxis_endpoints,
        flip_vertical_label = ax.flip_ylabel,
        flipped = yaxis_flipped,
        label = ax.ylabel,
        labelcolor = ax.ylabelcolor,
        labelfont = ax.ylabelfont,
        labelpadding = ax.ylabelpadding,
        labelsize = ax.ylabelsize,
        labelvisible = ax.ylabelvisible,
        limits = ylims,
        minortickalign = ax.yminortickalign,
        minortickcolor = ax.yminortickcolor,
        minorticks = ax.yminorticks,
        minorticksize = ax.yminorticksize,
        minorticksvisible = ax.yminorticksvisible,
        minortickwidth = ax.yminortickwidth,
        reversed = ax.yreversed,
        scale = ax.yscale,
        spinecolor = yspinecolor,
        spinevisible = yspinevisible,
        spinewidth = ax.spinewidth,
        tickalign = ax.ytickalign,
        tickcolor = ax.ytickcolor,
        tickformat = ax.ytickformat,
        ticklabelalign = ax.yticklabelalign,
        ticklabelcolor = ax.yticklabelcolor,
        ticklabelfont = ax.yticklabelfont,
        ticklabelpad = ax.yticklabelpad,
        ticklabelrotation = ax.yticklabelrotation,
        ticklabelsize = ax.yticklabelsize,
        ticklabelspace = ax.yticklabelspace,
        ticklabelsvisible = ax.yticklabelsvisible,
        ticks = ax.yticks,
        ticksize = ax.yticksize,
        ticksvisible = ax.yticksvisible,
        tickwidth = ax.ytickwidth,
        trimspine = ax.ytrimspine,
    )
    ax.yaxis = yaxis
    return
end


"""
    reset_limits!(ax; xauto = true, yauto = true)

Resets the axis limits depending on the value of `ax.limits`.
If one of the two components of limits is nothing,
that value is either copied from the targetlimits if `xauto` or `yauto` is false,
respectively, or it is determined automatically from the plots in the axis.
If one of the components is a tuple of two numbers, those are used directly.
"""
function reset_limits!(ax; xauto = true, yauto = true, zauto = true)
    mlims = convert_limit_attribute(ax.limits[])

    if ax isa Axis
        mxlims, mylims = mlims::Tuple{Any, Any}
    elseif ax isa Axis3
        mxlims, mylims, mzlims = mlims::Tuple{Any, Any, Any}
    else
        error()
    end

    xlims = if isnothing(mxlims) || mxlims[1] === nothing || mxlims[2] === nothing
        l = if xauto
            xautolimits(ax)
        else
            minimum(ax.targetlimits[])[1], maximum(ax.targetlimits[])[1]
        end
        if mxlims === nothing
            l
        else
            lo = mxlims[1] === nothing ? l[1] : mxlims[1]
            hi = mxlims[2] === nothing ? l[2] : mxlims[2]
            (lo, hi)
        end
    else
        convert(Tuple{Float32, Float32}, tuple(mxlims...))
    end
    ylims = if isnothing(mylims) || mylims[1] === nothing || mylims[2] === nothing
        l = if yauto
            yautolimits(ax)
        else
            minimum(ax.targetlimits[])[2], maximum(ax.targetlimits[])[2]
        end
        if mylims === nothing
            l
        else
            lo = mylims[1] === nothing ? l[1] : mylims[1]
            hi = mylims[2] === nothing ? l[2] : mylims[2]
            (lo, hi)
        end
    else
        convert(Tuple{Float32, Float32}, mylims)
    end

    if ax isa Axis3
        zlims = if isnothing(mzlims) || mzlims[1] === nothing || mzlims[2] === nothing
            l = if zauto
                zautolimits(ax)
            else
                minimum(ax.targetlimits[])[3], maximum(ax.targetlimits[])[3]
            end
            if mzlims === nothing
                l
            else
                lo = mzlims[1] === nothing ? l[1] : mzlims[1]
                hi = mzlims[2] === nothing ? l[2] : mzlims[2]
                (lo, hi)
            end
        else
            convert(Tuple{Float32, Float32}, mzlims)
        end
    end

    if !(xlims[1] <= xlims[2])
        error("Invalid x-limits as xlims[1] <= xlims[2] is not met for $xlims.")
    end
    if !(ylims[1] <= ylims[2])
        error("Invalid y-limits as ylims[1] <= ylims[2] is not met for $ylims.")
    end
    if ax isa Axis3
        if !(zlims[1] <= zlims[2])
            error("Invalid z-limits as zlims[1] <= zlims[2] is not met for $zlims.")
        end
    end

    if ax isa Axis
        ax.targetlimits[] = BBox(xlims..., ylims...)
    elseif ax isa Axis3
        ax.targetlimits[] = Rect3f(
            Vec3f(xlims[1], ylims[1], zlims[1]),
            Vec3f(xlims[2] - xlims[1], ylims[2] - ylims[1], zlims[2] - zlims[1]),
        )
    end
    nothing
end

# this is so users can do limits = (left, right, bottom, top)
function convert_limit_attribute(lims::Tuple{Any, Any, Any, Any})
    (lims[1:2], lims[3:4])
end

function convert_limit_attribute(lims::Tuple{Any, Any})
    lims
end
can_be_current_axis(ax::Axis) = true

function validate_limits_for_scales(lims::Rect, xsc, ysc)
    mi = minimum(lims)
    ma = maximum(lims)
    xlims = (mi[1], ma[1])
    ylims = (mi[2], ma[2])

    if !validate_limits_for_scale(xlims, xsc)
        error("Invalid x-limits $xlims for scale $xsc which is defined on the interval $(defined_interval(xsc))")
    end
    if !validate_limits_for_scale(ylims, ysc)
        error("Invalid y-limits $ylims for scale $ysc which is defined on the interval $(defined_interval(ysc))")
    end
    nothing
end

validate_limits_for_scale(lims, scale) = all(x -> x in defined_interval(scale), lims)



palettesyms(cycle::Cycle) = [c[2] for c in cycle.cycle]
attrsyms(cycle::Cycle) = [c[1] for c in cycle.cycle]

function get_cycler_index!(c::Cycler, P::Type)
    if !haskey(c.counters, P)
        c.counters[P] = 1
    else
        c.counters[P] += 1
    end
end

function get_cycle_for_plottype(allattrs, P)::Cycle
    psym = MakieCore.plotsym(P)

    plottheme = Makie.default_theme(nothing, P)

    cdt = Makie.current_default_theme()
    cycle_raw = if haskey(allattrs, :cycle)
        allattrs.cycle[]
    elseif haskey(cdt, psym) && haskey(cdt[psym], :cycle)
        cdt[psym].cycle[]
    else
        haskey(plottheme, :cycle) ? plottheme.cycle[] : nothing
    end

    if isnothing(cycle_raw)
        Cycle([])
    elseif cycle_raw isa Cycle
        cycle_raw
    else
        Cycle(cycle_raw)
    end
end

function add_cycle_attributes!(allattrs, P, cycle::Cycle, cycler::Cycler, palette::Attributes)
    no_cycle_attribute_passed = !any(keys(allattrs)) do key
        any(syms -> key in syms, attrsyms(cycle))
    end

    if no_cycle_attribute_passed
        index = get_cycler_index!(cycler, P)

        paletteattrs = [palette[sym] for sym in palettesyms(cycle)]

        for (isym, syms) in enumerate(attrsyms(cycle))
            for sym in syms
                allattrs[sym] = lift(Any, paletteattrs...) do ps...
                    if cycle.covary
                        ps[isym][mod1(index, length(ps[isym]))]
                    else
                        cis = CartesianIndices(length.(ps))
                        n = length(cis)
                        k = mod1(index, n)
                        idx = Tuple(cis[k])
                        ps[isym][idx[isym]]
                    end
                end
            end
        end
    end
end

function Makie.plot!(
        la::Axis, P::Makie.PlotFunc,
        attributes::Makie.Attributes, args...;
        kw_attributes...)

    allattrs = merge(attributes, Attributes(kw_attributes))

    cycle = get_cycle_for_plottype(allattrs, P)
    add_cycle_attributes!(allattrs, P, cycle, la.cycler, la.palette)

    plot = Makie.plot!(la.scene, P, allattrs, args...)

    # some area-like plots basically always look better if they cover the whole plot area.
    # adjust the limit margins in those cases automatically.
    needs_tight_limits(plot) && tightlimits!(la)

    reset_limits!(la)
    plot
end

function Makie.plot!(P::Makie.PlotFunc, ax::Axis, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(ax, P, attributes, args...)
end

needs_tight_limits(@nospecialize any) = false
needs_tight_limits(::Union{Heatmap, Image}) = true
function needs_tight_limits(c::Contourf)
    # we know that all values are included and the contourf is rectangular
    c.levels[] isa Int
    # otherwise here it could be in an arbitrary shape
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
    Rect2f(neworigin, newwidths)
end

function limitunion(lims1, lims2)
    (min(lims1..., lims2...), max(lims1..., lims2...))
end

function expandlimits(lims, margin_low, margin_high, scale)
    # expand limits so that the margins are applied at the current axis scale
    limsordered = (min(lims[1], lims[2]), max(lims[1], lims[2]))
    lims_scaled = scale.(limsordered)

    w_scaled = lims_scaled[2] - lims_scaled[1]
    d_low_scaled = w_scaled * margin_low
    d_high_scaled = w_scaled * margin_high
    inverse = Makie.inverse_transform(scale)
    lims = inverse.((lims_scaled[1] - d_low_scaled, lims_scaled[2] + d_high_scaled))

    # guard against singular limits from something like a vline or hline
    if lims[2] - lims[1] ≈ 0
        # this works for log as well
        # we look at the distance to zero in scaled space
        # then try to center the value between that zero and the value
        # that is the same scaled distance away on the other side
        # which centers the singular value optically
        zerodist = abs(scale(lims[1]))

        # for 0 in linear space this doesn't work so here we just expand to -1, 1
        if zerodist ≈ 0 && scale === identity
            lims = (-one(lims[1]), one(lims[1]))
        else
            lims = inverse.(scale.(lims) .+ (-zerodist, zerodist))
        end
    end
    lims
end

function getlimits(la::Axis, dim)

    # find all plots that don't have exclusion attributes set
    # for this dimension
    plots_with_autolimits = if dim == 1
        filter(p -> !haskey(p.attributes, :xautolimits) || p.attributes.xautolimits[], la.scene.plots)
    elseif dim == 2
        filter(p -> !haskey(p.attributes, :yautolimits) || p.attributes.yautolimits[], la.scene.plots)
    else
        error("Dimension $dim not allowed. Only 1 or 2.")
    end

    # only use visible plots for limits
    visible_plots = filter(
        p -> !haskey(p.attributes, :visible) || p.attributes.visible[],
        plots_with_autolimits)

    # get all data limits
    bboxes = [Rect2f(Makie.data_limits(p)) for p in visible_plots]

    # filter out bboxes that are invalid somehow
    finite_bboxes = filter(Makie.isfinite_rect, bboxes)

    # if there are no bboxes remaining, `nothing` signals that no limits could be determined
    isempty(finite_bboxes) && return nothing

    # otherwise start with the first box
    templim = (finite_bboxes[1].origin[dim], finite_bboxes[1].origin[dim] + finite_bboxes[1].widths[dim])

    # and union all other limits with it
    for bb in finite_bboxes[2:end]
        templim = limitunion(templim, (bb.origin[dim], bb.origin[dim] + bb.widths[dim]))
    end

    templim
end

getxlimits(la::Axis) = getlimits(la, 1)
getylimits(la::Axis) = getlimits(la, 2)

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
    autolimits!(la::Axis)

Reset manually specified limits of `la` to an automatically determined rectangle, that depends on the data limits of all plot objects in the axis, as well as the autolimit margins for x and y axis.
"""
function autolimits!(ax::Axis)
    ax.limits[] = (nothing, nothing)
    # bbox = BBox(xautolimits(ax)..., yautolimits(ax)...)
    # ax.targetlimits[] = bbox
    nothing
end

function xautolimits(ax::Axis)
    # try getting x limits for the axis and then union them with linked axes
    xlims = getxlimits(ax)

    for link in ax.xaxislinks
        if isnothing(xlims)
            xlims = getxlimits(link)
        else
            newxlims = getxlimits(link)
            if !isnothing(newxlims)
                xlims = limitunion(xlims, newxlims)
            end
        end
    end

    if !isnothing(xlims)
        if !validate_limits_for_scale(xlims, ax.xscale[])
            error("Found invalid x-limits $xlims for scale $(ax.xscale[]) which is defined on the interval $(defined_interval(ax.xscale[]))")
        end

        xlims = expandlimits(xlims,
            ax.xautolimitmargin[][1],
            ax.xautolimitmargin[][2],
            ax.xscale[])
    end

    # if no limits have been found, use the targetlimits directly
    if isnothing(xlims)
        xlims = (ax.targetlimits[].origin[1], ax.targetlimits[].origin[1] + ax.targetlimits[].widths[1])
    end
    xlims
end

function yautolimits(ax)
    # try getting y limits for the axis and then union them with linked axes
    ylims = getylimits(ax)

    for link in ax.yaxislinks
        if isnothing(ylims)
            ylims = getylimits(link)
        else
            newylims = getylimits(link)
            if !isnothing(newylims)
                ylims = limitunion(ylims, newylims)
            end
        end
    end

    if !isnothing(ylims)
        if !validate_limits_for_scale(ylims, ax.yscale[])
            error("Found invalid direct y-limits $ylims for scale $(ax.yscale[]) which is defined on the interval $(defined_interval(ax.yscale[]))")
        end

        ylims = expandlimits(ylims,
            ax.yautolimitmargin[][1],
            ax.yautolimitmargin[][2],
            ax.yscale[])
    end

    # if no limits have been found, use the targetlimits directly
    if isnothing(ylims)
        ylims = (ax.targetlimits[].origin[2], ax.targetlimits[].origin[2] + ax.targetlimits[].widths[2])
    end
    ylims
end

"""
    linkaxes!(a::Axis, others...)

Link both x and y axes of all given `Axis` so that they stay synchronized.
"""
function linkaxes!(a::Axis, others...)
    linkxaxes!(a, others...)
    linkyaxes!(a, others...)
end


function adjustlimits!(la)
    asp = la.autolimitaspect[]
    target = la.targetlimits[]

    # in the simplest case, just update the final limits with the target limits
    if isnothing(asp)
        la.finallimits[] = target
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

        xlims = expandlimits(xlims, ((correction_factor - 1) .* ratios)..., identity) # don't use scale here?
    elseif correction_factor < 1
        # need to go taller

        marginsum = sum(la.yautolimitmargin[])
        ratios = if marginsum == 0
            (0.5, 0.5)
        else
            (la.yautolimitmargin[] ./ marginsum)
        end
        ylims = expandlimits(ylims, (((1 / correction_factor) - 1) .* ratios)..., identity) # don't use scale here?
    end

    bbox = BBox(xlims[1], xlims[2], ylims[1], ylims[2])
    la.finallimits[] = bbox
    return
end

"""
    linkxaxes!(a::Axis, others...)

Link the x axes of all given `Axis` so that they stay synchronized.
"""
function linkxaxes!(a::Axis, others...)
    axes = Axis[a; others...]

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
    reset_limits!(a)
end

"""
    linkyaxes!(a::Axis, others...)

Link the y axes of all given `Axis` so that they stay synchronized.
"""
function linkyaxes!(a::Axis, others...)
    axes = Axis[a; others...]

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
    reset_limits!(a)
end


"""
Keeps the ticklabelspace static for a short duration and then resets it to its previous
value. If that value is Makie.automatic, the reset will trigger new
protrusions for the axis and the layout will adjust. This is so the layout doesn't
immediately readjust during interaction, which would let the whole layout jitter around.
"""
function timed_ticklabelspace_reset(ax::Axis, reset_timer::Ref,
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


"""
    hidexdecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)

Hide decorations of the x-axis: label, ticklabels, ticks and grid.
"""
function hidexdecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)
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
    if minorgrid
        la.xminorgridvisible = false
    end
    if minorticks
        la.xminorticksvisible = false
    end
end

"""
    hideydecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)

Hide decorations of the y-axis: label, ticklabels, ticks and grid.
"""
function hideydecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)
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
    if minorgrid
        la.yminorgridvisible = false
    end
    if minorticks
        la.yminorticksvisible = false
    end
end

"""
    hidedecorations!(la::Axis)

Hide decorations of both x and y-axis: label, ticklabels, ticks and grid.
"""
function hidedecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)
    hidexdecorations!(la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid,
        minorgrid = minorgrid, minorticks = minorticks)
    hideydecorations!(la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid,
        minorgrid = minorgrid, minorticks = minorticks)
end

"""
    hidespines!(la::Axis, spines::Symbol... = (:l, :r, :b, :t)...)

Hide all specified axis spines. Hides all spines by default, otherwise choose
with the symbols :l, :r, :b and :t.
"""
function hidespines!(la::Axis, spines::Symbol... = (:l, :r, :b, :t)...)
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


function tight_yticklabel_spacing!(la::Axis)
    tight_ticklabel_spacing!(la.elements[:yaxis])
end

function tight_xticklabel_spacing!(la::Axis)
    tight_ticklabel_spacing!(la.elements[:xaxis])
end

function tight_ticklabel_spacing!(la::Axis)
    tight_xticklabel_spacing!(la)
    tight_yticklabel_spacing!(la)
end

function Base.show(io::IO, ::MIME"text/plain", ax::Axis)
    nplots = length(ax.scene.plots)
    println(io, "Axis with $nplots plots:")

    for (i, p) in enumerate(ax.scene.plots)
        println(io, (i == nplots ? " ┗━ " : " ┣━ ") * string(typeof(p)))
    end
end

function Base.show(io::IO, ax::Axis)
    nplots = length(ax.scene.plots)
    print(io, "Axis ($nplots plots)")
end


function Makie.xlims!(ax::Axis, xlims)
    if length(xlims) != 2
        error("Invalid xlims length of $(length(xlims)), must be 2.")
    elseif xlims[1] == xlims[2]
        error("Can't set x limits to the same value $(xlims[1]).")
    elseif all(x -> x isa Real, xlims) && xlims[1] > xlims[2]
        xlims = reverse(xlims)
        ax.xreversed[] = true
    else
        ax.xreversed[] = false
    end

    ax.limits.val = (xlims, ax.limits[][2])
    reset_limits!(ax, yauto = false)
    nothing
end

function Makie.ylims!(ax::Axis, ylims)
    if length(ylims) != 2
        error("Invalid ylims length of $(length(ylims)), must be 2.")
    elseif ylims[1] == ylims[2]
        error("Can't set y limits to the same value $(ylims[1]).")
    elseif all(x -> x isa Real, ylims) && ylims[1] > ylims[2]
        ylims = reverse(ylims)
        ax.yreversed[] = true
    else
        ax.yreversed[] = false
    end

    ax.limits.val = (ax.limits[][1], ylims)
    reset_limits!(ax, xauto = false)
    nothing
end

Makie.xlims!(ax, low, high) = Makie.xlims!(ax, (low, high))
Makie.ylims!(ax, low, high) = Makie.ylims!(ax, (low, high))
Makie.zlims!(ax, low, high) = Makie.zlims!(ax, (low, high))

Makie.xlims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.xlims!(current_axis(), low, high)
Makie.ylims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.ylims!(current_axis(), low, high)
Makie.zlims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.zlims!(current_axis(), low, high)

Makie.xlims!(ax = current_axis(); low = nothing, high = nothing) = Makie.xlims!(ax, low, high)
Makie.ylims!(ax = current_axis(); low = nothing, high = nothing) = Makie.ylims!(ax, low, high)
Makie.zlims!(ax = current_axis(); low = nothing, high = nothing) = Makie.zlims!(ax, low, high)

"""
    limits!(ax::Axis, xlims, ylims)

Set the axis limits to `xlims` and `ylims`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, xlims, ylims)
    Makie.xlims!(ax, xlims)
    Makie.ylims!(ax, ylims)
end

"""
    limits!(ax::Axis, x1, x2, y1, y2)

Set the axis x-limits to `x1` and `x2` and the y-limits to `y1` and `y2`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, x1, x2, y1, y2)
    Makie.xlims!(ax, x1, x2)
    Makie.ylims!(ax, y1, y2)
end

"""
    limits!(ax::Axis, rect::Rect2)

Set the axis limits to `rect`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, rect::Rect2)
    xmin, ymin = minimum(rect)
    xmax, ymax = maximum(rect)
    Makie.xlims!(ax, xmin, xmax)
    Makie.ylims!(ax, ymin, ymax)
end

function limits!(args...)
    limits!(current_axis(), args...)
end

function Base.delete!(ax::Axis, plot::AbstractPlot)
    delete!(ax.scene, plot)
    ax
end

function Base.empty!(ax::Axis)
    for plot in copy(ax.scene.plots)
        delete!(ax, plot)
    end
    ax
end

Makie.transform_func(ax::Axis) = Makie.transform_func(ax.scene)


# these functions pick limits for different x and y scales, so that
# we don't pick values that are invalid, such as 0 for log etc.
function defaultlimits(userlimits::Tuple{Real, Real, Real, Real}, xscale, yscale)
    BBox(userlimits...)
end

defaultlimits(l::Tuple{Any, Any, Any, Any}, xscale, yscale) = defaultlimits(((l[1], l[2]), (l[3], l[4])), xscale, yscale)

function defaultlimits(userlimits::Tuple{Any, Any}, xscale, yscale)
    xl = defaultlimits(userlimits[1], xscale)
    yl = defaultlimits(userlimits[2], yscale)
    BBox(xl..., yl...)
end

defaultlimits(limits::Nothing, scale) = defaultlimits(scale)
defaultlimits(limits::Tuple{Real, Real}, scale) = limits
defaultlimits(limits::Tuple{Real, Nothing}, scale) = (limits[1], defaultlimits(scale)[2])
defaultlimits(limits::Tuple{Nothing, Real}, scale) = (defaultlimits(scale)[1], limits[2])
defaultlimits(limits::Tuple{Nothing, Nothing}, scale) = defaultlimits(scale)


defaultlimits(::typeof(log10)) = (1.0, 1000.0)
defaultlimits(::typeof(log2)) = (1.0, 8.0)
defaultlimits(::typeof(log)) = (1.0, exp(3.0))
defaultlimits(::typeof(identity)) = (0.0, 10.0)
defaultlimits(::typeof(sqrt)) = (0.0, 100.0)
defaultlimits(::typeof(Makie.logit)) = (0.01, 0.99)
defaultlimits(::typeof(Makie.pseudolog10)) = (0.0, 100.0)
defaultlimits(::Makie.Symlog10) = (0.0, 100.0)

defined_interval(::typeof(identity)) = OpenInterval(-Inf, Inf)
defined_interval(::Union{typeof(log2), typeof(log10), typeof(log)}) = OpenInterval(0.0, Inf)
defined_interval(::typeof(sqrt)) = Interval{:closed,:open}(0, Inf)
defined_interval(::typeof(Makie.logit)) = OpenInterval(0.0, 1.0)
defined_interval(::typeof(Makie.pseudolog10)) = OpenInterval(-Inf, Inf)
defined_interval(::Makie.Symlog10) = OpenInterval(-Inf, Inf)

