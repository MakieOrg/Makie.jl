function LineAxis(parent::Scene; @nospecialize(kwargs...))
    attrs = merge!(Attributes(kwargs), default_attributes(LineAxis))
    return LineAxis(parent, attrs)
end

function calcualte_horizontal_extends(endpoints)::Tuple{Float32, NTuple{2, Float32}, Bool}
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
        actual_ticklabelspace::Number, ticklabelpad::Number, _, _, _, _)

    pos_extents_horizontal, labeltext, ticklabel_annotation_obs = closure_args

    position, extents, horizontal = pos_extents_horizontal[]

    local label_is_empty::Bool = iswhitespace(label) || isempty(label)

    local real_labelsize::Float32 = if label_is_empty
        0f0
    else
        horizontal ? boundingbox(labeltext).widths[2] : boundingbox(labeltext).widths[1]
    end

    local labelspace::Float32 = (labelvisible && !label_is_empty) ? real_labelsize + labelpadding : 0f0

    local _tickspace::Float32 = (ticksvisible && !isempty(ticklabel_annotation_obs[])) ? tickspace : 0f0

    local ticklabelgap::Float32 = (ticklabelsvisible && actual_ticklabelspace > 0) ? actual_ticklabelspace + ticklabelpad : 0f0

    return _tickspace + ticklabelgap + labelspace
end


function create_linepoints(
        pos_ext_hor,
        flipped::Bool, spine_width::Number, trimspine::Bool, tickpositions::Vector{Point2f}, tickwidth::Number)

    (position::Float32, extents::Tuple{Float32, Float32}, horizontal::Bool) = pos_ext_hor

    if !trimspine || length(tickpositions) < 2
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
        pstart = horizontal ? Point2f(-0.5f0 * tickwidth, 0) : Point2f(0, -0.5f0 * tickwidth)
        pend = horizontal ? Point2f(0.5f0 * tickwidth, 0) : Point2f(0, 0.5f0 * tickwidth)
        return [tickpositions[1] .+ pstart, tickpositions[end] .+ pend]
    end
end

function calculate_real_ticklabel_align(al, pos_ext_hor, fl::Bool, rot::Number)
    local hor::Bool = pos_ext_hor[3]
    if al isa Automatic
        if rot == 0 || !(rot isa Real)
            if hor
                (:center, fl ? :bottom : :top)
            else
                (fl ? :left : :right, :center)
            end
        elseif rot ≈ pi/2
            if hor
                (fl ? :left : :right, :center)
            else
                (:center, fl ? :top : :bottom)
            end
        elseif rot ≈ -pi/2
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
    elseif al isa Tuple{Symbol, Symbol}
        return al
    else
        error("Align needs to be a Tuple{Symbol, Symbol}.")
    end
end

function update_ticklabel_node(
        closure_args,
        ticklabel_annotation_obs::Observable,
        labelgap::Number, flipped::Bool, tickpositions::Vector{Point2f}, tickstrings)
    # tickspace is always updated before labelgap
    # tickpositions are always updated before tickstrings
    # so we don't need to lift those

    pos_extents_horizontal, spinewidth, tickspace, ticklabelpad, tickvalues = closure_args

    horizontal = pos_extents_horizontal[][3]::Bool

    nticks = length(tickvalues[])

    local ticklabelgap::Float32 = spinewidth[] + tickspace[] + ticklabelpad[]

    shift = if horizontal
        Point2f(0f0, flipped ? ticklabelgap : -ticklabelgap)
    else
        Point2f(flipped ? ticklabelgap : -ticklabelgap, 0f0)
    end
    # re-use already allocated array
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

function update_tick_obs(tick_obs, pos_extents_horizontal, flipped::Observable{Bool}, tickpositions, tickalign, ticksize, spinewidth)
    horizontal = pos_extents_horizontal[][3]::Bool
    result = tick_obs[]
    empty!(result) # re-use allocated array
    if horizontal
        for tp in tickpositions
            tstart = tp + (flipped[] ? -1f0 : 1f0) * Point2f(0f0, tickalign * ticksize - 0.5f0 * spinewidth)
            tend = tstart + (flipped[] ? -1f0 : 1f0) * Point2f(0f0, -ticksize)
            push!(result, tstart, tend)
        end
    else
        for tp in tickpositions
            tstart = tp + (flipped[] ? -1f0 : 1f0) * Point2f(tickalign * ticksize - 0.5f0 * spinewidth, 0f0)
            tend = tstart + (flipped[] ? -1f0 : 1f0) * Point2f(-ticksize, 0f0)
            push!(result, tstart, tend)
        end
    end
    notify(tick_obs)
    return
end

function update_tickpos_string(closure_args, tickvalues_labels_unfiltered, reversed::Bool, scale)

    tickstrings, tickpositions, tickvalues, pos_extents_horizontal, limits_obs = closure_args
    limits = limits_obs[]::Tuple{Float32, Float32}

    tickvalues_unfiltered, tickstrings_unfiltered = tickvalues_labels_unfiltered

    position::Float32, extents_uncorrected::NTuple{2, Float32}, horizontal::Bool = pos_extents_horizontal[]

    extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

    px_o = extents[1]
    px_width = extents[2] - extents[1]

    lim_o = limits[1]
    lim_w = limits[2] - limits[1]

    # if labels are given manually, it's possible that some of them are outside the displayed limits
    # we only check approximately because otherwise because of floating point errors, ticks can be dismissed sometimes
    i_values_within_limits = findall(tickvalues_unfiltered) do tv
        return (limits[1] <= tv || limits[1] ≈ tv) &&
                (tv <= limits[2] || tv ≈ limits[2])
    end

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

function update_minor_ticks(minortickpositions, limits_obs, pos_extents_horizontal, minortickvalues, scale, reversed::Bool)

    limits = limits_obs[]::Tuple{Float32, Float32}

    position::Float32, extents_uncorrected::NTuple{2, Float32}, horizontal::Bool = pos_extents_horizontal[]

    extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

    px_o = extents[1]
    px_width = extents[2] - extents[1]

    lim_o = limits[1]
    lim_w = limits[2] - limits[1]

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

    @extract attrs (endpoints, ticksize, tickwidth,
        tickcolor, tickalign, ticks, tickformat, ticklabelalign, ticklabelrotation, ticksvisible,
        ticklabelspace, ticklabelpad, labelpadding,
        ticklabelsize, ticklabelsvisible, spinewidth, spinecolor, label, labelsize, labelcolor,
        labelfont, ticklabelfont, ticklabelcolor,
        labelvisible, spinevisible, trimspine, flip_vertical_label, reversed,
        minorticksvisible, minortickalign, minorticksize, minortickwidth, minortickcolor, minorticks)

    pos_extents_horizontal = lift(calcualte_horizontal_extends, endpoints; ignore_equal_values=true)

    limits = lift(x-> convert(Tuple{Float32, Float32}, x), attrs.limits; ignore_equal_values=true)
    flipped = lift(x-> convert(Bool, x), attrs.flipped; ignore_equal_values=true)

    ticksnode = Observable(Point2f[]; ignore_equal_values=true)
    ticklines = linesegments!(
        parent, ticksnode, linewidth = tickwidth, color = tickcolor, linestyle = nothing,
        visible = ticksvisible, inspectable = false
    )
    decorations[:ticklines] = ticklines
    translate!(ticklines, 0, 0, 10)

    minorticksnode = Observable(Point2f[]; ignore_equal_values=true)
    minorticklines = linesegments!(
        parent, minorticksnode, linewidth = minortickwidth, color = minortickcolor,
        linestyle = nothing, visible = minorticksvisible, inspectable = false
    )
    decorations[:minorticklines] = minorticklines

    realticklabelalign = Observable{Tuple{Symbol, Symbol}}((:none, :none); ignore_equal_values=true)

    map!(calculate_real_ticklabel_align, realticklabelalign, ticklabelalign, pos_extents_horizontal, flipped, ticklabelrotation)

    ticklabel_annotation_obs = Observable(Tuple{AbstractString, Point2f}[]; ignore_equal_values=true)
    ticklabels = nothing # this gets overwritten later to be used in the below
    ticklabel_ideal_space = Observable(0f0; ignore_equal_values=true)

    map!(ticklabel_ideal_space, ticklabel_annotation_obs, ticklabelalign, ticklabelrotation, ticklabelfont, ticklabelsvisible) do args...
        maxwidth = if pos_extents_horizontal[][3]
                # height
                ticklabelsvisible[] ? (ticklabels === nothing ? 0f0 : height(Rect2f(boundingbox(ticklabels)))) : 0f0
            else
                # width
                ticklabelsvisible[] ? (ticklabels === nothing ? 0f0 : width(Rect2f(boundingbox(ticklabels)))) : 0f0
        end
        # in case there is no string in the annotations and the boundingbox comes back all NaN
        if !isfinite(maxwidth)
            maxwidth = zero(maxwidth)
        end
        return maxwidth
    end

    attrs[:actual_ticklabelspace] = 0f0
    actual_ticklabelspace = attrs[:actual_ticklabelspace]

    onany(ticklabel_ideal_space, ticklabelspace) do idealspace, space
        s = if space == automatic
            idealspace
        else
            space
        end
        if s != actual_ticklabelspace[]
            actual_ticklabelspace[] = s
        end
    end

    tickspace = Observable(0f0; ignore_equal_values=true)
    map!(tickspace, ticksvisible, ticksize, tickalign) do ticksvisible,
            ticksize, tickalign

        ticksvisible ? max(0f0, ticksize * (1f0 - tickalign)) : 0f0
    end

    labelgap = Observable(0f0; ignore_equal_values=true)
    map!(labelgap, spinewidth, tickspace, ticklabelsvisible, actual_ticklabelspace,
        ticklabelpad, labelpadding) do spinewidth, tickspace, ticklabelsvisible,
            actual_ticklabelspace, ticklabelpad, labelpadding

        return spinewidth + tickspace +
            (ticklabelsvisible ? actual_ticklabelspace + ticklabelpad : 0f0) +
            labelpadding
    end

    labelpos = Observable(Point2f(NaN); ignore_equal_values=true)
    map!(labelpos, pos_extents_horizontal, flipped, labelgap) do (position, extents, horizontal), flipped, labelgap
        # fullgap = tickspace[] + labelgap
        middle = extents[1] + 0.5f0 * (extents[2] - extents[1])

        x_or_y = flipped ? position + labelgap : position - labelgap

        if horizontal
            return Point2f(middle, x_or_y)
        else
            return Point2f(x_or_y, middle)
        end
    end
    # Initial values should be overwritten by map!. `ignore_equal_values` doesn't work right now without initial values
    labelalign = Observable((:none, :none); ignore_equal_values=true)

    map!(labelalign, pos_extents_horizontal, flipped, flip_vertical_label) do (position, extents, horizontal), flipped, flip_vertical_label
        if horizontal
            return (:center, flipped ? :bottom : :top)
        else
            return (:center, if flipped
                    flip_vertical_label ? :bottom : :top
                else
                    flip_vertical_label ? :top : :bottom
                end
            )
        end
    end

    labelrotation = Observable(0f0; ignore_equal_values=true)
    map!(labelrotation, pos_extents_horizontal, flip_vertical_label) do (position, extents, horizontal), flip_vertical_label::Bool
        if horizontal
            return 0f0
        else
            if flip_vertical_label
                return Float32(-0.5pi)
            else
                return Float32(0.5pi)
            end
        end
    end

    labeltext = text!(
        parent, label, textsize = labelsize, color = labelcolor,
        position = labelpos, visible = labelvisible,
        align = labelalign, rotation = labelrotation, font = labelfont,
        markerspace = :data, inspectable = false
    )

    decorations[:labeltext] = labeltext

    tickvalues = Observable(Float32[]; ignore_equal_values=true)

    tickvalues_labels_unfiltered = lift(pos_extents_horizontal, limits, ticks, tickformat, attrs.scale) do (position, extents, horizontal),
            limits, ticks, tickformat, scale
        get_ticks(ticks, scale, tickformat, limits...)
    end

    tickpositions = Observable(Point2f[]; ignore_equal_values=true)
    tickstrings = Observable(AbstractString[]; ignore_equal_values=true)

    onany(update_tickpos_string,
        Observable((tickstrings, tickpositions, tickvalues, pos_extents_horizontal, limits)),
        tickvalues_labels_unfiltered, reversed, attrs.scale)

    minortickvalues = Observable(Float32[]; ignore_equal_values=true)
    minortickpositions = Observable(Point2f[]; ignore_equal_values=true)

    onany(tickvalues, minorticks) do tickvalues, minorticks
        minortickvalues[] = get_minor_tickvalues(minorticks, attrs.scale[], tickvalues, limits[]...)
        return
    end

    on(minortickvalues) do mtv
        update_minor_ticks(minortickpositions, limits, pos_extents_horizontal, mtv, attrs.scale[], reversed[])
    end

    onany(update_tick_obs,
        Observable(minorticksnode), Observable(pos_extents_horizontal), Observable(flipped),
        minortickpositions, minortickalign, minorticksize, spinewidth)

    onany(update_ticklabel_node,
        # we don't want to update on these, so we wrap them in an observable:
        Observable((pos_extents_horizontal, spinewidth, tickspace, ticklabelpad, tickvalues)),
        Observable(ticklabel_annotation_obs),
        labelgap, flipped, tickpositions, tickstrings)

    onany(update_tick_obs,
        Observable(ticksnode), Observable(pos_extents_horizontal), Observable(flipped),
        tickpositions, tickalign, ticksize, spinewidth)

    linepoints = lift(create_linepoints, pos_extents_horizontal, flipped, spinewidth, trimspine, tickpositions, tickwidth)

    decorations[:axisline] = linesegments!(parent, linepoints, linewidth = spinewidth, visible = spinevisible,
        color = spinecolor, inspectable = false, linestyle = nothing)

    translate!(decorations[:axisline], 0, 0, 20)

    protrusion = Observable(0f0; ignore_equal_values=true)

    map!(calculate_protrusion, protrusion,
        # We pass these as observables, to not trigger on them
        Observable((pos_extents_horizontal, labeltext, ticklabel_annotation_obs)),
        ticksvisible, label, labelvisible, labelpadding, tickspace, ticklabelsvisible, actual_ticklabelspace, ticklabelpad,
        # We don't need these as arguments to calculate it, but we need to pass it because it indirectly influences the protrosion
        labelfont, ticklabelfont, labelsize, tickalign)

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
        textsize = ticklabelsize,
        font = ticklabelfont,
        color = ticklabelcolor,
        visible = ticklabelsvisible,
        markerspace = :data,
        inspectable = false)

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
            tls.visible[] ? height(Rect2f(boundingbox(tls))) : 0f0
        else
            # width
            tls.visible[] ? width(Rect2f(boundingbox(tls))) : 0f0
    end
    la.attributes.ticklabelspace = maxwidth
end


function iswhitespace(str)
    match(r"^\s*$", str) !== nothing
end


function Base.delete!(la::LineAxis)
    for (_, d) in la.elements
        if d isa AbstractPlot
            delete!(d.parent, d)
        else
            delete!(d)
        end
    end
end

"""
    get_ticks(ticks, scale, formatter, vmin, vmax)

Base function that calls `get_tickvalues(ticks, vmin, max)` and
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
get_tickvalues(::Automatic, F, vmin, vmax) = get_tickvalues(automatic, identity, vmin, vmax)

# fall back to non-scale aware behavior if no special version is overloaded
get_tickvalues(ticks, scale, vmin, vmax) = get_tickvalues(ticks, vmin, vmax)



function get_ticks(ticks_and_labels::Tuple{Any, Any}, any_scale, ::Automatic, vmin, vmax)
    n1 = length(ticks_and_labels[1])
    n2 = length(ticks_and_labels[2])
    if n1 != n2
        error("There are $n1 tick values in $(ticks_and_labels[1]) but $n2 tick labels in $(ticks_and_labels[2]).")
    end
    ticks_and_labels
end

function get_ticks(tickfunction::Function, any_scale, formatter, vmin, vmax)
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
_logbase(::typeof(log2)) = "2"
_logbase(::typeof(log)) = "e"


function get_ticks(::Automatic, scale::Union{typeof(log10), typeof(log2), typeof(log)},
        any_formatter, vmin, vmax)
    get_ticks(LogTicks(WilkinsonTicks(5, k_min = 3)), scale, any_formatter, vmin, vmax)
end

# log ticks just use the normal pipeline but with log'd limits, then transform the labels
function get_ticks(l::LogTicks, scale::Union{typeof(log10), typeof(log2), typeof(log)}, ::Automatic, vmin, vmax)
    ticks_scaled = get_tickvalues(l.linear_ticks, identity, scale(vmin), scale(vmax))

    ticks = Makie.inverse_transform(scale).(ticks_scaled)

    labels_scaled = get_ticklabels(
        # avoid unicode superscripts in ticks, as the ticks are converted
        # to superscripts in the next step
        xs -> Showoff.showoff(xs, :plain),
        ticks_scaled
    )
    labels = _logbase(scale) .* Makie.UnicodeFun.to_superscript.(labels_scaled)

    (ticks, labels)
end

# function get_ticks(::Automatic, scale::typeof(Makie.logit), any_formatter, vmin, vmax)
#     get_ticks(LogitTicks(WilkinsonTicks(5, k_min = 3)), scale, any_formatter, vmin, vmax)
# end

logit_10(x) = Makie.logit(x) / log(10)
expit_10(x) = Makie.logistic(log(10) * x)

# function get_ticks(l::LogitTicks, scale::typeof(Makie.logit), ::Automatic, vmin, vmax)

#     ticks_scaled = get_tickvalues(l.linear_ticks, identity, logit_10(vmin), logit_10(vmax))

#     ticks = expit_10.(ticks_scaled)

#     base_labels = get_ticklabels(automatic, ticks_scaled)

#     labels = map(ticks_scaled, base_labels) do t, bl
#         if t == 0
#             "¹/₂"
#         elseif t < 0
#             "10" * Makie.UnicodeFun.to_superscript(bl)
#         else
#             "1-10" * Makie.UnicodeFun.to_superscript("-" * bl)
#         end
#     end

#     (ticks, labels)
# end

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
    Makie.inverse_transform(scale).(ticks_scaled)
end

"""
    get_ticklabels(::Automatic, values)

Gets tick labels by applying `Showoff.showoff` to `values`.
"""
get_ticklabels(::Automatic, values) = Showoff.showoff(values)

"""
    get_ticklabels(formatfunction::Function, values)

Gets tick labels by applying `formatfunction` to `values`.
"""
get_ticklabels(formatfunction::Function, values) = formatfunction(values)

"""
    get_ticklabels(formatstring::AbstractString, values)

Gets tick labels by formatting each value in `values` according to a `Formatting.format` format string.
"""
get_ticklabels(formatstring::AbstractString, values) = [Formatting.format(formatstring, v) for v in values]


function get_ticks(m::MultiplesTicks, any_scale, ::Automatic, vmin, vmax)
    dvmin = vmin / m.multiple
    dvmax = vmax / m.multiple
    multiples = MakieLayout.get_tickvalues(LinearTicks(m.n_ideal), dvmin, dvmax)

    multiples .* m.multiple, Showoff.showoff(multiples) .* m.suffix
end


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

    for (lo, hi) in zip(@view(tickvalues[1:end-1]), @view(tickvalues[2:end]))
        interval = hi - lo
        stepsize = interval / n
        v = lo
        for i in 1:n-1
            v += stepsize
            push!(vals, v)
        end
    end

    if i.mirror
        lastinterval = tickvalues[end] - tickvalues[end-1]
        stepsize = lastinterval / n
        v = tickvalues[end] + stepsize
        append!(vals, v:stepsize:vmax)
    end

    vals
end

# for log scales, we need to step in log steps at the edges
function get_minor_tickvalues(i::IntervalsBetween, scale::Union{typeof(log), typeof(log2), typeof(log10)}, tickvalues, vmin, vmax)

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

    for (lo, hi) in zip(@view(tickvalues[1:end-1]), @view(tickvalues[2:end]))
        interval = hi - lo
        stepsize = interval / n
        v = lo
        for i in 1:n-1
            v += stepsize
            push!(vals, v)
        end
    end

    if i.mirror
        lastinterval_scaled = scale(tickvalues[end]) - scale(tickvalues[end-1])
        nexttick = invscale(scale(tickvalues[end]) + lastinterval_scaled)
        stepsize = (nexttick - tickvalues[end]) / n
        v = tickvalues[end] + stepsize
        append!(vals, v:stepsize:vmax)
    end

    vals
end

function get_minor_tickvalues(v::AbstractVector{<:Real}, _, _, _, _)
    Float32.(v)
end
