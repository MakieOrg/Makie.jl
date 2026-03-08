function gridline_points(offset::Point2f, tickpositions::Vector{Point2f})
    result = Point2f[]
    for gridstart in tickpositions
        opposite_tickpos = gridstart .+ offset
        push!(result, gridstart, opposite_tickpos)
    end
    return result
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

function calculate_axis_projection_matrix(scene::Scene, tf, lims, xrev::Bool, yrev::Bool)
    nearclip = -10_000f0
    farclip = 10_000f0

    # we are computing transformed camera position, so this isn't space dependent
    tlims = Makie.apply_transform(tf, lims)

    update_limits!(scene.float32convert, tlims) # update float32 scaling
    lims32 = f32_convert(scene.float32convert, tlims)  # get scaled limits
    left, bottom = minimum(lims32)
    right, top = maximum(lims32)
    leftright = xrev ? (right, left) : (left, right)
    bottomtop = yrev ? (top, bottom) : (bottom, top)

    return Makie.orthographicprojection(
        Float32,
        leftright...,
        bottomtop..., nearclip, farclip
    )
end

function calculate_title_position(area, titlegap, align, xaxisposition, xaxisprotrusion, subtitle_height)
    local x::Float32 = if align === :center
        area.origin[1] + area.widths[1] / 2
    elseif align === :left
        area.origin[1]
    elseif align === :right
        area.origin[1] + area.widths[1]
    else
        error("Title align $align not supported.")
    end

    subtitlespace::Float32 = subtitle_height

    local yoffset::Float32 = top(area) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0.0f0) +
        subtitlespace

    return Point2f(x, yoffset)
end

function compute_protrusions(
        titleheight, subtitleheight,
        xaxisposition, xaxisprotrusion,
        yaxisposition, yaxisprotrusion,
    )

    left::Float32 = ifelse(yaxisposition === :left, yaxisprotrusion, 0.0f0)
    right::Float32 = ifelse(yaxisposition === :right, yaxisprotrusion, 0.0f0)
    bottom::Float32 = ifelse(xaxisposition === :bottom, xaxisprotrusion, 0.0f0)
    top::Float32 = ifelse(xaxisposition === :top, xaxisprotrusion, 0.0f0)

    top += titleheight + subtitleheight

    return GridLayoutBase.RectSides{Float32}(left, right, bottom, top)
end

function initialize_block!(ax::Axis; palette = nothing)
    blockscene = ax.blockscene
    elements = Dict{Symbol, Any}()
    ax.elements = elements

    scene = Scene(blockscene, viewport = Rect2i(0, 0, 0, 0), visible = false)
    add_input!(ax.attributes, :viewport, scene.viewport)
    # Hide to block updates, will be unhidden! in constructor who calls this!
    @assert !scene.visible[]
    ax.scene = scene
    # transfer conversions from axis to scene if there are any
    # or the other way around
    connect_conversions!(scene.conversions, ax)

    setfield!(scene, :float32convert, Float32Convert())

    initialize_limit_computations!(ax)

    add_input!(ax.attributes, :computedbbox, ax.layoutobservables.computedbbox)
    map!(calculate_scenearea, ax.attributes, [:computedbbox, :finallimits, :aspect], :scenearea)
    connect!(scene.viewport, ax.scenearea)

    if !isnothing(palette)
        # Backwards compatibility for when palette was part of axis!
        palette_attr = palette isa Attributes ? palette : Attributes(palette)
        ax.scene.theme.palette = palette_attr
    end

    # TODO: replace with mesh, however, CairoMakie needs a poly path for this signature
    # so it doesn't rasterize the scene
    background = poly!(
        blockscene, ax.viewport; color = ax.backgroundcolor, inspectable = false,
        shading = NoShading, strokecolor = :transparent
    )
    translate!(background, 0, 0, -100)
    elements[:background] = background

    map!(ax.attributes, [:xaxisposition, :viewport], :xaxis_endpoints) do xaxisposition, area
        if xaxisposition === :bottom
            return bottomline(Rect2f(area))
        elseif xaxisposition === :top
            return topline(Rect2f(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    map!(ax.attributes, [:yaxisposition, :viewport], :yaxis_endpoints) do yaxisposition, area
        if yaxisposition === :left
            return leftline(Rect2f(area))
        elseif yaxisposition === :right
            return rightline(Rect2f(area))
        else
            error("Invalid yaxisposition $yaxisposition")
        end
    end

    map!(x -> x === :top, ax.attributes, :xaxisposition, :xaxis_flipped)
    map!(x -> x === :right, ax.attributes, :yaxisposition, :yaxis_flipped)

    map!(
        (flip, bv, tv) -> ifelse(flip, (tv, bv), (bv, tv)),
        ax.attributes,
        [:xaxis_flipped, :bottomspinevisible, :topspinevisible],
        [:xspinevisible, :xoppositespinevisible]
    )
    map!(
        (flip, lv, rv) -> ifelse(flip, (rv, lv), (lv, rv)),
        ax.attributes,
        [:yaxis_flipped, :leftspinevisible, :rightspinevisible],
        [:yspinevisible, :yoppositespinevisible]
    )
    map!(
        (flip, bc, tc) -> ifelse(flip, (tc, bc), (bc, tc)),
        ax.attributes,
        [:xaxis_flipped, :bottomspinecolor, :topspinecolor],
        [:xspinecolor, :xoppositespinecolor]
    )
    map!(
        (flip, lc, rc) -> ifelse(flip, (rc, lc), (lc, rc)),
        ax.attributes,
        [:yaxis_flipped, :leftspinecolor, :rightspinecolor],
        [:yspinecolor, :yoppositespinecolor]
    )

    map!(xlimits, ax.attributes, :finallimits, :finalxlimits)
    map!(ylimits, ax.attributes, :finallimits, :finalylimits)

    xaxis = LineAxis(
        blockscene, ComputePipeline.ComputeGraphView(ax.attributes, :xaxis),
        endpoints = ax.xaxis_endpoints, limits = ax.finalxlimits,
        flipped = ax.xaxis_flipped, ticklabelrotation = ax.xticklabelrotation,
        ticklabelalign = ax.xticklabelalign, labelsize = ax.xlabelsize,
        labelpadding = ax.xlabelpadding, ticklabelpad = ax.xticklabelpad, labelvisible = ax.xlabelvisible,
        label = ax.xlabel, labelfont = ax.xlabelfont, labelrotation = ax.xlabelrotation, ticklabelfont = ax.xticklabelfont, ticklabelcolor = ax.xticklabelcolor, labelcolor = ax.xlabelcolor, tickalign = ax.xtickalign,
        ticklabelspace = ax.xticklabelspace, dim_convert = ax.dim1_conversion, ticks = ax.xticks, tickformat = ax.xtickformat, ticklabelsvisible = ax.xticklabelsvisible,
        ticksvisible = ax.xticksvisible, spinevisible = ax.xspinevisible, spinecolor = ax.xspinecolor, spinewidth = ax.spinewidth,
        ticklabelsize = ax.xticklabelsize, trimspine = ax.xtrimspine, ticksize = ax.xticksize,
        reversed = ax.xreversed, tickwidth = ax.xtickwidth, tickcolor = ax.xtickcolor,
        minorticksvisible = ax.xminorticksvisible, minortickalign = ax.xminortickalign, minorticksize = ax.xminorticksize, minortickwidth = ax.xminortickwidth, minortickcolor = ax.xminortickcolor, minorticks = ax.xminorticks, scale = ax.xscale,
        minorticksused = ax.xminorgridvisible,
        unit_in_ticklabel = ax.x_unit_in_ticklabel, unit_in_label = ax.x_unit_in_label,
        suffix_formatter = ax.xlabel_suffix, use_short_unit = ax.use_short_x_units
    )

    ax.xaxis = xaxis

    yaxis = LineAxis(
        blockscene, ComputePipeline.ComputeGraphView(ax.attributes, :yaxis),
        endpoints = ax.yaxis_endpoints, limits = ax.finalylimits,
        flipped = ax.yaxis_flipped, ticklabelrotation = ax.yticklabelrotation,
        ticklabelalign = ax.yticklabelalign, labelsize = ax.ylabelsize,
        labelpadding = ax.ylabelpadding, ticklabelpad = ax.yticklabelpad, labelvisible = ax.ylabelvisible,
        label = ax.ylabel, labelfont = ax.ylabelfont, labelrotation = ax.ylabelrotation, ticklabelfont = ax.yticklabelfont, ticklabelcolor = ax.yticklabelcolor, labelcolor = ax.ylabelcolor, tickalign = ax.ytickalign,
        ticklabelspace = ax.yticklabelspace, dim_convert = ax.dim2_conversion, ticks = ax.yticks, tickformat = ax.ytickformat, ticklabelsvisible = ax.yticklabelsvisible,
        ticksvisible = ax.yticksvisible, spinevisible = ax.yspinevisible, spinecolor = ax.yspinecolor, spinewidth = ax.spinewidth,
        trimspine = ax.ytrimspine, ticklabelsize = ax.yticklabelsize, ticksize = ax.yticksize, flip_vertical_label = ax.flip_ylabel, reversed = ax.yreversed, tickwidth = ax.ytickwidth,
        tickcolor = ax.ytickcolor,
        minorticksvisible = ax.yminorticksvisible, minortickalign = ax.yminortickalign, minorticksize = ax.yminorticksize, minortickwidth = ax.yminortickwidth, minortickcolor = ax.yminortickcolor, minorticks = ax.yminorticks, scale = ax.yscale,
        minorticksused = ax.yminorgridvisible,
        unit_in_ticklabel = ax.y_unit_in_ticklabel, unit_in_label = ax.y_unit_in_label,
        suffix_formatter = ax.ylabel_suffix, use_short_unit = ax.use_short_y_units
    )

    ax.yaxis = yaxis

    map!(
        ax.attributes,
        [:viewport, :spinewidth, :xaxisposition],
        :xoppositelinepoints
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

    map!(
        ax.attributes,
        [:viewport, :spinewidth, :yaxisposition],
        :yoppositelinepoints
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

    map!(
        mirror_xticks, ax.attributes,
        [(:xaxis, :tickpositions), :xticksize, :xtickalign, :viewport, :xaxisposition, :spinewidth],
        :xticksmirrored_points
    )
    map!((a, b) -> a && b, ax.attributes, [:xticksmirrored, :xticksvisible], :mirroredxticksvisible)
    xticksmirrored_lines = linesegments!(
        blockscene, ax.xticksmirrored_points, visible = ax.mirroredxticksvisible,
        linewidth = ax.xtickwidth, color = ax.xtickcolor
    )
    translate!(xticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_yticks, ax.attributes,
        [(:yaxis, :tickpositions), :yticksize, :ytickalign, :viewport, :yaxisposition, :spinewidth],
        :yticksmirrored_points
    )
    map!((a, b) -> a && b, ax.attributes, [:yticksmirrored, :yticksvisible], :mirroredyticksvisible)
    yticksmirrored_lines = linesegments!(
        blockscene, ax.yticksmirrored_points, visible = ax.mirroredyticksvisible,
        linewidth = ax.ytickwidth, color = ax.ytickcolor
    )
    translate!(yticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_xticks, ax.attributes,
        [(:xaxis, :minortickpositions), :xminorticksize, :xminortickalign, :viewport, :xaxisposition, :spinewidth],
        :xminorticksmirrored
    )
    map!((a, b) -> a && b, ax.attributes, [:xticksmirrored, :xminorticksvisible], :mirroredxminorticksvisible)
    xminorticksmirrored_lines = linesegments!(
        blockscene, ax.xminorticksmirrored, visible = ax.mirroredxminorticksvisible,
        linewidth = ax.xminortickwidth, color = ax.xminortickcolor
    )
    translate!(xminorticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_yticks, ax.attributes,
        [(:yaxis, :minortickpositions), :yminorticksize, :yminortickalign, :viewport, :yaxisposition, :spinewidth],
        :yminorticksmirrored
    )
    map!((a, b) -> a && b, ax.attributes, [:yticksmirrored, :yminorticksvisible], :mirroredyminorticksvisible)
    yminorticksmirrored_lines = linesegments!(
        blockscene, ax.yminorticksmirrored, visible = ax.mirroredyminorticksvisible,
        linewidth = ax.yminortickwidth, color = ax.yminortickcolor
    )
    translate!(yminorticksmirrored_lines, 0, 0, 10)

    xoppositeline = linesegments!(
        blockscene, ax.xoppositelinepoints, linewidth = ax.spinewidth,
        visible = ax.xoppositespinevisible, color = ax.xoppositespinecolor,
        inspectable = false,
        linestyle = nothing
    )
    elements[:xoppositeline] = xoppositeline
    translate!(xoppositeline, 0, 0, 20)

    yoppositeline = linesegments!(
        blockscene, ax.yoppositelinepoints, linewidth = ax.spinewidth,
        visible = ax.yoppositespinevisible, color = ax.yoppositespinecolor,
        inspectable = false,
        linestyle = nothing
    )
    elements[:yoppositeline] = yoppositeline
    translate!(yoppositeline, 0, 0, 20)

    map!(
        ax.attributes,
        [(:xaxis, :tickpositions), :xaxisposition, :viewport],
        :xgrid_points
    ) do tickpos, axispos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = axispos === :bottom ? pxheight : -pxheight
        return gridline_points(Point2f(0, offset), tickpos)
    end

    map!(
        ax.attributes,
        [(:yaxis, :tickpositions), :yaxisposition, :viewport],
        :ygrid_points
    ) do tickpos, axispos, area
        local pxwidth::Float32 = width(area)
        local offset::Float32 = axispos === :left ? pxwidth : -pxwidth
        return gridline_points(Point2f(offset, 0), tickpos)
    end

    map!(
        ax.attributes,
        [(:xaxis, :minortickpositions), :xaxisposition, :viewport],
        :xminorgrid_points
    ) do tickpos, axispos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = axispos === :bottom ? pxheight : -pxheight
        return gridline_points(Point2f(0, offset), tickpos)
    end

    map!(
        ax.attributes,
        [(:yaxis, :minortickpositions), :yaxisposition, :viewport],
        :yminorgrid_points
    ) do tickpos, axispos, area
        local pxwidth::Float32 = width(area)
        local offset::Float32 = axispos === :left ? pxwidth : -pxwidth
        return gridline_points(Point2f(offset, 0), tickpos)
    end

    xgridlines = linesegments!(
        blockscene, ax.xgrid_points, linewidth = ax.xgridwidth, visible = ax.xgridvisible,
        color = ax.xgridcolor, linestyle = ax.xgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xgridlines, 0, 0, -10)
    elements[:xgridlines] = xgridlines

    xminorgridlines = linesegments!(
        blockscene, ax.xminorgrid_points, linewidth = ax.xminorgridwidth, visible = ax.xminorgridvisible,
        color = ax.xminorgridcolor, linestyle = ax.xminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(xminorgridlines, 0, 0, -10)
    elements[:xminorgridlines] = xminorgridlines

    ygridlines = linesegments!(
        blockscene, ax.ygrid_points, linewidth = ax.ygridwidth, visible = ax.ygridvisible,
        color = ax.ygridcolor, linestyle = ax.ygridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(ygridlines, 0, 0, -10)
    elements[:ygridlines] = ygridlines

    yminorgridlines = linesegments!(
        blockscene, ax.yminorgrid_points, linewidth = ax.yminorgridwidth, visible = ax.yminorgridvisible,
        color = ax.yminorgridcolor, linestyle = ax.yminorgridstyle, inspectable = false
    )
    # put gridlines behind the zero plane so they don't overlay plots
    translate!(yminorgridlines, 0, 0, -10)
    elements[:yminorgridlines] = yminorgridlines

    map!(
        ax.attributes,
        [:viewport, :titlegap, :titlealign, :xaxisposition, (:xaxis, :protrusion)],
        :subtitlepos
    ) do a, titlegap, align, xaxisposition, xaxisprotrusion

        align_factor = halign2num(align, "Horizontal title align $align not supported.")
        x = a.origin[1] + align_factor * a.widths[1]

        yoffset = top(a) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0.0f0)

        return Point2f(x, yoffset)
    end

    map!(align -> (align, :bottom), ax.attributes, :titlealign, :titlealign_tuple)

    subtitlet = text!(
        blockscene,
        ax.subtitlepos,
        text = ax.subtitle,
        visible = ax.subtitlevisible,
        fontsize = ax.subtitlesize,
        align = ax.titlealign_tuple,
        font = ax.subtitlefont,
        color = ax.subtitlecolor,
        lineheight = ax.subtitlelineheight,
        markerspace = :data,
        inspectable = false
    )

    subtitle_bbox = register_raw_string_boundingboxes!(subtitlet)
    map!(
        ax.attributes, [subtitle_bbox, :subtitlevisible, :subtitlegap], :subtitle_height
    ) do bboxes, visible, gap
        bb = reduce(update_boundingbox, bboxes, init = Rect3f())
        height = widths(bb)[2]
        return isfinite(height) && visible ? Float32(height + gap) : 0.0f0
    end

    map!(
        calculate_title_position, ax.attributes,
        [:viewport, :titlegap, :titlealign, :xaxisposition, (:xaxis, :protrusion), :subtitle_height],
        :titlepos
    )

    titlet = text!(
        blockscene, ax.titlepos,
        text = ax.title,
        visible = ax.titlevisible,
        fontsize = ax.titlesize,
        align = ax.titlealign_tuple,
        font = ax.titlefont,
        color = ax.titlecolor,
        lineheight = ax.titlelineheight,
        markerspace = :data,
        inspectable = false
    )
    elements[:title] = titlet

    title_bbox = register_raw_string_boundingboxes!(titlet)
    map!(
        ax.attributes, [title_bbox, :titlevisible, :titlegap], :title_height
    ) do bboxes, visible, gap
        bb = reduce(update_boundingbox, bboxes, init = Rect3f())
        height = widths(bb)[2]
        return isfinite(height) && visible ? Float32(height + gap) : 0.0f0
    end

    map!(
        compute_protrusions, ax.attributes,
        [
            :title_height, :subtitle_height,
            :xaxisposition, (:xaxis, :protrusion),
            :yaxisposition, (:yaxis, :protrusion),
        ],
        :layout_protrusions
    )

    connect!(ax.layoutobservables.protrusions, ax.layout_protrusions)

    # trigger bboxnode so the axis layouts itself even if not connected to a
    # layout
    notify(ax.layoutobservables.suggestedbbox)

    register_events!(ax, scene)

    # # Needed to fully initialize layouting for some reason...
    # notify(ComputePipeline.get_observable!(ax.xlabelpadding))
    # notify(ComputePipeline.get_observable!(ax.ylabelpadding))

    # Add them last, so we skip all the internal iterations from above!
    add_input!(ax.scene.compute, :axis_limits, ax.attributes.finallimits)
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

################################################################################
# Limits

function add_attributes!(T::Type{<:Axis}, graph, attributes)
    limits = pop!(attributes, :limits)
    add_input!((k, v) -> convert_limit_attribute(v), graph, :limits, limits)
    ComputePipeline.set_type!(graph.limits, Any)
    _add_attributes!(T, graph, attributes)
    return
end

make_limit_update_explit(x::ComputePipeline.ExplicitUpdate) = x
make_limit_update_explit(x::Nothing) = ComputePipeline.ExplicitUpdate(x, :force)
make_limit_update_explit(x::Tuple{Nothing, <:Any}) = ComputePipeline.ExplicitUpdate(x, :force)
make_limit_update_explit(x::Tuple{<:Any, Nothing}) = ComputePipeline.ExplicitUpdate(x, :force)
make_limit_update_explit(x::Tuple{Nothing, Nothing}) = ComputePipeline.ExplicitUpdate(x, :force)
make_limit_update_explit(x::Tuple) = ComputePipeline.ExplicitUpdate(x, :auto)

function initialize_limit_computations!(ax)
    attr = ax.attributes

    # Propagate same value updates, e.g. (nothing, nothing) -> (nothing, nothing)
    attr.inputs[:limits].force_update = true

    # For plot boundingboxes in (x/y)limits -> local(x/y)limits we need the
    # transform_func observable of plots to be up to date. To guarantee that we
    # update it here, in the computation, so that the Observable will be update
    # before any computation depending on transform_func runs
    # (This is important for ticks which need finallimits to be up to date with
    # the user set (x/y)scale. This requires the path from limits -> finallimits
    # to be purely ComputeGraph computations.)
    map!(attr, [:xscale, :yscale], :transform_func) do transform_func...
        ax.scene.transformation.transform_func[] = transform_func
        return transform_func
    end
    ComputePipeline.set_type!(attr.transform_func, Any)

    map!(attr, :transform_func, :inverse_transform_func) do tf
        itf = inverse_transform(tf)
        # nothing is uses to discard updates so we need something else here
        return isnothing(itf) ? :nothing : itf
    end
    ComputePipeline.set_type!(attr.inverse_transform_func, Any)


    # (x/y)lims!() need to be able to set limits across one dimension without
    # affecting the limits of the other. To do that we need to mark one dimnesion
    # as an update to discard and the other as a normal update with ExplicitUpdate.
    # To avoid showing this to the user when fetching ax.limits[] we add another
    # input here, where (x/y)lims!() can mark which dimension to deny
    add_input!(attr, :_limit_update_rule, (:force, :force))
    attr.inputs[:_limit_update_rule].force_update = true

    register_computation!(
        attr,
        [:limits, :_limit_update_rule, :transform_func, :inverse_transform_func, :xautolimitmargin, :yautolimitmargin],
        [:localxlimits, :localylimits],
    ) do (limits, rule, tf, itf, xmargins, ymargins), changed, cached
        lims = calculate_local_limits(ax, limits, tf, itf, xmargins, ymargins)
        if changed._limit_update_rule
            # The update comes from (x/y)lims!() which explicitly set update rules
            xlims = ComputePipeline.ExplicitUpdate(lims[1], rule[1])
            ylims = ComputePipeline.ExplicitUpdate(lims[2], rule[2])
            return xlims, ylims
        else
            # force propagation of nothing, compare for numbers
            return ComputePipeline.ExplicitUpdate.(lims, :force)
        end
    end
    ComputePipeline.set_type!(attr.localxlimits, Union{Tuple{Float64, Float64}, ComputePipeline.ExplicitUpdate{Tuple{Float64, Float64}}})
    ComputePipeline.set_type!(attr.localylimits, Union{Tuple{Float64, Float64}, ComputePipeline.ExplicitUpdate{Tuple{Float64, Float64}}})

    setfield!(ax, :xaxislinks, Axis[])
    setfield!(ax, :yaxislinks, Axis[])

    #=
    Limit linking needs immediate updates. Consider linked ax1, ax2. If both
    axes are updated before the backend pulls, the order in whcih the backend
    pulls updates will determine whose limits are the "newest".
    So whenever the user sets limits, or interacts with an axis we need that
    change to be communicated to all linked axes asap. We make sure this happens
    by adding an (unused) observable output to shared(x/y)limits here. This will
    evaluate shared(x/y)limits whenever its input local(x/y)limits changes,
    running the linked axis update in its callback. Note that the callback must
    update shared(x/y)limits and not local(x/y)limits to not cause a feedback
    loop.
    Interactions must read from shared(x/y)limits of a dependent to get
    up-to-date limits with linked axes, and update local(x/y)limits to trigger
    the linked axis updates.
    Note for refactoring - exiting and reentering the compute graph between
    (x/y)scale and finallimits will cause ticks to update with the old
    finallimits and the new (x/y)scale if (x/y)scale changes.
    =#

    map!(attr, [:localxlimits, :xscale], :sharedxlimits) do _lims, xscale
        lims = unwrap_explicit_update(_lims)
        if !validate_limits_for_scale(lims, xscale)
            error("Invalid x-limits $lims for scale $(xscale) which is defined on the interval $(defined_interval(xscale))")
        end

        for link in ax.xaxislinks
            link === ax && continue
            # The world ends if this runs with link being this Axis
            link.sharedxlimits[] = lims
        end
        return lims
    end
    ComputePipeline.get_observable!(attr.sharedxlimits)

    map!(attr, [:localylimits, :yscale], :sharedylimits) do _lims, yscale
        lims = unwrap_explicit_update(_lims)
        if !validate_limits_for_scale(lims, yscale)
            error("Invalid y-limits $lims for scale $(yscale) which is defined on the interval $(defined_interval(yscale))")
        end

        for link in ax.yaxislinks
            link === ax && continue
            link.sharedylimits[] = lims
        end
        return lims
    end
    ComputePipeline.get_observable!(attr.sharedylimits)

    map!(attr, [:sharedxlimits, :sharedylimits], :targetlimits) do xlims, ylims
        return BBox(xlims[1], xlims[2], ylims[1], ylims[2])
    end

    map!(
        adjustlimits, attr,
        [:targetlimits, :autolimitaspect, :viewport, :xautolimitmargin, :yautolimitmargin],
        :finallimits
    )

    map!(
        attr,
        [:transform_func, :finallimits, :xreversed, :yreversed],
        :projectionmatrix
    ) do tf, lims, xrev, yrev
        return calculate_axis_projection_matrix(ax.scene, tf, lims, xrev, yrev)
    end

    # TODO: This could directly update scene.compute if we deprecate Camera
    idm = Makie.Mat4f(Makie.I)
    on(proj -> Makie.set_proj_view!(ax.scene.camera, proj, idm), attr.projectionmatrix, update = true)

    return
end

function get_limits(ax::Axis, tf, itf)
    x0, x1, y0, y1 = (Inf, -Inf, Inf, -Inf)
    for plot in ax.scene.plots
        update_x = to_value(get(plot, :xautolimits, true))
        update_y = to_value(get(plot, :yautolimits, true))
        if is_data_space(plot) && to_value(get(plot, :visible, true)) && (update_x || update_y)
            if (itf === nothing) || (itf === :nothing)
                @warn "Axis transformation $tf does not define an `inverse_transform()`. This may result in a bad choice of limits due to model transformations being ignored." maxlog = 1
                mini, maxi = extrema(Rect2d(data_limits(ax)))
            else
                # get limits with transform_func and model applied
                bb = boundingbox(plot)
                # then undo transform_func so that ticks can handle transform_func
                # without ignoring translations, scaling or rotations from model
                try
                    bb = apply_transform(itf, bb)
                catch e
                    @warn "Failed to apply inverse transform $itf to bounding box $bb. Falling back on data_limits()." exception = e
                    bb = data_limits(ax.scene, exclude)
                end
                mini, maxi = extrema(Rect2d(bb))
            end

            x0 = ifelse(update_x && isfinite(mini[1]), min(x0, mini[1]), x0)
            x1 = ifelse(update_x && isfinite(maxi[1]), max(x1, maxi[1]), x1)
            y0 = ifelse(update_y && isfinite(mini[2]), min(y0, mini[2]), y0)
            y1 = ifelse(update_y && isfinite(maxi[2]), max(y1, maxi[2]), y1)
        end
    end
    return (x0, x1), (y0, y1)
end

function autolimits(
        ax::Axis,
        tf = ax.scene.transform_func, itf = inverse_transform(tf),
        xmargin = ax.xautolimitmargin, ymargin = ax.yautolimitmargin
    )
    # try getting x limits for the axis and then union them with linked axes
    xlims, ylims = get_limits(ax, tf, itf)

    xlims = if xlims[1] <= xlims[2]
        expandlimits(xlims, xmargin..., tf[1])
    else
        defaultlimits(tf[1])
    end

    ylims = if ylims[1] <= ylims[2]
        expandlimits(ylims, ymargin..., tf[2])
    else
        defaultlimits(tf[2])
    end

    return xlims, ylims
end

function calculate_local_limits(ax, (user_xlims, user_ylims), tf, itf, xmargins, ymargins)
    # Skip boundingbox calls (in autolimits -> getlimits) if user provides full limits
    if isnothing(user_xlims) || isnothing(user_ylims) || any(isnothing, user_xlims) || any(isnothing, user_ylims)
        auto_xlims, auto_ylims = autolimits(ax, tf, itf, xmargins, ymargins)

        xlims = if isnothing(user_xlims)
            auto_xlims
        else
            something.(user_xlims, auto_xlims)
        end

        ylims = if isnothing(user_ylims)
            auto_ylims
        else
            something.(user_ylims, auto_ylims)
        end

        return Float64.(xlims), Float64.(ylims)
    else
        return Float64.(user_xlims), Float64.(user_ylims)
    end

end

function adjustlimits(limits, autolimitaspect, viewport, xautolimitmargin, yautolimitmargin)
    # in the simplest case, just update the final limits with the target limits
    if isnothing(autolimitaspect) || width(viewport) == 0 || height(viewport) == 0
        return limits
    end

    xlims = (left(limits), right(limits))
    ylims = (bottom(limits), top(limits))

    viewport_aspect = width(viewport) / height(viewport)
    data_aspect = (xlims[2] - xlims[1]) / (ylims[2] - ylims[1])
    aspect_ratio = data_aspect / viewport_aspect

    correction_factor = autolimitaspect / aspect_ratio

    if correction_factor > 1
        # need to go wider
        marginsum = sum(xautolimitmargin)
        ratios = (marginsum == 0) ? (0.5, 0.5) : (xautolimitmargin ./ marginsum)
        xlims = expandlimits(xlims, ((correction_factor - 1) .* ratios)..., identity) # don't use scale here?
    elseif correction_factor < 1
        # need to go taller
        marginsum = sum(yautolimitmargin)
        ratios = (marginsum == 0) ? (0.5, 0.5) : (yautolimitmargin ./ marginsum)
        ylims = expandlimits(ylims, (((1 / correction_factor) - 1) .* ratios)..., identity) # don't use scale here?
    end

    return BBox(xlims[1], xlims[2], ylims[1], ylims[2])
end

function xlims!(ax::Axis, xlims)
    xlims = map(x -> convert_dim_value(ax, 1, x), xlims)
    reversed = false
    if length(xlims) != 2
        error("Invalid xlims length of $(length(xlims)), must be 2.")
    elseif xlims[1] == xlims[2] && xlims[1] !== nothing
        error("Can't set x limits to the same value $(xlims[1]).")
    elseif all(x -> x isa Real, xlims) && xlims[1] > xlims[2]
        xlims = reverse(xlims)
        reversed = true
    end

    # update xlims if they changed, keep ylims
    update!(
        ax.attributes,
        limits = (xlims, ax.limits[][2]),
        _limit_update_rule = (:force, :deny),
        xreversed = reversed
    )

    return nothing
end

function Makie.ylims!(ax::Axis, ylims)
    ylims = map(x -> convert_dim_value(ax, 2, x), ylims)
    reversed = false
    if length(ylims) != 2
        error("Invalid ylims length of $(length(ylims)), must be 2.")
    elseif ylims[1] == ylims[2] && ylims[1] !== nothing
        error("Can't set y limits to the same value $(ylims[1]).")
    elseif all(x -> x isa Real, ylims) && ylims[1] > ylims[2]
        ylims = reverse(ylims)
        reversed = true
    end

    # update ylims if they changed, keep xlims
    update!(
        ax.attributes,
        limits = (ax.limits[][1], ylims),
        _limit_update_rule = (:deny, :force),
        yreversed = reversed
    )

    return nothing
end

function autolimits!(ax::Axis)
    ax.limits = (nothing, nothing)
    return
end

function reset_limits!(ax::Axis; xauto = true, yauto = true)
    # (x/y)auto = true means that we reset back to automatic limits for each
    # dimension with `nothing`. I.e. we trigger a standard update of limits
    # (x/y)auto = false means we keep whatever limits we currently have for
    # every nothing in limits

    prev_sharedxlimits = ax.sharedxlimits[]
    prev_sharedylimits = ax.sharedylimits[]

    ax.limits = ax.limits[]

    # recover previous limits for each *auto = false
    # Writes to local limits to re-trigger axis linking
    if !xauto
        current_sharedxlimits = ax.sharedxlimits[]
        ax.localxlimits[] = ifelse.(
            isnothing.(unwrap_explicit_update(ax.xlimits[])),
            prev_sharedxlimits, current_sharedxlimits
        )
    end

    if !yauto
        current_sharedylimits = ax.sharedylimits[]
        ax.localylimits[] = ifelse.(
            isnothing.(unwrap_explicit_update(ax.ylimits[])),
            prev_sharedylimits, current_sharedylimits
        )
    end

    return
end


################################################################################

mirror_xticks(tp, ts, ta, vp, ap, sw) = mirror_ticks(tp, ts, ta, vp, :x, ap, sw)
mirror_yticks(tp, ts, ta, vp, ap, sw) = mirror_ticks(tp, ts, ta, vp, :y, ap, sw)
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

# this is so users can do limits = (left, right, bottom, top)
function convert_limit_attribute(lims::Tuple{Any, Any, Any, Any})
    return (lims[1:2], lims[3:4])
end

function convert_limit_attribute(lims::Tuple{Any, Any})
    _convert_single_limit(x::Nothing) = x
    _convert_single_limit(x::Interval) = endpoints(x)
    _convert_single_limit(x::VecTypes{2}) = (x[1], x[2])
    function _convert_single_limit(x::AbstractArray)
        length(x) == 2 || error("Each dimension of limits must have 2 values, the minimum and maximum.")
        return (x[1], x[2])
    end
    return map(_convert_single_limit, lims)
end

validate_limits_for_scales(lims::Rect, tf::Tuple) = validate_limits_for_scales(lims, tf...)
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

getxlimits(la::Axis) = getlimits(la, 1)
getylimits(la::Axis) = getlimits(la, 2)

"""
    autolimits!()
    autolimits!(la::Axis)

Reset manually specified limits of `la` to an automatically determined rectangle, that depends on the data limits of all plot objects in the axis, as well as the autolimit margins for x and y axis.
The argument `la` defaults to `current_axis()`.
"""
function autolimits!()
    curr_ax = current_axis()
    isnothing(curr_ax)  &&  throw(ArgumentError("Attempted to call `autolimits!` on `current_axis()`, but `current_axis()` returned nothing."))
    return autolimits!(curr_ax)
end

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

linkaxes!(dir::Symbol, a::Axis, others...) = linkaxes!(dir, [a, others...])

function linkaxes!(dir::Symbol, axes::Vector{Axis})
    (length(axes) < 2) && return
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
    if links_changed
        ax = first(axes)
        if dir === :x
            ax.localxlimits[] = ax.sharedxlimits[]
        else
            ax.localylimits[] = ax.sharedylimits[]
        end
    end
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

        ax.xticklabelspace = Float64(ax.attributes.xaxis.actual_ticklabelspace[])
        ax.yticklabelspace = Float64(ax.attributes.yaxis.actual_ticklabelspace[])
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

xlims!(ax::Axis, xlims::Interval) = xlims!(ax, endpoints(xlims))
ylims!(ax::Axis, ylims::Interval) = ylims!(ax, endpoints(ylims))

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
