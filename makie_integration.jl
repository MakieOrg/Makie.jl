using AbstractPlotting.Keyboard
using AbstractPlotting.Mouse
using AbstractPlotting: ispressed, is_mouseinside

function axislines!(scene, rect)
    points = lift(rect) do r
        p1 = Point2(r.origin[1], r.origin[2] + r.widths[2])
        p2 = Point2(r.origin[1], r.origin[2])
        p3 = Point2(r.origin[1] + r.widths[1], r.origin[2])
        [p1, p2, p3]
    end
    lines!(scene, points, linewidth = 2, show_axis = false)
end

"""
A cheaper function that tries to come up with usable tick locations for a given value range
"""
function locateticks(xmin, xmax)
    # whats the distance?
    d = xmax - xmin
    # which order of magnitude is the distance in?
    ex = log10(d)
    # round the exponent to the closest one
    exrounded = round(ex)
    # this factor is used so we can find integer steps that then map back to
    # nice numbers in the given value range
    factor = 1 / 10 ^ (exrounded - 1)

    # minimum needs to be at least the lower value times the scaling factor
    xminf = ceil(xmin * factor)
    # maximum needs to be at most the higher value times the scaling factor
    xmaxf = floor(xmax * factor)

    # xminf and xmaxf are now both integers that are in an order of magnitude around ten steps apart
    df = xmaxf - xminf

    # step sizes we like
    steps = [5, 4, 2, 1]

    # from the highest to the lowest step size, choose the first that fits at least
    # two times between the end values (gives three ticks including the end value)
    for s in steps
        n, remainder = divrem(df, s)
        if n >= 2
            rang = 1:n
            # calculate the ticks by dividing with the factor from above
            ticks = [xminf; [xminf + x * s for x in rang]] ./ factor
            return ticks
        end
    end
end

# struct LimitCamera <: AbstractCamera end

function add_pan!(scene::SceneLike, limits)
    startpos = Base.RefValue((0.0, 0.0))
    pan = Mouse.right
    xzoom = Keyboard.x
    yzoom = Keyboard.y
    e = events(scene)
    on(
        camera(scene),
        # Node.((scene, cam, startpos))...,
        Node.((scene, startpos))...,
        e.mousedrag
    ) do scene, startpos, dragging
        # pan = cam.panbutton[]
        mp = e.mouseposition[]
        if ispressed(scene, pan) && is_mouseinside(scene)
            window_area = pixelarea(scene)[]
            if dragging == Mouse.down
                startpos[] = mp
            elseif dragging == Mouse.pressed && ispressed(scene, pan)
                diff = startpos[] .- mp
                startpos[] = mp
                pxa = scene.px_area[]
                diff_fraction = Vec2f0(diff) ./ Vec2f0(widths(pxa))

                diff_limits = diff_fraction .* widths(limits[])

                if ispressed(scene, xzoom)
                    limits[] = FRect(
                        Vec2f0(limits[].origin) .+ Vec2f0(diff_limits[1], 0), widths(limits[])
                    )
                elseif ispressed(scene, yzoom)
                    limits[] = FRect(
                        Vec2f0(limits[].origin) .+ Vec2f0(0, diff_limits[2]), widths(limits[])
                    )
                else
                    limits[] = FRect(Vec2f0(limits[].origin) .+ Vec2f0(diff_limits), widths(limits[]))
                end
            end
        end
        return
    end
end

function add_zoom!(scene::SceneLike, limits)

    e = events(scene)
    cam = camera(scene)
    on(cam, e.scroll) do x
        # @extractvalue cam (zoomspeed, zoombutton, area)
        zoomspeed = 0.10f0
        zoombutton = nothing
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) &&        AbstractPlotting.is_mouseinside(scene)
            pa = pixelarea(scene)[]

            # don't let z go negative
            z = max(0.1f0, 1f0 + (zoom * zoomspeed))

            # limits[] = FRect(limits[].origin..., (limits[].widths .* 0.99)...)
            mp_fraction = (Vec2f0(e.mouseposition[]) - minimum(pa)) ./ widths(pa)

            mp_data = limits[].origin .+ mp_fraction .* limits[].widths

            xorigin = limits[].origin[1]
            yorigin = limits[].origin[2]

            xwidth = limits[].widths[1]
            ywidth = limits[].widths[2]
            newxwidth = xwidth * z
            newywidth = ywidth * z

            newxorigin = xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yorigin + mp_fraction[2] * (ywidth - newywidth)

            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.x)
                limits[] = FRect(newxorigin, yorigin, newxwidth, ywidth)
            elseif AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.y)
                limits[] = FRect(xorigin, newyorigin, xwidth, newywidth)
            else
                limits[] = FRect(newxorigin, newyorigin, newxwidth, newywidth)
            end
        end
        return
    end
end

function LayoutedAxis(parent::Scene)
    scene = Scene(parent, Node(IRect(0, 0, 100, 100)), raw = true)
    limits = Node(FRect(0, 0, 100, 100))
    xlabel = Node("x label")
    ylabel = Node("y label")

    add_pan!(scene, limits)
    add_zoom!(scene, limits)

    campixel!(scene)

    ticksnode = Node(Point2f0[])
    ticks = linesegments!(
        parent, ticksnode, linewidth = 2, show_axis = false
    )[end]

    # the algorithm from above seems to not give more than 7 ticks with the step sizes I chose
    nmaxticks = 7

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            xticklabelnodes[i],
            position = xticklabelposnodes[i],
            align = (:center, :top),
            textsize = 20,
            show_axis = false
        )[end]
    end

    yticklabelnodes = [Node("0") for i in 1:nmaxticks]
    yticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    yticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            yticklabelnodes[i],
            position = yticklabelposnodes[i],
            align = (:center, :bottom),
            rotation = pi/2,
            textsize = 20,
            show_axis = false
        )[end]
    end

    on(camera(scene), pixelarea(scene), limits) do pxa, lims

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = Float32.(lims.origin)
        limw, limh = Float32.(widths(lims))
        l, b = Float32.(pxa.origin)
        w, h = Float32.(widths(pxa))
        # projection = AbstractPlotting.orthographicprojection(0f0, w * 2f0, 0f0, h, nearclip, farclip)
        projection = AbstractPlotting.orthographicprojection(limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection

        # pxa = scene.px_area[]
        px_aspect = pxa.widths[1] / pxa.widths[2]

        # @printf("cam %.1f, %.1f, %.1f, %.1f\n", a.origin..., a.widths...)
        # @printf("pix %.1f, %.1f, %.1f, %.1f\n", pxa.origin..., pxa.widths...)

        width = lims.widths[1]
        # width = px_aspect > 1 ? a.widths[1] / px_aspect : a.widths[1]
        xrange = (lims.origin[1], lims.origin[1] + width)


        if width == 0 || !isfinite(xrange[1]) || !isfinite(xrange[2])
            return
        end

        xtickvals = locateticks(xrange...)
        # xtickvals, vminbest, vmaxbest = optimize_ticks(xrange...)


        # this code here tries to transform between values given in pixels of the
        # scene and the camera area, but this is incorrect right now and everything
        # should just be determined by the now unused limits that are saved in the
        # LayoutedAxis object
        xfractions = (xtickvals .- xrange[1]) ./ width
        xrange_scene = (pxa.origin[1], pxa.origin[1] + pxa.widths[1])
        width_scene = xrange_scene[2] - xrange_scene[1]
        xticks_scene = xrange_scene[1] .+ width_scene .* xfractions
        ticksize = 10 # px
        y = pxa.origin[2]
        xtickstarts = [Point(x, y) for x in xticks_scene]
        xtickends = [t + Point(0.0, -ticksize) for t in xtickstarts]

        # height = px_aspect < 1 ? a.widths[2] * px_aspect : a.widths[2]
        height = lims.widths[2]
        yrange = (lims.origin[2], lims.origin[2] + height)


        ytickvals = locateticks(yrange...)
        # ytickvals, vminbest, vmaxbest = optimize_ticks(yrange...)
        yfractions = (ytickvals .- yrange[1]) ./ height
        yrange_scene = (pxa.origin[2], pxa.origin[2] + pxa.widths[2])
        height_scene = yrange_scene[2] - yrange_scene[1]
        yticks_scene = yrange_scene[1] .+ height_scene .* yfractions
        ticksize = 10 # px
        x = pxa.origin[1]
        ytickstarts = [Point(x, y) for y in yticks_scene]
        ytickends = [t + Point(-ticksize, 0.0) for t in ytickstarts]


        # set and position tick labels
        xtickstrings = Showoff.showoff(xtickvals, :plain)
        nxticks = length(xtickvals)
        for i in 1:nmaxticks
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]
                xticklabelposnodes[i][] = xtickends[i] + Point(0.0, -10.0)
                xticklabels[i].visible = true
            else
                xticklabels[i].visible = false
            end
        end

        ytickstrings = Showoff.showoff(ytickvals, :plain)
        nyticks = length(ytickvals)
        for i in 1:nmaxticks
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]
                yticklabelposnodes[i][] = ytickends[i] + Point(-10.0, 0.0)
                yticklabels[i].visible = true
            else
                yticklabels[i].visible = false
            end
        end

        # set tick mark positions
        ticksnode[] = collect(Iterators.flatten(zip(
            [xtickstarts; ytickstarts],
            [xtickends; ytickends]
        )))
    end

    labelgap = 50

    xlabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area) do a
        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(
        parent, xlabel, textsize = 20, position = xlabelpos, show_axis = false
    )[end]
    tx.align = [0.5, 1]
    ty = text!(
        parent, ylabel, textsize = 20,
        position = ylabelpos, rotation = pi/2, show_axis = false
    )[end]
    ty.align = [0.5, 0]

    axislines!(parent, scene.px_area)

    LayoutedAxis(parent, scene, xlabel, ylabel, limits)
end


function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedAxisLayout)
    sa.axis.scene.px_area[] = IRect2D(sa.inner)
end

function shrinkbymargin(rect, margin)
    IRect((rect.origin .+ margin), (rect.widths .- 2 .* margin))
end

function linkxaxes!(a::LayoutedAxis, b::LayoutedAxis)
    on(a.limits) do alim
        blim = b.limits[]

        ao = alim.origin[1]
        bo = blim.origin[1]
        aw = alim.widths[1]
        bw = blim.widths[1]

        if ao != bo || aw != bw
            b.limits[] = FRect(ao, blim.origin[2], aw, blim.widths[2])
        end
    end

    on(b.limits) do blim
        alim = a.limits[]

        ao = alim.origin[1]
        bo = blim.origin[1]
        aw = alim.widths[1]
        bw = blim.widths[1]

        if ao != bo || aw != bw
            a.limits[] = FRect(bo, alim.origin[2], bw, alim.widths[2])
        end
    end
end

function linkyaxes!(a::LayoutedAxis, b::LayoutedAxis)
    on(a.limits) do alim
        blim = b.limits[]

        ao = alim.origin[2]
        bo = blim.origin[2]
        aw = alim.widths[2]
        bw = blim.widths[2]

        if ao != bo || aw != bw
            b.limits[] = FRect(blim.origin[1], ao, blim.widths[1], aw)
        end
    end

    on(b.limits) do blim
        alim = a.limits[]

        ao = alim.origin[2]
        bo = blim.origin[2]
        aw = alim.widths[2]
        bw = blim.widths[2]

        if ao != bo || aw != bw
            a.limits[] = FRect(alim.origin[1], bo, alim.widths[1], bw)
        end
    end
end
