# the hyphen which is usually used to store negative number strings
# is shorter than the dedicated minus in most fonts, the minus glyph
# looks more balanced with numbers, especially in superscripts or subscripts
const MINUS_SIGN = "−" # == "\u2212" (Unicode minus)

function LineAxis(parent::Scene; @nospecialize(kwargs...))
    attrs = merge!(Attributes(kwargs), generic_plot_attributes(LineAxis))
    return LineAxis(parent, attrs)
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
        closure_args,
        ticksvisible::Bool, label, labelvisible::Bool, labelpadding::Number, tickspace::Number, ticklabelsvisible::Bool,
        actual_ticklabelspace::Number, ticklabelpad::Number, _...
    )

    horizontal, labeltext, ticklabel_annotation_obs = closure_args

    label_is_empty::Bool = iswhitespace(label)

    real_labelsize::Float32 = if label_is_empty
        0.0f0
    else
        boundingbox(labeltext, :data).widths[horizontal[] ? 2 : 1]
    end

    labelspace::Float32 = (labelvisible && !label_is_empty) ? real_labelsize + labelpadding : 0.0f0

    _tickspace::Float32 = (ticksvisible && !isempty(ticklabel_annotation_obs[])) ? tickspace : 0.0f0

    ticklabelgap::Float32 = (ticklabelsvisible && actual_ticklabelspace > 0) ? actual_ticklabelspace + ticklabelpad : 0.0f0

    return _tickspace + ticklabelgap + labelspace
end


function create_linepoints(
        pos_ext_hor,
        flipped::Bool, spine_width::Number, trimspine::Union{Bool, Tuple{Bool, Bool}}, tickpositions::Vector{Point2f}, tickwidth::Number
    )

    (position::Float32, extents::NTuple{2, Float32}, horizontal::Bool) = pos_ext_hor

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
    if al isa Automatic
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
        return al
    else
        error("Align needs to be a NTuple{2, Symbol}.")
    end
end

max_auto_ticklabel_spacing!(ax) = nothing


function update_ticklabel_node(
        closure_args,
        ticklabel_annotation_obs::Observable,
        labelgap::Number, flipped::Bool, tickpositions::Vector{Point2f}, tickstrings
    )
    # tickspace is always updated before labelgap
    # tickpositions are always updated before tickstrings
    # so we don't need to lift those

    horizontal, spinewidth, tickspace, ticklabelpad, tickvalues = closure_args

    nticks = length(tickvalues[])

    ticklabelgap::Float32 = spinewidth[] + tickspace[] + ticklabelpad[]

    shift = if horizontal[]
        Point2f(0.0f0, flipped ? ticklabelgap : -ticklabelgap)
    else
        Point2f(flipped ? ticklabelgap : -ticklabelgap, 0.0f0)
    end
    # reuse already allocated array
    result = ticklabel_annotation_obs[]
    empty!(result)
    for i in 1:min(length(tickstrings), length(tickpositions))
        pos = tickpositions[i]
        str = tickstrings[i]
        push!(result, (str, pos .+ shift))
    end
    # notify of the changes
    notify(ticklabel_annotation_obs)
    return
end

function update_tick_obs(tick_obs, horizontal::Observable{Bool}, flipped::Observable{Bool}, tickpositions, tickalign, ticksize, spinewidth)
    result = tick_obs[]
    empty!(result) # reuse allocated array
    sign::Int = flipped[] ? -1 : 1
    if horizontal[]
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
    notify(tick_obs)
    return
end

# if labels are given manually, it's possible that some of them are outside the displayed limits
# we only check approximately because we want to keep ticks on the frame
is_within_limits(tv, limits) = (limits[1] - 100eps(limits[1]) < tv) && (tv < limits[2] + 100eps(limits[2]))

function update_tickpos_string(closure_args, tickvalues_labels_unfiltered, reversed::Bool, scale)

    tickstrings, tickpositions, tickvalues, pos_extents_horizontal, limits_obs = closure_args
    limits = limits_obs[]::NTuple{2, Float64}

    tickvalues_unfiltered, tickstrings_unfiltered = tickvalues_labels_unfiltered

    position::Float32, extents_uncorrected::NTuple{2, Float32}, horizontal::Bool = pos_extents_horizontal[]

    extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

    px_o = extents[1]
    px_width = extents[2] - extents[1]

    lim_o = limits[1]
    lim_w = limits[2] - limits[1]

    i_values_within_limits = findall(tv -> is_within_limits(tv, limits), tickvalues_unfiltered)

    tickvalues[] = tickvalues_unfiltered[i_values_within_limits]

    tickvalues_scaled = scale.(tickvalues[])

    tick_fractions = (tickvalues_scaled .- scale(limits[1])) ./ (scale(limits[2]) - scale(limits[1]))

    tick_scenecoords = px_o .+ px_width .* tick_fractions

    tickpos = if horizontal
        [Point2f(x, position) for x in tick_scenecoords]
    else
        [Point2f(position, y) for y in tick_scenecoords]
    end

    # now trigger updates
    tickpositions[] = tickpos
    tickstrings[] = tickstrings_unfiltered[i_values_within_limits]
    return
end

function update_minor_ticks(minortickpositions, limits::NTuple{2, Float64}, pos_extents_horizontal, minortickvalues_unfiltered, scale, reversed::Bool)
    position::Float32, extents_uncorrected::NTuple{2, Float32}, horizontal::Bool = pos_extents_horizontal

    extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

    px_o = extents[1]
    px_width = extents[2] - extents[1]

    minortickvalues = filter(tv -> is_within_limits(tv, limits), minortickvalues_unfiltered)

    tickvalues_scaled = scale.(minortickvalues)

    tick_fractions = (tickvalues_scaled .- scale(limits[1])) ./ (scale(limits[2]) - scale(limits[1]))

    tick_scenecoords = px_o .+ px_width .* tick_fractions

    minortickpositions[] = if horizontal
        [Point2f(x, position) for x in tick_scenecoords]
    else
        [Point2f(position, y) for y in tick_scenecoords]
    end

    return
end

function LineAxis(parent::Scene, attrs::Attributes)
    decorations = Dict{Symbol, Any}()

    @extract attrs (
        endpoints, ticksize, tickwidth,
        tickcolor, tickalign, dim_convert, ticks, tickformat, ticklabelalign, ticklabelrotation, ticksvisible,
        ticklabelspace, ticklabelpad, labelpadding,
        ticklabelsize, ticklabelsvisible, spinewidth, spinecolor, label, labelsize, labelcolor,
        labelfont, ticklabelfont, ticklabelcolor,
        labelrotation, labelvisible, spinevisible, trimspine, flip_vertical_label, reversed,
        minorticksvisible, minortickalign, minorticksize, minortickwidth, minortickcolor, minorticks,
    )
    minorticksused = get(attrs, :minorticksused, Observable(false))

    pos_extents_horizontal = lift(calculate_horizontal_extends, parent, endpoints; ignore_equal_values = true)
    horizontal = lift(x -> x[3], parent, pos_extents_horizontal)
    # Tuple constructor converts more than `convert(NTuple{2, Float32}, x)` but we still need the conversion to Float32 tuple:
    limits = lift(x -> convert(NTuple{2, Float64}, Tuple(x)), parent, attrs.limits; ignore_equal_values = true)
    flipped = lift(x -> convert(Bool, x), parent, attrs.flipped; ignore_equal_values = true)

    ticksnode = Observable(Point2f[]; ignore_equal_values = true)
    ticklines = linesegments!(
        parent, ticksnode, linewidth = tickwidth, color = tickcolor, linestyle = nothing,
        visible = ticksvisible, inspectable = false
    )
    decorations[:ticklines] = ticklines
    translate!(ticklines, 0, 0, 10)

    minorticksnode = Observable(Point2f[]; ignore_equal_values = true)
    minorticklines = linesegments!(
        parent, minorticksnode, linewidth = minortickwidth, color = minortickcolor,
        linestyle = nothing, visible = minorticksvisible, inspectable = false
    )
    decorations[:minorticklines] = minorticklines
    translate!(minorticklines, 0, 0, 10)

    realticklabelalign = Observable{Tuple{Symbol, Symbol}}((:none, :none); ignore_equal_values = true)

    map!(
        calculate_real_ticklabel_align, parent, realticklabelalign, ticklabelalign, horizontal, flipped,
        ticklabelrotation
    )

    ticklabel_annotation_obs = Observable(Tuple{Any, Point2f}[]; ignore_equal_values = true)
    ticklabels = nothing # this gets overwritten later to be used in the below
    ticklabel_ideal_space = Observable(0.0f0; ignore_equal_values = true)

    map!(parent, ticklabel_ideal_space, ticklabel_annotation_obs, ticklabelalign, ticklabelrotation, ticklabelfont, ticklabelsvisible) do args...
        maxwidth = if pos_extents_horizontal[][3]
            # height
            ticklabelsvisible[] ? (ticklabels === nothing ? 0.0f0 : height(Rect2f(boundingbox(ticklabels, :data)))) : 0.0f0
        else
            # width
            ticklabelsvisible[] ? (ticklabels === nothing ? 0.0f0 : width(Rect2f(boundingbox(ticklabels, :data)))) : 0.0f0
        end
        # in case there is no string in the annotations and the boundingbox comes back all NaN
        if !isfinite(maxwidth)
            maxwidth = zero(maxwidth)
        end
        return maxwidth
    end

    attrs[:actual_ticklabelspace] = 0.0f0
    actual_ticklabelspace = attrs[:actual_ticklabelspace]

    onany(parent, ticklabel_ideal_space, ticklabelspace) do idealspace, space
        s = if space == automatic
            idealspace
        elseif space isa Symbol
            space === :max_auto || error("Invalid ticklabel space $(repr(space)), may be automatic, :max_auto or a real number")
            max(idealspace, actual_ticklabelspace[])
        else
            space
        end
        if s != actual_ticklabelspace[]
            actual_ticklabelspace[] = s
        end
    end

    tickspace = Observable(0.0f0; ignore_equal_values = true)
    map!(parent, tickspace, ticksvisible, ticksize, tickalign) do ticksvisible, ticksize, tickalign
        ticksvisible ? max(0.0f0, ticksize * (1.0f0 - tickalign)) : 0.0f0
    end

    labelgap = Observable(0.0f0; ignore_equal_values = true)
    map!(
        parent, labelgap, spinewidth, tickspace, ticklabelsvisible, actual_ticklabelspace,
        ticklabelpad, labelpadding
    ) do spinewidth, tickspace, ticklabelsvisible,
            actual_ticklabelspace, ticklabelpad, labelpadding

        return spinewidth + tickspace +
            (ticklabelsvisible ? actual_ticklabelspace + ticklabelpad : 0.0f0) +
            labelpadding
    end

    labelpos = Observable(Point2f(NaN); ignore_equal_values = true)

    map!(
        parent, labelpos, pos_extents_horizontal, flipped,
        labelgap
    ) do (position, extents, horizontal), flipped, labelgap
        # fullgap = tickspace[] + labelgap
        middle = extents[1] + 0.5f0 * (extents[2] - extents[1])

        x_or_y = flipped ? position + labelgap : position - labelgap

        return horizontal ? Point2f(middle, x_or_y) : Point2f(x_or_y, middle)
    end

    # Initial values should be overwritten by map!. `ignore_equal_values` doesn't work right now without initial values
    labelalign = Observable((:none, :none); ignore_equal_values = true)
    map!(
        parent, labelalign, labelrotation, horizontal, flipped,
        flip_vertical_label
    ) do labelrotation,
            horizontal::Bool, flipped::Bool, flip_vertical_label::Bool
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

    labelrot = Observable(0.0f0; ignore_equal_values = true)
    map!(
        parent, labelrot, labelrotation, horizontal,
        flip_vertical_label
    ) do labelrotation,
            horizontal::Bool, flip_vertical_label::Bool
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

    labeltext = text!(
        parent, labelpos, text = label, fontsize = labelsize, color = labelcolor,
        visible = labelvisible,
        align = labelalign, rotation = labelrot, font = labelfont,
        markerspace = :data, inspectable = false
    )

    # translate axis labels on explicit rotations
    # in order to prevent plot and axis overlap
    onany(parent, labelrotation, flipped, horizontal) do labelrotation, flipped, horizontal
        xs::Float32, ys::Float32 = if labelrotation isa Automatic
            0.0f0, 0.0f0
        else
            wx, wy = widths(boundingbox(labeltext, :data))
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

    tickvalues = Observable(Float64[]; ignore_equal_values = true)

    tickvalues_labels_unfiltered = Observable{Tuple{Vector{Float64}, Vector{Any}}}()
    obs = needs_tick_update_observable(dim_convert) # make sure we update tick calculation when needed
    map!(
        parent, tickvalues_labels_unfiltered, pos_extents_horizontal, obs, limits, ticks, tickformat,
        attrs.scale
    ) do (position, extents, horizontal), _, limits, ticks, tickformat, scale
        return get_ticks(dim_convert[], ticks, scale, tickformat, limits...)
    end

    tickpositions = Observable(Point2f[]; ignore_equal_values = true)
    tickstrings = Observable(Any[]; ignore_equal_values = true)

    onany(
        update_tickpos_string, parent,
        Observable((tickstrings, tickpositions, tickvalues, pos_extents_horizontal, limits)),
        tickvalues_labels_unfiltered, reversed, attrs.scale
    )

    minortickvalues = Observable(Float64[]; ignore_equal_values = true)
    minortickpositions = Observable(Point2f[]; ignore_equal_values = true)

    onany(parent, tickvalues, minorticks, minorticksvisible, minorticksused) do tickvalues, minorticks, visible, used
        if visible || used
            minortickvalues[] = get_minor_tickvalues(minorticks, attrs.scale[], tickvalues, limits[]...)
        end
        return
    end

    onany(parent, minortickvalues, limits, pos_extents_horizontal) do mtv, limits, peh
        update_minor_ticks(minortickpositions, limits, peh, mtv, attrs.scale[], reversed[])
    end

    onany(
        update_tick_obs, parent,
        Observable(minorticksnode), Observable(horizontal), Observable(flipped),
        minortickpositions, minortickalign, minorticksize, spinewidth
    )

    onany(
        update_ticklabel_node, parent,
        # we don't want to update on these, so we wrap them in an observable:
        Observable((horizontal, spinewidth, tickspace, ticklabelpad, tickvalues)),
        Observable(ticklabel_annotation_obs),
        labelgap, flipped, tickpositions, tickstrings
    )

    onany(
        update_tick_obs, parent,
        Observable(ticksnode), Observable(horizontal), Observable(flipped),
        tickpositions, tickalign, ticksize, spinewidth
    )

    linepoints = lift(
        create_linepoints, parent, pos_extents_horizontal, flipped, spinewidth, trimspine,
        tickpositions, tickwidth
    )

    decorations[:axisline] = linesegments!(
        parent, linepoints, linewidth = spinewidth, visible = spinevisible,
        color = spinecolor, inspectable = false, linestyle = nothing
    )

    translate!(decorations[:axisline], 0, 0, 20)

    protrusion = Observable(0.0f0; ignore_equal_values = true)

    map!(
        calculate_protrusion, parent, protrusion,
        # we pass these as observables, to not trigger on them
        Observable((horizontal, labeltext, ticklabel_annotation_obs)),
        ticksvisible, label, labelvisible, labelpadding, tickspace, ticklabelsvisible, actual_ticklabelspace, ticklabelpad,
        # we don't need these as arguments to calculate it, but we need to pass it because it indirectly influences the protrusion
        labelfont, labelalign, labelrot, labelsize, ticklabelfont, tickalign
    )

    # trigger whole pipeline once to fill tickpositions and tickstrings
    # etc to avoid empty ticks bug #69
    notify(limits)

    # in order to dispatch to the correct text recipe later (normal text, latex, etc.)
    # we need to have the ticklabel_annotation_obs populated once before adding the annotations
    ticklabels = text!(
        parent,
        ticklabel_annotation_obs,
        align = realticklabelalign,
        rotation = ticklabelrotation,
        fontsize = ticklabelsize,
        font = ticklabelfont,
        color = ticklabelcolor,
        visible = ticklabelsvisible,
        markerspace = :data,
        inspectable = false
    )

    decorations[:ticklabels] = ticklabels

    # HACKY: the ticklabels in the string need to be updated
    # before other stuff is triggered by them, which accesses the
    # ticklabel boundingbox (which needs to be updated already)
    # so we move the new listener from text! to the front

    pushfirst!(ticklabel_annotation_obs.listeners, pop!(ticklabel_annotation_obs.listeners))

    # trigger calculation of ticklabel width once, now that it's not nothing anymore
    notify(ticklabelsvisible)

    return LineAxis(parent, protrusion, attrs, decorations, tickpositions, tickvalues, tickstrings, minortickpositions, minortickvalues)
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
