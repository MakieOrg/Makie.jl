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
    ax.scene.visible[] || return Consume(false)
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

    on(scene, evs.scroll) do s
        if is_mouseinside(scene)
            result = setindex!(scrollevents, ScrollEvent(s[1], s[2]))
            return Consume(result)
        end
        return Consume(false)
    end

    # TODO this should probably just forward KeyEvent from Makie
    on(scene, evs.keyboardbutton) do e
        keysevents[] = KeysEvent(evs.keyboardstate)
        return Consume(false)
    end

    interactions = Dict{Symbol, Tuple{Bool, Any}}()
    setfield!(ax, :interactions, interactions)

    onany(process_axis_event, scene, ax, mouseeventhandle.obs)
    onany(process_axis_event, scene, ax, scrollevents)
    onany(process_axis_event, scene, ax, keysevents)

    register_interaction!(ax, :rectanglezoom, RectangleZoom(ax))

    register_interaction!(ax, :limitreset, LimitReset())

    register_interaction!(ax, :scrollzoom, ScrollZoom(0.1, 0.2))

    register_interaction!(ax, :dragpan, DragPan(0.2))

    return
end

function update_axis_camera(scene::Scene, t, lims, xrev::Bool, yrev::Bool)
    nearclip = -10_000f0
    farclip = 10_000f0

    # we are computing transformed camera position, so this isn't space dependent
    tlims = Makie.apply_transform(t, lims)
    camera = scene.camera

    update_limits!(scene.float32convert, tlims) # update float32 scaling
    lims32 = f32_convert(scene.float32convert, tlims)  # get scaled limits
    left, bottom = minimum(lims32)
    right, top = maximum(lims32)
    leftright = xrev ? (right, left) : (left, right)
    bottomtop = yrev ? (top, bottom) : (bottom, top)

    projection = Makie.orthographicprojection(
        Float32,
        leftright...,
        bottomtop..., nearclip, farclip
    )

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
        boundingbox(subtitlet, :data).widths[2] + subtitlegap
    else
        0.0f0
    end

    local yoffset::Float32 = top(area) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0.0f0) +
        subtitlespace

    return Point2f(x, yoffset)
end

function compute_protrusions(
        title, titlesize, titlegap, titlevisible, spinewidth,
        topspinevisible, bottomspinevisible, leftspinevisible, rightspinevisible,
        xaxisprotrusion, yaxisprotrusion, xaxisposition, yaxisposition,
        subtitle, subtitlevisible, subtitlesize, subtitlegap, titlelineheight, subtitlelineheight,
        subtitlet, titlet
    )

    local left::Float32, right::Float32, bottom::Float32, top::Float32 = 0.0f0, 0.0f0, 0.0f0, 0.0f0

    if xaxisposition === :bottom
        bottom = xaxisprotrusion
    else
        top = xaxisprotrusion
    end

    titleheight = boundingbox(titlet, :data).widths[2] + titlegap
    subtitleheight = boundingbox(subtitlet, :data).widths[2] + subtitlegap

    titlespace = if !titlevisible || iswhitespace(title)
        0.0f0
    else
        titleheight
    end
    subtitlespace = if !subtitlevisible || iswhitespace(subtitle)
        0.0f0
    else
        subtitleheight
    end

    top += titlespace + subtitlespace

    if yaxisposition === :left
        left = yaxisprotrusion
    else
        right = yaxisprotrusion
    end

    return GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
end

function initialize_block!(ax::Axis; palette = nothing)
    blockscene = ax.blockscene
    elements = Dict{Symbol, Any}()
    ax.elements = elements

    # initialize either with user limits, or pick defaults based on scales
    # so that we don't immediately error
    targetlimits = Observable{Rect2d}(defaultlimits(ax.limits[], ax.xscale[], ax.yscale[]))
    finallimits = Observable{Rect2d}(targetlimits[]; ignore_equal_values = true)
    setfield!(ax, :targetlimits, targetlimits)
    setfield!(ax, :finallimits, finallimits)

    on(blockscene, targetlimits) do lims
        # this should validate the targetlimits before anything else happens with them
        # so there should be nothing before this lifting `targetlimits`
        # we don't use finallimits because that's one step later and you
        # already shouldn't set invalid targetlimits (even if they could
        # theoretically be adjusted to fit somehow later?)
        # and this way we can error pretty early
        validate_limits_for_scales(lims, ax.xscale[], ax.yscale[])
    end

    scenearea = sceneareanode!(ax.layoutobservables.computedbbox, finallimits, ax.aspect)

    scene = Scene(blockscene, viewport = scenearea, visible = false)
    # Hide to block updates, will be unhidden! in constructor who calls this!
    @assert !scene.visible[]
    ax.scene = scene
    # transfer conversions from axis to scene if there are any
    # or the other way around
    connect_conversions!(scene.conversions, ax)

    setfield!(scene, :float32convert, Float32Convert())

    if !isnothing(palette)
        # Backwards compatibility for when palette was part of axis!
        palette_attr = palette isa Attributes ? palette : Attributes(palette)
        ax.scene.theme.palette = palette_attr
    end

    # TODO: replace with mesh, however, CairoMakie needs a poly path for this signature
    # so it doesn't rasterize the scene
    background = poly!(blockscene, scenearea; color = ax.backgroundcolor, inspectable = false, shading = NoShading, strokecolor = :transparent)
    translate!(background, 0, 0, -100)
    elements[:background] = background

    block_limit_linking = Observable(false)
    setfield!(ax, :block_limit_linking, block_limit_linking)

    ax.xaxislinks = Axis[]
    ax.yaxislinks = Axis[]

    xgridnode = Observable(Point2f[]; ignore_equal_values = true)
    xgridlines = linesegments!(
        blockscene, xgridnode, linewidth = ax.xgridwidth, visible = ax.xgridvisible,
        color = ax.xgridcolor, linestyle = ax.xgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    elements[:xgridlines] = xgridlines

    xminorgridnode = Observable(Point2f[]; ignore_equal_values = true)
    xminorgridlines = linesegments!(
        blockscene, xminorgridnode, linewidth = ax.xminorgridwidth, visible = ax.xminorgridvisible,
        color = ax.xminorgridcolor, linestyle = ax.xminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xminorgridlines, 0, 0, -10)
    elements[:xminorgridlines] = xminorgridlines

    ygridnode = Observable(Point2f[]; ignore_equal_values = true)
    ygridlines = linesegments!(
        blockscene, ygridnode, linewidth = ax.ygridwidth, visible = ax.ygridvisible,
        color = ax.ygridcolor, linestyle = ax.ygridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    elements[:ygridlines] = ygridlines

    yminorgridnode = Observable(Point2f[]; ignore_equal_values = true)
    yminorgridlines = linesegments!(
        blockscene, yminorgridnode, linewidth = ax.yminorgridwidth, visible = ax.yminorgridvisible,
        color = ax.yminorgridcolor, linestyle = ax.yminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(yminorgridlines, 0, 0, -10)
    elements[:yminorgridlines] = yminorgridlines

    # When the transform function (xscale, yscale) of a plot changes we
    # 1. communicate this change to plots (barplot needs this to make bars
    #    compatible with the new transform function/scale)
    onany(blockscene, ax.xscale, ax.yscale) do xsc, ysc
        scene.transformation.transform_func[] = (xsc, ysc)
        return
    end

    # 2. Update the limits of the plot
    onany(blockscene, scene.transformation.transform_func, priority = -1) do _
        reset_limits!(ax)
    end

    notify(ax.xscale)

    # 3. Update the view onto the plot (camera matrices)
    onany(
        blockscene, scene.transformation.transform_func, finallimits,
        ax.xreversed, ax.yreversed; priority = -2
    ) do args...
        update_axis_camera(scene, args...)
    end

    xaxis_endpoints = lift(
        blockscene, ax.xaxisposition, scene.viewport;
        ignore_equal_values = true
    ) do xaxisposition, area
        if xaxisposition === :bottom
            return bottomline(Rect2f(area))
        elseif xaxisposition === :top
            return topline(Rect2f(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    yaxis_endpoints = lift(
        blockscene, ax.yaxisposition, scene.viewport;
        ignore_equal_values = true
    ) do yaxisposition, area
        if yaxisposition === :left
            return leftline(Rect2f(area))
        elseif yaxisposition === :right
            return rightline(Rect2f(area))
        else
            error("Invalid yaxisposition $yaxisposition")
        end
    end

    xaxis_flipped = lift(x -> x === :top, blockscene, ax.xaxisposition; ignore_equal_values = true)
    yaxis_flipped = lift(x -> x === :right, blockscene, ax.yaxisposition; ignore_equal_values = true)

    xspinevisible = lift(
        blockscene, xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible;
        ignore_equal_values = true
    ) do xflip, bv, tv
        xflip ? tv : bv
    end
    xoppositespinevisible = lift(
        blockscene, xaxis_flipped, ax.bottomspinevisible, ax.topspinevisible;
        ignore_equal_values = true
    ) do xflip, bv, tv
        xflip ? bv : tv
    end
    yspinevisible = lift(
        blockscene, yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible;
        ignore_equal_values = true
    ) do yflip, lv, rv
        yflip ? rv : lv
    end
    yoppositespinevisible = lift(
        blockscene, yaxis_flipped, ax.leftspinevisible, ax.rightspinevisible;
        ignore_equal_values = true
    ) do yflip, lv, rv
        yflip ? lv : rv
    end
    xspinecolor = lift(
        blockscene, xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor;
        ignore_equal_values = true
    ) do xflip, bc, tc
        xflip ? tc : bc
    end
    xoppositespinecolor = lift(
        blockscene, xaxis_flipped, ax.bottomspinecolor, ax.topspinecolor;
        ignore_equal_values = true
    ) do xflip, bc, tc
        xflip ? bc : tc
    end
    yspinecolor = lift(
        blockscene, yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor;
        ignore_equal_values = true
    ) do yflip, lc, rc
        yflip ? rc : lc
    end
    yoppositespinecolor = lift(
        blockscene, yaxis_flipped, ax.leftspinecolor, ax.rightspinecolor;
        ignore_equal_values = true
    ) do yflip, lc, rc
        yflip ? lc : rc
    end

    xlims = lift(xlimits, blockscene, finallimits; ignore_equal_values = true)
    ylims = lift(ylimits, blockscene, finallimits; ignore_equal_values = true)

    xaxis = LineAxis(
        blockscene, endpoints = xaxis_endpoints, limits = xlims,
        flipped = xaxis_flipped, ticklabelrotation = ax.xticklabelrotation,
        ticklabelalign = ax.xticklabelalign, labelsize = ax.xlabelsize,
        labelpadding = ax.xlabelpadding, ticklabelpad = ax.xticklabelpad, labelvisible = ax.xlabelvisible,
        label = ax.xlabel, labelfont = ax.xlabelfont, labelrotation = ax.xlabelrotation, ticklabelfont = ax.xticklabelfont, ticklabelcolor = ax.xticklabelcolor, labelcolor = ax.xlabelcolor, tickalign = ax.xtickalign,
        ticklabelspace = ax.xticklabelspace, dim_convert = ax.dim1_conversion, ticks = ax.xticks, tickformat = ax.xtickformat, ticklabelsvisible = ax.xticklabelsvisible,
        ticksvisible = ax.xticksvisible, spinevisible = xspinevisible, spinecolor = xspinecolor, spinewidth = ax.spinewidth,
        ticklabelsize = ax.xticklabelsize, trimspine = ax.xtrimspine, ticksize = ax.xticksize,
        reversed = ax.xreversed, tickwidth = ax.xtickwidth, tickcolor = ax.xtickcolor,
        minorticksvisible = ax.xminorticksvisible, minortickalign = ax.xminortickalign, minorticksize = ax.xminorticksize, minortickwidth = ax.xminortickwidth, minortickcolor = ax.xminortickcolor, minorticks = ax.xminorticks, scale = ax.xscale,
        minorticksused = ax.xminorgridvisible,
    )

    ax.xaxis = xaxis

    yaxis = LineAxis(
        blockscene, endpoints = yaxis_endpoints, limits = ylims,
        flipped = yaxis_flipped, ticklabelrotation = ax.yticklabelrotation,
        ticklabelalign = ax.yticklabelalign, labelsize = ax.ylabelsize,
        labelpadding = ax.ylabelpadding, ticklabelpad = ax.yticklabelpad, labelvisible = ax.ylabelvisible,
        label = ax.ylabel, labelfont = ax.ylabelfont, labelrotation = ax.ylabelrotation, ticklabelfont = ax.yticklabelfont, ticklabelcolor = ax.yticklabelcolor, labelcolor = ax.ylabelcolor, tickalign = ax.ytickalign,
        ticklabelspace = ax.yticklabelspace, dim_convert = ax.dim2_conversion, ticks = ax.yticks, tickformat = ax.ytickformat, ticklabelsvisible = ax.yticklabelsvisible,
        ticksvisible = ax.yticksvisible, spinevisible = yspinevisible, spinecolor = yspinecolor, spinewidth = ax.spinewidth,
        trimspine = ax.ytrimspine, ticklabelsize = ax.yticklabelsize, ticksize = ax.yticksize, flip_vertical_label = ax.flip_ylabel, reversed = ax.yreversed, tickwidth = ax.ytickwidth,
        tickcolor = ax.ytickcolor,
        minorticksvisible = ax.yminorticksvisible, minortickalign = ax.yminortickalign, minorticksize = ax.yminorticksize, minortickwidth = ax.yminortickwidth, minortickcolor = ax.yminortickcolor, minorticks = ax.yminorticks, scale = ax.yscale,
        minorticksused = ax.yminorgridvisible,
    )

    ax.yaxis = yaxis

    xoppositelinepoints = lift(
        blockscene, scene.viewport, ax.spinewidth, ax.xaxisposition;
        ignore_equal_values = true
    ) do r, sw, xaxpos
        if xaxpos === :top
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

    yoppositelinepoints = lift(
        blockscene, scene.viewport, ax.spinewidth, ax.yaxisposition;
        ignore_equal_values = true
    ) do r, sw, yaxpos
        if yaxpos === :right
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

    xticksmirrored = lift(
        mirror_ticks, blockscene, xaxis.tickpositions, ax.xticksize, ax.xtickalign,
        scene.viewport, :x, ax.xaxisposition[], ax.spinewidth
    )
    xticksmirrored_lines = linesegments!(
        blockscene, xticksmirrored, visible = @lift($(ax.xticksmirrored) && $(ax.xticksvisible)),
        linewidth = ax.xtickwidth, color = ax.xtickcolor
    )
    translate!(xticksmirrored_lines, 0, 0, 10)
    yticksmirrored = lift(
        mirror_ticks, blockscene, yaxis.tickpositions, ax.yticksize, ax.ytickalign,
        scene.viewport, :y, ax.yaxisposition[], ax.spinewidth
    )
    yticksmirrored_lines = linesegments!(
        blockscene, yticksmirrored, visible = @lift($(ax.yticksmirrored) && $(ax.yticksvisible)),
        linewidth = ax.ytickwidth, color = ax.ytickcolor
    )
    translate!(yticksmirrored_lines, 0, 0, 10)
    xminorticksmirrored = lift(
        mirror_ticks, blockscene, xaxis.minortickpositions, ax.xminorticksize,
        ax.xminortickalign, scene.viewport, :x, ax.xaxisposition[], ax.spinewidth
    )
    xminorticksmirrored_lines = linesegments!(
        blockscene, xminorticksmirrored, visible = @lift($(ax.xticksmirrored) && $(ax.xminorticksvisible)),
        linewidth = ax.xminortickwidth, color = ax.xminortickcolor
    )
    translate!(xminorticksmirrored_lines, 0, 0, 10)
    yminorticksmirrored = lift(
        mirror_ticks, blockscene, yaxis.minortickpositions, ax.yminorticksize,
        ax.yminortickalign, scene.viewport, :y, ax.yaxisposition[], ax.spinewidth
    )
    yminorticksmirrored_lines = linesegments!(
        blockscene, yminorticksmirrored, visible = @lift($(ax.yticksmirrored) && $(ax.yminorticksvisible)),
        linewidth = ax.yminortickwidth, color = ax.yminortickcolor
    )
    translate!(yminorticksmirrored_lines, 0, 0, 10)

    xoppositeline = linesegments!(
        blockscene, xoppositelinepoints, linewidth = ax.spinewidth,
        visible = xoppositespinevisible, color = xoppositespinecolor, inspectable = false,
        linestyle = nothing
    )
    elements[:xoppositeline] = xoppositeline
    translate!(xoppositeline, 0, 0, 20)

    yoppositeline = linesegments!(
        blockscene, yoppositelinepoints, linewidth = ax.spinewidth,
        visible = yoppositespinevisible, color = yoppositespinecolor, inspectable = false,
        linestyle = nothing
    )
    elements[:yoppositeline] = yoppositeline
    translate!(yoppositeline, 0, 0, 20)

    onany(blockscene, xaxis.tickpositions, scene.viewport) do tickpos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = ax.xaxisposition[] === :bottom ? pxheight : -pxheight
        update_gridlines!(xgridnode, Point2f(0, offset), tickpos)
    end

    onany(blockscene, yaxis.tickpositions, scene.viewport) do tickpos, area
        local pxwidth::Float32 = width(area)
        local offset::Float32 = ax.yaxisposition[] === :left ? pxwidth : -pxwidth
        update_gridlines!(ygridnode, Point2f(offset, 0), tickpos)
    end

    onany(blockscene, xaxis.minortickpositions, scene.viewport) do tickpos, area
        local pxheight::Float32 = height(scene.viewport[])
        local offset::Float32 = ax.xaxisposition[] === :bottom ? pxheight : -pxheight
        update_gridlines!(xminorgridnode, Point2f(0, offset), tickpos)
    end

    onany(blockscene, yaxis.minortickpositions, scene.viewport) do tickpos, area
        local pxwidth::Float32 = width(scene.viewport[])
        local offset::Float32 = ax.yaxisposition[] === :left ? pxwidth : -pxwidth
        update_gridlines!(yminorgridnode, Point2f(offset, 0), tickpos)
    end

    subtitlepos = lift(
        blockscene, scene.viewport, ax.titlegap, ax.titlealign, ax.xaxisposition,
        xaxis.protrusion;
        ignore_equal_values = true
    ) do a,
            titlegap, align, xaxisposition, xaxisprotrusion

        align_factor = halign2num(align, "Horizontal title align $align not supported.")
        x = a.origin[1] + align_factor * a.widths[1]

        yoffset = top(a) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0.0f0)

        return Point2f(x, yoffset)
    end

    titlealignnode = lift(blockscene, ax.titlealign; ignore_equal_values = true) do align
        (align, :bottom)
    end

    subtitlet = text!(
        blockscene, subtitlepos,
        text = ax.subtitle,
        visible = ax.subtitlevisible,
        fontsize = ax.subtitlesize,
        align = titlealignnode,
        font = ax.subtitlefont,
        color = ax.subtitlecolor,
        lineheight = ax.subtitlelineheight,
        markerspace = :data,
        inspectable = false
    )

    titlepos = lift(
        calculate_title_position, blockscene, scene.viewport, ax.titlegap, ax.subtitlegap,
        ax.titlealign, ax.xaxisposition, xaxis.protrusion, ax.subtitlelineheight, ax, subtitlet; ignore_equal_values = true
    )

    titlet = text!(
        blockscene, titlepos,
        text = ax.title,
        visible = ax.titlevisible,
        fontsize = ax.titlesize,
        align = titlealignnode,
        font = ax.titlefont,
        color = ax.titlecolor,
        lineheight = ax.titlelineheight,
        markerspace = :data,
        inspectable = false
    )
    elements[:title] = titlet

    map!(
        compute_protrusions, blockscene, ax.layoutobservables.protrusions, ax.title, ax.titlesize,
        ax.titlegap, ax.titlevisible, ax.spinewidth,
        ax.topspinevisible, ax.bottomspinevisible, ax.leftspinevisible, ax.rightspinevisible,
        xaxis.protrusion, yaxis.protrusion, ax.xaxisposition, ax.yaxisposition,
        ax.subtitle, ax.subtitlevisible, ax.subtitlesize, ax.subtitlegap,
        ax.titlelineheight, ax.subtitlelineheight, subtitlet, titlet
    )
    # trigger first protrusions with one of the observables
    notify(ax.title)

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    notify(ax.layoutobservables.suggestedbbox)

    register_events!(ax, scene)

    # these are the user defined limits
    on(blockscene, ax.limits) do _
        reset_limits!(ax)
    end

    # these are the limits that we try to target, but they can be changed for correct aspects
    on(blockscene, targetlimits) do tlims
        update_linked_limits!(block_limit_linking, ax.xaxislinks, ax.yaxislinks, tlims)
    end

    # compute limits that adhere to the limit aspect ratio whenever the targeted
    # limits or the scene size change, because both influence the displayed ratio
    onany(blockscene, scene.viewport, targetlimits) do pxa, lims
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
    # Add them last, so we skip all the internal iterations from above!
    add_input!(ax.scene.compute, :axis_limits, finallimits)
    map!(apply_transform, ax.scene.compute, [:transform_func, :axis_limits], :axis_limits_transformed)
    return ax
end

function add_axis_limits!(plot)
    scene = parent_scene(plot)
    if !haskey(scene.compute, :axis_limits)
        error("add_axis_limits! can only be used with `Axis`, not with any other Axis type or a pure scene!")
    end
    add_input!(plot.attributes, :axis_limits, scene.compute.axis_limits)
    add_input!(plot.attributes, :axis_limits_transformed, scene.compute.axis_limits_transformed)
    return
end

function mirror_ticks(tickpositions, ticksize, tickalign, viewport, side, axisposition, spinewidth)
    a = viewport
    if side === :x
        opp = axisposition === :bottom ? top(a) : bottom(a)
        sign = axisposition === :bottom ? 1 : -1
    else
        opp = axisposition === :left ? right(a) : left(a)
        sign = axisposition === :left ? 1 : -1
    end
    d = ticksize * sign
    points = Vector{Point2f}(undef, 2 * length(tickpositions))
    spineoffset = sign * (0.5 * spinewidth)
    if side === :x
        for (i, (x, _)) in enumerate(tickpositions)
            points[2i - 1] = Point2f(x, opp - d * tickalign + spineoffset)
            points[2i] = Point2f(x, opp + d - d * tickalign + spineoffset)
        end
    else
        for (i, (_, y)) in enumerate(tickpositions)
            points[2i - 1] = Point2f(opp - d * tickalign + spineoffset, y)
            points[2i] = Point2f(opp + d - d * tickalign + spineoffset, y)
        end
    end
    return points
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
        convert(Tuple{Float64, Float64}, tuple(mxlims...))
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
        convert(Tuple{Float64, Float64}, tuple(mylims...))
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

    tlims = if ax isa Axis
        BBox(xlims..., ylims...)
    elseif ax isa Axis3
        Rect3f(
            Vec3f(xlims[1], ylims[1], zlims[1]),
            Vec3f(xlims[2] - xlims[1], ylims[2] - ylims[1], zlims[2] - zlims[1]),
        )
    end
    ax.targetlimits[] = tlims
    return nothing
end

# this is so users can do limits = (left, right, bottom, top)
function convert_limit_attribute(lims::Tuple{Any, Any, Any, Any})
    return (lims[1:2], lims[3:4])
end

function convert_limit_attribute(lims::Tuple{Any, Any})
    _convert_single_limit(x) = x
    _convert_single_limit(x::Interval) = endpoints(x)
    return map(_convert_single_limit, lims)
end

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
    return nothing
end

validate_limits_for_scale(lims, scale) = all(x -> x in defined_interval(scale), lims)

is_open_or_any_parent(s::Scene) = isopen(s) || is_open_or_any_parent(s.parent)
is_open_or_any_parent(::Nothing) = false


needs_tight_limits(@nospecialize any) = false
needs_tight_limits(::Union{Heatmap, Image}) = true
function needs_tight_limits(c::Contourf)
    # we know that all values are included and the contourf is rectangular
    # otherwise here it could be in an arbitrary shape
    return c.levels[] isa Int
end
function needs_tight_limits(p::Triplot)
    return p.show_ghost_edges[]
end
function needs_tight_limits(p::Voronoiplot)
    p = p.plots[1] isa Voronoiplot ? p.plots[1] : p
    return !isempty(DelTri.get_unbounded_polygons(p[1][]))
end

function expandbboxwithfractionalmargins(bb, margins)
    newwidths = bb.widths .* (1.0f0 .+ margins)
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
    return lims
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
        is_data_space(plot) || return true
        # only use visible plots for limits
        return !to_value(get(plot, :visible, true))
    end

    # get all data limits, minus the excluded plots
    tf = la.scene.transformation.transform_func[]
    itf = inverse_transform(tf)
    if itf === nothing
        @warn "Axis transformation $tf does not define an `inverse_transform()`. This may result in a bad choice of limits due to model transformations being ignored." maxlog = 1
        bb = data_limits(la.scene, exclude)
    else
        # get limits with transform_func and model applied
        bb = boundingbox(la.scene, exclude)
        # then undo transform_func so that ticks can handle transform_func
        # without ignoring translations, scaling or rotations from model
        try
            bb = apply_transform(itf, bb)
        catch e
            # TODO: Is this necessary?
            @warn "Failed to apply inverse transform $itf to bounding box $bb. Falling back on data_limits()." exception = e
            bb = data_limits(la.scene, exclude)
        end
    end

    # if there are no bboxes remaining, `nothing` signals that no limits could be determined
    isfinite_rect(bb, dim) || return nothing

    # otherwise start with the first box
    mini, maxi = minimum(bb), maximum(bb)
    return (mini[dim], maxi[dim])
end

getxlimits(la::Axis) = getlimits(la, 1)
getylimits(la::Axis) = getlimits(la, 2)

function update_linked_limits!(block_limit_linking, xaxislinks, yaxislinks, tlims)

    thisxlims = xlimits(tlims)
    thisylims = ylimits(tlims)

    # only change linked axis if not prohibited from doing so because
    # we're currently being updated by another axis' link
    return if !block_limit_linking[]

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
    autolimits!()
    autolimits!(la::Axis)

Reset manually specified limits of `la` to an automatically determined rectangle, that depends on the data limits of all plot objects in the axis, as well as the autolimit margins for x and y axis.
The argument `la` defaults to `current_axis()`.
"""
function autolimits!(ax::Axis)
    ax.limits[] = (nothing, nothing)
    return
end
function autolimits!()
    curr_ax = current_axis()
    isnothing(curr_ax)  &&  throw(ArgumentError("Attempted to call `autolimits!` on `current_axis()`, but `current_axis()` returned nothing."))
    return autolimits!(curr_ax)
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
            error("Found invalid $(dimsym)-limits $lims for scale $(scale) which is defined on the interval $(defined_interval(scale))")
        end
        lims = expandlimits(lims, margin[1], margin[2], scale)
    end

    # if no limits have been found, use the targetlimits directly
    if isnothing(lims)
        lims = limits(ax.targetlimits[], dim)
    end
    return lims
end

xautolimits(ax::Axis = current_axis()) = autolimits(ax, 1)
yautolimits(ax::Axis = current_axis()) = autolimits(ax, 2)

"""
    linkaxes!(a::Axis, others...)

Link both x and y axes of all given `Axis` so that they stay synchronized.
"""
function linkaxes!(axes::Vector{<:Axis})
    linkxaxes!(axes)
    return linkyaxes!(axes)
end

function linkaxes!(a::Axis, others...)
    return linkaxes!([a, others...])
end

function adjustlimits!(la)
    asp = la.autolimitaspect[]
    target = la.targetlimits[]
    area = la.scene.viewport[]

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

linkaxes!(dir::Symbol, a::Axis, others...) = linkaxes!(dir, [a, others...])

function linkaxes!(dir::Symbol, axes::Vector{Axis})
    all_links = Set{Axis}(axes)
    for ax in axes
        links = dir === :x ? ax.xaxislinks : ax.yaxislinks
        for ax in links
            push!(all_links, ax)
        end
    end
    links_changed = false
    for ax in all_links
        links = dir === :x ? ax.xaxislinks : ax.yaxislinks
        for linked_ax in all_links
            if linked_ax !== ax && !(linked_ax in links)
                links_changed = true
                push!(links, linked_ax)
            end
        end
    end
    reset_limits!(first(axes))
    return
end

"""
    linkxaxes!(a::Axis, others...)

Link the x axes of all given `Axis` so that they stay synchronized.
"""
linkxaxes!(axes::Vector{Axis}) = linkaxes!(:x, axes)
linkxaxes!(a::Axis, others...) = linkaxes!(:x, [a, others...])

"""
    linkyaxes!(a::Axis, others...)

Link the y axes of all given `Axis` so that they stay synchronized.
"""
linkyaxes!(axes::Vector{Axis}) = linkaxes!(:y, axes)
linkyaxes!(a::Axis, others...) = linkaxes!(:y, [a, others...])

"""
Keeps the ticklabelspace static for a short duration and then resets it to its previous
value. If that value is Makie.automatic, the reset will trigger new
protrusions for the axis and the layout will adjust. This is so the layout doesn't
immediately readjust during interaction, which would let the whole layout jitter around.
"""
function timed_ticklabelspace_reset(
        ax::Axis, reset_timer::Ref,
        prev_xticklabelspace::Ref, prev_yticklabelspace::Ref, threshold_sec::Real
    )

    if !isnothing(reset_timer[])
        close(reset_timer[])
    else
        prev_xticklabelspace[] = ax.xticklabelspace[]
        prev_yticklabelspace[] = ax.yticklabelspace[]

        ax.xticklabelspace = Float64(ax.xaxis.attributes.actual_ticklabelspace[])
        ax.yticklabelspace = Float64(ax.yaxis.attributes.actual_ticklabelspace[])
    end

    return reset_timer[] = Timer(threshold_sec) do t
        reset_timer[] = nothing

        ax.xticklabelspace = prev_xticklabelspace[]
        ax.yticklabelspace = prev_yticklabelspace[]
    end

end


"""
    hidexdecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)

Hide decorations of the x-axis: label, ticklabels, ticks and grid. Keyword
arguments can be used to disable hiding of certain types of decorations.
"""
function hidexdecorations!(
        la::Axis = current_axis(); label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true
    )
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
    return if minorticks
        la.xminorticksvisible = false
    end
end

"""
    hideydecorations!(la::Axis; label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true)

Hide decorations of the y-axis: label, ticklabels, ticks and grid. Keyword
arguments can be used to disable hiding of certain types of decorations.
"""
function hideydecorations!(
        la::Axis = current_axis(); label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true
    )
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
    return if minorticks
        la.yminorticksvisible = false
    end
end

"""
    hidedecorations!(la::Axis; label = true, ticklabels = true, ticks = true,
                     grid = true, minorgrid = true, minorticks = true)

Hide decorations of both x and y-axis: label, ticklabels, ticks and grid.
Keyword arguments can be used to disable hiding of certain types of decorations.

See also [`hidexdecorations!`], [`hideydecorations!`], [`hidezdecorations!`]
"""
function hidedecorations!(
        la::Axis = current_axis(); label = true, ticklabels = true, ticks = true, grid = true,
        minorgrid = true, minorticks = true
    )
    hidexdecorations!(
        la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid,
        minorgrid = minorgrid, minorticks = minorticks
    )
    return hideydecorations!(
        la; label = label, ticklabels = ticklabels, ticks = ticks, grid = grid,
        minorgrid = minorgrid, minorticks = minorticks
    )
end

"""
    hidespines!(la::Axis, spines::Symbol... = (:l, :r, :b, :t)...)

Hide all specified axis spines. Hides all spines by default, otherwise choose
which sides to hide with the symbols :l (left), :r (right), :b (bottom) and
:t (top).
"""
function hidespines!(la::Axis, spines::Symbol... = (:l, :r, :b, :t)...)
    for s in spines
        if s === :l
            la.leftspinevisible = false
        elseif s === :r
            la.rightspinevisible = false
        elseif s === :b
            la.bottomspinevisible = false
        elseif s === :t
            la.topspinevisible = false
        else
            error("Invalid spine identifier $s. Valid options are :l, :r, :b and :t.")
        end
    end
    return
end
hidespines!(spines::Symbol...) = hidespines!(current_axis(), spines...)

"""
    space = tight_yticklabel_spacing!(ax::Axis)

Sets the space allocated for the yticklabels of the `Axis` to the minimum that is needed and returns that value.
"""
function tight_yticklabel_spacing!(ax::Axis = current_axis())
    space = tight_ticklabel_spacing!(ax.yaxis)
    return space
end

"""
    space = tight_xticklabel_spacing!(ax::Axis)

Sets the space allocated for the xticklabels of the `Axis` to the minimum that is needed and returns that value.
"""
function tight_xticklabel_spacing!(ax::Axis = current_axis())
    space = tight_ticklabel_spacing!(ax.xaxis)
    return space
end

"""
    tight_ticklabel_spacing!(ax::Axis)

Sets the space allocated for the xticklabels and yticklabels of the `Axis` to the minimum that is needed.
"""
function tight_ticklabel_spacing!(ax::Axis = current_axis())
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
    return
end

function Base.show(io::IO, ax::Axis)
    nplots = length(ax.scene.plots)
    return print(io, "Axis ($nplots plots)")
end

Makie.xlims!(ax::Axis, xlims::Interval) = Makie.xlims!(ax, endpoints(xlims))
Makie.ylims!(ax::Axis, ylims::Interval) = Makie.ylims!(ax, endpoints(ylims))

function Makie.xlims!(ax::Axis, xlims)
    xlims = map(x -> convert_dim_value(ax, 1, x), xlims)
    if length(xlims) != 2
        error("Invalid xlims length of $(length(xlims)), must be 2.")
    elseif xlims[1] == xlims[2] && xlims[1] !== nothing
        error("Can't set x limits to the same value $(xlims[1]).")
    elseif all(x -> x isa Real, xlims) && xlims[1] > xlims[2]
        xlims = reverse(xlims)
        ax.xreversed[] = true
    else
        ax.xreversed[] = false
    end

    mlims = convert_limit_attribute(ax.limits[])
    ax.limits.val = (xlims, mlims[2])

    # update xlims for linked axes
    for xlink in ax.xaxislinks
        xlink_mlims = convert_limit_attribute(xlink.limits[])
        xlink.limits.val = (xlims, xlink_mlims[2])
    end

    reset_limits!(ax, yauto = false)
    return nothing
end

function Makie.ylims!(ax::Axis, ylims)
    ylims = map(x -> convert_dim_value(ax, 2, x), ylims)
    if length(ylims) != 2
        error("Invalid ylims length of $(length(ylims)), must be 2.")
    elseif ylims[1] == ylims[2] && ylims[1] !== nothing
        error("Can't set y limits to the same value $(ylims[1]).")
    elseif all(x -> x isa Real, ylims) && ylims[1] > ylims[2]
        ylims = reverse(ylims)
        ax.yreversed[] = true
    else
        ax.yreversed[] = false
    end
    mlims = convert_limit_attribute(ax.limits[])
    ax.limits.val = (mlims[1], ylims)

    # update ylims for linked axes
    for ylink in ax.yaxislinks
        ylink_mlims = convert_limit_attribute(ylink.limits[])
        ylink.limits.val = (ylink_mlims[1], ylims)
    end

    reset_limits!(ax, xauto = false)
    return nothing
end

"""
    xlims!(ax, low, high)
    xlims!(ax; low = nothing, high = nothing)
    xlims!(ax, (low, high))
    xlims!(ax, low..high)

Set the x-axis limits of axis `ax` to `low` and `high` or a tuple
`xlims = (low,high)`. If the limits are ordered high-low, the axis orientation
will be reversed. If a limit is `nothing` it will be determined automatically
from the plots in the axis.
"""
Makie.xlims!(ax, low, high) = Makie.xlims!(ax, (low, high))
"""
    ylims!(ax, low, high)
    ylims!(ax; low = nothing, high = nothing)
    ylims!(ax, (low, high))
    ylims!(ax, low..high)

Set the y-axis limits of axis `ax` to `low` and `high` or a tuple
`ylims = (low,high)`. If the limits are ordered high-low, the axis orientation
will be reversed. If a limit is `nothing` it will be determined automatically
from the plots in the axis.
"""
Makie.ylims!(ax, low, high) = Makie.ylims!(ax, (low, high))
"""
    zlims!(ax, low, high)
    zlims!(ax; low = nothing, high = nothing)
    zlims!(ax, (low, high))
    zlims!(ax, low..high)

Set the z-axis limits of axis `ax` to `low` and `high` or a tuple
`zlims = (low,high)`. If the limits are ordered high-low, the axis orientation
will be reversed. If a limit is `nothing` it will be determined automatically
from the plots in the axis.
"""
Makie.zlims!(ax, low, high) = Makie.zlims!(ax, (low, high))

"""
    xlims!(low, high)
    xlims!(; low = nothing, high = nothing)

Set the x-axis limits of the current axis to `low` and `high`. If the limits
are ordered high-low, this reverses the axis orientation. A limit set to
`nothing` will be determined automatically from the plots in the axis.
"""
Makie.xlims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.xlims!(current_axis(), low, high)
"""
    ylims!(low, high)
    ylims!(; low = nothing, high = nothing)

Set the y-axis limits of the current axis to `low` and `high`. If the limits
are ordered high-low, this reverses the axis orientation. A limit set to
`nothing` will be determined automatically from the plots in the axis.
"""
Makie.ylims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.ylims!(current_axis(), low, high)
"""
    zlims!(low, high)
    zlims!(; low = nothing, high = nothing)

Set the z-axis limits of the current axis to `low` and `high`. If the limits
are ordered high-low, this reverses the axis orientation. A limit set to
`nothing` will be determined automatically from the plots in the axis.
"""
Makie.zlims!(low::Optional{<:Real}, high::Optional{<:Real}) = Makie.zlims!(current_axis(), low, high)

"""
    xlims!(ax = current_axis())

Reset the x-axis limits to be determined automatically from the plots in the
axis.
"""
Makie.xlims!(ax = current_axis(); low = nothing, high = nothing) = Makie.xlims!(ax, low, high)
"""
    ylims!(ax = current_axis())

Reset the y-axis limits to be determined automatically from the plots in the
axis.
"""
Makie.ylims!(ax = current_axis(); low = nothing, high = nothing) = Makie.ylims!(ax, low, high)
"""
    zlims!(ax = current_axis())

Reset the z-axis limits to be determined automatically from the plots in the
axis.
"""
Makie.zlims!(ax = current_axis(); low = nothing, high = nothing) = Makie.zlims!(ax, low, high)

"""
    limits!(ax::Axis, xlims, ylims)

Set the axis limits to `xlims` and `ylims`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, xlims, ylims)
    Makie.xlims!(ax, xlims)
    return Makie.ylims!(ax, ylims)
end

"""
    limits!(ax::Axis, x1, x2, y1, y2)

Set the axis x-limits to `x1` and `x2` and the y-limits to `y1` and `y2`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, x1, x2, y1, y2)
    Makie.xlims!(ax, x1, x2)
    return Makie.ylims!(ax, y1, y2)
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
    return Makie.ylims!(ax, ymin, ymax)
end

function limits!(args::Union{Nothing, Real, HyperRectangle}...)
    axis = current_axis()
    axis isa Nothing && error("There is no currently active axis!")
    return limits!(axis, args...)
end

Makie.transform_func(ax::Axis) = Makie.transform_func(ax.scene)

# these functions pick limits for different x and y scales, so that
# we don't pick values that are invalid, such as 0 for log etc.
function defaultlimits(userlimits::Tuple{Real, Real, Real, Real}, xscale, yscale)
    return BBox(Float64.(userlimits)...)
end

defaultlimits(l::Tuple{Any, Any, Any, Any}, xscale, yscale) = defaultlimits(((l[1], l[2]), (l[3], l[4])), xscale, yscale)

function defaultlimits(userlimits::Tuple{Any, Any}, xscale, yscale)
    xl = Float64.(defaultlimits(userlimits[1], xscale))
    yl = Float64.(defaultlimits(userlimits[2], yscale))
    return BBox(xl..., yl...)
end

defaultlimits(limits::Nothing, scale) = defaultlimits(scale)
defaultlimits(limits::Tuple{Real, Real}, scale) = limits
defaultlimits(limits::Interval, scale) = endpoints(limits)
defaultlimits(limits::Tuple{Real, Nothing}, scale) = (limits[1], defaultlimits(scale)[2])
defaultlimits(limits::Tuple{Nothing, Real}, scale) = (defaultlimits(scale)[1], limits[2])
defaultlimits(limits::Tuple{Nothing, Nothing}, scale) = defaultlimits(scale)

defaultlimits(scale::ReversibleScale) = inverse_transform(scale).(scale.limits)
defaultlimits(scale::LogFunctions) = let inv_scale = inverse_transform(scale)
    (inv_scale(0.0), inv_scale(3.0))
end
defaultlimits(::typeof(identity)) = (0.0, 10.0)
defaultlimits(::typeof(sqrt)) = (0.0, 100.0)
defaultlimits(::typeof(Makie.logit)) = (0.01, 0.99)

defined_interval(scale::ReversibleScale) = scale.interval
defined_interval(::typeof(identity)) = OpenInterval(-Inf, Inf)
defined_interval(::LogFunctions) = OpenInterval(0.0, Inf)
defined_interval(::typeof(sqrt)) = Interval{:closed, :open}(0, Inf)
defined_interval(::typeof(Makie.logit)) = OpenInterval(0.0, 1.0)


function attribute_examples(::Type{Axis})
    return Dict(
        :xticks => [
            Example(
                code = """
                fig = Figure()
                Axis(fig[1, 1], xticks = 1:10)
                Axis(fig[2, 1], xticks = (1:2:9, ["A", "B", "C", "D", "E"]))
                Axis(fig[3, 1], xticks = WilkinsonTicks(5))
                fig
                """
            ),
        ],
        :yticks => [
            Example(
                code = """
                fig = Figure()
                Axis(fig[1, 1], yticks = 1:10)
                Axis(fig[1, 2], yticks = (1:2:9, ["A", "B", "C", "D", "E"]))
                Axis(fig[1, 3], yticks = WilkinsonTicks(5))
                fig
                """
            ),
        ],
        :aspect => [
            Example(
                code = """
                using FileIO

                f = Figure()

                ax1 = Axis(f[1, 1], aspect = nothing, title = "nothing")
                ax2 = Axis(f[1, 2], aspect = DataAspect(), title = "DataAspect()")
                ax3 = Axis(f[2, 1], aspect = AxisAspect(1), title = "AxisAspect(1)")
                ax4 = Axis(f[2, 2], aspect = AxisAspect(2), title = "AxisAspect(2)")

                img = rotr90(load(assetpath("cow.png")))
                for ax in [ax1, ax2, ax3, ax4]
                    image!(ax, img)
                end

                f
                """
            ),
        ],
        :autolimitaspect => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], autolimitaspect = nothing)
                ax2 = Axis(f[1, 2], autolimitaspect = 1)

                for ax in [ax1, ax2]
                    lines!(ax, 0..10, sin)
                end

                f
                """
            ),
        ],
        :backgroundcolor => [
            Example(
                code = """
                    f = Figure()

                    ax1 = Axis(f[1, 1])
                    ax2 = Axis(f[1, 2], backgroundcolor = :gray80)

                    f
                """
            ),
        ],
        :xautolimitmargin => [
            Example(
                code = """
                    f = Figure()

                    data = 0:1

                    ax1 = Axis(f[1, 1], xautolimitmargin = (0, 0), title = "xautolimitmargin = (0, 0)")
                    ax2 = Axis(f[2, 1], xautolimitmargin = (0.05, 0.05), title = "xautolimitmargin = (0.05, 0.05)")
                    ax3 = Axis(f[3, 1], xautolimitmargin = (0, 0.2), title = "xautolimitmargin = (0, 0.2)")

                    for ax in [ax1, ax2, ax3]
                        lines!(ax, data)
                    end

                    f
                """
            ),
        ],
        :yautolimitmargin => [
            Example(
                code = """
                    f = Figure()

                    data = 0:1

                    ax1 = Axis(f[1, 1], yautolimitmargin = (0, 0), title = "yautolimitmargin = (0, 0)")
                    ax2 = Axis(f[1, 2], yautolimitmargin = (0.05, 0.05), title = "yautolimitmargin = (0.05, 0.05)")
                    ax3 = Axis(f[1, 3], yautolimitmargin = (0, 0.2), title = "yautolimitmargin = (0, 0.2)")

                    for ax in [ax1, ax2, ax3]
                        lines!(ax, data)
                    end

                    f
                """
            ),
        ],
        :xticklabelpad => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xticklabelpad = 0, title = "xticklabelpad = 0")
                    Axis(f[1, 2], xticklabelpad = 5, title = "xticklabelpad = 5")
                    Axis(f[1, 3], xticklabelpad = 15, title = "xticklabelpad = 15")

                    f
                """
            ),
        ],
        :yticklabelpad => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], yticklabelpad = 0, title = "yticklabelpad = 0")
                    Axis(f[2, 1], yticklabelpad = 5, title = "yticklabelpad = 5")
                    Axis(f[3, 1], yticklabelpad = 15, title = "yticklabelpad = 15")

                    f
                """
            ),
        ],
        :xticklabelspace => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xlabel = "X Label", xticklabelspace = 0.0, title = "xticklabelspace = 0.0")
                    Axis(f[1, 2], xlabel = "X Label", xticklabelspace = 30.0, title = "xticklabelspace = 30.0")
                    Axis(f[1, 3], xlabel = "X Label", xticklabelspace = Makie.automatic, title = "xticklabelspace = automatic")

                    f
                """
            ),
        ],
        :yticklabelspace => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], ylabel = "Y Label", yticklabelspace = 0.0, title = "yticklabelspace = 0.0")
                    Axis(f[2, 1], ylabel = "Y Label", yticklabelspace = 30.0, title = "yticklabelspace = 30.0")
                    Axis(f[3, 1], ylabel = "Y Label", yticklabelspace = Makie.automatic, title = "yticklabelspace = automatic")

                    f
                """
            ),
        ],
        :xlabelpadding => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], xlabel = "X Label", xlabelpadding = 0, title = "xlabelpadding = 0")
                    Axis(f[1, 2], xlabel = "X Label", xlabelpadding = 5, title = "xlabelpadding = 5")
                    Axis(f[1, 3], xlabel = "X Label", xlabelpadding = 10, title = "xlabelpadding = 10")

                    f
                """
            ),
        ],
        :ylabelpadding => [
            Example(
                code = """
                    f = Figure()

                    Axis(f[1, 1], ylabel = "Y Label", ylabelpadding = 0, title = "ylabelpadding = 0")
                    Axis(f[2, 1], ylabel = "Y Label", ylabelpadding = 5, title = "ylabelpadding = 5")
                    Axis(f[3, 1], ylabel = "Y Label", ylabelpadding = 10, title = "ylabelpadding = 10")

                    f
                """
            ),
        ],
        :title => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], title = "Title")
                Axis(f[2, 1], title = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], title = rich(
                    "Rich text title",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :titlealign => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], titlealign = :left, title = "Left aligned title")
                Axis(f[2, 1], titlealign = :center, title = "Center aligned title")
                Axis(f[3, 1], titlealign = :right, title = "Right aligned title")

                f
                """
            ),
        ],
        :subtitle => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], title = "Title", subtitle = "Subtitle")
                Axis(f[2, 1], title = "Title", subtitle = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], title = "Title", subtitle = rich(
                    "Rich text subtitle",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :xlabel => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xlabel = "X Label")
                Axis(f[2, 1], xlabel = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], xlabel = rich(
                    "X Label",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :ylabel => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], ylabel = "Y Label")
                Axis(f[2, 1], ylabel = L"\\sum_i{x_i \\times y_i}")
                Axis(f[3, 1], ylabel = rich(
                    "Y Label",
                    subscript(" with subscript", color = :slategray)
                ))

                f
                """
            ),
        ],
        :xtrimspine => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], xtrimspine = false)
                ax2 = Axis(f[2, 1], xtrimspine = true)
                ax3 = Axis(f[3, 1], xtrimspine = (true, false))
                ax4 = Axis(f[4, 1], xtrimspine = (false, true))

                for ax in [ax1, ax2, ax3, ax4]
                    ax.xgridvisible = false
                    ax.ygridvisible = false
                    ax.rightspinevisible = false
                    ax.topspinevisible = false
                    xlims!(ax, 0.5, 5.5)
                end

                f
                """
            ),
        ],
        :ytrimspine => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], ytrimspine = false)
                ax2 = Axis(f[1, 2], ytrimspine = true)
                ax3 = Axis(f[1, 3], ytrimspine = (true, false))
                ax4 = Axis(f[1, 4], ytrimspine = (false, true))

                for ax in [ax1, ax2, ax3, ax4]
                    ax.xgridvisible = false
                    ax.ygridvisible = false
                    ax.rightspinevisible = false
                    ax.topspinevisible = false
                    ylims!(ax, 0.5, 5.5)
                end

                f
                """
            ),
        ],
        :xaxisposition => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xaxisposition = :bottom)
                Axis(f[1, 2], xaxisposition = :top)

                f
                """
            ),
        ],
        :yaxisposition => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], yaxisposition = :left)
                Axis(f[2, 1], yaxisposition = :right)

                f
                """
            ),
        ],
        :limits => [
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1], limits = (nothing, nothing), title = "(nothing, nothing)")
                ax2 = Axis(f[1, 2], limits = (0, 4pi, -1, 1), title = "(0, 4pi, -1, 1)")
                ax3 = Axis(f[2, 1], limits = ((0, 4pi), nothing), title = "((0, 4pi), nothing)")
                ax4 = Axis(f[2, 2], limits = (nothing, 4pi, nothing, 1), title = "(nothing, 4pi, nothing, 1)")

                for ax in [ax1, ax2, ax3, ax4]
                    lines!(ax, 0..4pi, sin)
                end

                f
                """
            ),
        ],
        :yscale => [
            Example(
                code = """
                f = Figure()

                for (i, scale) in enumerate([identity, log10, log2, log, sqrt, Makie.logit])
                    row, col = fldmod1(i, 3)
                    Axis(f[row, col], yscale = scale, title = string(scale),
                        yminorticksvisible = true, yminorgridvisible = true,
                        yminorticks = IntervalsBetween(5))

                    lines!(range(0.01, 0.99, length = 200))
                end

                f
                """
            ),
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1],
                    yscale = Makie.pseudolog10,
                    title = "Pseudolog scale",
                    yticks = [-100, -10, -1, 0, 1, 10, 100]
                )

                ax2 = Axis(f[2, 1],
                    yscale = Makie.Symlog10(10.0),
                    title = "Symlog10 with linear scaling between -10 and 10",
                    yticks = [-100, -10, 0, 10, 100]
                )

                ax3 = Axis(f[1, 1],
                    yscale = Makie.pseudolog10,
                    title = "Pseudolog scale with LogTicks",
                    yticks = LogTicks(-2:2)
                )

                for ax in [ax1, ax2, ax3]
                    lines!(ax, -100:0.1:100)
                end

                f
                """
            ),
        ],
        :xscale => [
            Example(
                code = """
                f = Figure()

                for (i, scale) in enumerate([identity, log10, log2, log, sqrt, Makie.logit])
                    row, col = fldmod1(i, 2)
                    Axis(f[row, col], xscale = scale, title = string(scale),
                        xminorticksvisible = true, xminorgridvisible = true,
                        xminorticks = IntervalsBetween(5))

                    lines!(range(0.01, 0.99, length = 200), 1:200)
                end

                f
                """
            ),
            Example(
                code = """
                f = Figure()

                ax1 = Axis(f[1, 1],
                    xscale = Makie.pseudolog10,
                    title = "Pseudolog scale",
                    xticks = [-100, -10, -1, 0, 1, 10, 100]
                )

                ax2 = Axis(f[1, 2],
                    xscale = Makie.Symlog10(10.0),
                    title = "Symlog10 with linear scaling\nbetween -10 and 10",
                    xticks = [-100, -10, 0, 10, 100]
                )

                for ax in [ax1, ax2]
                    lines!(ax, -100:0.1:100, -100:0.1:100)
                end

                f
                """
            ),
        ],
        :xtickformat => [
            Example(
                code = """
                f = Figure(figure_padding = 50)

                Axis(f[1, 1], xtickformat = values -> ["\$(value)kg" for value in values])
                Axis(f[2, 1], xtickformat = "{:.2f}ms")
                Axis(f[3, 1], xtickformat = values -> [L"\\sqrt{%\$(value^2)}" for value in values])
                Axis(f[4, 1], xtickformat = values -> [rich("\$value", superscript("XY", color = :red))
                                                       for value in values])

                f
                """
            ),
        ],
        :ytickformat => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], ytickformat = values -> ["\$(value)kg" for value in values])
                Axis(f[1, 2], ytickformat = "{:.2f}ms")
                Axis(f[1, 3], ytickformat = values -> [L"\\sqrt{%\$(value^2)}" for value in values])
                Axis(f[1, 4], ytickformat = values -> [rich("\$value", superscript("XY", color = :red))
                                                       for value in values])

                f
                """
            ),
        ],
        :xticksmirrored => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], xticksmirrored = false, xminorticksvisible = true)
                Axis(f[1, 2], xticksmirrored = true, xminorticksvisible = true)

                f
                """
            ),
        ],
        :yticksmirrored => [
            Example(
                code = """
                f = Figure()

                Axis(f[1, 1], yticksmirrored = false, yminorticksvisible = true)
                Axis(f[2, 1], yticksmirrored = true, yminorticksvisible = true)

                f
                """
            ),
        ],
        :xminorticks => [
            Example(
                code = """
                f = Figure()

                kwargs = (; xminorticksvisible = true, xminorgridvisible = true)
                Axis(f[1, 1]; xminorticks = IntervalsBetween(2), kwargs...)
                Axis(f[2, 1]; xminorticks = IntervalsBetween(5), kwargs...)
                Axis(f[3, 1]; xminorticks = [1, 2, 3, 4], kwargs...)

                f
                """
            ),
        ],
        :yminorticks => [
            Example(
                code = """
                f = Figure()

                kwargs = (; yminorticksvisible = true, yminorgridvisible = true)
                Axis(f[1, 1]; yminorticks = IntervalsBetween(2), kwargs...)
                Axis(f[1, 2]; yminorticks = IntervalsBetween(5), kwargs...)
                Axis(f[1, 3]; yminorticks = [1, 2, 3, 4], kwargs...)

                f
                """
            ),
        ],
    )
end

function axis_bounds_with_decoration(axis::Axis)
    # Filter out the zoomrect + background plot
    lims = Makie.data_limits(axis.blockscene.plots, p -> p isa Mesh || p isa Poly)
    return Makie.parent_transform(axis.blockscene) * lims
end

"""
    colorbuffer(ax::Axis; include_decorations=true, colorbuffer_kws...)

Gets the colorbuffer of the `Axis` in `JuliaNative` image format.
If `include_decorations=false`, only the inside of the axis is fetched.
"""
function colorbuffer(ax::Axis; include_decorations = true, update = true, colorbuffer_kws...)
    if update
        update_state_before_display!(ax)
    end
    root_scene = root(ax.scene)
    img = colorbuffer(root_scene; update = false, colorbuffer_kws...)
    scale_factor = first(size(img) ./ reverse(size(root_scene)))
    bb = if include_decorations
        bb = axis_bounds_with_decoration(ax)
        Rect2{Int}(round.(Int, minimum(bb) .* scale_factor) .+ 1, round.(Int, widths(bb) .* scale_factor))
    else
        vp = viewport(ax.scene)[]
        mini, wh = minimum(vp), widths(vp)
        Rect2(round.(Int, mini .* scale_factor), round.(Int, wh .* scale_factor))
    end
    return get_sub_picture(img, JuliaNative, bb)
end
