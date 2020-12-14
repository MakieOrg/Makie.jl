function LineAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LineAxis))

    decorations = Dict{Symbol, Any}()

    @extract attrs (endpoints, limits, flipped, ticksize, tickwidth,
        tickcolor, tickalign, ticks, tickformat, ticklabelalign, ticklabelrotation, ticksvisible,
        ticklabelspace, ticklabelpad, labelpadding,
        ticklabelsize, ticklabelsvisible, spinewidth, spinecolor, label, labelsize, labelcolor,
        labelfont, ticklabelfont, ticklabelcolor,
        labelvisible, spinevisible, trimspine, flip_vertical_label, reversed)

    pos_extents_horizontal = lift(endpoints) do endpoints
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
            error("Axis endpoints $(endpoints[1]) and $(endpoints[2]) are neither on a horizontal nor vertical line")
        end
    end

    ticksnode = Node(Point2f0[])
    ticklines = linesegments!(
        parent, ticksnode, linewidth = tickwidth, color = tickcolor,
        show_axis = false, visible = ticksvisible
    )[end]
    decorations[:ticklines] = ticklines

    ticklabelannosnode = Node(Tuple{String, Point2f0}[])
    ticklabels = annotations!(
        parent,
        ticklabelannosnode,
        align = ticklabelalign,
        rotation = ticklabelrotation,
        textsize = ticklabelsize,
        font = ticklabelfont,
        color = ticklabelcolor,
        show_axis = false,
        visible = ticklabelsvisible)[end]

    ticklabel_ideal_space = lift(ticklabelannosnode, ticklabelalign, ticklabelrotation, ticklabelfont, ticklabelsvisible, typ=Float32) do args...
        maxwidth = if pos_extents_horizontal[][3]
                # height
                ticklabelsvisible[] ? height(FRect2D(boundingbox(ticklabels))) : 0f0
            else
                # width
                ticklabelsvisible[] ? width(FRect2D(boundingbox(ticklabels))) : 0f0
        end
        # in case there is no string in the annotations and the boundingbox comes back all NaN
        if !isfinite(maxwidth)
            maxwidth = zero(maxwidth)
        end
        maxwidth
    end

    attrs[:actual_ticklabelspace] = 0f0
    actual_ticklabelspace = attrs[:actual_ticklabelspace]

    onany(ticklabel_ideal_space, ticklabelspace) do idealspace, space
        s = if space == AbstractPlotting.automatic
            idealspace
        else
            space
        end
        if s != actual_ticklabelspace[]
            actual_ticklabelspace[] = s
        end
    end


    decorations[:ticklabels] = ticklabels

    tickspace = lift(ticksvisible, ticksize, tickalign) do ticksvisible,
            ticksize, tickalign

        ticksvisible ? max(0f0, ticksize * (1f0 - tickalign)) : 0f0
    end

    labelgap = lift(spinewidth, tickspace, ticklabelsvisible, actual_ticklabelspace,
        ticklabelpad, labelpadding) do spinewidth, tickspace, ticklabelsvisible,
            actual_ticklabelspace, ticklabelpad, labelpadding


        spinewidth + tickspace +
            (ticklabelsvisible ? actual_ticklabelspace + ticklabelpad : 0f0) +
            labelpadding
    end

    labelpos = lift(pos_extents_horizontal, flipped, labelgap) do (position, extents, horizontal), flipped, labelgap

        # fullgap = tickspace[] + labelgap

        middle = extents[1] + 0.5f0 * (extents[2] - extents[1])

        x_or_y = flipped ? position + labelgap : position - labelgap

        if horizontal
            Point2(middle, x_or_y)
        else
            Point2(x_or_y, middle)
        end
    end

    labelalign = lift(pos_extents_horizontal, flipped, flip_vertical_label) do (position, extents, horizontal), flipped, flip_vertical_label
        if horizontal
            (:center, flipped ? :bottom : :top)
        else
            (:center, if flipped
                    flip_vertical_label ? :bottom : :top
                else
                    flip_vertical_label ? :top : :bottom
                end
            )
        end
    end

    labelrotation = lift(pos_extents_horizontal, flip_vertical_label) do (position, extents, horizontal), flip_vertical_label
        if horizontal
            0f0
        else
            if flip_vertical_label
                Float32(-0.5pi)
            else
                Float32(0.5pi)
            end
        end
    end

    labeltext = text!(
        parent, label, textsize = labelsize, color = labelcolor,
        position = labelpos, show_axis = false, visible = labelvisible,
        align = labelalign, rotation = labelrotation, font = labelfont,
    )[end]

    decorations[:labeltext] = labeltext

    tickvalues = Node(Float32[])

    tickvalues_unfiltered = lift(pos_extents_horizontal, limits, ticks) do (position, extents, horizontal),
            limits, ticks
        get_tickvalues(ticks, limits...)
    end

    tickpositions = Node(Point2f0[])
    tickstrings = Node(String[])

    onany(tickvalues_unfiltered, reversed, tickformat) do tickvalues_unfiltered, reversed, tickformat

        tickstrings_unfiltered = get_ticklabels(tickformat, ticks[], tickvalues_unfiltered)

        position, extents_uncorrected, horizontal = pos_extents_horizontal[]

        extents = reversed ? reverse(extents_uncorrected) : extents_uncorrected

        px_o = extents[1]
        px_width = extents[2] - extents[1]

        lim_o = limits[][1]
        lim_w = limits[][2] - limits[][1]

        # if labels are given manually, it's possible that some of them are outside the displayed limits
        i_values_within_limits = findall(tv -> lim_o <= tv <= (lim_o + lim_w), tickvalues_unfiltered)
        tickvalues[] = tickvalues_unfiltered[i_values_within_limits]

        tick_fractions = (tickvalues[] .- lim_o) ./ lim_w
        tick_scenecoords = px_o .+ px_width .* tick_fractions

        tickpos = if horizontal
            [Point(x, position) for x in tick_scenecoords]
        else
            [Point(position, y) for y in tick_scenecoords]
        end

        # now trigger updates
        tickpositions[] = tickpos

        tickstrings[] = tickstrings_unfiltered[i_values_within_limits]
    end

    onany(tickstrings, labelgap, flipped) do tickstrings, labelgap, flipped
        # tickspace is always updated before labelgap
        # tickpositions are always updated before tickstrings
        # so we don't need to lift those

        position, extents, horizontal = pos_extents_horizontal[]

        nticks = length(tickvalues[])

        ticklabelgap = spinewidth[] + tickspace[] + ticklabelpad[]

        shift = if horizontal
            Point2f0(0f0, flipped ? ticklabelgap : -ticklabelgap)
        else
            Point2f0(flipped ? ticklabelgap : -ticklabelgap, 0f0)
        end

        ticklabelpositions = tickpositions[] .+ Ref(shift)
        ticklabelannosnode[] = collect(zip(tickstrings, ticklabelpositions))
    end

    onany(tickpositions, tickalign, ticksize, spinewidth) do tickpositions,
            tickalign, ticksize, spinewidth

        position, extents, horizontal = pos_extents_horizontal[]

        if horizontal
            tickstarts = [tp + (flipped[] ? -1f0 : 1f0) * Point2f0(0f0, tickalign * ticksize - 0.5f0 * spinewidth) for tp in tickpositions]
            tickends = [t + (flipped[] ? -1f0 : 1f0) * Point2f0(0f0, -ticksize) for t in tickstarts]
            ticksnode[] = interleave_vectors(tickstarts, tickends)
        else
            tickstarts = [tp + (flipped[] ? -1f0 : 1f0) * Point2f0(tickalign * ticksize - 0.5f0 * spinewidth, 0f0) for tp in tickpositions]
            tickends = [t + (flipped[] ? -1f0 : 1f0) * Point2f0(-ticksize, 0f0) for t in tickstarts]
            ticksnode[] = interleave_vectors(tickstarts, tickends)
        end
    end

    linepoints = lift(pos_extents_horizontal, flipped, spinewidth, trimspine, tickpositions, tickwidth) do (position, extents, horizontal),
            flipped, sw, trimspine, tickpositions, tickwidth

        if !trimspine
            if horizontal
                y = position
                p1 = Point2f0(extents[1] - 0.5sw, y)
                p2 = Point2f0(extents[2] + 0.5sw, y)
                [p1, p2]
            else
                x = position
                p1 = Point2f0(x, extents[1] - 0.5sw)
                p2 = Point2f0(x, extents[2] + 0.5sw)
                [p1, p2]
            end
        else
            [tickpositions[1], tickpositions[end]] .+ [
                (horizontal ? Point2f0(-0.5f0 * tickwidth, 0) : Point2f0(0, -0.5f0 * tickwidth)),
                (horizontal ? Point2f0(0.5f0 * tickwidth, 0) : Point2f0(0, 0.5f0 * tickwidth)),
            ]
        end
    end

    decorations[:axisline] = lines!(parent, linepoints, linewidth = spinewidth, visible = spinevisible,
        color = spinecolor, raw = true)[end]


    protrusion = lift(ticksvisible, label, labelvisible, labelpadding, labelsize, tickalign, tickspace, ticklabelsvisible, actual_ticklabelspace, ticklabelpad, labelfont, ticklabelfont) do ticksvisible,
            label, labelvisible, labelpadding, labelsize, tickalign, tickspace, ticklabelsvisible,
            actual_ticklabelspace, ticklabelpad, labelfont, ticklabelfont

        position, extents, horizontal = pos_extents_horizontal[]

        label_is_empty = iswhitespace(label) || isempty(label)
        real_labelsize = if label_is_empty
            0f0
        else
            horizontal ? boundingbox(labeltext).widths[2] : boundingbox(labeltext).widths[1]
        end

        labelspace = (labelvisible && !label_is_empty) ? real_labelsize + labelpadding : 0f0
        # tickspace = ticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0
        tickspace = (ticksvisible && !isempty(ticklabelannosnode[])) ? tickspace : 0f0

        ticklabelgap = (ticklabelsvisible && actual_ticklabelspace > 0) ? actual_ticklabelspace + ticklabelpad : 0f0

        together = tickspace + ticklabelgap + labelspace
    end

    # trigger whole pipeline once to fill tickpositions and tickstrings
    # etc to avoid empty ticks bug #69
    limits[] = limits[]

    LineAxis(parent, protrusion, attrs, decorations, tickpositions, tickvalues, tickstrings)
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
            tls.visible[] ? height(FRect2D(boundingbox(tls))) : 0f0
        else
            # width
            tls.visible[] ? width(FRect2D(boundingbox(tls))) : 0f0
    end
    la.attributes.ticklabelspace = maxwidth
end

function iswhitespace(str)
    match(r"^\s+$", str) !== nothing
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
    get_tickvalues(::AbstractPlotting.Automatic, vmin, vmax)

Calls the default tick finding algorithm, which could depend on the current LAxis
state.
"""
get_tickvalues(::AbstractPlotting.Automatic, vmin, vmax) = get_tickvalues(LinearTicks(5), vmin, vmax)

"""
    get_tickvalues(lt::LinearTicks, vmin, vmax)

Runs a common tick finding algorithm to as many ticks as requested by the
`LinearTicks` instance.
"""
get_tickvalues(lt::LinearTicks, vmin, vmax) = locateticks(vmin, vmax, lt.n_ideal)

"""
    get_tickvalues(tup::Tuple{<:Any, <:Any}, vmin, vmax)

Calls `get_tickvalues(tup[1], vmin, vmax)` where the first entry of the tuple
should contain an iterable tick values and the second entry should contain an
iterable of the respective labels.
"""
get_tickvalues(tup::Tuple{<:Any, <:Any}, vmin, vmax) = get_tickvalues(tup[1], vmin, vmax)

"""
    get_tickvalues(tickvalues, vmin, vmax)

Uses tickvalues directly.
"""
get_tickvalues(tickvalues, vmin, vmax) = tickvalues

# there is an opportunity to overload formatters for specific ticks,
# but the generic case doesn't use this and just forwards to a less specific method
"""
    get_ticklabels(formatter, ticks, values)

Forwards to `get_ticklabels(formatter, values)` if no specialization exists.
"""
get_ticklabels(formatter, ticks, values) = get_ticklabels(formatter, values)

"""
    get_ticklabels(::AbstractPlotting.Automatic, tup::Tuple{<:Any, <:Any}, values)

Returns the second entry of `tup`, which should be an iterable of strings, as the tick labels for `values`.
"""
function get_ticklabels(::AbstractPlotting.Automatic, tup::Tuple{<:Any, <:Any}, values)
    n1 = length(tup[1])
    n2 = length(tup[2])
    if n1 != n2
        error("There are $n1 tick values in $(tup[1]) but $n2 tick labels in $(tup[2]).")
    end
    tup[2]
end

"""
    get_ticklabels(::AbstractPlotting.Automatic, values)

Gets tick labels by applying `Showoff.showoff` to `values`.
"""
get_ticklabels(::AbstractPlotting.Automatic, values) = Showoff.showoff(values)

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
