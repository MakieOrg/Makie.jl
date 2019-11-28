function LineAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LineAxis))

    decorations = Dict{Symbol, Any}()

    @extract attrs (endpoints, limits, flipped, ticksize, tickwidth,
        tickcolor, tickalign, ticks, ticklabelalign, ticklabelrotation, ticksvisible,
        ticklabelspace, ticklabelpad, labelpadding,
        ticklabelsize, ticklabelsvisible, spinewidth, label, labelsize, labelcolor,
        labelvisible)

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

    linepoints = lift(pos_extents_horizontal, flipped, spinewidth) do (position, extents, horizontal),
            flipped, sw

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
    end

    lines!(parent, linepoints, linewidth = spinewidth, raw = true)

    ticksnode = Node(Point2f0[])
    ticklines = linesegments!(
        parent, ticksnode, linewidth = tickwidth, color = tickcolor,
        show_axis = false, visible = ticksvisible
    )[end]
    decorations[:ticklines] = ticklines

    nmaxticks = 20
    ticklabelnodes = [Node("0") for i in 1:nmaxticks]
    ticklabelposnodes = [Node(Point2f0(0.0, 0.0)) for i in 1:nmaxticks]
    ticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            ticklabelnodes[i],
            position = ticklabelposnodes[i],
            align = ticklabelalign,
            rotation = ticklabelrotation,
            textsize = ticklabelsize,
            show_axis = false,
            visible = ticklabelsvisible
        )[end]
    end
    decorations[:ticklabels] = ticklabels

    tickspace = lift(ticksvisible, ticksize, tickalign) do ticksvisible,
            ticksize, tickalign

        ticksvisible ? max(0f0, ticksize * (1f0 - tickalign)) : 0f0
    end

    labelgap = lift(spinewidth, tickspace, ticklabelsvisible, ticklabelspace,
        ticklabelpad, labelpadding) do spinewidth, tickspace, ticklabelsvisible,
            ticklabelspace, ticklabelpad, labelpadding


        spinewidth + tickspace +
            (ticklabelsvisible ? ticklabelspace + ticklabelpad : 0f0) +
            labelpadding
    end

    labelpos = lift(pos_extents_horizontal, flipped, labelgap) do (position, extents, horizontal), flipped, labelgap

        fullgap = tickspace[] + labelgap

        w_ext = extents[2] - extents[1]

        x_or_y = flipped ? position + labelgap : position - labelgap
        if horizontal
            Point2(extents[1] + 0.5f0 * w_ext, x_or_y)
        else
            Point2(x_or_y, extents[1] + 0.5f0 * w_ext)
        end
    end

    labelalign = lift(pos_extents_horizontal, flipped) do (position, extents, horizontal), flipped
        if horizontal
            (:center, flipped ? :bottom : :top)
        else
            (:center, :bottom)
        end
    end

    labelrotation = lift(pos_extents_horizontal, flipped) do (position, extents, horizontal), flipped
        horizontal ? 0f0 : (flipped ? Float32(-0.5pi) : Float32(0.5pi))
    end

    labeltext = text!(
        parent, label, textsize = labelsize, color = labelcolor,
        position = labelpos, show_axis = false, visible = labelvisible,
        align = labelalign, rotation = labelrotation
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

        for i in 1:length(ticklabels)
            if i <= nticks
                ticklabelnodes[i][] = tickstrings[i]

                ticklabelgap = spinewidth[] + tickspace[] + ticklabelpad[]

                shift = if horizontal
                    Point2f0(0f0, flipped ? ticklabelgap : -ticklabelgap)
                else
                    Point2f0(flipped ? ticklabelgap : -ticklabelgap, 0f0)
                end

                ticklabelposnodes[i][] = tickpositions[][i] .+ shift

                ticklabels[i].visible = true && ticklabelsvisible[]
            else
                ticklabels[i].visible = false
            end
        end
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

    protrusion = Node(Float32(0))

    # extents[] = extents[] # trigger

    LineAxis(parent, protrusion, attrs, decorations)
end
