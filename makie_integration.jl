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

function add_reset_limits!(la::LayoutedAxis)
    scene = la.scene
    e = events(scene)
    cam = camera(scene)
    on(cam, e.mousebuttons) do buttons
        if ispressed(scene, AbstractPlotting.Mouse.left) && AbstractPlotting.is_mouseinside(scene)
            if AbstractPlotting.ispressed(scene, AbstractPlotting.Keyboard.left_control)
                autolimits!(la)
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
