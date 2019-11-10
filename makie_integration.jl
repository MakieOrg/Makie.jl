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

function scale_range(vmin, vmax, n=1, threshold=100)
    dv = abs(vmax - vmin)  # > 0 as nonsingular is called before.
    meanv = (vmax + vmin) / 2
    offset = if abs(meanv) / dv < threshold
        0
    else
        copysign(10 ^ (log10(abs(meanv)) ÷ 1), meanv)
    end
    scale = 10 ^ (log10(dv / n) ÷ 1)
    scale, offset
end

function _staircase(steps)
    [0.1 .* steps[1:end-1]; steps; 10 .* steps[2]]
end


struct EdgeInteger
    step::Float64
    offset::Float64

    function EdgeInteger(step, offset)
        if step <= 0
            error("Step must be positive")
        end
        new(step, abs(offset))
    end
end

function closeto(e::EdgeInteger, ms, edge)
    tol = if e.offset > 0
        digits = log10(e.offset / e.step)
        tol = max(1e-10, 10 ^ (digits - 12))
        min(0.4999, tol)
    else
        1e-10
    end
    abs(ms - edge) < tol
end

function le(e::EdgeInteger, x)
    # 'Return the largest n: n*step <= x.'
    d, m = divrem(x, e.step)
    if closeto(e, m / e.step, 1)
        d + 1
    else
        d
    end
end

function ge(e::EdgeInteger, x)
    # 'Return the smallest n: n*step >= x.'
    d, m = divrem(x, e.step)
    if closeto(e, m / e.step, 0)
        d
    else
        d + 1
    end
end

"""
A cheaper function that tries to come up with usable tick locations for a given value range
"""
function locateticks(vmin, vmax, width_px, ideal_spacing_px; _integer=false, _min_n_ticks=2)

    _steps = [1, 1.5, 2, 2.5, 3, 4, 5, 6, 8, 10]
    _extended_steps = _staircase(_steps)

    # how many ticks would ideally fit?
    n_ideal = Int(round(width_px / ideal_spacing_px)) + 1

    scale, offset = scale_range(vmin, vmax, n_ideal)

    _vmin = vmin - offset
    _vmax = vmax - offset

    raw_step = (_vmax - _vmin) / n_ideal

    steps = _extended_steps * scale

    if _integer
        # For steps > 1, keep only integer values.
        igood = (steps .< 1) .| (abs.(steps .- round.(steps)) .< 0.001)
        steps = steps[igood]
    end

    #istep = np.nonzero(steps >= raw_step)[0][0]
    istep = findfirst(steps .>= raw_step)

    ticks = nothing
    for istep in istep:-1:1
        step = steps[istep]

        if _integer && (floor(_vmax) - ceil(_vmin) >= _min_n_ticks - 1)
            step = max(1, step)
        end
        best_vmin = (_vmin ÷ step) * step

        # Find tick locations spanning the vmin-vmax range, taking into
        # account degradation of precision when there is a large offset.
        # The edge ticks beyond vmin and/or vmax are needed for the
        # "round_numbers" autolimit mode.
        edge = EdgeInteger(step, offset)
        low = le(edge, _vmin - best_vmin)
        high = ge(edge, _vmax - best_vmin)
        low:high
        ticks = (low:high) .* step .+ best_vmin
        # Count only the ticks that will be displayed.
        # nticks = sum((ticks .<= _vmax) .& (ticks .>= _vmin))

        # manual sum because broadcasting was slow
        nticks = 0
        for t in ticks
            if _vmin <= t <= _vmax
                nticks += 1
            end
        end

        if nticks >= _min_n_ticks
            break
        end
    end
    ticks = ticks .+ offset
    filter(x -> vmin <= x <= vmax, ticks)
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

function LayoutedAxis(parent::Scene; kwargs...)

    attrs = merge!(default_attributes(LayoutedAxis), Attributes(kwargs))

    @extract attrs (
        xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelpad,
        yticklabelpad, xtickalign, ytickalign,
    )

    bboxnode = Node(BBox(0, 100, 100, 0))
    scenearea = lift(bb -> IRect2D(bb), bboxnode)

    scene = Scene(parent, scenearea, raw = true)
    limits = Node(FRect(0, 0, 100, 100))

    add_pan!(scene, limits)
    add_zoom!(scene, limits)

    campixel!(scene)

    xticksnode = Node(Point2f0[])
    xticks = linesegments!(
        parent, xticksnode, linewidth = 2, show_axis = false, visible = xticksvisible
    )[end]

    yticksnode = Node(Point2f0[])
    yticks = linesegments!(
        parent, yticksnode, linewidth = 2, show_axis = false, visible = yticksvisible
    )[end]

    nmaxticks = 20

    xticklabelnodes = [Node("0") for i in 1:nmaxticks]
    xticklabelposnodes = [Node(Point(0.0, 0.0)) for i in 1:nmaxticks]
    xticklabels = map(1:nmaxticks) do i
        text!(
            parent,
            xticklabelnodes[i],
            position = xticklabelposnodes[i],
            align = (:center, :top),
            textsize = xticklabelsize,
            show_axis = false,
            visible = xticklabelsvisible
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
            textsize = yticklabelsize,
            show_axis = false,
            visible = yticklabelsvisible
        )[end]
    end

    on(camera(scene), pixelarea(scene), limits) do pxa, lims

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = Float32.(lims.origin)
        limw, limh = Float32.(widths(lims))
        l, b = Float32.(pxa.origin)
        w, h = Float32.(widths(pxa))
        projection = AbstractPlotting.orthographicprojection(
            limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection

        px_aspect = pxa.widths[1] / pxa.widths[2]

        width = lims.widths[1]
        xrange = (lims.origin[1], lims.origin[1] + width)

        if width == 0 || !isfinite(xrange[1]) || !isfinite(xrange[2])
            return
        end

        ideal_tick_distance = 80 # px
        xtickvals = locateticks(xrange..., pxa.widths[1], ideal_tick_distance)
        # xtickvals, vminbest, vmaxbest = optimize_ticks(xrange...)


        # this code here tries to transform between values given in pixels of the
        # scene and the camera area, but this is incorrect right now and everything
        # should just be determined by the now unused limits that are saved in the
        # LayoutedAxis object
        xfractions = (xtickvals .- xrange[1]) ./ width
        xrange_scene = (pxa.origin[1], pxa.origin[1] + pxa.widths[1])
        width_scene = xrange_scene[2] - xrange_scene[1]
        xticks_scene = xrange_scene[1] .+ width_scene .* xfractions

        y = pxa.origin[2]
        xtickpositions = [Point(x, y) for x in xticks_scene]
        xtickstarts = [xtp + Point(0f0, xtickalign[] * xticksize[]) for xtp in xtickpositions]
        xtickends = [t + Point(0.0, -xticksize[]) for t in xtickstarts]

        # height = px_aspect < 1 ? a.widths[2] * px_aspect : a.widths[2]
        height = lims.widths[2]
        yrange = (lims.origin[2], lims.origin[2] + height)


        ytickvals = locateticks(yrange..., pxa.widths[2], ideal_tick_distance)
        # ytickvals, vminbest, vmaxbest = optimize_ticks(yrange...)
        yfractions = (ytickvals .- yrange[1]) ./ height
        yrange_scene = (pxa.origin[2], pxa.origin[2] + pxa.widths[2])
        height_scene = yrange_scene[2] - yrange_scene[1]
        yticks_scene = yrange_scene[1] .+ height_scene .* yfractions

        x = pxa.origin[1]
        ytickpositions = [Point(x, y) for y in yticks_scene]
        ytickstarts = [ytp + Point(ytickalign[] * yticksize[], 0f0) for ytp in ytickpositions]
        ytickends = [t + Point(-yticksize[], 0.0) for t in ytickstarts]


        # set and position tick labels
        xtickstrings = Showoff.showoff(xtickvals, :plain)
        nxticks = length(xtickvals)
        for i in 1:nmaxticks
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]
                xticklabelposnodes[i][] = xtickpositions[i] +
                    Point(0f0, -xticklabelpad[])
                xticklabels[i].visible = true && xticklabelsvisible[]
            else
                xticklabels[i].visible = false
            end
        end

        ytickstrings = Showoff.showoff(ytickvals, :plain)
        nyticks = length(ytickvals)
        for i in 1:nmaxticks
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]
                yticklabelposnodes[i][] = ytickpositions[i] +
                    Point(-yticklabelpad[], 0f0)
                yticklabels[i].visible = true && yticklabelsvisible[]
            else
                yticklabels[i].visible = false
            end
        end

        # set tick mark positions
        xticksnode[] = collect(Iterators.flatten(zip(xtickstarts, xtickends)))
        yticksnode[] = collect(Iterators.flatten(zip(ytickstarts, ytickends)))
    end

    xlabelpos = lift(scene.px_area, xlabelvisible, xticklabelsvisible,
        xticklabelpad, xticklabelsize, xlabelpadding) do a, xlabelvisible, xticklabelsvisible,
                xticklabelpad, xticklabelsize, xlabelpadding

        labelgap = xlabelpadding +
            (xticklabelsvisible ? xticklabelpad + xticklabelsize : 0f0)

        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area, ylabelvisible, yticklabelsvisible,
        yticklabelpad, yticklabelsize, ylabelpadding) do a, ylabelvisible, yticklabelsvisible,
                yticklabelpad, yticklabelsize, ylabelpadding

        labelgap = ylabelpadding +
            (yticklabelsvisible ? yticklabelpad + yticklabelsize : 0f0)

        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(
        parent, xlabel, textsize = xlabelsize,
        position = xlabelpos, show_axis = false, visible = xlabelvisible
    )[end]

    tx.align = (:center, :top)

    ty = text!(
        parent, ylabel, textsize = ylabelsize,
        position = ylabelpos, rotation = pi/2, show_axis = false,
        visible = ylabelvisible

    )[end]

    ty.align = (:center, :bottom)

    titlepos = lift(scene.px_area, titlegap) do a, titlegap
        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] + a.widths[2] + titlegap)
    end


    titlet = text!(
        parent, title,
        position = titlepos,
        visible = titlevisible,
        textsize = titlesize,
        align = (:center, :bottom),
        show_axis=false)[end]

    axislines!(parent, scene.px_area)

    function getprotrusions(xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
                ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding,
                ylabelpadding, xticklabelsize, yticklabelsize, xticklabelsvisible,
                yticklabelsvisible, xticksize, yticksize, xticksvisible, yticksvisible,
                xticklabelpad, yticklabelpad, xtickalign, ytickalign)

        top = titlevisible ? boundingbox(titlet).widths[2] + titlegap : 0f0
        bottom = (xlabelvisible ? boundingbox(tx).widths[2] + xlabelpadding : 0f0) +
            max(
                # when the xticklabel is visible take its size and pad
                (xticklabelsvisible ? xticklabelsize + xticklabelpad : 0f0),
                # or the xtick protrusion, depending on which value is larger
                (xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0)
            )
        left = (ylabelvisible ? boundingbox(ty).widths[1] + ylabelpadding : 0f0) +
            max(
                (yticklabelsvisible ? yticklabelsize + yticklabelpad : 0f0),
                (yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0)
            )
        right = 0f0

        (left, right, top, bottom)
    end

    protrusions = lift(getprotrusions,
        xlabel,
        ylabel,
        title,
        titlesize,
        titlegap,
        titlevisible,
        xlabelsize,
        ylabelsize,
        xlabelvisible,
        ylabelvisible,
        xlabelpadding,
        ylabelpadding,
        xticklabelsize,
        yticklabelsize,
        xticklabelsvisible,
        yticklabelsvisible,
        xticksize,
        yticksize,
        xticksvisible,
        yticksvisible,
        xticklabelpad,
        yticklabelpad,
        xtickalign,
        ytickalign
        )

    needs_update = Node(true)

    # trigger a layout update whenever the protrusions change
    on(protrusions) do prot
        needs_update[] = true
    end

    LayoutedAxis(parent, scene, bboxnode, limits, protrusions, needs_update, attrs)
end

function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedAxisLayout)
    # sa.axis.scene.px_area[] = IRect2D(sa.inner)
    sa.innerbboxnode[] = sa.innerbbox
end

function applylayout(sfb::SolvedBoxLayout)
    sfb.bboxnode[] = sfb.bbox
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
