# the hyphen which is usually used to store negative number strings
# is shorter than the dedicated minus in most fonts, the minus glyph
# looks more balanced with numbers, especially in superscripts or subscripts
const MINUS_SIGN = "−" # == "\u2212" (Unicode minus)

function LineAxis(parent::Scene, graph::AbstractComputeGraph; @nospecialize(kwargs...))
    attrs = mergeleft!(Attributes(kwargs), generic_plot_attributes(LineAxis))

    # Attributes() maps all typed observables to Observable{Any}. This means
    # any typed Observable that's passed to LineAxis will not actually arrive
    # here. Instead we get a child of it with Any.
    # For Computed that doesn't happen. If a Computed is passed we will get it
    # as is. If we write to it, we adjust something in the parent compute graph.
    # And if the type of the written value doesn't match we error
    # This happens for:
    if haskey(attrs, :ticklabelspace) && eltype(attrs[:ticklabelspace]) !== Any
        attrs[:ticklabelspace] = ComputePipeline.get_observable!(attrs[:ticklabelspace])
    end

    return LineAxis(parent, graph, attrs)
end

function calculate_horizontal_extends(endpoints)::Tuple{Float32, NTuple{2, Float32}, Bool}
    if endpoints[1][2] == endpoints[2][2]
        horizontal = true
        extents = (endpoints[1][1], endpoints[2][1])
        position = endpoints[1][2]
        return (position, extents, horizontal)
    elseif endpoints[1][1] == endpoints[2][1]
        horizontal = false
        extents = (endpoints[1][2], endpoints[2][2])
        position = endpoints[1][1]
        return (position, extents, horizontal)
    else
        error("OldAxis endpoints $(endpoints[1]) and $(endpoints[2]) are neither on a horizontal nor vertical line")
    end
end


function calculate_protrusion(
        horizontal, labeltext, ticklabel_position,
        ticksvisible::Bool, label, labelvisible::Bool, labelpadding::Number,
        tickspace::Number, ticklabelsvisible::Bool,
        actual_ticklabelspace::Number, ticklabelpad::Number, _...
    )

    label_is_empty::Bool = iswhitespace(label)

    real_labelsize::Float32 = if label_is_empty
        0.0f0
    else
        # TODO: This can probably be
        #   widths(fast_string_boundingboxes(labeltext)[1])
        # to skip positions? (This only runs for axis labels)
        widths(boundingbox(labeltext, :data))[horizontal[] ? 2 : 1]
    end

    labelspace::Float32 = (labelvisible && !label_is_empty) ? real_labelsize + labelpadding : 0.0f0

    _tickspace::Float32 = (ticksvisible && !isempty(ticklabel_position[])) ? tickspace : 0.0f0

    needs_gap = (ticklabelsvisible && actual_ticklabelspace > 0)
    ticklabelgap::Float32 = needs_gap ? actual_ticklabelspace + ticklabelpad : 0.0f0

    return _tickspace + ticklabelgap + labelspace
end


function create_linepoints(
        position::Float32, extents::NTuple{2, Float32}, horizontal::Bool,
        flipped::Bool, spine_width::Number, trimspine::Union{Bool, Tuple{Bool, Bool}},
        tickpositions::Vector{Point2f}, tickwidth::Number
    )

    if trimspine isa Bool
        trimspine = (trimspine, trimspine)
    end

    return if trimspine == (false, false) || length(tickpositions) < 2
        if horizontal
            y = position
            p1 = Point2f(extents[1] - 0.5spine_width, y)
            p2 = Point2f(extents[2] + 0.5spine_width, y)
            return [p1, p2]
        else
            x = position
            p1 = Point2f(x, extents[1] - 0.5spine_width)
            p2 = Point2f(x, extents[2] + 0.5spine_width)
            return [p1, p2]
        end
    else
        extents_oriented = last(tickpositions) > first(tickpositions) ? extents : reverse(extents)
        if horizontal
            y = position
            pstart = Point2f(-0.5f0 * tickwidth, 0)
            pend = Point2f(0.5f0 * tickwidth, 0)
            from = trimspine[1] ? tickpositions[1] .+ pstart : Point2f(extents_oriented[1] - 0.5spine_width, y)
            to = trimspine[2] ? tickpositions[end] .+ pend : Point2f(extents_oriented[2] + 0.5spine_width, y)
            return [from, to]
        else
            x = position
            pstart = Point2f(0, -0.5f0 * tickwidth)
            pend = Point2f(0, 0.5f0 * tickwidth)
            from = trimspine[1] ? tickpositions[1] .+ pstart : Point2f(x, extents_oriented[1] - 0.5spine_width)
            to = trimspine[2] ? tickpositions[end] .+ pend : Point2f(x, extents_oriented[2] + 0.5spine_width)
            return [from, to]
        end
    end

end

function calculate_real_ticklabel_align(al, horizontal, fl::Bool, rot::Number)
    hor = horizontal[]::Bool
    return if al isa Automatic
        if rot == 0 || !(rot isa Real)
            if hor
                (:center, fl ? :bottom : :top)
            else
                (fl ? :left : :right, :center)
            end
        elseif rot ≈ pi / 2
            if hor
                (fl ? :left : :right, :center)
            else
                (:center, fl ? :top : :bottom)
            end
        elseif rot ≈ -pi / 2
            if hor
                (fl ? :right : :left, :center)
            else
                (:center, fl ? :bottom : :top)
            end
        elseif rot > 0
            if hor
                (fl ? :left : :right, fl ? :bottom : :top)
            else
                (fl ? :left : :right, :center)
            end
        elseif rot < 0
            if hor
                (fl ? :right : :left, fl ? :bottom : :top)
            else
                (fl ? :left : :right, :center)
            end
        end
    elseif al isa NTuple{2, Symbol}
        al
    else
        error("Align needs to be a NTuple{2, Symbol}.")
    end
end

max_auto_ticklabel_spacing!(ax) = nothing

function adjust_ticklabel_placement(
        tickpositions, horizontal, flipped,
        spinewidth, tickspace, ticklabelpad
    )
    ticklabelgap = spinewidth + tickspace + ticklabelpad

    shift = if horizontal
        Point2f(0.0f0, flipped ? ticklabelgap : -ticklabelgap)
    else
        Point2f(flipped ? ticklabelgap : -ticklabelgap, 0.0f0)
    end
    # reuse already allocated array
    return Point2f[pos .+ shift for pos in tickpositions]
end

function calculated_aligned_ticks(horizontal, flipped, tickpositions, tickalign, ticksize, spinewidth)
    result = Point2f[]
    sign = ifelse(flipped, -1, 1)
    if horizontal
        for tp in tickpositions
            tstart = tp + sign * Point2f(0.0f0, tickalign * ticksize - 0.5f0 * spinewidth)
            tend = tstart + sign * Point2f(0.0f0, -ticksize)
            push!(result, tstart, tend)
        end
    else
        for tp in tickpositions
            tstart = tp + sign * Point2f(tickalign * ticksize - 0.5f0 * spinewidth, 0.0f0)
            tend = tstart + sign * Point2f(-ticksize, 0.0f0)
            push!(result, tstart, tend)
        end
    end
    return result
end

# if labels are given manually, it's possible that some of them are outside the displayed limits
# we only check approximately because we want to keep ticks on the frame
is_within_limits(tv, limits) = (limits[1] - 100eps(limits[1]) < tv) && (tv < limits[2] + 100eps(limits[2]))

function compute_minor_ticks(
        limits, position, extents_uncorrected, horizontal, minortickvalues_unfiltered,
        scale, reversed::Bool
    )
    extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

    px_o = extents[1]
    px_width = extents[2] - extents[1]

    minortickvalues = filter(tv -> is_within_limits(tv, limits), minortickvalues_unfiltered)

    tickvalues_scaled = scale.(minortickvalues)

    tick_fractions = (tickvalues_scaled .- scale(limits[1])) ./ (scale(limits[2]) - scale(limits[1]))

    tick_scenecoords = px_o .+ px_width .* tick_fractions

    if horizontal
        return [Point2f(x, position) for x in tick_scenecoords]
    else
        return [Point2f(position, y) for y in tick_scenecoords]
    end
end

function build_label_with_unit_suffix(dim_convert, formatter, label, show_unit_in_label, use_short_units)
    should_show = show_dim_convert_in_axis_label(dim_convert, show_unit_in_label)
    if should_show
        suffix = get_label_suffix(dim_convert, formatter, use_short_units)
        return isempty(label) ? suffix : rich("$label ", suffix)
    else
        return label
    end
end

macro make_computed(graph, key)
    return quote
        if !haskey($(esc(graph)), $(QuoteNode(key)))
            # if !isa($(esc(key)), Computed)
            #     println("Added: ", $(QuoteNode(key)), "::", typeof($(esc(key))))
            # end
            add_input!($(esc(graph)), $(QuoteNode(key)), $(esc(key)))
        end
    end
end

function _extract_computed(graph::ComputePipeline.AbstractComputeGraph, dictlike, name)
    entry = dictlike[name]
    root = ComputePipeline.root(graph)
    if (entry isa ComputePipeline.Computed) && (entry.parent.graph == root)
        return entry
    elseif entry isa Union{Attributes, ComputePipeline.AbstractComputeGraph}
        error("$name::$(typeof(entry)) is not supported in @extract_computed")
    else
        # to_recipe_attribute does Ref{Any} wrapping (in case types can change)
        add_input!(to_recipe_attribute, graph, name, entry)
        return graph[name]
    end
end

"""
    @extract_computed source graph (name1, name2, ...)

Extracts entries with the given names from `source` and makes them available as
variables with the same name. If the entry is a compute node from (the root
parent of) `graph` it will be written to the variable directly with
`name1 = source[:name1]`. Otherwise it will be added to `graph` with
`add_input!(graph, :name1, source[:name1])` and the added node will be used
instead with `name1 = graph[:name1]`.

Note that this does not imply that `graph[:name1]` exists. It implies that
`:name1` exists somewhere in the root parent of graph, which might be a
(different) nested sub graph from `graph`. To be safe, pass `name1` instead of
`:name1` to computations when using this macro.
"""
macro extract_computed(attrs, graph, names)
    define_func = quote
        extract_computed(dictlike, name) = _extract_computed($(esc(graph)), dictlike, name)
    end
    expr = extract_expr(:extract_computed, attrs, names)
    pushfirst!(expr.args, define_func)
    return expr
end

function LineAxis(parent::Scene, graph::AbstractComputeGraph, attrs::Attributes)
    decorations = Dict{Symbol, Any}()

    @extract_computed attrs graph (
        endpoints, limits, flipped, scale, dim_convert,
        ticksize, tickwidth, tickcolor, tickalign, ticks, tickformat, ticksvisible,
        ticklabelalign, ticklabelrotation, ticklabelspace, ticklabelpad,
        ticklabelsize, ticklabelsvisible, ticklabelfont, ticklabelcolor,
        spinewidth, spinecolor, spinevisible,
        label, labelsize, labelcolor, labelpadding, labelfont, labelrotation, labelvisible,
        trimspine, flip_vertical_label, reversed,
        minorticksvisible, minortickalign, minorticksize, minortickwidth, minortickcolor,
        minorticks, minorticksused,
        unit_in_ticklabel, suffix_formatter, unit_in_label, use_short_unit,
    )

    map!(calculate_horizontal_extends, graph, endpoints, [:position, :extents, :horizontal])

    # TODO: Does this have side effects on Axis, plots?
    # TODO: Does this propagate enough on same value updates?
    # make sure we update tick calculation when needed
    obs = needs_tick_update_observable(dim_convert)
    if !isnothing(obs)
        on(x -> ComputePipeline.mark_dirty!(dim_convert), obs)
    end

    map!(
        graph,
        # TODO: Why was :pos_extents_horizontal in here?
        [dim_convert, limits, ticks, tickformat, scale, unit_in_ticklabel],
        [:tickvalues_unfiltered, :tickstrings_unfiltered],
    ) do dim_convert, limits, ticks, tickformat, scale, unit_in_ticklabel
        should_show = show_dim_convert_in_ticklabel(dim_convert, unit_in_ticklabel)
        vals, strs = get_ticks(dim_convert, ticks, scale, tickformat, limits..., should_show)
        return vals, convert(Vector{Any}, strs)
    end

    map!(
        graph,
        [:tickvalues_unfiltered, limits],
        :tick_indices_within_limits
    ) do tickvalues_unfiltered, limits
        return findall(tv -> is_within_limits(tv, limits), tickvalues_unfiltered)
    end

    map!(
        graph,
        [:tickvalues_unfiltered, :tickstrings_unfiltered, :tick_indices_within_limits],
        [:tickvalues, :tickstrings],
    ) do tickvalues_unfiltered, tickstrings_unfiltered, indices
        return tickvalues_unfiltered[indices], tickstrings_unfiltered[indices]
    end

    map!(
        graph,
        [:tickvalues, minorticks, minorticksvisible, minorticksused, scale, limits],
        :minortickvalues,
        init = Float64[]
    ) do values, ticks, visible, used, scale, limits
        if visible || used
            return get_minor_tickvalues(ticks, scale, values, limits...)
        else
            return nothing
        end
    end
    ComputePipeline.mark_dirty!(graph.minortickvalues)

    ######################################
    ### Ticks
    ######################################

    map!(
        graph,
        [:tickvalues, scale, :position, :extents, :horizontal, limits, reversed],
        :tickpositions
    ) do tickvalues, scale, position, extents_uncorrected, horizontal, limits, reversed

        # TODO: maybe move out?
        extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected
        px_o = extents[1]
        px_width = extents[2] - extents[1]
        tickvalues_scaled = scale.(tickvalues)
        tick_fractions = (tickvalues_scaled .- scale(limits[1])) ./ (scale(limits[2]) - scale(limits[1]))

        tick_scenecoords = px_o .+ px_width .* tick_fractions

        if horizontal
            return [Point2f(x, position) for x in tick_scenecoords]
        else
            return [Point2f(position, y) for y in tick_scenecoords]
        end
    end

    map!(
        calculated_aligned_ticks, graph,
        [:horizontal, flipped, :tickpositions, tickalign, ticksize, spinewidth],
        :ticksnode
    )

    ticklines = linesegments!(
        parent, graph.ticksnode, linewidth = tickwidth, color = tickcolor,
        linestyle = nothing, visible = ticksvisible, inspectable = false
    )
    decorations[:ticklines] = ticklines
    translate!(ticklines, 0, 0, 10)

    ######################################
    ### Minor Ticks
    ######################################

    map!(
        compute_minor_ticks, graph,
        [limits, :position, :extents, :horizontal, :minortickvalues, scale, reversed],
        :minortickpositions
    )

    map!(
        calculated_aligned_ticks, graph,
        [:horizontal, flipped, :minortickpositions, minortickalign, minorticksize, spinewidth],
        :minorticksnode
    )

    minorticklines = linesegments!(
        parent, graph.minorticksnode, linewidth = minortickwidth, color = minortickcolor,
        linestyle = nothing, visible = minorticksvisible, inspectable = false
    )
    decorations[:minorticklines] = minorticklines
    translate!(minorticklines, 0, 0, 10)

    ######################################
    ### Axis Line
    ######################################

    map!(
        create_linepoints, graph,
        [:position, :extents, :horizontal, flipped, spinewidth, trimspine, :tickpositions, tickwidth],
        :linepoints
    )

    decorations[:axisline] = linesegments!(
        parent, graph.linepoints, linewidth = spinewidth, visible = spinevisible,
        color = spinecolor, inspectable = false, linestyle = nothing
    )
    translate!(decorations[:axisline], 0, 0, 20)

    ######################################
    ### Tick Labels
    ######################################

    map!(graph, [ticksvisible, ticksize, tickalign], :tickspace) do ticksvisible, ticksize, tickalign
        return ticksvisible ? max(0.0f0, ticksize * (1.0f0 - tickalign)) : 0.0f0
    end

    map!(
        adjust_ticklabel_placement, graph,
        [:tickpositions, :horizontal, flipped, spinewidth, :tickspace, ticklabelpad],
        :ticklabel_position
    )

    map!(
        calculate_real_ticklabel_align, graph,
        [ticklabelalign, :horizontal, flipped, ticklabelrotation],
        :realticklabelalign
    )

    ticklabels_plot = text!(
        parent,
        graph.ticklabel_position,
        text = graph.tickstrings,
        align = graph.realticklabelalign,
        rotation = ticklabelrotation,
        fontsize = ticklabelsize,
        font = ticklabelfont,
        color = ticklabelcolor,
        visible = ticklabelsvisible,
        markerspace = :data,
        inspectable = false
    )

    decorations[:ticklabels] = ticklabels_plot

    ticklabels_bbox = register_raw_string_boundingboxes!(ticklabels_plot)
    map!(graph, ticklabels_bbox, :ticklabelbbox) do bbs
        return reduce(update_boundingbox, bbs, init = Rect3f())
    end

    ######################################
    ### Axis Labels
    ######################################

    map!(graph, [:horizontal, :ticklabelbbox], :ticklabel_ideal_space) do horizontal, bbox
        maxwidth = horizontal ? height(bbox) : width(bbox)
        # not finite until the plot is created
        # Note: This used to be `isfinite(maxwidth) && visible` - probably not needed?
        return isfinite(maxwidth) ? maxwidth : zero(maxwidth)
    end

    register_computation!(
        graph,
        [:ticklabel_ideal_space, ticklabelspace],
        [:actual_ticklabelspace]
    ) do (idealspace, space), changed, cached
        actual_ticklabelspace = isnothing(cached) ? 0.0f0 : cached[1]
        if space == automatic
            return (idealspace,)
        elseif space isa Symbol
            space === :max_auto || error("Invalid ticklabel space $(repr(space)), may be automatic, :max_auto or a real number")
            return (max(idealspace, actual_ticklabelspace),)
        else
            return (space,)
        end
    end

    map!(
        graph,
        [labelrotation, :horizontal, flip_vertical_label],
        :labelrot
    ) do labelrotation, horizontal::Bool, flip_vertical_label::Bool
        return if labelrotation isa Automatic
            if horizontal
                0.0f0
            else
                (flip_vertical_label ? -0.5f0 : 0.5f0) * π
            end
        else
            Float32(labelrotation)
        end::Float32
    end

    map!(
        graph,
        [labelrotation, :horizontal, flipped, flip_vertical_label],
        :labelalign
    ) do labelrotation, horizontal::Bool, flipped::Bool, flip_vertical_label::Bool
        return if labelrotation isa Automatic
            if horizontal
                (:center, flipped ? :bottom : :top)
            else
                (
                    :center, if flipped
                        flip_vertical_label ? :bottom : :top
                    else
                        flip_vertical_label ? :top : :bottom
                    end,
                )
            end
        else
            (:center, :center)
        end::NTuple{2, Symbol}
    end

    map!(
        graph,
        [spinewidth, :tickspace, ticklabelsvisible, :actual_ticklabelspace, ticklabelpad, labelpadding],
        :labelgap
    ) do spinewidth, tickspace, ticklabelsvisible, actual_ticklabelspace, ticklabelpad, labelpadding

        return spinewidth + tickspace +
            (ticklabelsvisible ? actual_ticklabelspace + ticklabelpad : 0.0f0) +
            labelpadding
    end

    map!(
        graph,
        [:position, :extents, :horizontal, flipped, :labelgap],
        :labelpos
    ) do position, extents, horizontal, flipped, labelgap
        # fullgap = tickspace[] + labelgap
        middle = extents[1] + 0.5f0 * (extents[2] - extents[1])

        x_or_y = flipped ? position + labelgap : position - labelgap

        return horizontal ? Point2f(middle, x_or_y) : Point2f(x_or_y, middle)
    end

    # label + dim convert suffix
    map!(
        build_label_with_unit_suffix, graph,
        [dim_convert, suffix_formatter, label, unit_in_label, use_short_unit],
        :label_with_suffix
    )
    ComputePipeline.set_type!(graph.label_with_suffix, Any)

    labeltext = text!(
        parent, graph.labelpos, text = graph.label_with_suffix,
        fontsize = labelsize, color = labelcolor,
        visible = labelvisible,
        align = graph.labelalign, rotation = graph.labelrot, font = labelfont,
        markerspace = :data, inspectable = false
    )

    _labelbbox = register_raw_string_boundingboxes!(labeltext)
    map!(bbs -> Rect2d(bbs[1]), graph, _labelbbox, :labelbbox)

    # translate axis labels on explicit rotations
    # in order to prevent plot and axis overlap
    onany(
        parent, labelrotation, flipped, graph.horizontal, graph.labelbbox, update = true
    ) do labelrotation, flipped, horizontal, bb
        xs::Float32, ys::Float32 = if labelrotation isa Automatic
            0.0f0, 0.0f0
        else
            wx, wy = widths(bb)
            sign::Int = flipped ? 1 : -1
            if horizontal
                0.0f0, Float32(sign * 0.5f0 * wy)
            else
                Float32(sign * 0.5f0 * wx), 0.0f0
            end
        end
        translate!(labeltext, xs, ys, 0.0f0)
    end

    decorations[:labeltext] = labeltext

    ######################################
    ### Protrusions
    ######################################

    map!(
        graph,
        [labelvisible, :label_with_suffix, :labelbbox, labelpadding, :horizontal],
        :protrusion_labelspace
    ) do visible, label, bbox, labelpadding, horizontal
        label_is_empty = iswhitespace(label)
        if label_is_empty || !visible
            return 0.0f0
        else
            real_labelsize = widths(bbox)[ifelse(horizontal, 2, 1)]
            return real_labelsize + labelpadding
        end
    end

    map!(
        graph,
        [ticklabelsvisible, :ticklabel_position, :tickspace],
        :protrusion_tickspace
    ) do visible, positions, tickspace
        return (visible && !isempty(positions)) ? tickspace : 0.0f0
    end

    map!(
        graph,
        [ticklabelsvisible, :actual_ticklabelspace, ticklabelpad],
        :protrusion_ticklabelgap
    ) do visible, ticklabelspace, pad
        needs_gap = (visible && ticklabelspace > 0)
        return needs_gap ? ticklabelspace + pad : 0.0f0
    end

    map!(
        +, graph,
        [:protrusion_labelspace, :protrusion_tickspace, :protrusion_ticklabelgap],
        :protrusion
    )

    return LineAxis(parent, attrs, graph, decorations)
end

function tight_ticklabel_spacing!(la::LineAxis)

    horizontal = if la.attributes.endpoints[][1][2] == la.attributes.endpoints[][2][2]
        true
    elseif la.attributes.endpoints[][1][1] == la.attributes.endpoints[][2][1]
        false
    else
        error("endpoints not on a horizontal or vertical line")
    end

    tls = la.elements[:ticklabels]
    maxwidth = if horizontal
        # height
        tls.visible[] ? height(Rect2f(boundingbox(tls, :data))) : 0.0f0
    else
        # width
        tls.visible[] ? width(Rect2f(boundingbox(tls, :data))) : 0.0f0
    end
    la.attributes.ticklabelspace = maxwidth
    return Float64(maxwidth)
end


iswhitespace(str) = match(r"^\s*$", str) !== nothing

function Base.delete!(la::LineAxis)
    for (_, d) in la.elements
        if d isa AbstractPlot
            delete!(d.parent, d)
        else
            delete!(d)
        end
    end
    return
end

"""
    get_ticks(ticks, scale, formatter, vmin, vmax)

Base function that calls `get_tickvalues(ticks, scale, vmin, max)` and
`get_ticklabels(formatter, tickvalues)` and returns a tuple
`(tickvalues, ticklabels)`.
For custom ticks / formatter combinations, this method can be overloaded
directly, or both `get_tickvalues` and `get_ticklabels` separately.
"""
function get_ticks(ticks, scale, formatter, vmin, vmax)
    tickvalues = get_tickvalues(ticks, scale, vmin, vmax)
    ticklabels = get_ticklabels(formatter, tickvalues)
    return tickvalues, ticklabels
end

# automatic with identity scaling uses WilkinsonTicks by default
get_tickvalues(::Automatic, ::typeof(identity), vmin, vmax) = get_tickvalues(WilkinsonTicks(5, k_min = 3), vmin, vmax)

# fall back to identity if not overloaded scale function is used with automatic
get_tickvalues(::Automatic, _, vmin, vmax) = get_tickvalues(automatic, identity, vmin, vmax)

# fall back to non-scale aware behavior if no special version is overloaded
get_tickvalues(ticks, _, vmin, vmax) = get_tickvalues(ticks, vmin, vmax)

function get_ticks(ticks_and_labels::Tuple{Any, Any}, _, ::Automatic, vmin, vmax)
    n1 = length(ticks_and_labels[1])
    n2 = length(ticks_and_labels[2])
    if n1 != n2
        error("There are $n1 tick values in $(ticks_and_labels[1]) but $n2 tick labels in $(ticks_and_labels[2]).")
    end
    return ticks_and_labels
end

function get_ticks(tickfunction::Function, _, formatter, vmin, vmax)
    result = tickfunction(vmin, vmax)
    if result isa Tuple{Any, Any}
        tickvalues, ticklabels = result
    else
        tickvalues = result
        ticklabels = get_ticklabels(formatter, tickvalues)
    end
    return tickvalues, ticklabels
end

_logbase(::typeof(log10)) = "10"
_logbase(::typeof(pseudolog10)) = "10"
_logbase(::typeof(log2)) = "2"
_logbase(::typeof(log)) = "e"

function get_ticks(::Automatic, scale::LogFunctions, any_formatter, vmin, vmax)
    ticks = LogTicks(WilkinsonTicks(5, k_min = 3))
    return get_ticks(ticks, scale, any_formatter, vmin, vmax)
end

# log ticks just use the normal pipeline but with log'd limits, then transform the labels
function get_ticks(l::LogTicks, scale::Union{LogFunctions, typeof(pseudolog10)}, ::Automatic, vmin, vmax)
    ticks_scaled = get_tickvalues(l.linear_ticks, identity, scale(vmin), scale(vmax))

    ticks = Makie.inverse_transform(scale).(ticks_scaled)

    labels_scaled = get_ticklabels(
        # avoid unicode superscripts in ticks, as the ticks are converted
        # to superscripts in the next step
        xs -> Showoff.showoff(xs, :plain),
        ticks_scaled
    )

    prefix = ifelse.(ticks .< 0, MINUS_SIGN, "") # only useful for pseudolog10
    labels = rich.(prefix, _logbase(scale), superscript.(replace.(labels_scaled, "-" => MINUS_SIGN), offset = Vec2f(0.1f0, 0.0f0)))

    return ticks, labels
end

logit_10(x) = Makie.logit(x) / log(10)
expit_10(x) = Makie.logistic(log(10) * x)

"""
    get_tickvalues(lt::LinearTicks, vmin, vmax)

Runs a common tick finding algorithm to as many ticks as requested by the
`LinearTicks` instance.
"""
get_tickvalues(lt::LinearTicks, vmin, vmax) = locateticks(vmin, vmax, lt.n_ideal)


"""
    get_tickvalues(tickvalues, vmin, vmax)

Convert tickvalues to a float array by default.
"""
get_tickvalues(tickvalues, vmin, vmax) = convert(Vector{Float64}, tickvalues)


# function get_tickvalues(l::LogitTicks, vmin, vmax)
#     ticks_scaled = get_tickvalues(l.linear_ticks, identity, logit_10(vmin), logit_10(vmax))
#     expit_10.(ticks_scaled)
# end

function get_tickvalues(l::LogTicks, scale, vmin, vmax)
    ticks_scaled = get_tickvalues(l.linear_ticks, scale(vmin), scale(vmax))
    return Makie.inverse_transform(scale).(ticks_scaled)
end

"""
    get_ticklabels(::Automatic, values)

Gets tick labels by applying `showoff_minus` to `values`.
"""
get_ticklabels(::Automatic, values) = showoff_minus(values)

"""
    get_ticklabels(formatfunction::Function, values)

Gets tick labels by applying `formatfunction` to `values`.
"""
get_ticklabels(formatfunction::Function, values) = formatfunction(values)

"""
    get_ticklabels(formatstring::AbstractString, values)

Gets tick labels by formatting each value in `values` according to a `Format.format` format string.
"""
get_ticklabels(formatstring::AbstractString, values) = [Format.format(formatstring, v) for v in values]

function get_ticks(m::MultiplesTicks, any_scale, ::Automatic, vmin, vmax)
    dvmin = vmin / m.multiple
    dvmax = vmax / m.multiple
    multiples = Makie.get_tickvalues(LinearTicks(m.n_ideal), dvmin, dvmax)

    locs = multiples .* m.multiple
    labs = showoff_minus(multiples) .* m.suffix
    if m.strip_zero
        labs = map(((x, lab),) -> x != 0 ? lab : "0", zip(multiples, labs))
    end

    return locs, labs
end

function get_ticks(m::AngularTicks, any_scale, ::Automatic, vmin, vmax)
    dvmin = vmin
    dvmax = vmax
    delta = dvmax - dvmin

    # get proposed step from
    step = delta / max(2, mapreduce(v -> v[1] * delta + v[2], min, m.n_ideal))
    if delta ≥ 0.05 # ≈ 3°
        # rad values for (1, 2, 3, 5, 10, 15, 30, 45, 60, 90, 120) degrees
        ideal_step = 0.017453292519943295
        for option in (0.03490658503988659, 0.05235987755982989, 0.08726646259971647, 0.17453292519943295, 0.2617993877991494, 0.5235987755982988, 0.7853981633974483, 1.0471975511965976, 1.5707963267948966, 2.0943951023931953)
            if (step - option)^2 < (step - ideal_step)^2
                ideal_step = option
            end
        end

        ϵ = 1.0e-6
        vmin = ceil(Int, dvmin / ideal_step - ϵ) * ideal_step
        vmax = floor(Int, dvmax / ideal_step + ϵ) * ideal_step
        multiples = collect(vmin:ideal_step:(vmax + ϵ))
    else
        s = 360 / 2pi
        multiples = Makie.get_tickvalues(LinearTicks(3), s * dvmin, s * dvmax) ./ s
    end

    # We need to round this to avoid showoff giving us 179 for 179.99999999999997
    # We also need to be careful that we don't remove significant digits
    sigdigits = ceil(Int, log10(1000 * max(abs(vmin), abs(vmax)) / delta))

    return multiples, showoff_minus(round.(multiples .* m.label_factor, sigdigits = sigdigits)) .* m.suffix
end

# Replaces hyphens in negative numbers with the unicode MINUS_SIGN
function showoff_minus(x::AbstractVector)
    # TODO: don't use the `replace` workaround
    return replace.(Showoff.showoff(x), r"-(?=\d)" => MINUS_SIGN)
end

# identity or unsupported scales
function get_minor_tickvalues(i::IntervalsBetween, scale, tickvalues, vmin, vmax)
    vals = Float64[]
    length(tickvalues) < 2 && return vals
    n = i.n

    if i.mirror
        firstinterval = tickvalues[2] - tickvalues[1]
        stepsize = firstinterval / n
        v = tickvalues[1] - stepsize
        prepend!(vals, v:-stepsize:vmin)
    end

    for (lo, hi) in zip(@view(tickvalues[1:(end - 1)]), @view(tickvalues[2:end]))
        interval = hi - lo
        stepsize = interval / n
        v = lo
        for i in 1:(n - 1)
            v += stepsize
            push!(vals, v)
        end
    end

    if i.mirror
        lastinterval = tickvalues[end] - tickvalues[end - 1]
        stepsize = lastinterval / n
        v = tickvalues[end] + stepsize
        append!(vals, v:stepsize:vmax)
    end

    return vals
end

# for log scales, we need to step in log steps at the edges
function get_minor_tickvalues(i::IntervalsBetween, scale::LogFunctions, tickvalues, vmin, vmax)
    vals = Float64[]
    length(tickvalues) < 2 && return vals
    n = i.n

    invscale = Makie.inverse_transform(scale)

    if i.mirror
        firstinterval_scaled = scale(tickvalues[2]) - scale(tickvalues[1])
        stepsize = firstinterval_scaled / n
        prevtick = invscale(scale(tickvalues[1]) - firstinterval_scaled)
        stepsize = (tickvalues[1] - prevtick) / n
        v = tickvalues[1] - stepsize
        prepend!(vals, v:-stepsize:vmin)
    end

    for (lo, hi) in zip(@view(tickvalues[1:(end - 1)]), @view(tickvalues[2:end]))
        interval = hi - lo
        stepsize = interval / n
        v = lo
        for i in 1:(n - 1)
            v += stepsize
            push!(vals, v)
        end
    end

    if i.mirror
        lastinterval_scaled = scale(tickvalues[end]) - scale(tickvalues[end - 1])
        nexttick = invscale(scale(tickvalues[end]) + lastinterval_scaled)
        stepsize = (nexttick - tickvalues[end]) / n
        v = tickvalues[end] + stepsize
        append!(vals, v:stepsize:vmax)
    end

    return vals
end

function get_minor_tickvalues(v::AbstractVector{<:Real}, _, _, _, _)
    return Float32.(v)
end
