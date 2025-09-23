struct Axis3Camera <: AbstractCamera end

function initialize_block!(ax::Axis3)

    blockscene = ax.blockscene

    on(blockscene, ax.protrusions) do prot
        ax.layoutobservables.protrusions[] = to_protrusions(prot)
    end
    notify(ax.protrusions)

    finallimits = Observable(Rect3d(Vec3d(0.0), Vec3d(100.0)))
    setfield!(ax, :finallimits, finallimits)

    scenearea = lift(blockscene, ax.layoutobservables.computedbbox, ax.layoutobservables.protrusions) do bbox, prot
        mini = minimum(bbox) - Vec2(prot.left, prot.bottom)
        maxi = maximum(bbox) + Vec2(prot.right, prot.top)
        return round_to_IRect2D(Rect2f(mini, maxi - mini))
    end

    onany(blockscene, scenearea, ax.clip_decorations) do area, clip
        if clip
            blockscene.viewport[] = area
        elseif blockscene.viewport[] != root(blockscene).viewport[]
            blockscene.viewport[] = root(blockscene).viewport[]
        end
    end

    scene = Scene(blockscene, scenearea, clear = false, backgroundcolor = ax.backgroundcolor)
    ax.scene = scene
    # transfer conversions from axis to scene if there are any
    # or the other way around
    connect_conversions!(scene.conversions, ax)

    cam = Axis3Camera()
    cameracontrols!(scene, cam)
    scene.theme.clip_planes = map(scene, scene.transformation.model, ax.finallimits, ax.clip) do model, lims, clip
        if clip
            _planes = planes(lims)
            _planes = apply_transform.(Ref(model), _planes)
            nudge = 1.0f0 + 1.0f-5 # clip slightly outside to avoid float precision issues with 0 margin
            return map(plane -> Plane3f(plane.normal, nudge * plane.distance), _planes)
        else
            return Plane3f[]
        end
    end

    mi1 = Observable(!(pi / 2 <= mod1(ax.azimuth[], 2pi) < 3pi / 2))
    mi2 = Observable(0 <= mod1(ax.azimuth[], 2pi) < pi)
    mi3 = Observable(ax.elevation[] > 0)

    on(scene, ax.azimuth) do x
        b = !(pi / 2 <= mod1(x, 2pi) < 3pi / 2)
        mi1.val == b || (mi1[] = b)
        return
    end
    on(scene, ax.azimuth) do x
        b = 0 <= mod1(x, 2pi) < pi
        mi2.val == b || (mi2[] = b)
        return
    end
    on(scene, ax.elevation) do x
        mi3.val == (x > 0) || (mi3[] = x > 0)
        return
    end

    setfield!(ax, :axis_offset, Observable(Vec2d(0)))
    setfield!(ax, :zoom_mult, Observable(1.0))

    matrices = lift(
        calculate_matrices, scene, finallimits, scene.viewport, ax.protrusions,
        ax.elevation, ax.azimuth, ax.perspectiveness, ax.aspect, ax.viewmode,
        ax.xreversed, ax.yreversed, ax.zreversed,
        ax.zoom_mult, ax.axis_offset, ax.near
    )

    on(scene, matrices) do (model, view, proj, lookat, eyepos)
        cam = camera(scene)
        Makie.set_proj_view!(cam, proj, view)
        scene.transformation.model[] = model

        viewdir = normalize(lookat - eyepos)
        up = Vec3d(0, 0, 1)
        u_z = -viewdir
        u_x = normalize(cross(up, u_z))
        cam.eyeposition[] = eyepos
        cam.upvector[] = cross(u_z, u_x)
        cam.view_direction[] = viewdir
    end

    ticknode_1 = Observable{Any}()
    map!(scene, ticknode_1, finallimits, ax.xticks, ax.xtickformat) do lims, ticks, format
        get_ticks(ax.scene.conversions[1], ticks, identity, format, minimum(lims)[1], maximum(lims)[1])
    end

    ticknode_2 = Observable{Any}()
    map!(scene, ticknode_2, finallimits, ax.yticks, ax.ytickformat) do lims, ticks, format
        get_ticks(ax.scene.conversions[2], ticks, identity, format, minimum(lims)[2], maximum(lims)[2])
    end

    ticknode_3 = Observable{Any}()
    map!(scene, ticknode_3, finallimits, ax.zticks, ax.ztickformat) do lims, ticks, format
        get_ticks(ax.scene.conversions[3], ticks, identity, format, minimum(lims)[3], maximum(lims)[3])
    end

    add_panel!(scene, ax, 1, 2, 3, finallimits, mi3)
    add_panel!(scene, ax, 2, 3, 1, finallimits, mi1)
    add_panel!(scene, ax, 1, 3, 2, finallimits, mi2)

    # This exists as a bandaid for WGLMakie. See add_gridlines_and_frames!()
    overlay = Scene(
        blockscene, scenearea, clear = false, backgroundcolor = :transparent,
        camera = scene.camera, transformation = scene.transformation
    )

    xgridline1, xgridline2, xframelines = add_gridlines_and_frames!(
        blockscene, scene, overlay, ax, 1, finallimits, ticknode_1, mi1, mi2, mi3,
        ax.xreversed, ax.yreversed, ax.zreversed
    )
    ygridline1, ygridline2, yframelines = add_gridlines_and_frames!(
        blockscene, scene, overlay, ax, 2, finallimits, ticknode_2, mi2, mi1, mi3,
        ax.xreversed, ax.yreversed, ax.zreversed
    )
    zgridline1, zgridline2, zframelines = add_gridlines_and_frames!(
        blockscene, scene, overlay, ax, 3, finallimits, ticknode_3, mi3, mi1, mi2,
        ax.xreversed, ax.yreversed, ax.zreversed
    )

    xticks, xticklabels, xlabel =
        add_ticks_and_ticklabels!(blockscene, scene, ax, 1, finallimits, ticknode_1, mi1, mi2, mi3, ax.azimuth, ax.xreversed, ax.yreversed, ax.zreversed)
    yticks, yticklabels, ylabel =
        add_ticks_and_ticklabels!(blockscene, scene, ax, 2, finallimits, ticknode_2, mi2, mi1, mi3, ax.azimuth, ax.xreversed, ax.yreversed, ax.zreversed)
    zticks, zticklabels, zlabel =
        add_ticks_and_ticklabels!(blockscene, scene, ax, 3, finallimits, ticknode_3, mi3, mi1, mi2, ax.azimuth, ax.xreversed, ax.yreversed, ax.zreversed)

    titlepos = lift(scene, ax.layoutobservables.computedbbox, ax.titlegap, ax.titlealign) do a, titlegap, align

        align_factor = halign2num(align, "Horizontal title align $align not supported.")
        x = a.origin[1] + align_factor * a.widths[1]

        yoffset = top(a) + titlegap

        Point2(x, yoffset)
    end

    titlealignnode = lift(scene, ax.titlealign) do align
        (align, :bottom)
    end

    titlet = text!(
        blockscene, ax.title,
        position = titlepos,
        visible = ax.titlevisible,
        fontsize = ax.titlesize,
        align = titlealignnode,
        font = ax.titlefont,
        color = ax.titlecolor,
        markerspace = :data,
        inspectable = false
    )

    ax.mouseeventhandle = addmouseevents!(scene)
    scrollevents = Observable(ScrollEvent(0, 0))
    setfield!(ax, :scrollevents, scrollevents)
    keysevents = Observable(KeysEvent(Set()))
    setfield!(ax, :keysevents, keysevents)

    on(scene, scene.events.scroll) do s
        if is_mouseinside(scene)
            ax.scrollevents[] = ScrollEvent(s[1], s[2])
            return Consume(true)
        end
        return Consume(false)
    end

    on(scene, scene.events.keyboardbutton) do e
        ax.keysevents[] = KeysEvent(scene.events.keyboardstate)
        return Consume(false)
    end

    ax.interactions = Dict{Symbol, Tuple{Bool, Any}}()

    on(scene, ax.limits) do lims
        reset_limits!(ax)
    end

    on(scene, ax.targetlimits) do lims
        # adjustlimits!(ax)
        # we have no aspect constraints here currently, so just update final limits
        ax.finallimits[] = lims
        return
    end

    function process_event(event)
        ax.scene.visible[] || return Consume(false)
        for (active, interaction) in values(ax.interactions)
            if active
                maybe_consume = process_interaction(interaction, event, ax)
                maybe_consume == Consume(true) && return Consume(true)
            end
        end
        return Consume(false)
    end

    on(process_event, scene, ax.mouseeventhandle.obs)
    on(process_event, scene, ax.scrollevents)
    on(process_event, scene, ax.keysevents)

    register_interaction!(ax, :dragrotate, DragRotate())
    register_interaction!(ax, :limitreset, LimitReset())
    register_interaction!(ax, :scrollzoom, ScrollZoom(0.05, NaN))
    register_interaction!(ax, :translation, DragPan(NaN))
    register_interaction!(ax, :cursorfocus, FocusOnCursor(length(ax.scene.plots)))

    # in case the user set limits already
    notify(ax.limits)

    return
end

function calculate_matrices(
        limits, viewport, protrusions, elev, azim, perspectiveness, aspect,
        viewmode, xreversed, yreversed, zreversed, zoom_mult, scene_offset, near
    )

    ori = limits.origin
    ws = widths(limits)

    limits = Rect3d(
        (
            ori[1] + (xreversed ? ws[1] : zero(ws[1])),
            ori[2] + (yreversed ? ws[2] : zero(ws[2])),
            ori[3] + (zreversed ? ws[3] : zero(ws[3])),
        ),
        (
            ws[1] * (xreversed ? -1 : 1),
            ws[2] * (yreversed ? -1 : 1),
            ws[3] * (zreversed ? -1 : 1),
        )
    )

    ws = widths(limits)

    if aspect === :equal
        scales = 2 ./ Float64.(ws)
    elseif aspect === :data
        scales = 2 .* sign.(ws) ./ max.(maximum(ws), Float64.(ws))
    elseif aspect isa VecTypes{3}
        scales = 2 ./ Float64.(ws) .* Float64.(aspect) ./ maximum(aspect)
    else
        error("Invalid aspect $aspect")
    end

    # center and scale axis bbox so that the longest side is -1..1
    # then rotate (and permute axes) according to azimuth and elevation
    model =
        translationmatrix(-0.5 .* ws .* scales) *
        scalematrix(scales) *
        translationmatrix(-Float64.(limits.origin))

    ang_max = 90
    ang_min = 0.5

    @assert 0 <= perspectiveness <= 1

    fov = ang_min + (ang_max - ang_min) * perspectiveness

    # After model content is normalized to a -1..1^3 box, i.e. within radius sqrt(3)
    radius = zoom_mult * sqrt(3) / sind(fov / 2)
    camdir = Vec3d(cos(elev) * cos(azim), cos(elev) * sin(azim), sin(elev))
    eyepos = radius * camdir

    if viewmode == :free
        up = Vec3d(0, 0, 1)
        u_z = camdir
        u_x = normalize(cross(up, u_z))
        u_y = cross(u_z, u_x)

        lookat = zoom_mult * sqrt(3) * (scene_offset[1] * u_x + scene_offset[2] * u_y)
        eyepos += lookat
    else
        lookat = Vec3d(0)
    end

    lookat_matrix = Makie.lookat(eyepos, lookat, Vec3d(0, 0, 1))

    w = width(viewport)
    h = height(viewport)

    projection_matrix = projectionmatrix(
        lookat_matrix * model, limits, radius, fov,
        w, h, to_protrusions(protrusions), viewmode, near
    )

    return model, lookat_matrix, projection_matrix, lookat, eyepos
end

function projectionmatrix(viewmatrix, limits, radius, fov, width, height, protrusions, viewmode, near_limit)
    # model normalizes the the longest axis of the axis bbox to -1..1, so its
    # bounding sphere has a radius of sqrt(3)
    # The distance of the camera to the center of the bounding sphere is "radius"
    near_limit > 0.0 || error("near value must be > 0, but is $near_limit.")
    near = max(near_limit, radius - sqrt(3))
    far = max((1 + 1.0e-3) * near, radius + sqrt(3))

    aspect_ratio = width / height

    return projection_matrix = if viewmode in (:free, :fit, :fitzoom, :stretch)
        if height > width
            fov = fov / aspect_ratio
        end

        # this transforms w.r.t scene viewport, i.e. protrusions are not yet
        # included
        pm = Makie.perspectiveprojection(Float64, fov, aspect_ratio, near, far)

        # protrusions shrink the effective viewport which causes clip space
        # coordinates in the real viewport to grow
        dx = (protrusions.left - protrusions.right) / width
        dy = (protrusions.bottom - protrusions.top) / height
        w = (width - protrusions.left - protrusions.right)
        h = (height - protrusions.bottom - protrusions.top)

        if viewmode in (:fitzoom, :stretch)
            # coordinates of axis rect w.r.t real viewport
            points = decompose(Point3d, limits)
            projpoints = Ref(pm * viewmatrix) .* to_ndim.(Point4d, points, 1)

            # convert to effective viewport
            w = w / width; h = h / height
            maxx = maximum(x -> abs(x[1] / (w * x[4])), projpoints)
            maxy = maximum(x -> abs(x[2] / (h * x[4])), projpoints)

            # normalization to map max x/y to 1 in effective viewport
            ratio_x = 1.0 / maxx
            ratio_y = 1.0 / maxy

            if viewmode === :fitzoom
                s = min(ratio_x, ratio_y)
                pm = transformationmatrix(Vec3(dx, dy, 0), Vec3(s, s, 1)) * pm
            else
                pm = transformationmatrix(Vec3(dx, dy, 0), Vec3(ratio_x, ratio_y, 1)) * pm
            end
        else
            wh = min(w, h) / min(width, height) # works for :fit
            pm = transformationmatrix(Vec3(dx, dy, 0), Vec3(wh, wh, 1)) * pm
        end

        pm
    else
        error("Invalid viewmode $viewmode")
    end
end

function update_state_before_display!(ax::Axis3)
    reset_limits!(ax)
    return
end

function autolimits!(ax::Axis3)
    ax.limits[] = (nothing, nothing, nothing)
    return
end

to_protrusions(x::Number) = GridLayoutBase.RectSides{Float32}(x, x, x, x)
to_protrusions(x::Tuple{Any, Any, Any, Any}) = GridLayoutBase.RectSides{Float32}(x...)

function getlimits(ax::Axis3, dim)
    dim in (1, 2, 3) || error("Dimension $dim not allowed. Only 1, 2 or 3.")

    filtered_plots = filter(ax.scene.plots) do p
        attr = p.attributes
        visible = to_value(get(p, :visible, true))
        visible &&
            is_data_space(p) &&
            ifelse(dim == 1, to_value(get(attr, :xautolimits, true)), true) &&
            ifelse(dim == 2, to_value(get(attr, :yautolimits, true)), true) &&
            ifelse(dim == 3, to_value(get(attr, :zautolimits, true)), true)
    end

    bboxes = Makie.data_limits.(filtered_plots)
    finite_bboxes = filter(Makie.isfinite_rect, bboxes)

    isempty(finite_bboxes) && return nothing

    templim = (finite_bboxes[1].origin[dim], finite_bboxes[1].origin[dim] + finite_bboxes[1].widths[dim])

    for bb in finite_bboxes[2:end]
        templim = limitunion(templim, (bb.origin[dim], bb.origin[dim] + bb.widths[dim]))
    end

    return templim
end

function dimpoint(dim, v, v1, v2)
    return if dim == 1
        Point(v, v1, v2)
    elseif dim == 2
        Point(v1, v, v2)
    elseif dim == 3
        Point(v1, v2, v)
    end
end

function dim1(dim)
    return if dim == 1
        2
    elseif dim == 2
        1
    elseif dim == 3
        1
    end
end

function dim2(dim)
    return if dim == 1
        3
    elseif dim == 2
        3
    elseif dim == 3
        2
    end
end

function add_gridlines_and_frames!(topscene, scene, overlay, ax, dim::Int, limits, ticknode, miv, min1, min2, xreversed, yreversed, zreversed)

    dimsym(sym) = Symbol(string((:x, :y, :z)[dim]) * string(sym))
    attr(sym) = getproperty(ax, dimsym(sym))

    dpoint = (v, v1, v2) -> dimpoint(dim, v, v1, v2)
    d1 = dim1(dim)
    d2 = dim2(dim)


    tickvalues = @lift($ticknode[1])

    endpoints = lift(limits, tickvalues, min1, min2, xreversed, yreversed, zreversed) do lims, ticks, min1, min2, xrev, yrev, zrev
        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]
        f1 = min1 ⊻ rev1 ? minimum(lims)[d1] : maximum(lims)[d1]
        f2 = min2 ⊻ rev2 ? minimum(lims)[d2] : maximum(lims)[d2]
        # from tickvalues and f1 and min2:max2
        mi = minimum(lims)
        ma = maximum(lims)
        map(filter(x -> !any(y -> x ≈ y[dim], extrema(lims)), ticks)) do t
            dpoint(t, f1, mi[d2]), dpoint(t, f1, ma[d2])
        end
    end
    gridline1 = linesegments!(
        scene, endpoints, color = attr(:gridcolor),
        linewidth = attr(:gridwidth), clip_planes = Plane3f[],
        xautolimits = false, yautolimits = false, zautolimits = false, transparency = true,
        visible = attr(:gridvisible), inspectable = false
    )

    endpoints2 = lift(limits, tickvalues, min1, min2, xreversed, yreversed, zreversed) do lims, ticks, min1, min2, xrev, yrev, zrev
        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]
        f1 = min1 ⊻ rev1 ? minimum(lims)[d1] : maximum(lims)[d1]
        f2 = min2 ⊻ rev2 ? minimum(lims)[d2] : maximum(lims)[d2]
        # from tickvalues and f1 and min2:max2
        mi = minimum(lims)
        ma = maximum(lims)
        map(filter(x -> !any(y -> x ≈ y[dim], extrema(lims)), ticks)) do t
            dpoint(t, mi[d1], f2), dpoint(t, ma[d1], f2)
        end
    end
    gridline2 = linesegments!(
        scene, endpoints2, color = attr(:gridcolor),
        linewidth = attr(:gridwidth), clip_planes = Plane3f[],
        xautolimits = false, yautolimits = false, zautolimits = false, transparency = true,
        visible = attr(:gridvisible), inspectable = false
    )


    framepoints = lift(
        limits, min1, min2, xreversed, yreversed, zreversed
    ) do lims, mi1, mi2, xrev, yrev, zrev

        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]

        mi1 = mi1 ⊻ rev1
        mi2 = mi2 ⊻ rev2

        f(mi) = mi ? minimum : maximum
        p1 = dpoint(minimum(lims)[dim], f(!mi1)(lims)[d1], f(mi2)(lims)[d2])
        p2 = dpoint(maximum(lims)[dim], f(!mi1)(lims)[d1], f(mi2)(lims)[d2])
        p3 = dpoint(minimum(lims)[dim], f(mi1)(lims)[d1], f(mi2)(lims)[d2])
        p4 = dpoint(maximum(lims)[dim], f(mi1)(lims)[d1], f(mi2)(lims)[d2])
        p5 = dpoint(minimum(lims)[dim], f(mi1)(lims)[d1], f(!mi2)(lims)[d2])
        p6 = dpoint(maximum(lims)[dim], f(mi1)(lims)[d1], f(!mi2)(lims)[d2])

        return [p1, p2, p3, p4, p5, p6]
    end
    framepoints_front_spines = lift(
        limits, min1, min2, xreversed, yreversed, zreversed
    ) do lims, mi1, mi2, xrev, yrev, zrev

        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]

        mi1 = mi1 ⊻ rev1
        mi2 = mi2 ⊻ rev2

        f(mi) = mi ? minimum : maximum

        p7 = dpoint(minimum(lims)[dim], f(!mi1)(lims)[d1], f(!mi2)(lims)[d2])
        p8 = dpoint(maximum(lims)[dim], f(!mi1)(lims)[d1], f(!mi2)(lims)[d2])

        return [p7, p8]
    end
    colors = Observable{Any}()
    map!(vcat, colors, attr(:spinecolor_1), attr(:spinecolor_2), attr(:spinecolor_3))

    framelines = linesegments!(
        scene, framepoints, color = colors, linewidth = attr(:spinewidth),
        transparency = true, visible = attr(:spinesvisible), inspectable = false,
        xautolimits = false, yautolimits = false, zautolimits = false, clip_planes = Plane3f[]
    )

    front_framelines = linesegments!(
        overlay, framepoints_front_spines, color = attr(:spinecolor_4),
        linewidth = attr(:spinewidth), visible = map((a, b) -> a && b, ax.front_spines, attr(:spinesvisible)),
        transparency = true, inspectable = false,
        xautolimits = false, yautolimits = false, zautolimits = false, clip_planes = Plane3f[]
    )

    #= On transparency and render order
    We have transparency = true here mostly for render order and depth testing
    reasons.
    In GLMakie:
    - transparency = true gets rendered after transparency = false. This fixes
      artifacts of the line AA, which mixes with the current background. (I.e.
      if lines render first they will mix with the scene background color rather
      than plots)
    - transparency = true turns off depth writes which means the frame lines don't
      see the grid lines and draw over them. This fixes grid lines poking through
      frame lines, and also fixes mixing issues where frame lines meet. This
      could also be fixed by explicit order with overdraw = true
    - Note that transparency = true causes frame lines to never be 100% opaque
      in GLMakie
    In WGLMakie:
    - transparency = true also turns off depth writes, see above
    - transparency = true does not affect render order. Since it does turn off
      depth writes other things will draw over the front frame lines. To fix this
      we add an overlay scene which renders after the main scene, i.e. after
      grid lines, back frame lines and user plots.
    In CairoMakie:
    - transparency does not matter, only plot order does. The overlay scene
      forces does the same as in WGLMakie
    =#

    return gridline1, gridline2, framelines
end

function add_ticks_and_ticklabels!(topscene, scene, ax, dim::Int, limits, ticknode, miv, min1, min2, azimuth, xreversed, yreversed, zreversed)

    dimsym(sym) = Symbol(string((:x, :y, :z)[dim]) * string(sym))
    attr(sym) = getproperty(ax, dimsym(sym))

    dpoint = (v, v1, v2) -> dimpoint(dim, v, v1, v2)
    d1 = dim1(dim)
    d2 = dim2(dim)

    tickvalues = @lift($ticknode[1])
    ticklabels = Observable{Any}()
    map!(ticklabels, ticknode) do (values, labels)
        labels
    end
    ticksize = attr(:ticksize)

    tick_segments = lift(
        topscene, limits, tickvalues, miv, min1, min2,
        scene.camera.projectionview, scene.viewport, ticksize, xreversed, yreversed, zreversed
    ) do lims, ticks, miv, min1, min2,
            pview, pxa, tsize, xrev, yrev, zrev

        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]

        f1 = !(min1 ⊻ rev1) ? minimum(lims)[d1] : maximum(lims)[d1]
        f2 = (min2 ⊻ rev2) ? minimum(lims)[d2] : maximum(lims)[d2]

        f1_oppo = (min1 ⊻ rev1) ? minimum(lims)[d1] : maximum(lims)[d1]
        f2_oppo = !(min2 ⊻ rev2) ? minimum(lims)[d2] : maximum(lims)[d2]

        diff_f1 = f1 - f1_oppo
        diff_f2 = f2 - f2_oppo

        o = (origin(pxa) - origin(topscene.viewport[]))

        return map(ticks) do t
            p1 = dpoint(t, f1, f2)
            p2 = if dim == 3
                # special case the z axis, here it depends on azimuth in which direction the ticks go
                if 45 <= mod1(rad2deg(azimuth[]), 180) <= 135
                    dpoint(t, f1 + diff_f1, f2)
                else
                    dpoint(t, f1, f2 + diff_f2)
                end
            else
                dpoint(t, f1 + diff_f1, f2)
            end

            pp1 = Point2f(o + Makie.project(scene, p1))
            pp2 = Point2f(o + Makie.project(scene, p2))
            diff_pp = Makie.GeometryBasics.normalize(Point2f(pp2 - pp1))

            return (pp1, pp1 .+ Float32(tsize) .* diff_pp)
        end
    end

    ticks = linesegments!(
        topscene, tick_segments,
        transparency = true, inspectable = false,
        color = attr(:tickcolor), linewidth = attr(:tickwidth), visible = attr(:ticksvisible)
    )
    # move ticks behind plots, -10000 is the far value in campixel
    translate!(ticks, 0, 0, -10000)

    labels_positions = Observable{Any}()
    map!(
        topscene, labels_positions, scene.viewport, scene.camera.projectionview,
        tick_segments, ticklabels, attr(:ticklabelpad)
    ) do pxa, pv, ticksegs, ticklabs, pad

        o = (origin(pxa) - origin(topscene.viewport[]))

        points = map(ticksegs) do (tstart, tend)
            offset = pad * Makie.GeometryBasics.normalize(Point2f(tend - tstart))
            tend + offset
        end

        N = min(length(ticklabs), length(points))
        Tuple{Any, Point2f}[(ticklabs[i], points[i]) for i in 1:N]
    end

    align = lift(topscene, miv, min1, min2) do mv, m1, m2
        if dim == 1
            (mv ⊻ m1 ? :right : :left, m2 ? :top : :bottom)
        elseif dim == 2
            (mv ⊻ m1 ? :left : :right, m2 ? :top : :bottom)
        elseif dim == 3
            (m1 ⊻ m2 ? :left : :right, :center)
        end
    end

    ticklabels_text = text!(
        topscene, labels_positions, align = align,
        color = attr(:ticklabelcolor), fontsize = attr(:ticklabelsize),
        font = attr(:ticklabelfont), visible = attr(:ticklabelsvisible), inspectable = false
    )

    translate!(ticklabels_text, 0, 0, 1000)

    label_position = Observable(Point2f(0))
    label_rotation = Observable(0.0f0)
    label_align = Observable((:center, :top))

    onany(
        topscene,
        scene.viewport, scene.camera.projectionview, limits, miv, min1, min2,
        attr(:labeloffset), attr(:labelrotation), attr(:labelalign), xreversed, yreversed, zreversed
    ) do pxa, pv, lims, miv, min1, min2, labeloffset, lrotation, lalign, xrev, yrev, zrev

        o = (origin(pxa) - origin(topscene.viewport[]))

        rev1 = (xrev, yrev, zrev)[d1]
        rev2 = (xrev, yrev, zrev)[d2]
        revdim = (xrev, yrev, zrev)[dim]

        minr1 = min1 ⊻ rev1
        minr2 = min2 ⊻ rev2

        f1 = !minr1 ? minimum(lims)[d1] : maximum(lims)[d1]
        f2 = minr2 ? minimum(lims)[d2] : maximum(lims)[d2]

        # get end points of axis
        p1 = dpoint(minimum(lims)[dim], f1, f2)
        p2 = dpoint(maximum(lims)[dim], f1, f2)

        # project them into screen space
        pp1 = Point2f(o + Makie.project(scene, p1))
        pp2 = Point2f(o + Makie.project(scene, p2))

        # find the midpoint
        midpoint = (pp1 + pp2) ./ 2

        # and the difference vector
        diff = pp2 - pp1

        diffsign = if dim == 1 || dim == 3
            !(min1 ⊻ min2 ⊻ revdim) ? 1 : -1
        else
            (min1 ⊻ min2 ⊻ revdim) ? 1 : -1
        end

        a = pi / 2

        # get the vector pointing from the axis in the direction of the label anchor
        offset_vec = (
            Makie.Mat2f(cos(a), sin(a), -sin(a), cos(a)) *
                Makie.GeometryBasics.normalize(diffsign * diff)
        )

        # calculate the label offset from the axis midpoint
        plus_offset = midpoint + labeloffset * offset_vec

        offset_ang = atan(offset_vec[2], offset_vec[1])
        offset_ang_90deg = offset_ang + pi / 2
        offset_ang_90deg_alwaysup = ((offset_ang + pi / 2 + pi / 2) % pi) - pi / 2

        # # prefer rotated left 90deg to rotated right 90deg
        slight_flip = offset_ang_90deg_alwaysup < -deg2rad(88)
        if slight_flip
            offset_ang_90deg_alwaysup += pi
        end

        labelrotation = if lrotation == Makie.automatic
            offset_ang_90deg_alwaysup
        else
            lrotation
        end

        valign = offset_vec[2] > 0 || slight_flip ? :bottom : :top
        align = if lalign == Makie.automatic
            (:center, valign)
        else
            lalign
        end

        label_align[] != align && (label_align[] = align)
        label_rotation[] != labelrotation && (label_rotation[] = labelrotation)
        label_position[] = plus_offset

        return
    end
    notify(attr(:labelalign))

    label = text!(
        topscene, label_position,
        text = attr(:label),
        color = attr(:labelcolor),
        fontsize = attr(:labelsize),
        font = attr(:labelfont),
        rotation = label_rotation,
        align = label_align,
        visible = attr(:labelvisible),
        inspectable = false
    )

    return ticks, ticklabels_text, label
end

function dim3point(dim1, dim2, dim3, v1, v2, v3)
    return if (dim1, dim2, dim3) == (1, 2, 3)
        Point(v1, v2, v3)
    elseif (dim1, dim2, dim3) == (2, 3, 1)
        Point(v3, v1, v2)
    elseif (dim1, dim2, dim3) == (1, 3, 2)
        Point(v1, v3, v2)
    else
        error("Invalid dim order $dim1, $dim2, $dim3")
    end
end

function add_panel!(scene, ax, dim1, dim2, dim3, limits, min3)

    dimsym(sym) = Symbol(
        string((:x, :y, :z)[dim1]) *
            string((:x, :y, :z)[dim2]) * string(sym)
    )
    attr(sym) = getproperty(ax, dimsym(sym))

    rect = lift(limits) do lims
        mi = minimum(lims)
        ma = maximum(lims)
        Polygon(
            [
                Point2(mi[dim1], mi[dim2]),
                Point2(ma[dim1], mi[dim2]),
                Point2(ma[dim1], ma[dim2]),
                Point2(mi[dim1], ma[dim2]),
            ]
        )
    end

    plane_offset = lift(limits, min3) do lims, mi3
        mi = minimum(lims)
        ma = maximum(lims)

        mi3 ? mi[dim3] : ma[dim3]
    end

    plane = Symbol((:x, :y, :z)[dim1], (:x, :y, :z)[dim2])

    panel = poly!(
        scene, rect, inspectable = false,
        xautolimits = false, yautolimits = false, zautolimits = false,
        color = attr(:panelcolor), visible = attr(:panelvisible),
        strokecolor = :transparent, strokewidth = 0,
        transformation = (plane, 0),
    )

    on(plane_offset) do offset
        translate!(
            panel,
            dim3 == 1 ? offset : zero(offset),
            dim3 == 2 ? offset : zero(offset),
            dim3 == 3 ? offset : zero(offset),
        )
    end

    return panel
end

function hidexdecorations!(
        ax::Axis3;
        label = true, ticklabels = true, ticks = true, grid = true
    )

    if label
        ax.xlabelvisible = false
    end
    if ticklabels
        ax.xticklabelsvisible = false
    end
    if ticks
        ax.xticksvisible = false
    end
    if grid
        ax.xgridvisible = false
    end
    # if minorgrid
    #     ax.xminorgridvisible = false
    # end
    # if minorticks
    #     ax.xminorticksvisible = false
    # end

    return ax
end

function hideydecorations!(
        ax::Axis3;
        label = true, ticklabels = true, ticks = true, grid = true
    )

    if label
        ax.ylabelvisible = false
    end
    if ticklabels
        ax.yticklabelsvisible = false
    end
    if ticks
        ax.yticksvisible = false
    end
    if grid
        ax.ygridvisible = false
    end
    # if minorgrid
    #     ax.yminorgridvisible = false
    # end
    # if minorticks
    #     ax.yminorticksvisible = false
    # end

    return ax
end

"""
    hidezdecorations!(ax::Axis3; label = true, ticklabels = true, ticks = true, grid = true)

Hide decorations of the z-axis: label, ticklabels, ticks and grid. Keyword
arguments can be used to disable hiding of certain types of decorations.
"""
function hidezdecorations!(
        ax::Axis3;
        label = true, ticklabels = true, ticks = true, grid = true
    )

    if label
        ax.zlabelvisible = false
    end
    if ticklabels
        ax.zticklabelsvisible = false
    end
    if ticks
        ax.zticksvisible = false
    end
    if grid
        ax.zgridvisible = false
    end
    # if minorgrid
    #     ax.zminorgridvisible = false
    # end
    # if minorticks
    #     ax.zminorticksvisible = false
    # end

    return ax
end

function hidedecorations!(
        ax::Axis3;
        label = true, ticklabels = true, ticks = true, grid = true
    )

    hidexdecorations!(
        ax; label = label, ticklabels = ticklabels,
        ticks = ticks, grid = grid
    )
    hideydecorations!(
        ax; label = label, ticklabels = ticklabels,
        ticks = ticks, grid = grid
    )
    hidezdecorations!(
        ax; label = label, ticklabels = ticklabels,
        ticks = ticks, grid = grid
    )

    return ax
end

function hidespines!(ax::Axis3)
    ax.xspinesvisible = false
    ax.yspinesvisible = false
    ax.zspinesvisible = false
    return ax
end


# this is so users can do limits = (x1, x2, y1, y2, z1, z2)
function convert_limit_attribute(lims::Tuple{Any, Any, Any, Any, Any, Any})
    return (lims[1:2], lims[3:4], lims[5:6])
end

function convert_limit_attribute(lims::Tuple{Any, Any, Any})
    _convert_single_limit(x) = x
    _convert_single_limit(x::Interval) = endpoints(x)
    return map(_convert_single_limit, lims)
end


function xautolimits(ax::Axis3)
    xlims = getlimits(ax, 1)

    if isnothing(xlims)
        xlims = (ax.targetlimits[].origin[1], ax.targetlimits[].origin[1] + ax.targetlimits[].widths[1])
    else
        xlims = expandlimits(
            xlims,
            ax.xautolimitmargin[][1],
            ax.xautolimitmargin[][2],
            identity
        )
    end
    return xlims
end

function yautolimits(ax::Axis3)
    ylims = getlimits(ax, 2)

    if isnothing(ylims)
        ylims = (ax.targetlimits[].origin[2], ax.targetlimits[].origin[2] + ax.targetlimits[].widths[2])
    else
        ylims = expandlimits(
            ylims,
            ax.yautolimitmargin[][1],
            ax.yautolimitmargin[][2],
            identity
        )
    end
    return ylims
end

function zautolimits(ax::Axis3)
    zlims = getlimits(ax, 3)

    if isnothing(zlims)
        zlims = (ax.targetlimits[].origin[3], ax.targetlimits[].origin[3] + ax.targetlimits[].widths[3])
    else
        zlims = expandlimits(
            zlims,
            ax.zautolimitmargin[][1],
            ax.zautolimitmargin[][2],
            identity
        )
    end
    return zlims
end

Makie.xlims!(ax::Axis3, xlims::Interval) = Makie.xlims!(ax, endpoints(xlims))
Makie.ylims!(ax::Axis3, ylims::Interval) = Makie.ylims!(ax, endpoints(ylims))
Makie.zlims!(ax::Axis3, zlims::Interval) = Makie.zlims!(ax, endpoints(zlims))

function Makie.xlims!(ax::Axis3, xlims::Tuple{Union{Real, Nothing}, Union{Real, Nothing}})
    if length(xlims) != 2
        error("Invalid xlims length of $(length(xlims)), must be 2.")
    elseif xlims[1] == xlims[2] && xlims[1] !== nothing
        error("Can't set x limits to the same value $(xlims[1]).")
    elseif all(x -> x isa Real, xlims) && xlims[1] > xlims[2]
        xlims = reverse(xlims)
        ax.xreversed[] = true
    else
        ax.xreversed[] = false
    end
    mlims = convert_limit_attribute(ax.limits[])

    ax.limits.val = (xlims, mlims[2], mlims[3])
    reset_limits!(ax, yauto = false, zauto = false)
    return nothing
end

function Makie.ylims!(ax::Axis3, ylims::Tuple{Union{Real, Nothing}, Union{Real, Nothing}})
    if length(ylims) != 2
        error("Invalid ylims length of $(length(ylims)), must be 2.")
    elseif ylims[1] == ylims[2] && ylims[1] !== nothing
        error("Can't set y limits to the same value $(ylims[1]).")
    elseif all(x -> x isa Real, ylims) && ylims[1] > ylims[2]
        ylims = reverse(ylims)
        ax.yreversed[] = true
    else
        ax.yreversed[] = false
    end
    mlims = convert_limit_attribute(ax.limits[])

    ax.limits.val = (mlims[1], ylims, mlims[3])
    reset_limits!(ax, xauto = false, zauto = false)
    return nothing
end

function Makie.zlims!(ax::Axis3, zlims)
    if length(zlims) != 2
        error("Invalid zlims length of $(length(zlims)), must be 2.")
    elseif zlims[1] == zlims[2] && zlims[1] !== nothing
        error("Can't set z limits to the same value $(zlims[1]).")
    elseif all(x -> x isa Real, zlims) && zlims[1] > zlims[2]
        zlims = reverse(zlims)
        ax.zreversed[] = true
    else
        ax.zreversed[] = false
    end
    mlims = convert_limit_attribute(ax.limits[])

    ax.limits.val = (mlims[1], mlims[2], zlims)
    reset_limits!(ax, xauto = false, yauto = false)
    return nothing
end


"""
    limits!(ax::Axis3, xlims, ylims, zlims)

Set the axis limits to `xlims`, `ylims`, and `zlims`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis3, xlims, ylims, zlims)
    Makie.xlims!(ax, xlims)
    Makie.ylims!(ax, ylims)
    return Makie.zlims!(ax, zlims)
end

"""
    limits!(ax::Axis3, x1, x2, y1, y2, z1, z2)

Set the axis x-limits to `x1` and `x2`, the y-limits to `y1` and `y2`, and the
z-limits to `z1` and `z2`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis3, x1, x2, y1, y2, z1, z2)
    Makie.xlims!(ax, x1, x2)
    Makie.ylims!(ax, y1, y2)
    return Makie.zlims!(ax, z1, z2)
end

"""
    limits!(ax::Axis3, rect::Rect3)

Set the axis limits to `rect`.
If limits are ordered high-low, this reverses the axis orientation.
"""
function limits!(ax::Axis3, rect::Rect3)
    xmin, ymin, zmin = minimum(rect)
    xmax, ymax, zmax = maximum(rect)
    Makie.xlims!(ax, xmin, xmax)
    Makie.ylims!(ax, ymin, ymax)
    return Makie.zlims!(ax, zmin, zmax)
end

function attribute_examples(::Type{Axis3})
    return Dict(
        :aspect => [
            Example(
                code = """
                fig = Figure()

                Axis3(fig[1, 1], aspect = (1, 1, 1), title = "aspect = (1, 1, 1)")
                Axis3(fig[1, 2], aspect = (2, 1, 1), title = "aspect = (2, 1, 1)")
                Axis3(fig[2, 1], aspect = (1, 2, 1), title = "aspect = (1, 2, 1)")
                Axis3(fig[2, 2], aspect = (1, 1, 2), title = "aspect = (1, 1, 2)")

                fig
                """
            ),
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], aspect = :equal, title = "aspect = :equal")
                ax2 = Axis3(fig[1, 2], aspect = :data, title = "aspect = :data")

                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = :gray80)
                end

                fig
                """
            ),
        ],
        :viewmode => [
            Example(
                code = """
                fig = Figure()

                for (i, viewmode) in enumerate([:fit, :fitzoom, :stretch])
                    for (j, elevation) in enumerate([0.1, 0.2, 0.3] .* pi)

                        Label(fig[i, 1:3, Top()], "viewmode = \$(repr(viewmode))", font = :bold)

                        # show the extent of each cell using a box
                        Box(fig[i, j], strokewidth = 0, color = :gray95)

                        ax = Axis3(fig[i, j]; viewmode, elevation, protrusions = 0, aspect = :equal)
                        hidedecorations!(ax)

                    end
                end

                fig
                """
            ),
        ],
        :perspectiveness => [
            Example(
                code = """
                fig = Figure()

                for (i, perspectiveness) in enumerate(range(0, 1, length = 6))
                    ax = Axis3(fig[fldmod1(i, 3)...]; perspectiveness, protrusions = (0, 0, 0, 15),
                        title = ":perspectiveness = \$(perspectiveness)")
                    hidedecorations!(ax)
                end

                fig
                """
            ),
        ],
        :azimuth => [
            Example(
                code = """
                fig = Figure()

                for (i, azimuth) in enumerate([0, 0.1, 0.2, 0.3, 0.4, 0.5])
                    Axis3(fig[fldmod1(i, 3)...], azimuth = azimuth * pi,
                        title = "azimuth = \$(azimuth)π", viewmode = :fit)
                end

                fig
                """
            ),
        ],
        :elevation => [
            Example(
                code = """
                fig = Figure()

                for (i, elevation) in enumerate([0, 0.05, 0.1, 0.15, 0.2, 0.25])
                    Axis3(fig[fldmod1(i, 3)...], elevation = elevation * pi,
                        title = "elevation = \$(elevation)π", viewmode = :fit)
                end

                fig
                """
            ),
        ],
        :xreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "xreversed = false")
                ax2 = Axis3(fig[2, 1], title = "xreversed = true", xreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 1))
                end

                fig
                    """
            ),
        ],
        :yreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "yreversed = false")
                ax2 = Axis3(fig[2, 1], title = "yreversed = true", yreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 2))
                end

                fig
                """
            ),
        ],
        :zreversed => [
            Example(
                code = """
                using FileIO

                fig = Figure()

                brain = load(assetpath("brain.stl"))

                ax1 = Axis3(fig[1, 1], title = "zreversed = false")
                ax2 = Axis3(fig[2, 1], title = "zreversed = true", zreversed = true)
                for ax in [ax1, ax2]
                    mesh!(ax, brain, color = getindex.(brain.position, 3))
                end

                fig
                """
            ),
        ],
        :protrusions => [
            Example(
                code = """
                    fig = Figure(backgroundcolor = :gray97)
                    Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
                    Axis3(fig[1, 1], protrusions = 100, viewmode = :stretch,
                        title = "protrusions = 100")
                    fig
                """
            ),
            Example(
                code = """
                    fig = Figure(backgroundcolor = :gray97)
                    Box(fig[1, 1], strokewidth = 0) # visualizes the layout cell
                    ax = Axis3(fig[1, 1], protrusions = (0, 0, 0, 20), viewmode = :stretch,
                        title = "protrusions = (0, 0, 0, 20)")
                    hidedecorations!(ax)
                    fig
                """
            ),
        ]
    )
end


# Axis interface

tightlimits!(ax::Axis3) = nothing # TODO, not implemented yet
