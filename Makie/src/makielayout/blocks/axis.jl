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

    # positivize widths in case the transform inverts space
    tlims = positivize(apply_transform(tf, lims))

    update_limits!(scene.float32convert, tlims) # update float32 scaling
    lims32 = f32_convert(scene.float32convert, tlims)  # get scaled limits
    left, bottom = minimum(lims32)
    right, top = maximum(lims32)
    leftright = xrev ? (right, left) : (left, right)
    bottomtop = yrev ? (top, bottom) : (bottom, top)

    # CairoMakie relies on eyeposition for mesh, surface, ...
    # Technically the camera should be infinitely far away from the 0 plane
    # because there is no perspective projection
    center = 0.5 * Point2f(left + right, bottom + top)
    eyeposition = Point3f(center..., 1.0e12)

    return Makie.orthographicprojection(
            Float32,
            leftright...,
            bottomtop..., nearclip, farclip
        ), eyeposition
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

block_kwargs(::Type{Axis}) = Set([:palette])
function initialize_block!(ax::Axis; palette = nothing)
    blockscene = ax.blockscene
    elements = Dict{Symbol, Any}()
    ax.elements = elements

    scene = Scene(blockscene, viewport = Rect2i(0, 0, 0, 0), visible = false)
    add_input!(ax, :viewport, scene.viewport)
    # Hide to block updates, will be unhidden! in constructor who calls this!
    @assert !scene.visible[]
    ax.scene = scene
    # transfer conversions from axis to scene if there are any
    # or the other way around
    connect_conversions!(scene.conversions, ax)

    setfield!(scene, :float32convert, Float32Convert())

    initialize_limit_computations!(ax)

    add_input!(ax, :computedbbox, ax.layoutobservables.computedbbox)
    map!(calculate_scenearea, ax, [:computedbbox, :finallimits, :aspect, :xscale, :yscale], :scenearea)
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

    map!(ax, [:xaxisposition, :viewport], :xaxis_endpoints) do xaxisposition, area
        if xaxisposition === :bottom
            return bottomline(Rect2f(area))
        elseif xaxisposition === :top
            return topline(Rect2f(area))
        else
            error("Invalid xaxisposition $xaxisposition")
        end
    end

    map!(ax, [:yaxisposition, :viewport], :yaxis_endpoints) do yaxisposition, area
        if yaxisposition === :left
            return leftline(Rect2f(area))
        elseif yaxisposition === :right
            return rightline(Rect2f(area))
        else
            error("Invalid yaxisposition $yaxisposition")
        end
    end

    map!(x -> x === :top, ax, :xaxisposition, :xaxis_flipped)
    map!(x -> x === :right, ax, :yaxisposition, :yaxis_flipped)

    map!(
        (flip, bv, tv) -> ifelse(flip, (tv, bv), (bv, tv)),
        ax,
        [:xaxis_flipped, :bottomspinevisible, :topspinevisible],
        [:xspinevisible, :xoppositespinevisible]
    )
    map!(
        (flip, lv, rv) -> ifelse(flip, (rv, lv), (lv, rv)),
        ax,
        [:yaxis_flipped, :leftspinevisible, :rightspinevisible],
        [:yspinevisible, :yoppositespinevisible]
    )
    map!(
        (flip, bc, tc) -> ifelse(flip, (tc, bc), (bc, tc)),
        ax,
        [:xaxis_flipped, :bottomspinecolor, :topspinecolor],
        [:xspinecolor, :xoppositespinecolor]
    )
    map!(
        (flip, lc, rc) -> ifelse(flip, (rc, lc), (lc, rc)),
        ax,
        [:yaxis_flipped, :leftspinecolor, :rightspinecolor],
        [:yspinecolor, :yoppositespinecolor]
    )

    map!(xlimits, ax, :finallimits, :finalxlimits)
    map!(ylimits, ax, :finallimits, :finalylimits)

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
        suffix_formatter = ax.xlabel_suffix
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
        suffix_formatter = ax.ylabel_suffix
    )

    ax.yaxis = yaxis

    map!(ax, [:viewport, :xaxisposition], :xoppositelinepoints) do r, xaxpos
        y = xaxpos === :top ? bottom(r) : top(r)
        return [Point2f(left(r), y), Point2f(right(r), y)]
    end

    map!(ax, [:viewport, :yaxisposition], :yoppositelinepoints) do r, yaxpos
        x = yaxpos === :right ? left(r) : right(r)
        return [Point2f(x, bottom(r)), Point2f(x, top(r))]
    end

    map!(
        mirror_xticks, ax,
        [(:xaxis, :tickpositions), :xticksize, :xtickalign, :viewport, :xaxisposition, :spinewidth],
        :xticksmirrored_points
    )
    map!((a, b) -> a && b, ax, [:xticksmirrored, :xticksvisible], :mirroredxticksvisible)
    xticksmirrored_lines = linesegments!(
        blockscene, ax.xticksmirrored_points, visible = ax.mirroredxticksvisible,
        linewidth = ax.xtickwidth, color = ax.xtickcolor
    )
    translate!(xticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_yticks, ax,
        [(:yaxis, :tickpositions), :yticksize, :ytickalign, :viewport, :yaxisposition, :spinewidth],
        :yticksmirrored_points
    )
    map!((a, b) -> a && b, ax, [:yticksmirrored, :yticksvisible], :mirroredyticksvisible)
    yticksmirrored_lines = linesegments!(
        blockscene, ax.yticksmirrored_points, visible = ax.mirroredyticksvisible,
        linewidth = ax.ytickwidth, color = ax.ytickcolor
    )
    translate!(yticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_xticks, ax,
        [(:xaxis, :minortickpositions), :xminorticksize, :xminortickalign, :viewport, :xaxisposition, :spinewidth],
        :xminorticksmirrored
    )
    map!((a, b) -> a && b, ax, [:xticksmirrored, :xminorticksvisible], :mirroredxminorticksvisible)
    xminorticksmirrored_lines = linesegments!(
        blockscene, ax.xminorticksmirrored, visible = ax.mirroredxminorticksvisible,
        linewidth = ax.xminortickwidth, color = ax.xminortickcolor
    )
    translate!(xminorticksmirrored_lines, 0, 0, 10)

    map!(
        mirror_yticks, ax,
        [(:yaxis, :minortickpositions), :yminorticksize, :yminortickalign, :viewport, :yaxisposition, :spinewidth],
        :yminorticksmirrored
    )
    map!((a, b) -> a && b, ax, [:yticksmirrored, :yminorticksvisible], :mirroredyminorticksvisible)
    yminorticksmirrored_lines = linesegments!(
        blockscene, ax.yminorticksmirrored, visible = ax.mirroredyminorticksvisible,
        linewidth = ax.yminortickwidth, color = ax.yminortickcolor
    )
    translate!(yminorticksmirrored_lines, 0, 0, 10)

    xoppositeline = linesegments!(
        blockscene, ax.xoppositelinepoints, linewidth = ax.spinewidth,
        visible = ax.xoppositespinevisible, color = ax.xoppositespinecolor,
        inspectable = false, linestyle = nothing, linecap = :square
    )
    elements[:xoppositeline] = xoppositeline
    translate!(xoppositeline, 0, 0, 20)

    yoppositeline = linesegments!(
        blockscene, ax.yoppositelinepoints, linewidth = ax.spinewidth,
        visible = ax.yoppositespinevisible, color = ax.yoppositespinecolor,
        inspectable = false, linestyle = nothing, linecap = :square
    )
    elements[:yoppositeline] = yoppositeline
    translate!(yoppositeline, 0, 0, 20)

    map!(
        ax,
        [(:xaxis, :tickpositions), :xaxisposition, :viewport],
        :xgrid_points
    ) do tickpos, axispos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = axispos === :bottom ? pxheight : -pxheight
        return gridline_points(Point2f(0, offset), tickpos)
    end

    map!(
        ax,
        [(:yaxis, :tickpositions), :yaxisposition, :viewport],
        :ygrid_points
    ) do tickpos, axispos, area
        local pxwidth::Float32 = width(area)
        local offset::Float32 = axispos === :left ? pxwidth : -pxwidth
        return gridline_points(Point2f(offset, 0), tickpos)
    end

    map!(
        ax,
        [(:xaxis, :minortickpositions), :xaxisposition, :viewport],
        :xminorgrid_points
    ) do tickpos, axispos, area
        local pxheight::Float32 = height(area)
        local offset::Float32 = axispos === :bottom ? pxheight : -pxheight
        return gridline_points(Point2f(0, offset), tickpos)
    end

    map!(
        ax,
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
        ax,
        [:viewport, :titlegap, :titlealign, :xaxisposition, (:xaxis, :protrusion)],
        :subtitlepos
    ) do a, titlegap, align, xaxisposition, xaxisprotrusion

        align_factor = halign2num(align, "Horizontal title align $align not supported.")
        x = a.origin[1] + align_factor * a.widths[1]

        yoffset = top(a) + titlegap + (xaxisposition === :top ? xaxisprotrusion : 0.0f0)

        return Point2f(x, yoffset)
    end

    map!(align -> (align, :bottom), ax, :titlealign, :titlealign_tuple)

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
        ax, [subtitle_bbox, :subtitlevisible, :subtitlegap], :subtitle_height
    ) do bboxes, visible, gap
        bb = reduce(update_boundingbox, bboxes, init = Rect3f())
        height = widths(bb)[2]
        return isfinite(height) && visible ? Float32(height + gap) : 0.0f0
    end

    map!(
        calculate_title_position, ax,
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
        ax, [title_bbox, :titlevisible, :titlegap], :title_height
    ) do bboxes, visible, gap
        bb = reduce(update_boundingbox, bboxes, init = Rect3f())
        height = widths(bb)[2]
        return isfinite(height) && visible ? Float32(height + gap) : 0.0f0
    end

    map!(
        compute_protrusions, ax,
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

function add_attributes!(::Type{<:Axis}, graph, flattened_defaults)
    attr = documented_attributes(Axis)
    _, default = get_typed_default(attr, flattened_defaults, :limits)
    add_input!(convert_limit_attribute, graph, :limits, default)
    ComputePipeline.set_type!(graph.limits, Any)
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
    ) do (limits, rule, tf, itf, xmargins, ymargins), changed, @nospecialize(cached)
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
    axes are updated before the backend pulls, the order in which the backend
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

        return lims
    end

    # Setting link.sharedxlimits will loop back to this axis, which causes state
    # to be overwritten if it happens during resolve, i.e. in the callback above.
    # Using a compute graph Observable to link limits is fine though
    on(attr.sharedxlimits) do lims
        for link in ax.xaxislinks
            link === ax && continue
            # The world ends if this runs with link being this Axis
            link.sharedxlimits[] = lims
        end
        return
    end

    map!(attr, [:localylimits, :yscale], :sharedylimits) do _lims, yscale
        lims = unwrap_explicit_update(_lims)
        if !validate_limits_for_scale(lims, yscale)
            error("Invalid y-limits $lims for scale $(yscale) which is defined on the interval $(defined_interval(yscale))")
        end

        return lims
    end

    on(attr.sharedylimits) do lims
        for link in ax.yaxislinks
            link === ax && continue
            link.sharedylimits[] = lims
        end
        return
    end

    map!(attr, [:sharedxlimits, :sharedylimits], :targetlimits) do xlims, ylims
        return BBox(xlims[1], xlims[2], ylims[1], ylims[2])
    end

    map!(
        adjustlimits, attr,
        [:targetlimits, :autolimitaspect, :viewport, :xautolimitmargin, :yautolimitmargin, :xscale, :yscale],
        :finallimits
    )

    map!(
        attr,
        [:transform_func, :finallimits, :xreversed, :yreversed],
        [:projectionmatrix, :eyeposition]
    ) do tf, lims, xrev, yrev
        return calculate_axis_projection_matrix(ax.scene, tf, lims, xrev, yrev)
    end

    # TODO: This could directly update scene.compute if we deprecate Camera
    idm = Makie.Mat4f(Makie.I)
    on(proj -> Makie.set_proj_view!(ax.scene.camera, proj, idm), attr.projectionmatrix, update = true)
    connect!(ax.scene.camera.eyeposition, attr.eyeposition)

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

function adjustlimits(limits, autolimitaspect, viewport, xautolimitmargin, yautolimitmargin, xscale, yscale)
    # in the simplest case, just update the final limits with the target limits
    if isnothing(autolimitaspect) || width(viewport) == 0 || height(viewport) == 0
        return limits
    end

    xlims = (left(limits), right(limits))
    ylims = (bottom(limits), top(limits))

    # issue #5909: aspect ratios and expansions are computed in scaled (e.g. log10) coordinates
    viewport_aspect = width(viewport) / height(viewport)
    data_aspect = scaled_width(xscale, xlims...) / scaled_width(yscale, ylims...)
    aspect_ratio = data_aspect / viewport_aspect


    correction_factor = autolimitaspect / aspect_ratio

    if correction_factor > 1
        # need to go wider
        marginsum = sum(xautolimitmargin)
        ratios = (marginsum == 0) ? (0.5, 0.5) : (xautolimitmargin ./ marginsum)
        xlims = expandlimits(xlims, ((correction_factor - 1) .* ratios)..., xscale)
    elseif correction_factor < 1
        # need to go taller
        marginsum = sum(yautolimitmargin)
        ratios = (marginsum == 0) ? (0.5, 0.5) : (yautolimitmargin ./ marginsum)
        ylims = expandlimits(ylims, (((1 / correction_factor) - 1) .* ratios)..., yscale)
    end

    return BBox(xlims[1], xlims[2], ylims[1], ylims[2])
end

function prepare_user_lims(ax, _lims, idx)
    dim = ("x", "y")[idx]
    lims = map(x -> convert_dim_value(ax, idx, x), _convert_single_limit(_lims))
    reversed = false
    if length(lims) != 2
        error("Invalid $(dim)lims length of $(length(lims)), must be 2.")
    elseif lims[1] == lims[2] && lims[1] !== nothing
        error("Can't set $dim limits to the same value $(lims[1]).")
    elseif all(x -> x isa Real, lims) && lims[1] > lims[2]
        lims = reverse(lims)
        reversed = true
    end
    return lims, reversed
end

function update_xlims_locally!(ax, xlims, xreversed)
    # update xlims if they changed, keep ylims
    update!(
        ax,
        limits = (xlims, ax.limits[][2]),
        _limit_update_rule = (:force, :deny),
        xreversed = xreversed
    )
    return
end

function update_ylims_locally!(ax, ylims, yreversed)
    # update ylims if they changed, keep xlims
    update!(
        ax,
        limits = (ax.limits[][1], ylims),
        _limit_update_rule = (:deny, :force),
        yreversed = yreversed
    )
    return
end

function xlims!(ax::Axis, _xlims)
    xlims, reversed = prepare_user_lims(ax, _xlims, 1)
    update_xlims_locally!(ax, xlims, reversed)

    for link in ax.xaxislinks
        link === ax && continue
        update_xlims_locally!(link, xlims, reversed)
    end

    return
end

function ylims!(ax::Axis, _ylims)
    ylims, reversed = prepare_user_lims(ax, _ylims, 2)
    update_ylims_locally!(ax, ylims, reversed)

    for link in ax.yaxislinks
        link === ax && continue
        update_ylims_locally!(link, ylims, reversed)
    end

    return
end

function _limits!(ax, lims)
    xlims, xreversed = prepare_user_lims(ax, lims[1], 1)
    ylims, yreversed = prepare_user_lims(ax, lims[2], 2)

    # update xlims if they changed, keep ylims
    update!(
        ax,
        limits = (xlims, ylims),
        xreversed = xreversed,
        yreversed = yreversed
    )

    for link in ax.xaxislinks
        link === ax && continue
        update_xlims_locally!(link, xlims, xreversed)
    end

    for link in ax.yaxislinks
        link === ax && continue
        update_ylims_locally!(link, ylims, yreversed)
    end

    return
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

    ax.limits::Computed = ax.limits[]

    # recover previous limits for each *auto = false
    # Writes to local limits to re-trigger axis linking
    if !xauto
        current_sharedxlimits = ax.sharedxlimits[]
        ax.localxlimits[]::Computed = ifelse.(
            isnothing.(unwrap_explicit_update(ax.xlimits[])),
            prev_sharedxlimits, current_sharedxlimits
        )
    end

    if !yauto
        current_sharedylimits = ax.sharedylimits[]
        ax.localylimits[]::Computed = ifelse.(
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
    # same geometry as the primary ticks, see `tick_extents`; outward is `+sign` here
    outer, inner = tick_extents(tickalign, ticksize, spinewidth)
    points = Vector{Point2f}(undef, 2 * length(tickpositions))
    if side === :x
        for (i, (x, _)) in enumerate(tickpositions)
            points[2i - 1] = Point2f(x, opp - sign * inner)
            points[2i] = Point2f(x, opp + sign * outer)
        end
    else
        for (i, (_, y)) in enumerate(tickpositions)
            points[2i - 1] = Point2f(opp - sign * inner, y)
            points[2i] = Point2f(opp + sign * outer, y)
        end
    end
    return points
end

# this is so users can do limits = (left, right, bottom, top)
function convert_limit_attribute(lims::Tuple{Any, Any, Any, Any})
    return (lims[1:2], lims[3:4])
end

_convert_single_limit(x::Nothing) = x
_convert_single_limit(x::Interval) = endpoints(x)
_convert_single_limit(x::VecTypes{2}) = (x[1], x[2])
function _convert_single_limit(x::AbstractArray)
    length(x) == 2 || error("Each dimension of limits must have 2 values, the minimum and maximum.")
    return (x[1], x[2])
end

function convert_limit_attribute(lims::Tuple{Any, Any})
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
            notify(ComputePipeline.get_observable!(ax.sharedxlimits))
        else
            notify(ComputePipeline.get_observable!(ax.sharedylimits))
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
Keeps the ticklabelspace static until no interaction has happened for `reset.delay`
seconds of tick time and then resets it to its previous value. If that value is
Makie.automatic, the reset will trigger new protrusions for the axis and the layout
will adjust. This is so the layout doesn't immediately readjust during interaction,
which would let the whole layout jitter around.
"""
function freeze_ticklabelspace_until_idle!(ax::Axis, reset::TicklabelspaceReset)
    reset.idle_time = 0.0
    isnothing(reset.tick_listener) || return

    reset.prev_xticklabelspace = ax.xticklabelspace[]
    reset.prev_yticklabelspace = ax.yticklabelspace[]
    ax.xticklabelspace = Float64(ax.attributes.xaxis.actual_ticklabelspace[])
    ax.yticklabelspace = Float64(ax.attributes.yaxis.actual_ticklabelspace[])

    reset.tick_listener = on(events(ax.scene).tick) do tick
        reset.idle_time += tick.delta_time
        reset.idle_time >= reset.delay || return
        Observables.off(reset.tick_listener)
        reset.tick_listener = nothing
        ax.xticklabelspace = reset.prev_xticklabelspace
        ax.yticklabelspace = reset.prev_yticklabelspace
        return
    end
    return
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
Makie.xlims!(low, high) = Makie.xlims!(current_axis(), low, high)
"""
    ylims!(low, high)
    ylims!(; low = nothing, high = nothing)

Set the y-axis limits of the current axis to `low` and `high`. If the limits
are ordered high-low, this reverses the axis orientation. A limit set to
`nothing` will be determined automatically from the plots in the axis.
"""
Makie.ylims!(low, high) = Makie.ylims!(current_axis(), low, high)
"""
    zlims!(low, high)
    zlims!(; low = nothing, high = nothing)

Set the z-axis limits of the current axis to `low` and `high`. If the limits
are ordered high-low, this reverses the axis orientation. A limit set to
`nothing` will be determined automatically from the plots in the axis.
"""
Makie.zlims!(low, high) = Makie.zlims!(current_axis(), low, high)

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
    return _limits!(ax, (xlims, ylims))
end

"""
    limits!(ax::Axis, x1, x2, y1, y2)

Set the axis x-limits to `x1` and `x2` and the y-limits to `y1` and `y2`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, x1, x2, y1, y2)
    return _limits!(ax, ((x1, x2), (y1, y2)))
end

"""
    limits!(ax::Axis, rect::Rect2)

Set the axis limits to `rect`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis, rect::Rect2)
    xmin, ymin = minimum(rect)
    xmax, ymax = maximum(rect)
    return _limits!(ax, ((xmin, xmax), (ymin, ymax)))
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

"""
    defaultlimits(scale)

Returns a tuple (low, high) of default limits based on the x/y/zscale of an axis.
These are used when limits can't be determined from the content of an Axis.
"""
defaultlimits(scale::ReversibleScale) = inverse_transform(scale).(scale.limits)
defaultlimits(scale::Makie.Symlog10) = defaultlimits(scale.scale)
defaultlimits(scale::LogFunctions) = let inv_scale = inverse_transform(scale)
    (inv_scale(0.0), inv_scale(3.0))
end
defaultlimits(::typeof(identity)) = (0.0, 10.0)
defaultlimits(::typeof(sqrt)) = (0.0, 100.0)
defaultlimits(::typeof(Makie.logit)) = (0.01, 0.99)

"""
    defined_interval(scale)

Returns an Interval on which the given x/y/zscale is defined.
"""
defined_interval(scale::ReversibleScale) = scale.interval
defined_interval(scale::Makie.Symlog10) = defined_interval(scale.scale)
defined_interval(::typeof(identity)) = OpenInterval(-Inf, Inf)
defined_interval(::LogFunctions) = OpenInterval(0.0, Inf)
defined_interval(::typeof(sqrt)) = Interval{:closed, :open}(0, Inf)
defined_interval(::typeof(Makie.logit)) = OpenInterval(0.0, 1.0)

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
