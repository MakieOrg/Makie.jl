################################################################################
### Main Block Intialization
################################################################################


can_be_current_axis(ax::PolarAxis) = true

function initialize_block!(po::PolarAxis; palette=nothing)
    # Setup Scenes
    cb = po.layoutobservables.computedbbox
    scenearea = map(po.blockscene, cb) do cb
        return Rect(round.(Int, minimum(cb)), round.(Int, widths(cb)))
    end

    po.scene = Scene(
        po.blockscene, scenearea, backgroundcolor = po.backgroundcolor, clear = true
    )
    map!(to_color, po.scene, po.scene.backgroundcolor, po.backgroundcolor)

    po.overlay = Scene(
        po.scene, scenearea, clear = false, backgroundcolor = :transparent,
        transformation = Transformation(po.scene, transform_func = identity)
    )


    # Setup Cycler
    po.cycler = Cycler()
    if palette === nothing
        palette = fast_deepcopy(get(po.blockscene.theme, :palette, DEFAULT_PALETTES))
    end
    po.palette = palette isa Attributes ? palette : Attributes(palette)


    # Setup camera/limits and Polar transform
    usable_fraction, radius_at_origin = setup_camera_matrices!(po)

    Observables.connect!(
        po.scene.transformation.transform_func,
        @lift(Polar($(po.theta_as_x), $(po.theta_0), $(po.direction), $(radius_at_origin)))
    )
    Observables.connect!(
        po.overlay.transformation.transform_func,
        @lift(Polar(false, $(po.theta_0), $(po.direction)))
    )

    # Draw clip, grid lines, spine, ticks
    rticklabelplot, thetaticklabelplot = draw_axis!(po, radius_at_origin)

    # Calculate fraction of screen usable after reserving space for theta ticks
    # TODO: Should we include rticks here?
    # OPT: only update on relevant text attributes rather than glyphcollection
    onany(
            po.blockscene,
            rticklabelplot.plots[1].text,
            rticklabelplot.plots[1].fontsize,
            rticklabelplot.plots[1].font,
            po.rticklabelpad,
            thetaticklabelplot.plots[1].text,
            thetaticklabelplot.plots[1].fontsize,
            thetaticklabelplot.plots[1].font,
            po.thetaticklabelpad,
            po.overlay.px_area
        ) do _, _, _, rpad, _, _, _, tpad, area

        # get maximum size of tick label
        # (each boundingbox represents a string without text.position applied)
        max_widths = Vec2f(0)
        for gc in thetaticklabelplot.plots[1].plots[1][1][]
            bbox = boundingbox(gc, Quaternionf(0, 0, 0, 1)) # no rotation
            max_widths = max.(max_widths, widths(bbox)[Vec(1,2)])
        end
        for gc in rticklabelplot.plots[1].plots[1][1][]
            bbox = boundingbox(gc, Quaternionf(0, 0, 0, 1)) # no rotation
            max_widths = max.(max_widths, widths(bbox)[Vec(1,2)])
        end

        max_width, max_height = max_widths

        space_from_center = 0.5 .* widths(area)
        space_for_ticks = 2max(rpad, tpad) .+ (max_width, max_height)
        space_for_axis = space_from_center .- space_for_ticks

        # divide by width only because aspect ratios
        usable_fraction[] = space_for_axis ./ space_from_center[1]
    end

    # Set up the title position
    title_position = map(
            po.blockscene,
            po.target_rlims, po.target_thetalims, po.theta_0, po.direction,
            po.rticklabelsize, po.rticklabelpad,
            po.thetaticklabelsize, po.thetaticklabelpad,
            po.overlay.px_area, po.overlay.camera.projectionview,
            po.titlegap, po.titlesize, po.titlealign
        ) do rlims, thetalims, theta_0, dir, r_fs, r_pad, t_fs, t_pad, area, pv, gap, size, align

        # derive y position
        # transform to pixel space
        w, h = widths(area)
        m = 0.5h * pv[2, 2]
        b = 0.5h * (pv[2, 4] + 1)

        thetamin, thetamax = extrema(dir .* (thetalims .+ theta_0))
        shift = 2pi * div(thetamin, 2pi, RoundDown)
        thetamin, thetamax = (thetamin, thetamax) .- shift

        if thetamin < pi/2 < thetamax
            # clip at 1 in overlay scene
            # theta fontsize & pad relevant
            ypx = (m * 1.0 + b) + (2t_pad + t_fs + gap)
        else
            y1 = sin(thetamin); y2 = sin(thetamax)
            rscale = rlims[1] / rlims[2]
            y = max(rscale * y1, rscale * y2, y1, y2)
            ypx = (m * y + b) + (2max(t_pad, r_pad) + max(t_fs, r_fs) + gap)
        end

        xpx::Float32 = if align === :center
            area.origin[1] + w / 2
        elseif align === :left
            area.origin[1]
        elseif align === :right
            area.origin[1] + w
        elseif align isa Real
            area.origin[1] + align * w
        else
            error("Title align $align not supported.")
        end

        return Point2f(xpx, area.origin[2] + ypx)
    end

    # p = scatter!(po.blockscene, title_position, color = :red, overdraw = true)
    # translate!(p, 0, 0, 9100)
    titleplot = text!(
        po.blockscene,
        title_position;
        text = po.title,
        font = po.titlefont,
        fontsize = po.titlesize,
        color = po.titlecolor,
        align = @lift(($(po.titlealign), :bottom)),
        visible = po.titlevisible,
    )
    translate!(titleplot, 0, 0, 9100) # Make sure this draws on top of clip

    # Protrusions are space reserved for ticks and labels outside `scenearea`.
    # Since we handle ticks within out `scenearea` this only needs to reserve
    # space for the title
    protrusions = map(
            po.blockscene, po.title, po.titlegap, po.titlesize
        ) do title, gap, size
        titlespace = po.title[] == "" ? 0f0 : Float32(2gap + size)
        return GridLayoutBase.RectSides(0f0, 0f0, 0f0, titlespace)
    end

    connect!(po.layoutobservables.protrusions, protrusions)

    return
end


################################################################################
### Camera and Controls
################################################################################


function polar2cartesian(r, angle)
    s, c = sincos(angle)
    return Point2f(r * c, r * s)
end

# Bounding box specified by limits in Cartesian coordinates
function polaraxis_bbox(rlims, thetalims, r0, dir, theta_0)
    thetamin, thetamax = thetalims
    rmin, rmax = max.(0.0, rlims .- r0)

    if abs(thetamax - thetamin) > 3pi/2
        return Rect2f(-rmax, -rmax, 2rmax, 2rmax)
    end

    @assert thetamin < thetamax # otherwise shift by 2pi I guess
    thetamin, thetamax = dir .* (thetalims .+ theta_0)

    # Normalize angles
    # keep interval in order
    if thetamin > thetamax
        thetamin, thetamax = thetamax, thetamin
    end
    # keep in -2pi .. 2pi interval
    shift = 2pi * (max(0, div(thetamin, -2pi)) - max(0, div(thetamax, 2pi)))
    thetamin += shift
    thetamax += shift

    # Initial bbox from corners
    p = polar2cartesian(rmin, thetamin)
    bb = Rect2f(p, Vec2f(0))
    bb = _update_rect(bb, polar2cartesian(rmax, thetamin))
    bb = _update_rect(bb, polar2cartesian(rmin, thetamax))
    bb = _update_rect(bb, polar2cartesian(rmax, thetamax))

    # only outer circle can update bb
    if thetamin < -3pi/2 < thetamax || thetamin < pi/2 < thetamax
        bb = _update_rect(bb, polar2cartesian(rmax, pi/2))
    end
    if thetamin < -pi < thetamax || thetamin < pi < thetamax
        bb = _update_rect(bb, polar2cartesian(rmax, pi))
    end
    if thetamin < -pi/2 < thetamax || thetamin < 3pi/2 < thetamax
        bb = _update_rect(bb, polar2cartesian(rmax, 3pi/2))
    end
    if thetamin < 0 < thetamax
        bb = _update_rect(bb, polar2cartesian(rmax, 0))
    end

    return bb
end

function setup_camera_matrices!(po::PolarAxis)
    # Initialization
    usable_fraction = Observable(Vec2f(1.0, 1.0))
    setfield!(po, :target_rlims, Observable{Tuple{Float64, Float64}}((0.0, 10.0)))
    setfield!(po, :target_thetalims, Observable{Tuple{Float64, Float64}}((0.0, 2pi)))
    reset_limits!(po)
    onany((_, _) -> reset_limits!(po), po.blockscene, po.rlimits, po.thetalimits)

    # To keep the inner clip radius below a certain fraction of the outer clip
    # radius we map all r > r0 to 0. This computes that r0.
    radius_at_origin = map(po.blockscene, po.target_rlims, po.radial_distortion_threshhold) do (rmin, rmax), max_fraction
        # max_fraction = (rmin - r0) / (rmax - r0) solved for r0
        return max(0.0, (rmin - max_fraction * rmax) / (1 - max_fraction))
    end

    # get cartesian bbox defined by axis limits
    # OPT: target_radius update triggers radius_at_origin update
    data_bbox = map(po.blockscene, po.target_thetalims, radius_at_origin, po.direction, po.theta_0) do tlims, ro, dir, t0
        return polaraxis_bbox(po.target_rlims[], tlims, ro, dir, t0)
    end

    # fit data_bbox into the usable area of PolarAxis (i.e. with tick space subtracted)
    onany(po.blockscene, usable_fraction, data_bbox) do usable_fraction, bb
        mini = minimum(bb); ws = widths(bb)
        scale = minimum(2usable_fraction ./ ws)
        trans = to_ndim(Vec3f, -scale .* (mini .+ 0.5ws), 0)
        camera(po.scene).view[] = transformationmatrix(trans, Vec3f(scale, scale, 1))
        return
    end

    # same as above, but with rmax scaled to 1
    onany(po.blockscene, usable_fraction, data_bbox) do usable_fraction, bb
        mini = minimum(bb); ws = widths(bb)
        rmax = po.target_rlims[][2] - radius_at_origin[] # both update data_bbox
        scale = minimum(2usable_fraction ./ ws)
        trans = to_ndim(Vec3f, -scale .* (mini .+ 0.5ws), 0)
        scale *= rmax
        camera(po.overlay).view[] = transformationmatrix(trans, Vec3f(scale, scale, 1))
    end

    max_z = 10_000f0

    # update projection matrices
    # this just aspect-aware clip space (-1 .. 1, -h/w ... h/w, -max_z ... max_z)
    on(po.blockscene, po.scene.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.scene).projection[] = orthographicprojection(-w, w, -h, h, -max_z, max_z)
    end

    on(po.blockscene, po.overlay.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.overlay).projection[] = orthographicprojection(-w, w, -h, h, -max_z, max_z)
    end

    # Interactivity
    e = events(po.scene)

    # scroll to zoom
    on(po.blockscene, e.scroll) do scroll
        if is_mouseinside(po.scene)
            mp = mouseposition(po.scene)
            r = norm(mp)
            zoom_scale = (1.0 - po.zoomspeed[]) ^ scroll[2]
            rmin, rmax = po.target_rlims[]
            thetamin, thetamax =  po.target_thetalims[]

            # keep circumference to radial length ratio constant by default
            dtheta = thetamax - thetamin
            aspect = r * dtheta / (rmax - rmin)

            # change in radial length
            dr = (zoom_scale - 1) * (rmax - rmin)

            # to keep the point under the cursor roughly in place we keep
            # r at the same percentage between rmin and rmax
            w = (r - rmin) / (rmax - rmin)

            # keep rmin at 0 when zooming near zero
            if rmin != 0 || r > 0.1rmax
                rmin = max(0, rmin - w * dr)
            end
            rmax = max(rmin + 1e-6, rmax + (1 - w) * dr)

            if !ispressed(e, po.thetazoomkey[])
                if po.fixrmin[]
                    rmin = po.target_rlims[][1]
                    rmax = max(rmin + 1e-6, rmax + dr)
                end
                po.target_rlims[] = (rmin, rmax)
            end

            if abs(thetamax - thetamin) < 2pi

                # angle of mouse position normalized to range
                theta = po.direction[] * atan(mp[2], mp[1]) - po.theta_0[]
                thetacenter = 0.5 * (thetamin + thetamax)
                theta = mod(theta, thetacenter-pi .. thetacenter+pi)

                w = (theta - thetamin) / (thetamax - thetamin)
                dtheta = (thetamax - thetamin) - clamp(aspect * (rmax - rmin) / r, 0, 2pi)
                thetamin = thetamin + w * dtheta
                thetamax = thetamax - (1-w) * dtheta

                if !ispressed(e, po.rzoomkey[])
                    po.target_thetalims[] = (thetamin, thetamax)
                end

            # don't open a gap when zooming a full circle near the center
            elseif r > 0.1rmax && zoom_scale < 1

                # open angle on the opposite site of theta
                theta = po.direction[] * atan(mp[2], mp[1]) - po.theta_0[]
                theta = mod(theta + pi, -pi..pi)

                dtheta = (thetamax - thetamin) - clamp(aspect * (rmax - rmin) / r, 1e-6, 2pi)
                thetamin = theta + 0.5 * dtheta
                thetamax = theta + 2pi - 0.5 * dtheta

                if !ispressed(e, po.rzoomkey[])
                    po.target_thetalims[] = (thetamin, thetamax)
                end
            end

            return Consume(true)
        end
        return Consume(false)
    end

    # translation
    last_pos = RefValue(Point2f(0))
    last_px_pos = RefValue(Point2f(0))
    on(po.blockscene, e.mousebutton) do e
        if e.action == Mouse.press && is_mouseinside(po.scene) && (
                ispressed(po.scene, po.r_translation_button[]) ||
                ispressed(po.scene, po.theta_translation_button[]) ||
                ispressed(po.scene, po.axis_rotation_button[])
            )
            last_px_pos[] = Point2f(mouseposition_px(po.scene))
            last_pos[] = Point2f(mouseposition(po.scene))
            return Consume(true)
        end
        return Consume(false)
    end

    on(po.blockscene, e.mouseposition) do _
        state = (
            ispressed(po.scene, po.r_translation_button[]),
            ispressed(po.scene, po.theta_translation_button[])
        )
        if ispressed(po.scene, po.axis_rotation_button[])
            w = widths(po.scene.px_area[])
            p0 = (last_px_pos[] .- 0.5w) ./ w
            p1 = Point2f(mouseposition_px(po.scene) .- 0.5w) ./ w
            if norm(p0) * norm(p1) < 1e-6
                Δθ = 0.0
            else
                Δθ = mod(po.direction[] * (atan(p1[2], p1[1]) - atan(p0[2], p0[1])), -pi..pi)
            end

            po.theta_0[] = mod(po.theta_0[] + Δθ, 0..2pi)

            last_px_pos[] = Point2f(mouseposition_px(po.scene))
            last_pos[] = Point2f(mouseposition(po.scene))

        elseif any(state)
            pos = Point2f(mouseposition(po.scene))
            diff = pos - last_pos[]
            r = norm(last_pos[])

            if r < 1e-6
                Δr = norm(pos)
                Δθ = 0.0
            else
                u_r = last_pos[] ./ r
                u_θ = Point2f(-u_r[2], u_r[1])
                Δr = dot(u_r, diff)
                Δθ = po.direction[] * dot(u_θ, diff ./ r)
            end

            if state[1]
                rmin, rmax = po.target_rlims[]
                dr = min(rmin, Δr)
                po.target_rlims[] = (rmin - dr, rmax - dr)
            end
            if state[2]
                thetamin, thetamax = po.target_thetalims[] .- Δθ
                shift = 2pi * (max(0, div(thetamin, -2pi)) - max(0, div(thetamax, 2pi)))
                po.target_thetalims[] = (thetamin, thetamax) .+ shift
                po.theta_0[] = mod(po.theta_0[] .+ Δθ, 0..2pi)
            end

            # Needs recomputation because target_radius may have changed
            last_px_pos[] = Point2f(mouseposition_px(po.scene))
            last_pos[] = Point2f(mouseposition(po.scene))
            return Consume(true)
        end
        return Consume(false)
    end

    # Reset button
    onany(po.blockscene, e.mousebutton, e.keyboardbutton) do e1, e2
        if ispressed(e, po.reset_button[]) && is_mouseinside(po.scene) &&
            (e1.action == Mouse.press) && (e2.action == Keyboard.press)
            if ispressed(e, Keyboard.left_shift)
                autolimits!(po)
            else
                reset_limits!(po)
            end
            return Consume(true)
        end
        return Consume(false)
    end

    return usable_fraction, radius_at_origin
end

function reset_limits!(po::PolarAxis)
    # at least one derived limit
    if any(isnothing, po.rlimits[]) || any(isnothing, po.thetalimits[])
        if !isempty(po.scene.plots)
            # TODO: Why does this include child scenes by default?

            # Generate auto limits
            lims2d = Rect2f(data_limits(po.scene, p -> !(p in po.scene.plots)))
            if po.theta_as_x[]
                ws = (widths(lims2d)[1] > 1.9pi ? 0.0 : widths(lims2d)[1], widths(lims2d)[2])
                thetamin, rmin = minimum(lims2d) .- 0.05 .* ws
                thetamax, rmax = maximum(lims2d) .+ 0.05 .* ws
            else
                ws = (widths(lims2d)[1], widths(lims2d)[2] > 1.9pi ? 0.0 : widths(lims2d)[2])
                rmin, thetamin = minimum(lims2d) .- 0.05 .* ws
                rmax, thetamax = maximum(lims2d) .+ 0.05 .* ws
            end

            # cleanup autolimits (0 width, negative rmin)
            rmin = max(0.0, rmin)
            if rmin == rmax
                rmin = max(0.0, rmin - 5.0)
                rmax = rmin + 10.0
            end
            if thetamin == thetamax
                thetamin, thetamax = (0.0, 2pi)
            elseif thetamax - thetamin > 1.5pi
                thetamax = thetamin + 2pi
            end

            # apply
            po.target_rlims[]     = ifelse.(isnothing.(po.rlimits[]),     (rmin, rmax),         po.rlimits[])
            po.target_thetalims[] = ifelse.(isnothing.(po.thetalimits[]), (thetamin, thetamax), po.thetalimits[])
        end
    else # all limits set
        if po.target_rlims[] != po.rlimits[]
            po.target_rlims[] = po.rlimits[]
        end
        if po.target_thetalims[] != po.thetalimits[]
            po.target_thetalims[] = po.thetalimits[]
        end
    end

    return
end


################################################################################
### Axis visualization - grid lines, clip, ticks
################################################################################


# generates large square with circle sector cutout
function _polar_clip_polygon(
        thetamin, thetamax, steps = 120, outer = 1e4,
        exterior = convert_arguments(PointBased(), Rect2f(-outer, -outer, 2outer, 2outer))[1]
    )
    # make sure we have 2+ points per arc
    interior = map(theta -> polar2cartesian(1.0, theta), LinRange(thetamin, thetamax, steps))
    (abs(thetamax - thetamin) ≈ 2pi) || push!(interior, Point2f(0))
    return [Polygon(exterior, [interior])]
end

function draw_axis!(po::PolarAxis, radius_at_origin)
    rtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    rtick_align = Observable{Point2f}()
    rtick_offset = Observable{Point2f}()
    rtick_rotation = Observable{Float32}()
    rgridpoints = Observable{Vector{GeometryBasics.LineString}}()
    rminorgridpoints = Observable{Vector{GeometryBasics.LineString}}()

    function default_rtickangle(rtickangle, direction, thetalims)
        if rtickangle === automatic
            if direction == -1
                return thetalims[2]
            else
                return thetalims[1]
            end
        else
            return rtickangle
        end
    end

    # OPT: target_radius update triggers radius_at_origin update
    onany(
            po.blockscene,
            po.rticks, po.rminorticks, po.rtickformat, po.rtickangle,
            po.direction, po.target_thetalims, po.sample_density, radius_at_origin
        ) do rticks, rminorticks, rtickformat, rtickangle,
            dir, thetalims, sample_density, radius_at_origin

        # For text:
        rlims = po.target_rlims[]
        rmaxinv = 1.0 / (rlims[2] - radius_at_origin)
        _rtickvalues, _rticklabels = get_ticks(rticks, identity, rtickformat, rlims...)
        _rtickradius = (_rtickvalues .- radius_at_origin) .* rmaxinv
        _rtickangle = default_rtickangle(rtickangle, dir, thetalims)
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickradius, _rtickangle))

        # For grid lines
        thetas = LinRange(thetalims..., sample_density)
        rgridpoints[] = GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rtickradius])

        _rminortickvalues = get_minor_tickvalues(rminorticks, identity, _rtickvalues, rlims...)
        _rminortickvalues .= (_rminortickvalues .- radius_at_origin) .* rmaxinv
        rminorgridpoints[] = GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rminortickvalues])

        return
    end

    # doesn't have a lot of overlap with the inputs above so calculate this independently
    onany(
            po.blockscene,
            po.direction, po.theta_0, po.rtickangle, po.target_thetalims, po.rticklabelpad,
            po.rticklabelrotation
        ) do dir, theta_0, rtickangle, thetalims, pad, rot
        angle = mod(dir * (default_rtickangle(rtickangle, dir, thetalims) + theta_0), 0..2pi)
        s, c = sincos(angle - pi/2)
        rtick_offset[] = Point2f(pad * c, pad * s)
        if rot == false
            rtick_rotation[] = 0f0
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            rtick_align[] = Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        elseif rot == true
            rtick_rotation[] = angle - pi/2
            rtick_align[] = Point2f(0, 0.5)
        elseif rot === automatic
            N = div(angle + pi/4, pi/2) % 4
            rtick_rotation[] = angle - (N) * pi/2 # mod(angle, -pi/4 .. pi/4)
            rtick_align[] = Point2f((0.5, 0.0, 0.5, 1.0)[N+1], (1.0, 0.5, 0.0, 0.5)[N+1])
        else
            rtick_rotation[] = rot
            scale = 1 / max(abs(s), abs(c))
            rtick_align[] = Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end
        return
    end


    thetatick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    thetatick_align = Observable(Point2f[])
    thetatick_offset = Observable(Point2f[])
    thetagridpoints = Observable{Vector{Point2f}}()
    thetaminorgridpoints = Observable{Vector{Point2f}}()

    onany(
            po.blockscene,
            po.thetaticks, po.thetaminorticks, po.thetatickformat, po.thetaticklabelpad,
            po.direction, po.theta_0, po.target_rlims, po.target_thetalims, po.radial_distortion_threshhold
        ) do thetaticks, thetaminorticks, thetatickformat, px_pad, dir, theta_0, rlims, thetalims, max_clip

        _thetatickvalues, _thetaticklabels = get_ticks(thetaticks, identity, thetatickformat, thetalims...)

        # Since theta = 0 is at the same position as theta = 2π, we remove the last tick
        # iff the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_thetatickvalues[end] - _thetatickvalues[begin]) == 2π
            pop!(_thetatickvalues)
            pop!(_thetaticklabels)
        end

        # Text
        resize!(thetatick_align.val, length(_thetatickvalues))
        resize!(thetatick_offset.val, length(_thetatickvalues))
        for (i, angle) in enumerate(_thetatickvalues)
            s, c = sincos(dir * (angle + theta_0))
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            thetatick_align.val[i] = Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
            thetatick_offset.val[i] = Point2f(px_pad * c, px_pad * s)
        end
        foreach(notify, (thetatick_align, thetatick_offset))

        thetatick_pos_lbl[] = tuple.(_thetaticklabels, Point2f.(1, _thetatickvalues))

        # Grid lines
        rmin = min(rlims[1] / rlims[2], max_clip)
        thetagridpoints[] = [Point2f(r, theta) for theta in _thetatickvalues for r in (rmin, 1)]

        _thetaminortickvalues = get_minor_tickvalues(thetaminorticks, identity, _thetatickvalues, thetalims...)
        thetaminorgridpoints[] = [Point2f(r, theta) for theta in _thetaminortickvalues for r in (rmin, 1)]

        return
    end

    notify(po.target_thetalims)

    # plot using the created observables

    # major grids
    rgridplot = lines!(
        po.overlay, rgridpoints;
        color = po.rgridcolor,
        linestyle = po.rgridstyle,
        linewidth = po.rgridwidth,
        visible = po.rgridvisible,
    )

    thetagridplot = linesegments!(
        po.overlay, thetagridpoints;
        color = po.thetagridcolor,
        linestyle = po.thetagridstyle,
        linewidth = po.thetagridwidth,
        visible = po.thetagridvisible,
    )
    # minor grids
    rminorgridplot = lines!(
        po.overlay, rminorgridpoints;
        color = po.rminorgridcolor,
        linestyle = po.rminorgridstyle,
        linewidth = po.rminorgridwidth,
        visible = po.rminorgridvisible,
    )

    thetaminorgridplot = linesegments!(
        po.overlay, thetaminorgridpoints;
        color = po.thetaminorgridcolor,
        linestyle = po.thetaminorgridstyle,
        linewidth = po.thetaminorgridwidth,
        visible = po.thetaminorgridvisible,
    )

    # tick labels

    clipcolor = map(po.blockscene, po.clipcolor, po.backgroundcolor) do cc, bgc
        return cc === automatic ? RGBf(to_color(bgc)) : RGBf(to_color(cc))
    end

    rstrokecolor = map(po.blockscene, clipcolor, po.rticklabelstrokecolor) do bg, sc
        sc === automatic ? bg : to_color(sc)
    end

    rticklabelplot = text!(
        po.overlay, rtick_pos_lbl;
        fontsize = po.rticklabelsize,
        font = po.rticklabelfont,
        color = po.rticklabelcolor,
        strokewidth = po.rticklabelstrokewidth,
        strokecolor = rstrokecolor,
        align = rtick_align,
        rotation = rtick_rotation,
        visible = po.rticklabelsvisible
    )
    # OPT: skip glyphcollection update on offset changes
    rticklabelplot.plots[1].plots[1].offset = rtick_offset


    thetastrokecolor = map(po.blockscene, clipcolor, po.thetaticklabelstrokecolor) do bg, sc
        sc === automatic ? bg : to_color(sc)
    end

    thetaticklabelplot = text!(
        po.overlay, thetatick_pos_lbl;
        fontsize = po.thetaticklabelsize,
        font = po.thetaticklabelfont,
        color = po.thetaticklabelcolor,
        strokewidth = po.thetaticklabelstrokewidth,
        strokecolor = thetastrokecolor,
        align = thetatick_align[],
        visible = po.thetaticklabelsvisible
    )
    thetaticklabelplot.plots[1].plots[1].offset = thetatick_offset

    # Hack to deal with synchronous update problems
    on(po.blockscene, thetatick_align) do align
        thetaticklabelplot.align.val = align
        if length(align) == length(thetatick_pos_lbl[])
            notify(thetaticklabelplot.align)
        end
        return
    end

    # Clipping

    # create large square with r=1 circle sector cutout
    # only regenerate if circle sector angle changes
    thetadiff = map(lims -> abs(lims[2] - lims[1]), po.blockscene, po.target_thetalims, ignore_equal_values = true)
    outer_clip = map(po.blockscene, thetadiff, po.sample_density) do diff, sample_density
        return _polar_clip_polygon(0, diff, sample_density)
    end
    outer_clip_plot = poly!(
        po.overlay,
        outer_clip,
        color = clipcolor,
        visible = po.clip,
        fxaa = false,
        transformation = Transformation(), # no polar transform for this
        shading = false
    )

    # inner clip is a (filled) circle sector which also needs to regenerate with
    # changes in thetadiff
    inner_clip = map(po.blockscene, thetadiff, po.sample_density) do diff, sample_density
        pad = diff / sample_density
        if diff > 2pi - 2pad
            ps = polar2cartesian.(1.0, LinRange(0, 2pi, sample_density))
        else
            ps = polar2cartesian.(1.0, LinRange(-pad, diff + pad, sample_density))
            push!(ps, Point2f(0))
        end
        return Polygon(ps)
    end
    inner_clip_plot = poly!(
        po.overlay,
        inner_clip,
        color = clipcolor,
        visible = po.clip,
        fxaa = false,
        transformation = Transformation(),
        shading = false
    )

    # handle placement with transform
    onany(po.blockscene, po.target_thetalims, po.direction, po.theta_0) do thetalims, dir, theta_0
        thetamin, thetamax = dir .* (thetalims .+ theta_0)
        angle = dir > 0 ? thetamin : thetamax
        rotate!.((outer_clip_plot, inner_clip_plot), (Vec3f(0,0,1),), angle)
    end

    onany(po.blockscene, po.target_rlims, po.radial_distortion_threshhold) do lims, maxclip
        s = min(lims[1] / lims[2], maxclip)
        scale!(inner_clip_plot, Vec3f(s, s, 1))
    end

    notify(po.radial_distortion_threshhold)

    # spine traces circle sector - inner circle
    spine_points = map(po.blockscene,
            po.target_rlims, po.target_thetalims, po.radial_distortion_threshhold, po.sample_density
        ) do (rmin, rmax), thetalims, max_clip, N
        thetamin, thetamax = thetalims
        rmin = min(rmin/rmax, max_clip)
        rmax = 1.0

        # make sure we have 2+ points per arc
        if abs(thetamax - thetamin) ≈ 2pi
            ps = Point2f.(rmax, LinRange(thetamin, thetamax, N))
            if rmin > 1e-6
                push!(ps, Point2f(NaN))
                append!(ps, Point2f.(rmin, LinRange(thetamin, thetamax, N)))
            end
        else
            ps = sizehint!(Point2f[], 2N+1)
            for angle in LinRange(thetamin, thetamax, N)
                push!(ps, Point2f(rmin, angle))
            end
            for angle in LinRange(thetamax, thetamin, N)
                push!(ps, Point2f(rmax, angle))
            end
            push!(ps, first(ps))
        end
        return ps
    end
    spineplot = lines!(
        po.overlay,
        spine_points,
        strokecolor = po.spinecolor,
        strokewidth = po.spinewidth,
        linestyle = po.spinestyle,
        visible = po.spinevisible
    )

    notify(po.target_thetalims)

    translate!.((rticklabelplot, thetaticklabelplot), 0, 0, 9002)
    translate!(spineplot, 0, 0, 9001)
    translate!.((outer_clip_plot, inner_clip_plot), 0, 0, 9000)
    on(po.blockscene, po.griddepth) do depth
        translate!.((rgridplot, thetagridplot, rminorgridplot, thetaminorgridplot), 0, 0, depth)
    end
    notify(po.griddepth)

    return rticklabelplot, thetaticklabelplot
end


################################################################################
### Plotting
################################################################################


function plot!(
    po::PolarAxis, P::PlotFunc,
    attributes::Attributes, args...;
    kw_attributes...)

    allattrs = merge(attributes, Attributes(kw_attributes))

    cycle = get_cycle_for_plottype(allattrs, P)
    add_cycle_attributes!(allattrs, P, cycle, po.cycler, po.palette)

    plot = plot!(po.scene, P, allattrs, args...)

    reset_limits!(po)

    plot
end


function plot!(P::PlotFunc, po::PolarAxis, args...; kw_attributes...)
    attributes = Attributes(kw_attributes)
    plot!(po, P, attributes, args...)
end

delete!(ax::PolarAxis, p::AbstractPlot) = delete!(ax.scene, p)


################################################################################
### Utilities
################################################################################


function autolimits!(po::PolarAxis)
    po.rlimits[] = (0.0, nothing)
    po.thetalimits[] = (nothing, nothing)
    return
end

"""
    rlims!(ax::PolarAxis[, rmin], rmax)

Sets the radial limits of a given `PolarAxis`.
"""
rlims!(po::PolarAxis, r::Union{Nothing, Real}) = rlims!(po, po.rlimits[][1], r)

function rlims!(po::PolarAxis, rmin::Union{Nothing, Real}, rmax::Union{Nothing, Real})
    po.rlimits[] = (rmin, rmax)
    return
end

"""
    thetalims!(ax::PolarAxis, thetamin, thetamax)

Sets the angular limits of a given `PolarAxis`.
"""
function thetalims!(po::PolarAxis, thetamin::Union{Nothing, Real}, thetamax::Union{Nothing, Real})
    po.thetalimits[] = (thetamin, thetamax)
    return
end

"""
    restrict_to_full_circle!(ax::PolarAxis[, enable = true])

Restricts a given PolarAxis to not show partial views of a circle. Can be reset
by passing `false`.
"""
function restrict_to_full_circle!(po::PolarAxis, enabled = true)
    # no center cutout, always 0..2pi
    rlims!(po, enabled ? 0.0 : nothing, po.rlimits[][2])
    po.thetalimits[] = enabled ? (0.0, 2pi) : (nothing, nothing)
    # only rmax zooming
    po.fixrmin[]      = enabled ? true : false
    po.rzoomkey[]     = enabled ? true : Keyboard.r
    po.thetazoomkey[] = enabled ? false : Keyboard.t
    # onyl translate in theta
    po.r_translation_button[] = enabled ? false : Mouse.right
    reset_limits!(po)
    return
end