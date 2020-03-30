function LineAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LineAxis))

    decorations = Dict{Symbol, Any}()

    @extract attrs (endpoints, limits, flipped, ticksize, tickwidth,
        tickcolor, tickalign, ticks, ticklabelalign, ticklabelrotation, ticksvisible,
        ticklabelspace, ticklabelpad, labelpadding,
        ticklabelsize, ticklabelsvisible, spinewidth, spinecolor, label, labelsize, labelcolor,
        labelfont, ticklabelfont,
        labelvisible, spinevisible, trimspine, flip_vertical_label)

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

    ticklabelannosnode = Node{Vector{Tuple{String, Point2f0}}}([("temp", Point2f0(0, 0))])
    ticklabels = annotations!(
        parent,
        ticklabelannosnode,
        align = ticklabelalign,
        rotation = ticklabelrotation,
        textsize = ticklabelsize,
        font = ticklabelfont,
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
    end

    actual_ticklabelspace = Node(0f0)

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

    tickvalues = lift(pos_extents_horizontal, limits, ticks) do (position, extents, horizontal),
            limits, ticks
        px_width = extents[2] - extents[1]
        compute_tick_values(ticks, limits..., px_width)
    end

    tickpositions = Node(Point2f0[])
    tickstrings = Node(String[])

    onany(tickvalues) do tickvalues
        # limoy = limits[].origin[2]
        # limh = limits[].widths[2]
        # px_ox = pixelarea(scene)[].origin[1]
        # px_oy = pixelarea(scene)[].origin[2]
        # px_w = pixelarea(scene)[].widths[1]
        # px_h = pixelarea(scene)[].widths[2]

        position, extents, horizontal = pos_extents_horizontal[]

        px_o = extents[1]
        px_width = extents[2] - extents[1]

        lim_o = limits[][1]
        lim_w = limits[][2] - limits[][1]

        tick_fractions = (tickvalues .- lim_o) ./ lim_w
        tick_scenecoords = px_o .+ px_width .* tick_fractions

        tickpos = if horizontal
            [Point(x, position) for x in tick_scenecoords]
        else
            [Point(position, y) for y in tick_scenecoords]
        end

        # now trigger updates
        tickpositions[] = tickpos

        tickstrings[] = get_tick_labels(ticks[], tickvalues)
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
                y = position + (flipped ? 1f0 : -1f0) * 0.5f0 * sw
                p1 = Point2f0(extents[1] - sw, y)
                p2 = Point2(extents[2] + sw, y)
                [p1, p2]
            else
                x = position + (flipped ? 1f0 : -1f0) * 0.5f0 * sw
                p1 = Point2f0(x, extents[1] - sw)
                p2 = Point2f0(x, extents[2] + sw)
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


    protrusion = lift(ticksvisible, label, labelvisible, labelpadding, labelsize, tickalign, spinewidth,
            tickspace, ticklabelsvisible, actual_ticklabelspace, ticklabelpad, labelfont, ticklabelfont) do ticksvisible,
            label, labelvisible, labelpadding, labelsize, tickalign, spinewidth, tickspace, ticklabelsvisible,
            actual_ticklabelspace, ticklabelpad, labelfont, ticklabelfont

        position, extents, horizontal = pos_extents_horizontal[]

        real_labelsize = if iswhitespace(label)
            0f0
        else
            horizontal ? boundingbox(labeltext).widths[2] : boundingbox(labeltext).widths[1]
        end

        labelspace = (labelvisible && !iswhitespace(label)) ? real_labelsize + labelpadding : 0f0
        spinespace = spinewidth
        # tickspace = ticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0
        ticklabelgap = ticklabelsvisible ? actual_ticklabelspace + ticklabelpad : 0f0

        together = spinespace + tickspace + ticklabelgap + labelspace
    end

    # extents[] = extents[] # trigger

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

    tls = la.decorations[:ticklabels]
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

compute_tick_values(ct::CustomTicks, args...) = ct.f_tickvalues(args...)
get_tick_labels(ct::CustomTicks, values) = ct.f_ticklabels(values)
