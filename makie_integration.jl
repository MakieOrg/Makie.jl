using AbstractPlotting.Keyboard
using AbstractPlotting.Mouse
using AbstractPlotting: ispressed, is_mouseinside

function axislines!(scene, rect, spinewidth, topspinevisible, rightspinevisible,
    leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
    rightspinecolor, bottomspinecolor)

    bottomline = lift(rect, spinewidth) do r, sw
        y = r.origin[2] - 0.5f0 * sw
        p1 = Point2(r.origin[1] - sw, y)
        p2 = Point2(r.origin[1] + r.widths[1] + sw, y)
        [p1, p2]
    end

    leftline = lift(rect, spinewidth) do r, sw
        x = r.origin[1] - 0.5f0 * sw
        p1 = Point2(x, r.origin[2] - sw)
        p2 = Point2(x, r.origin[2] + r.widths[2] + sw)
        [p1, p2]
    end

    topline = lift(rect, spinewidth) do r, sw
        y = r.origin[2] + r.widths[2] + 0.5f0 * sw
        p1 = Point2(r.origin[1] - sw, y)
        p2 = Point2(r.origin[1] + r.widths[1] + sw, y)
        [p1, p2]
    end

    rightline = lift(rect, spinewidth) do r, sw
        x = r.origin[1] + r.widths[1] + 0.5f0 * sw
        p1 = Point2(x, r.origin[2] - sw)
        p2 = Point2(x, r.origin[2] + r.widths[2] + sw)
        [p1, p2]
    end

    lines!(scene, bottomline, linewidth = spinewidth, show_axis = false,
        visible = bottomspinevisible, color = bottomspinecolor)
    lines!(scene, leftline, linewidth = spinewidth, show_axis = false,
        visible = leftspinevisible, color = leftspinecolor)
    lines!(scene, rightline, linewidth = spinewidth, show_axis = false,
        visible = rightspinevisible, color = rightspinecolor)
    lines!(scene, topline, linewidth = spinewidth, show_axis = false,
        visible = topspinevisible, color = topspinecolor)
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

function add_pan!(scene::SceneLike, limits, xpanlock, ypanlock)
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

                xori, yori = Vec2f0(limits[].origin) .+ Vec2f0(diff_limits)

                if xpanlock[] || ispressed(scene, yzoom)
                    xori = limits[].origin[1]
                end

                if ypanlock[] || ispressed(scene, xzoom)
                    yori = limits[].origin[2]
                end

                limits[] = FRect(Vec2f0(xori, yori), widths(limits[]))
            end
        end
        return
    end
end

function add_zoom!(scene::SceneLike, limits, xzoomlock, yzoomlock)

    e = events(scene)
    cam = camera(scene)
    on(cam, e.scroll) do x
        # @extractvalue cam (zoomspeed, zoombutton, area)
        zoomspeed = 0.10f0
        zoombutton = nothing
        zoom = Float32(x[2])
        if zoom != 0 && ispressed(scene, zoombutton) && AbstractPlotting.is_mouseinside(scene)
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

            newxwidth = xzoomlock[] ? xwidth : xwidth * z
            newywidth = yzoomlock[] ? ywidth : ywidth * z

            newxorigin = xzoomlock[] ? xorigin : xorigin + mp_fraction[1] * (xwidth - newxwidth)
            newyorigin = yzoomlock[] ? yorigin : yorigin + mp_fraction[2] * (ywidth - newywidth)

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

function interleave_vectors(vec1::Vector{T}, vec2::Vector{T}) where T
    n = length(vec1)
    @assert n == length(vec2)

    vec = Vector{T}(undef, 2 * n)
    for i in 1:n
        k = 2(i - 1)
        vec[k + 1] = vec1[i]
        vec[k + 2] = vec2[i]
    end
    vec
end

function connect_scenearea_and_bbox!(scenearea, bboxnode, aspect, alignment, maxsize)
    onany(bboxnode, aspect, alignment, maxsize) do bbox, aspect, alignment, maxsize

        w = width(bbox)
        h = height(bbox)
        mw = min(w, maxsize[1])
        mh = min(h, maxsize[2])
        as = mw / mh

        aspect = aspect.aspect
        if !isnothing(aspect)

            if as >= aspect
                # too wide
                mw *= aspect / as
            else
                # too high
                mh *= as / aspect
            end
        end

        restw = w - mw
        resth = h - mh

        l = left(bbox) + alignment[1] * restw
        b = bottom(bbox) + alignment[2] * resth

        newbbox = BBox(l, l + mw, b + mh, b)

        # only update scene if pixel positions change
        new_scenearea = IRect2D(newbbox)
        if new_scenearea != scenearea[]
            scenearea[] = new_scenearea
        end
    end
end

function LayoutedAxis(parent::Scene; kwargs...)

    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedAxis))

    @extract attrs (
        xlabel, ylabel, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        xlabelcolor, ylabelcolor, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelpad,
        yticklabelpad, xtickalign, ytickalign, xtickwidth, ytickwidth, xtickcolor,
        ytickcolor, xpanlock,
        ypanlock, xzoomlock, yzoomlock, spinewidth, xgridvisible, ygridvisible,
        xgridwidth, ygridwidth, xgridcolor, ygridcolor, xidealtickdistance,
        yidealtickdistance, topspinevisible, rightspinevisible, leftspinevisible,
        bottomspinevisible, topspinecolor, leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, alignment, maxsize
    )

    bboxnode = Node(BBox(0, 100, 100, 0))

    scenearea = Node(IRect(0, 0, 100, 100))

    connect_scenearea_and_bbox!(scenearea, bboxnode, aspect, alignment, maxsize)

    scene = Scene(parent, scenearea, raw = true)
    limits = Node(FRect(0, 0, 100, 100))

    plots = AbstractPlot[]

    add_pan!(scene, limits, xpanlock, ypanlock)
    add_zoom!(scene, limits, xzoomlock, yzoomlock)

    campixel!(scene)

    # set up empty nodes for ticks and their labels
    xticksnode = Node(Point2f0[])
    xticks = linesegments!(
        parent, xticksnode, linewidth = xtickwidth, color = xtickcolor,
        show_axis = false, visible = xticksvisible
    )[end]

    yticksnode = Node(Point2f0[])
    yticks = linesegments!(
        parent, yticksnode, linewidth = ytickwidth, color = ytickcolor,
        show_axis = false, visible = yticksvisible
    )[end]

    xgridnode = Node(Point2f0[])
    xgridlines = linesegments!(
        parent, xgridnode, linewidth = xgridwidth, show_axis = false, visible = xgridvisible,
        color = xgridcolor
    )[end]

    ygridnode = Node(Point2f0[])
    ygridlines = linesegments!(
        parent, ygridnode, linewidth = ygridwidth, show_axis = false, visible = ygridvisible,
        color = ygridcolor
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

    xlabelpos = lift(scene.px_area, xlabelvisible, xticklabelsvisible,
        xticklabelpad, xticklabelsize, xlabelpadding, spinewidth) do a, xlabelvisible, xticklabelsvisible,
                xticklabelpad, xticklabelsize, xlabelpadding, spinewidth

        labelgap = xlabelpadding +
            0.5f0 * spinewidth +
            (xticklabelsvisible ? xticklabelpad + xticklabelsize : 0f0)

        Point2(a.origin[1] + a.widths[1] / 2, a.origin[2] - labelgap)
    end

    ylabelpos = lift(scene.px_area, ylabelvisible, yticklabelsvisible,
        yticklabelpad, yticklabelsize, ylabelpadding, spinewidth) do a, ylabelvisible, yticklabelsvisible,
                yticklabelpad, yticklabelsize, ylabelpadding, spinewidth

        labelgap = ylabelpadding +
            0.5f0 * spinewidth +
            (yticklabelsvisible ? yticklabelpad + yticklabelsize : 0f0)

        Point2(a.origin[1] - labelgap, a.origin[2] + a.widths[2] / 2)
    end

    tx = text!(
        parent, xlabel, textsize = xlabelsize, color = xlabelcolor,
        position = xlabelpos, show_axis = false, visible = xlabelvisible,
        align = (:center, :top)
    )[end]

    ty = text!(
        parent, ylabel, textsize = ylabelsize, color = ylabelcolor,
        position = ylabelpos, rotation = pi/2, show_axis = false,
        visible = ylabelvisible, align = (:center, :bottom)
    )[end]

    titlepos = lift(scene.px_area, titlegap, titlealign) do a, titlegap, align
        x = if align == :center
            a.origin[1] + a.widths[1] / 2
        elseif align == :left
            a.origin[1]
        elseif align == :right
            a.origin[1] + a.widths[1]
        else
            error("Title align $align not supported.")
        end

        Point2(x, a.origin[2] + a.widths[2] + titlegap)
    end

    titlealignnode = lift(titlealign) do align
        (align, :bottom)
    end

    titlet = text!(
        parent, title,
        position = titlepos,
        visible = titlevisible,
        textsize = titlesize,
        align = titlealignnode,
        font = titlefont,
        show_axis=false)[end]

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    xtickvalues = Node(Float32[])
    ytickvalues = Node(Float32[])

    # connect camera, plot size or limit changes to the axis decorations

    onany(pixelarea(scene), limits) do pxa, lims

        px_ox, px_oy = pxa.origin
        px_w, px_h = pxa.widths

        nearclip = -10_000f0
        farclip = 10_000f0

        limox, limoy = lims.origin
        limw, limh = lims.widths

        projection = AbstractPlotting.orthographicprojection(
            limox, limox + limw, limoy, limoy + limh, nearclip, farclip)
        camera(scene).projection[] = projection
        camera(scene).projectionview[] = projection
    end

    # change tick values with scene, limits and tick distance preference

    onany(pixelarea(scene), limits, xidealtickdistance) do pxa, limits, xidealtickdistance
        limox = limits.origin[1]
        limw = limits.widths[1]
        px_w = pxa.widths[1]
        xtickvalues[] = locateticks(limox, limox + limw, px_w, xidealtickdistance)
    end

    onany(pixelarea(scene), limits, yidealtickdistance) do pxa, limits, yidealtickdistance
        limoy = limits.origin[2]
        limh = limits.widths[2]
        px_h = pxa.widths[2]
        ytickvalues[] = locateticks(limoy, limoy + limh, px_h, yidealtickdistance)
    end

    xtickpositions = Node(Point2f0[])
    xtickstrings = Node(String[])

    # change tick positions when tick values change, also update grid and tick strings

    on(xtickvalues) do xtickvalues
        limox = limits[].origin[1]
        limw = limits[].widths[1]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        xfractions = (xtickvalues .- limox) ./ limw
        xticks_scene = px_ox .+ px_w .* xfractions

        xtickpos = [Point(x, px_oy) for x in xticks_scene]
        topxtickpositions = [xtp + Point2f0(0, px_h) for xtp in xtickpos]

        xgridnode[] = interleave_vectors(xtickpos, topxtickpositions)

        # now trigger updates
        xtickpositions[] = xtickpos

        xtickstrings[] = Showoff.showoff(xtickvalues, :plain)
    end

    ytickpositions = Node(Point2f0[])
    ytickstrings = Node(String[])

    on(ytickvalues) do ytickvalues
        limoy = limits[].origin[2]
        limh = limits[].widths[2]
        px_ox = pixelarea(scene)[].origin[1]
        px_oy = pixelarea(scene)[].origin[2]
        px_w = pixelarea(scene)[].widths[1]
        px_h = pixelarea(scene)[].widths[2]

        yfractions = (ytickvalues .- limoy) ./ limh
        yticks_scene = px_oy .+ px_h .* yfractions

        ytickpos = [Point(px_ox, y) for y in yticks_scene]
        rightytickpositions = [ytp + Point2f0(px_w, 0) for ytp in ytickpos]

        ygridnode[] = interleave_vectors(ytickpos, rightytickpositions)

        # now trigger updates
        ytickpositions[] = ytickpos

        ytickstrings[] = Showoff.showoff(ytickvalues, :plain)
    end

    # update tick labels when strings or properties change

    onany(xtickstrings, xticklabelpad, spinewidth, xticklabelsvisible) do xtickstrings,
            xticklabelpad, spinewidth, xticklabelsvisible

        nxticks = length(xtickvalues[])

        for i in 1:length(xticklabels)
            if i <= nxticks
                xticklabelnodes[i][] = xtickstrings[i]
                xticklabelposnodes[i][] = xtickpositions[][i] +
                    Point(0f0, -xticklabelpad - 0.5f0 * spinewidth)
                xticklabels[i].visible = true && xticklabelsvisible
            else
                xticklabels[i].visible = false
            end
        end
    end

    onany(ytickstrings, yticklabelpad, spinewidth, yticklabelsvisible) do ytickstrings,
            yticklabelpad, spinewidth, yticklabelsvisible

        nyticks = length(ytickvalues[])

        for i in 1:length(yticklabels)
            if i <= nyticks
                yticklabelnodes[i][] = ytickstrings[i]
                yticklabelposnodes[i][] = ytickpositions[][i] +
                    Point(-yticklabelpad - 0.5f0 * spinewidth, 0f0)
                yticklabels[i].visible = true && yticklabelsvisible
            else
                yticklabels[i].visible = false
            end
        end
    end

    # update tick geometry when positions or parameters change

    onany(xtickpositions, xtickalign, xticksize, spinewidth) do xtickpositions,
            xtickalign, xticksize, spinewidth

        xtickstarts = [xtp + Point(0f0, xtickalign * xticksize - 0.5f0 * spinewidth) for xtp in xtickpositions]
        xtickends = [t + Point(0f0, -xticksize) for t in xtickstarts]

        xticksnode[] = interleave_vectors(xtickstarts, xtickends)
    end

    onany(ytickpositions, ytickalign, yticksize, spinewidth) do ytickpositions,
            ytickalign, yticksize, spinewidth

        ytickstarts = [ytp + Point(ytickalign * yticksize - 0.5f0 * spinewidth, 0f0) for ytp in ytickpositions]
        ytickends = [t + Point(-yticksize, 0f0) for t in ytickstarts]

        yticksnode[] = interleave_vectors(ytickstarts, ytickends)
    end



    function compute_protrusions(xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
                ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding,
                ylabelpadding, xticklabelsize, yticklabelsize, xticklabelsvisible,
                yticklabelsvisible, xticksize, yticksize, xticksvisible, yticksvisible,
                xticklabelpad, yticklabelpad, xtickalign, ytickalign, spinewidth)

        top = titlevisible ? boundingbox(titlet).widths[2] + titlegap : 0f0
        bottom = (xlabelvisible ? boundingbox(tx).widths[2] + xlabelpadding : 0f0) +
            0.5f0 * spinewidth +
            max(
                # when the xticklabel is visible take its size and pad
                (xticklabelsvisible ? xticklabelsize + xticklabelpad : 0f0),
                # or the xtick protrusion, depending on which value is larger
                (xticksvisible ? max(0f0, xticksize * (1f0 - xtickalign)) : 0f0)
            )
        left = (ylabelvisible ? boundingbox(ty).widths[1] + ylabelpadding : 0f0) +
            0.5f0 * spinewidth +
            max(
                (yticklabelsvisible ? yticklabelsize + yticklabelpad : 0f0),
                (yticksvisible ? max(0f0, yticksize * (1f0 - ytickalign)) : 0f0)
            )
        right = 0f0

        (left, right, top, bottom)
    end

    protrusions = lift(compute_protrusions,
        xlabel, ylabel, title, titlesize, titlegap, titlevisible, xlabelsize,
        ylabelsize, xlabelvisible, ylabelvisible, xlabelpadding, ylabelpadding,
        xticklabelsize, yticklabelsize, xticklabelsvisible, yticklabelsvisible,
        xticksize, yticksize, xticksvisible, yticksvisible, xticklabelpad,
        yticklabelpad, xtickalign, ytickalign, spinewidth)

    needs_update = Node(true)

    # trigger a layout update whenever the protrusions change
    on(protrusions) do prot
        needs_update[] = true
    end

    LayoutedAxis(parent, scene, plots, bboxnode, limits, protrusions, needs_update, attrs)
end


function LayoutedColorbar(parent::Scene; kwargs...)
    attrs = merge!(default_attributes(LayoutedColorbar), Attributes(kwargs))

    @extract attrs (
        label, title, titlefont, titlesize, titlegap, titlevisible, titlealign,
        labelcolor, labelsize, labelvisible, labelpadding, ticklabelsize,
        ticklabelsvisible, ticksize, ticksvisible, ticklabelpad, tickalign,
        tickwidth, tickcolor, spinewidth, idealtickdistance, topspinevisible,
        rightspinevisible, leftspinevisible, bottomspinevisible, topspinecolor,
        leftspinecolor, rightspinecolor, bottomspinecolor,
        aspect, alignment, maxsize)

    bboxnode = Node(BBox(0, 100, 100, 0))

    scenearea = Node(IRect(0, 0, 100, 100))

    connect_scenearea_and_bbox!(scenearea, bboxnode, aspect, alignment, maxsize)

    limits = Node((0.0f0, 1.0f0))

    scene = Scene(parent, scenearea, raw = true)

    axislines!(
        parent, scene.px_area, spinewidth, topspinevisible, rightspinevisible,
        leftspinevisible, bottomspinevisible, topspinecolor, leftspinecolor,
        rightspinecolor, bottomspinecolor)

    campixel!(scene)

    protrusions = Node((0f0, 0f0, 0f0, 0f0))

    needs_update = Node(false)

    on(protrusions) do p
        needs_update[] = true
    end

    LayoutedColorbar(
        parent, scene, bboxnode, limits, protrusions,
        needs_update, attrs)
end

function LayoutedText(parent::Scene; kwargs...)
    attrs = merge!(Attributes(kwargs), default_attributes(LayoutedText))

    @extract attrs (text, textsize, font, color, visible, valign, halign,
        rotation)

    bboxnode = Node(BBox(0, 100, 100, 0))

    # align = lift(valign, halign) do v, h
    #     (h, v)
    # end

    position = Node(Point2f0(0, 0))

    t = text!(parent, text, position = position, textsize = textsize, font = font, color = color,
        visible = visible, align = (:center, :center), rotation = rotation)[end]

    heightnode = Node(1f0)
    widthnode = Node(1f0)

    onany(text, textsize, font, visible, rotation) do text, textsize, font, visible,
            rotation

        if visible
            bb = FRect2D(boundingbox(t))
            heightnode[] = height(bb)
            widthnode[] = width(bb)
        else
            heightnode[] = 0f0
            widthnode[] = 0f0
        end
    end

    onany(bboxnode, valign, halign) do bbox, valign, halign

        w = widthnode[]
        h = heightnode[]

        bw = width(bbox)
        bh = height(bbox)

        box = bbox.origin[1]
        boy = bbox.origin[2]

        x = if halign == :left
            box + 0.5f0 * w
        elseif halign == :right
            box + bw - 0.5f0 * w
        elseif halign == :center
            box + 0.5f0 * bw
        else
            error("Invalid halign $halign")
        end

        y = if valign == :bottom
            boy + 0.5f0 * h
        elseif valign == :top
            boy + bh - 0.5f0 * h
        elseif valign == :center
            boy + 0.5f0 * bh
        else
            error("Invalid valign $valign")
        end

        position[] = Point2f0(x, y)
    end

    lt = LayoutedText(parent, bboxnode, heightnode, widthnode, t, attrs)

    # trigger first update, otherwise bounds are wrong somehow
    text[] = text[]

    lt
end

function applylayout(sg::SolvedGridLayout)
    for c in sg.content
        applylayout(c.al)
    end
end

function applylayout(sa::SolvedAxisLayout)
    # sa.axis.scene.px_area[] = IRect2D(sa.inner)
    sa.bboxnode[] = sa.bbox
end

function applylayout(sb::SolvedBoxLayout)
    sb.bboxnode[] = sb.bbox
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
