function block_docs(::Type{Axis})
    """
    A 2D axis which can be plotted into.

    ## Constructors

    ```julia
    Axis(fig_or_scene; palette = nothing, kwargs...)
    ```

    ## Examples

    ```julia
    ax = Axis(fig[1, 1])
    ```
    """
end

function update_gridlines!(grid_obs::Observable{Vector{Point2f}}, offset::Point2f, tickpositions::Vector{Point2f})
    result = grid_obs[]
    empty!(result) # reuse array for less allocations
    for gridstart in tickpositions
        opposite_tickpos = gridstart .+ offset
        push!(result, gridstart, opposite_tickpos)
    end
    notify(grid_obs)
    return
end

function process_axis_event(ax, event)
    for (active, interaction) in values(ax.interactions)
        if active
            maybe_consume = process_interaction(interaction, event, ax)
            maybe_consume == Consume(true) && return Consume(true)
        end
    end
    return Consume(false)
end

function register_events!(ax, scene)

    mouseeventhandle = addmouseevents!(scene)
    setfield!(ax, :mouseeventhandle, mouseeventhandle)
    scrollevents = Observable(ScrollEvent(0, 0))
    setfield!(ax, :scrollevents, scrollevents)
    keysevents = Observable(KeysEvent(Set()))
    setfield!(ax, :keysevents, keysevents)
    evs = events(scene)
    on(evs.scroll) do s
        if is_mouseinside(scene)
            scrollevents[] = ScrollEvent(s[1], s[2])
            return Consume(true)
        end
        return Consume(false)
    end

    # TODO this should probably just forward KeyEvent from Makie
    on(evs.keyboardbutton) do e
        keysevents[] = KeysEvent(evs.keyboardstate)
        return Consume(false)
    end

    interactions = Dict{Symbol, Tuple{Bool, Any}}()
    setfield!(ax, :interactions, interactions)

    onany(process_axis_event, ax, mouseeventhandle.obs)
    onany(process_axis_event, ax, scrollevents)
    onany(process_axis_event, ax, keysevents)

    register_interaction!(ax, :rectanglezoom, RectangleZoom(ax))

    register_interaction!(ax, :limitreset, LimitReset())

    register_interaction!(ax,
        :scrollzoom,
        ScrollZoom(0.1, Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))

    register_interaction!(ax,
        :dragpan,
        DragPan(Ref{Any}(nothing), Ref{Any}(0), Ref{Any}(0), 0.2))

    return
end

function update_axis_camera(camera::Camera, t, lims, xrev::Bool, yrev::Bool)
    nearclip = -10_000f0
    farclip = 10_000f0

    tlims = Makie.apply_transform(t, lims)

    left, bottom = minimum(tlims)
    right, top = maximum(tlims)

    leftright = xrev ? (right, left) : (left, right)
    bottomtop = yrev ? (top, bottom) : (bottom, top)

    projection = Makie.orthographicprojection(
        leftright...,
        bottomtop..., nearclip, farclip)

    Makie.set_proj_view!(camera, projection, Makie.Mat4f(Makie.I))
    return
end


function calculate_title_position(area, titlegap, subtitlegap, align, xaxisposition, xaxisprotrusion, _, ax, subtitlet)
    local x::Float32 = if align === :center
        area.origin[1] + area.widths[1] / 2
    elseif align === :left
        area.origin[1]
    elseif align === :right
        area.origin[1] + area.widths[1]
    else
        error("Title align $align not supported.")
    end

    local subtitlespace::Float32 = if ax.subtitlevisible[] && !iswhitespace(ax.subtitle[])
        boundingbox(subtitlet).widths[2] + subtitlegap
    else
        0f0
    end

    local yoffset::Float32 = top(area) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0f0) +
        subtitlespace

    return Point2f(x, yoffset)
end

function compute_protrusions(title, titlesize, titlegap, titlevisible, spinewidth,
        topspinevisible, bottomspinevisible, leftspinevisible, rightspinevisible,
        xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition,
        subtitle, subtitlevisible, subtitlesize, subtitlegap, titlelineheight, subtitlelineheight,
        subtitlet, titlet)

    local left::Float32, right::Float32, bottom::Float32, top::Float32 = 0f0, 0f0, 0f0, 0f0

    if xaxisposition === :bottom
        bottom = xaxisprotrusion
    else
        top = xaxisprotrusion
    end

    titleheight = boundingbox(titlet).widths[2] + titlegap
    subtitleheight = boundingbox(subtitlet).widths[2] + subtitlegap

    titlespace = if !titlevisible || iswhitespace(title)
        0f0
    else
        titleheight
    end
    subtitlespace = if !subtitlevisible || iswhitespace(subtitle)
        0f0
    else
        subtitleheight
    end

    top += titlespace + subtitlespace

    if yaxisposition == :left
        left = yaxisprotrusion
    else
        right = yaxisprotrusion
    end

    return GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
end

function initialize_block!(ax::Axis; palette = nothing)

    topscene = ax.blockscene

    decorations = Dict{Symbol, Any}()

    if palette === nothing
        palette = haskey(topscene.theme, :palette) ? deepcopy(topscene.theme[:palette]) : copy(Makie.default_palettes)
    end
    ax.palette = palette isa Attributes ? palette : Attributes(palette)

    # initialize either with user limits, or pick defaults based on scales
    # so that we don't immediately error
    targetlimits = Observable{Rect2f}(defaultlimits(ax.limits[], ax.xscale[], ax.yscale[]))
    finallimits = Observable{Rect2f}(targetlimits[]; ignore_equal_values=true)
    setfield!(ax, :targetlimits, targetlimits)
    setfield!(ax, :finallimits, finallimits)

    ax.cycler = Cycler()

    # the first thing to do when setting a new scale is
    # resetting the limits because simply through expanding they might be invalid for log
    onany(ax.xscale, ax.yscale) do _, _
        reset_limits!(ax)
    end

    on(targetlimits) do lims
        # this should validate the targetlimits before anything else happens with them
        # so there should be nothing before this lifting `targetlimits`
        # we don't use finallimits because that's one step later and you
        # already shouldn't set invalid targetlimits (even if they could
        # theoretically be adjusted to fit somehow later?)
        # and this way we can error pretty early
        validate_limits_for_scales(lims, ax.xscale[], ax.yscale[])
    end

    scenearea = sceneareanode!(ax.layoutobservables.computedbbox, finallimits, ax.aspect)

    scene = Scene(topscene, px_area=scenearea)
    ax.scene = scene

    # TODO: replace with mesh, however, CairoMakie needs a poly path for this signature
    # so it doesn't rasterize the scene
    background = poly!(topscene, scenearea; color=ax.backgroundcolor, inspectable=false, shading=false, strokecolor=:transparent)
    translate!(background, 0, 0, -100)
    decorations[:background] = background

    block_limit_linking = Observable(false)
    setfield!(ax, :block_limit_linking, block_limit_linking)

    ax.xaxislinks = Axis[]
    ax.yaxislinks = Axis[]

    xgridnode = Observable(Point2f[]; ignore_equal_values=true)
    xgridlines = linesegments!(
        topscene, xgridnode, linewidth = ax.xgridwidth, visible = ax.xgridvisible,
        color = ax.xgridcolor, linestyle = ax.xgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    decorations[:xgridlines] = xgridlines

    xminorgridnode = Observable(Point2f[]; ignore_equal_values=true)
    xminorgridlines = linesegments!(
        topscene, xminorgridnode, linewidth = ax.xminorgridwidth, visible = ax.xminorgridvisible,
        color = ax.xminorgridcolor, linestyle = ax.xminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xminorgridlines, 0, 0, -10)
    decorations[:xminorgridlines] = xminorgridlines

    ygridnode = Observable(Point2f[]; ignore_equal_values=true)
    ygridlines = linesegments!(
        topscene, ygridnode, linewidth = ax.ygridwidth, visible = ax.ygridvisible,
        color = ax.ygridcolor, linestyle = ax.ygridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    decorations[:ygridlines] = ygridlines

    yminorgridnode = Observable(Point2f[]; ignore_equal_values=true)
    yminorgridlines = linesegments!(
        topscene, yminorgridnode, linewidth = ax.yminorgridwidth, visible = ax.yminorgridvisible,
        color = ax.yminorgridcolor, linestyle = ax.yminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(yminorgridlines, 0, 0, -10)
    decorations[:yminorgridlines] = yminorgridlines

    onany(ax.xscale, ax.yscale) do xsc, ysc
        scene.transformation.transform_func[] = (xsc, ysc)
        return
    end

    notify(ax.xscale)

    onany(update_axis_camera, camera(scene), scene.transformation.transform_func, finallimits, ax.xreversed, ax.yreversed)

    xaxis_endpoints = lift(ax.xaxisposition, scene.px_area; ignore_equal_values=true) do xaxisposition, area
        if xaxisposition == :bottom
            return bottomline(Rect2f(area))
        elseif xaxisposition == :top
            return topline(Rect2f(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    yaxis_endpoints = lift(ax.yaxisposition, scene.px_area; ignore_equal_values=true) do yaxisposition, area
        if yaxisposition == :left
            return leftline(Rect2f(area))
        elseif yaxisposition == :right
            return rightline(Rect2f(area))
        else
            error("Invalid yaxisposition $yaxisposition")
        end
    end

    xaxis_flipped = lift(x->x == :top, ax.xaxisposition; ignore_equal_values=true)
    yaxis_flipped = lift(x->x == :right, ax.yaxisposition; ignore_equal_values=true)

    xspinevisible = lift(xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible; ignore_equal_values=true) do xflip, bv, tv
        xflip ? tv : bv
    end
    xoppositespinevisible = lift(xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible; ignore_equal_values=true) do xflip, bv, tv
        xflip ? bv : tv
    end
    yspinevisible = lift(yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible; ignore_equal_values=true) do yflip, lv, rv
        yflip ? rv : lv
    end
    yoppositespinevisible = lift(yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible; ignore_equal_values=true) do yflip, lv, rv
        yflip ? lv : rv
    end
    xspinecolor = lift(xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor; ignore_equal_values=true) do xflip, bc, tc
        xflip ? tc : bc
    end
    xoppositespinecolor = lift(xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor; ignore_equal_values=true) do xflip, bc, tc
        xflip ? bc : tc
    end
    yspinecolor = lift(yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor; ignore_equal_values=true) do yflip, lc, rc
        yflip ? rc : lc
    end
    yoppositespinecolor = lift(yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor; ignore_equal_values=true) do yflip, lc, rc
        yflip ? lc : rc
    end

    xlims = lift(xlimits, finallimits; ignore_equal_values=true)
    ylims = lift(ylimits, finallimits; ignore_equal_values=true)

    xaxis = LineAxis(topscene, endpoints = xaxis_endpoints, limits = xlims,
        flipped = xaxis_flipped, ticklabelrotation = ax.xticklabelrotation,
        ticklabelalign = ax.xticklabelalign, labelsize = ax.xlabelsize,
        labelpadding = ax.xlabelpadding, ticklabelpad = ax.xticklabelpad, labelvisible = ax.xlabelvisible,
        label = ax.xlabel, labelfont = ax.xlabelfont, ticklabelfont = ax.xticklabelfont, ticklabelcolor = ax.xticklabelcolor, labelcolor = ax.xlabelcolor, tickalign = ax.xtickalign,
        ticklabelspace = ax.xticklabelspace, ticks = ax.xticks, tickformat = ax.xtickformat, ticklabelsvisible = ax.xticklabelsvisible,
        ticksvisible = ax.xticksvisible, spinevisible = xspinevisible, spinecolor = xspinecolor, spinewidth = ax.spinewidth,
        ticklabelsize = ax.xticklabelsize, trimspine = ax.xtrimspine, ticksize = ax.xticksize,
        reversed = ax.xreversed, tickwidth = ax.xtickwidth, tickcolor = ax.xtickcolor,
        minorticksvisible = ax.xminorticksvisible, minortickalign = ax.xminortickalign, minorticksize = ax.xminorticksize, minortickwidth = ax.xminortickwidth, minortickcolor = ax.xminortickcolor, minorticks = ax.xminorticks, scale = ax.xscale,
        )
    ax.xaxis = xaxis

    yaxis = LineAxis(topscene, endpoints = yaxis_endpoints, limits = ylims,
        flipped = yaxis_flipped, ticklabelrotation = ax.yticklabelrotation,
        ticklabelalign = ax.yticklabelalign, labelsize = ax.ylabelsize,
        labelpadding = ax.ylabelpadding, ticklabelpad = ax.yticklabelpad, labelvisible = ax.ylabelvisible,
        label = ax.ylabel, labelfont = ax.ylabelfont, ticklabelfont = ax.yticklabelfont, ticklabelcolor = ax.yticklabelcolor, labelcolor = ax.ylabelcolor, tickalign = ax.ytickalign,
        ticklabelspace = ax.yticklabelspace, ticks = ax.yticks, tickformat = ax.ytickformat, ticklabelsvisible = ax.yticklabelsvisible,
        ticksvisible = ax.yticksvisible, spinevisible = yspinevisible, spinecolor = yspinecolor, spinewidth = ax.spinewidth,
        trimspine = ax.ytrimspine, ticklabelsize = ax.yticklabelsize, ticksize = ax.yticksize, flip_vertical_label = ax.flip_ylabel, reversed = ax.yreversed, tickwidth = ax.ytickwidth,
            tickcolor = ax.ytickcolor,
        minorticksvisible = ax.yminorticksvisible, minortickalign = ax.yminortickalign, minorticksize = ax.yminorticksize, minortickwidth = ax.yminortickwidth, minortickcolor = ax.yminortickcolor, minorticks = ax.yminorticks, scale = ax.yscale,
        )

    ax.yaxis = yaxis

    xoppositelinepoints = lift(scene.px_area, ax.spinewidth, ax.xaxisposition; ignore_equal_values=true) do r, sw, xaxpos
        if xaxpos == :top
            y = bottom(r)
            p1 = Point2f(left(r) - 0.5sw, y)
            p2 = Point2f(right(r) + 0.5sw, y)
            return [p1, p2]
        else
            y = top(r)
            p1 = Point2f(left(r) - 0.5sw, y)
            p2 = Point2f(right(r) + 0.5sw, y)
            return [p1, p2]
        end
    end

    yoppositelinepoints = lift(scene.px_area, ax.spinewidth, ax.yaxisposition; ignore_equal_values=true) do r, sw, yaxpos
        if yaxpos == :right
            x = left(r)
            p1 = Point2f(x, bottom(r) - 0.5sw)
            p2 = Point2f(x, top(r) + 0.5sw)
            return [p1, p2]
        else
            x = right(r)
            p1 = Point2f(x, bottom(r) - 0.5sw)
            p2 = Point2f(x, top(r) + 0.5sw)
            return [p1, p2]
        end
    end

    xoppositeline = linesegments!(topscene, xoppositelinepoints, linewidth = ax.spinewidth,
        visible = xoppositespinevisible, color = xoppositespinecolor, inspectable = false,
        linestyle = nothing)
    decorations[:xoppositeline] = xoppositeline
    translate!(xoppositeline, 0, 0, 20)

    yoppositeline = linesegments!(topscene, yoppositelinepoints, linewidth = ax.spinewidth,
        visible = yoppositespinevisible, color = yoppositespinecolor, inspectable = false,
        linestyle = nothing)
    decorations[:yoppositeline] = yoppositeline
    translate!(yoppositeline, 0, 0, 20)

    onany(xaxis.tickpositions, scene.px_area) do tickpos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = ax.xaxisposition[] === :bottom ? pxheight : -pxheight
        update_gridlines!(xgridnode, Point2f(0, offset), tickpos)
    end

    onany(yaxis.tickpositions, scene.px_area) do tickpos, area
        local pxwidth::Float32 = width(area)
        local offset::Float32 = ax.yaxisposition[] === :left ? pxwidth : -pxwidth
        update_gridlines!(ygridnode, Point2f(offset, 0), tickpos)
    end

    on(xaxis.minortickpositions) do tickpos
        local pxheight::Float32 = height(scene.px_area[])
        local offset::Float32 = ax.xaxisposition[] == :bottom ? pxheight : -pxheight
        update_gridlines!(xminorgridnode, Point2f(0, offset), tickpos)
    end

    on(yaxis.minortickpositions) do tickpos
        local pxwidth::Float32 = width(scene.px_area[])
        local offset::Float32 = ax.yaxisposition[] == :left ? pxwidth : -pxwidth
        update_gridlines!(yminorgridnode, Point2f(offset, 0), tickpos)
    end

    subtitlepos = lift(scene.px_area, ax.titlegap, ax.titlealign, ax.xaxisposition, xaxis.protrusion; ignore_equal_values=true) do a,
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

        return Point2f(x, yoffset)
    end

    titlealignnode = lift(ax.titlealign; ignore_equal_values=true) do align
        (align, :bottom)
    end

    subtitlet = text!(
        topscene, subtitlepos,
        text = ax.subtitle,
        visible = ax.subtitlevisible,
        textsize = ax.subtitlesize,
        align = titlealignnode,
        font = ax.subtitlefont,
        color = ax.subtitlecolor,
        lineheight = ax.subtitlelineheight,
        markerspace = :data,
        inspectable = false)

    titlepos = lift(calculate_title_position, scene.px_area, ax.titlegap, ax.subtitlegap,
        ax.titlealign, ax.xaxisposition, xaxis.protrusion, ax.subtitlelineheight, ax, subtitlet; ignore_equal_values=true)

    titlet = text!(
        topscene, titlepos,
        text = ax.title,
        visible = ax.titlevisible,
        textsize = ax.titlesize,
        align = titlealignnode,
        font = ax.titlefont,
        color = ax.titlecolor,
        lineheight = ax.titlelineheight,
        markerspace = :data,
        inspectable = false)
    decorations[:title] = titlet

    map!(compute_protrusions, ax.layoutobservables.protrusions, ax.title, ax.titlesize, ax.titlegap, ax.titlevisible, ax.spinewidth,
            ax.topspinevisible, ax.bottomspinevisible, ax.leftspinevisible, ax.rightspinevisible,
            xaxis.protrusion, yaxis.protrusion, ax.xaxisposition, ax.yaxisposition,
            ax.subtitle, ax.subtitlevisible, ax.subtitlesize, ax.subtitlegap,
            ax.titlelineheight, ax.subtitlelineheight, subtitlet, titlet)
    # trigger first protrusions with one of the observables
    notify(ax.title)

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    notify(ax.layoutobservables.suggestedbbox)

    register_events!(ax, scene)

    # these are the user defined limits
    on(ax.limits) do mlims
        reset_limits!(ax)
    end

    # these are the limits that we try to target, but they can be changed for correct aspects
    on(targetlimits) do tlims
        update_linked_limits!(block_limit_linking, ax.xaxislinks, ax.yaxislinks, tlims)
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

    return ax
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
        convert(Tuple{Float32, Float32}, tuple(mylims...))
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
            convert(Tuple{Float32, Float32}, tuple(mzlims...))
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
    # check if none of the cycled attributes of this plot
    # were passed manually, because we don't use the cycler
    # if any of the cycled attributes were specified manually
    no_cycle_attribute_passed = !any(keys(allattrs)) do key
        any(syms -> key in syms, attrsyms(cycle))
    end

    # check if any attributes were passed as `Cycled` entries
    # because if there were any, these are looked up directly
    # in the cycler without advancing the counter etc.
    manually_cycled_attributes = filter(keys(allattrs)) do key
        to_value(allattrs[key]) isa Cycled
    end

    # if there are any manually cycled attributes, we don't do the normal
    # cycling but only look up exactly the passed attributes
    cycle_attrsyms = attrsyms(cycle)
    if !isempty(manually_cycled_attributes)
        # an attribute given as Cycled needs to be present in the cycler,
        # otherwise there's no cycle in which to look up a value
        for k in manually_cycled_attributes
            if !any(x -> k in x, cycle_attrsyms)
                error("Attribute `$k` was passed with an explicit `Cycled` value, but $k is not specified in the cycler for this plot type $P.")
            end
        end

        palettes = [palette[sym][] for sym in palettesyms(cycle)]

        for sym in manually_cycled_attributes
            isym = findfirst(syms -> sym in syms, attrsyms(cycle))
            index = allattrs[sym][].i
            # replace the Cycled values with values from the correct palettes
            # at the index inside the Cycled object
            allattrs[sym] = if cycle.covary
                palettes[isym][mod1(index, length(palettes[isym]))]
            else
                cis = CartesianIndices(Tuple(length(p) for p in palettes))
                n = length(cis)
                k = mod1(index, n)
                idx = Tuple(cis[k])
                palettes[isym][idx[isym]]
            end
        end

    elseif no_cycle_attribute_passed
        index = get_cycler_index!(cycler, P)

        palettes = [palette[sym][] for sym in palettesyms(cycle)]

        for (isym, syms) in enumerate(attrsyms(cycle))
            for sym in syms
                allattrs[sym] = if cycle.covary
                    palettes[isym][mod1(index, length(palettes[isym]))]
                else
                    cis = CartesianIndices(Tuple(length(p) for p in palettes))
                    n = length(cis)
                    k = mod1(index, n)
                    idx = Tuple(cis[k])
                    palettes[isym][idx[isym]]
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

    _disallow_keyword(:axis, allattrs)
    _disallow_keyword(:figure, allattrs)

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
    # otherwise here it could be in an arbitrary shape
    return c.levels[] isa Int
end

function expandbboxwithfractionalmargins(bb, margins)
    newwidths = bb.widths .* (1f0 .+ margins)
    diffs = newwidths .- bb.widths
    neworigin = bb.origin .- (0.5f0 .* diffs)
    return Rect2f(neworigin, newwidths)
end

limitunion(lims1, lims2) = (min(lims1..., lims2...), max(lims1..., lims2...))

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
    if !(dim in (1, 2))
        error("Dimension $dim not allowed. Only 1 or 2.")
    end

    function exclude(plot)
        # only use plots with autolimits = true
        to_value(get(plot, dim == 1 ? :xautolimits : :yautolimits, true)) || return true
        # only if they use data coordinates
        is_data_space(to_value(get(plot, :space, :data))) || return true
        # only use visible plots for limits
        return !to_value(get(plot, :visible, true))
    end
    # get all data limits, minus the excluded plots
    boundingbox = Makie.data_limits(la.scene, exclude)
    # if there are no bboxes remaining, `nothing` signals that no limits could be determined
    Makie.isfinite_rect(boundingbox) || return nothing

    # otherwise start with the first box
    mini, maxi = minimum(boundingbox), maximum(boundingbox)
    return (mini[dim], maxi[dim])
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
            otherxlims = limits(otherlims, 1)
            otherylims = limits(otherlims, 2)
            if thisxlims != otherxlims
                xlink.block_limit_linking[] = true
                xlink.targetlimits[] = BBox(thisxlims[1], thisxlims[2], otherylims[1], otherylims[2])
                xlink.block_limit_linking[] = false
            end
        end

        for ylink in ylinks
            otherlims = ylink.targetlimits[]
            otherxlims = limits(otherlims, 1)
            otherylims = limits(otherlims, 2)
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
    return
end

function autolimits(ax::Axis, dim::Integer)
    # try getting x limits for the axis and then union them with linked axes
    lims = getlimits(ax, dim)

    links = dim == 1 ? ax.xaxislinks : ax.yaxislinks
    for link in links
        if isnothing(lims)
            lims = getlimits(link, dim)
        else
            newlims = getlimits(link, dim)
            if !isnothing(newlims)
                lims = limitunion(lims, newlims)
            end
        end
    end

    dimsym = dim == 1 ? :x : :y
    scale = getproperty(ax, Symbol(dimsym, :scale))[]
    margin = getproperty(ax, Symbol(dimsym, :autolimitmargin))[]
    if !isnothing(lims)
        if !validate_limits_for_scale(lims, scale)
            error("Found invalid x-limits $lims for scale $(scale) which is defined on the interval $(defined_interval(scale))")
        end
        lims = expandlimits(lims, margin[1], margin[2], scale)
    end

    # if no limits have been found, use the targetlimits directly
    if isnothing(lims)
        lims = limits(ax.targetlimits[], dim)
    end
    return lims
end

xautolimits(ax::Axis) = autolimits(ax, 1)
yautolimits(ax::Axis) = autolimits(ax, 2)

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
    area = la.scene.px_area[]

    # in the simplest case, just update the final limits with the target limits
    if isnothing(asp) || width(area) == 0 || height(area) == 0
        la.finallimits[] = target
        return
    end

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

        ax.xticklabelspace = Float64(ax.xaxis.attributes.actual_ticklabelspace[])
        ax.yticklabelspace = Float64(ax.yaxis.attributes.actual_ticklabelspace[])
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

"""
    space = tight_xticklabel_spacing!(ax::Axis)
    
Sets the space allocated for the xticklabels of the `Axis` to the minimum that is needed and returns that value.
"""
function tight_yticklabel_spacing!(ax::Axis)
    space = tight_ticklabel_spacing!(ax.yaxis)
    return space
end

"""
    space = tight_xticklabel_spacing!(ax::Axis)
    
Sets the space allocated for the yticklabels of the `Axis` to the minimum that is needed and returns that value.
"""
function tight_xticklabel_spacing!(ax::Axis)
    space = tight_ticklabel_spacing!(ax.xaxis)
    return space
end

"""
Sets the space allocated for the xticklabels and yticklabels of the `Axis` to the minimum that is needed.
"""
function tight_ticklabel_spacing!(ax::Axis)
    tight_xticklabel_spacing!(ax)
    tight_yticklabel_spacing!(ax)
    return
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
