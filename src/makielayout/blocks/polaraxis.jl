################################################################################
### Main Block Intialization
################################################################################


Makie.can_be_current_axis(ax::PolarAxis) = true

function Makie.initialize_block!(po::PolarAxis; palette=nothing)
    # Setup Scenes
    cb = po.layoutobservables.computedbbox
    scenearea = map(po.blockscene, cb) do cb
        return Rect(round.(Int, minimum(cb)), round.(Int, widths(cb)))
    end

    po.scene = Scene(
        po.blockscene, scenearea, backgroundcolor = po.backgroundcolor, clear = true
    )
    map!(to_color, po.scene.backgroundcolor, po.backgroundcolor)

    po.overlay = Scene(
        po.scene, scenearea, clear = false, backgroundcolor = :transparent,
        transformation = Transformation(po.scene, transform_func = identity)
    )


    # Setup Cycler
    po.cycler = Cycler()
    if palette === nothing
        palette = fast_deepcopy(get(po.blockscene.theme, :palette, Makie.DEFAULT_PALETTES))
    end
    po.palette = palette isa Attributes ? palette : Attributes(palette)


    # Setup camera/limits and Polar transform
    usable_fraction, radius_at_origin = setup_camera_matrices!(po)

    Observables.connect!(
        po.scene.transformation.transform_func,
        @lift(Polar($(po.theta_0), $(po.direction), $(radius_at_origin)))
    )
    Observables.connect!(
        po.overlay.transformation.transform_func,
        @lift(Polar($(po.theta_0), $(po.direction)))
    )

    # Draw clip, grid lines, spine, ticks
    thetaticklabelplot = draw_axis!(po, radius_at_origin)

    # Calculate fraction of screen usable after reserving space for theta ticks
    # TODO: Should we include rticks here?
    # OPT: only update on relevant text attributes rather than glyphcollection
    onany(
            po.blockscene,
            thetaticklabelplot.plots[1].text,
            thetaticklabelplot.plots[1].fontsize,
            thetaticklabelplot.plots[1].font,
            po.thetaticklabelpad, po.overlay.px_area
        ) do _, _, _, pad, area

        # get maximum size of tick label
        # (each boundingbox represents a string without text.position applied)
        max_widths = Vec2f(0)
        for gc in thetaticklabelplot.plots[1].plots[1][1][]
            bbox = boundingbox(gc, Quaternionf(0, 0, 0, 1)) # no rotation
            max_widths = max.(max_widths, widths(bbox)[Vec(1,2)])
        end

        max_width, max_height = max_widths

        space_from_center = 0.5 .* widths(area)
        space_for_ticks = 2pad .+ (max_width, max_height)
        space_for_axis = space_from_center .- space_for_ticks

        # divide by width only because aspect ratios
        usable_fraction[] = space_for_axis ./ space_from_center[1]
    end

    # Set up the title position
    title_position = map(
            po.blockscene, scenearea, po.titlegap, po.titlealign
        ) do area, titlegap, titlealign
        calculate_polar_title_position(area, titlegap, titlealign)
    end

    titleplot = text!(
        po.blockscene,
        title_position;
        text = po.title,
        font = po.titlefont,
        fontsize = po.titlesize,
        color = po.titlecolor,
        align = @lift(($(po.titlealign), :center)),
        visible = po.titlevisible
    )
    translate!(titleplot, 0, 0, 9001) # Make sure this draws on top of clip

    # Protrusions are space reserved for ticks and labels outside `scenearea`.
    # Since we handle ticks within out `scenearea` this only needs to reservse
    # space for the title
    protrusions = map(
            po.blockscene, po.title, po.titlefont, po.titlegap, po.titlealign, po.titlevisible, po.titlesize
        ) do _, _, _, _, _, _
        titlespace = if po.title[] != ""
            (title_position[][2] + boundingbox(titleplot).widths[2]/2 - top(pixelarea(po.scene)[]))
        else
            0f0
        end
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
    rmin, rmax = po.rlimits[]
    init = Observable{Tuple{Float64, Float64}}((rmin, isnothing(rmax) ? 10.0 : rmax))
    setfield!(po, :target_radius, init)
    on(_ -> reset_limits!(po), po.blockscene, po.rlimits)

    # To keep the inner clip radius below a certain fraction of the outer clip
    # radius we map all r > r0 to 0. This computes that r0.
    radius_at_origin = map(po.blockscene, po.target_radius, po.maximum_clip_radius) do (rmin, rmax), max_fraction
        # max_fraction = (rmin - r0) / (rmax - r0) solved for r0
        return max(0.0, (rmin - max_fraction * rmax) / (1 - max_fraction))
    end

    # get cartesian bbox defined by axis limits
    # OPT: target_radius update triggers radius_at_origin update
    data_bbox = map(po.blockscene, po.thetalimits, radius_at_origin, po.direction, po.theta_0) do tlims, ro, dir, t0
        polaraxis_bbox(po.target_radius[], tlims, ro, dir, t0)
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
        rmax = po.target_radius[][2] - radius_at_origin[] # both update data_bbox
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
        camera(po.scene).projection[] = Makie.orthographicprojection(-w, w, -h, h, -max_z, max_z)
    end

    on(po.blockscene, po.overlay.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.overlay).projection[] = Makie.orthographicprojection(-w, w, -h, h, -max_z, max_z)
    end

    # Interactivity
    e = events(po.scene)

    # scroll to zoom
    on(po.blockscene, e.scroll) do scroll
        if Makie.is_mouseinside(po.scene)
            rmin, rmax = po.target_radius[]
            rmax = rmin + (rmax - rmin) * (1.1 ^ -scroll[2])
            po.target_radius[] = (rmin, rmax)
            return Consume(true)
        end
        return Consume(false)
    end

    # translation
    drag_state = RefValue((false, false))
    last_pos = RefValue(Point2f(0))
    on(po.blockscene, e.mousebutton) do e
        drag_state[] = (
            ispressed(po.scene, po.radial_translation_button[]),
            ispressed(po.scene, po.theta_translation_button[])
        )
        if is_mouseinside(po.scene) && (drag_state[][1] || drag_state[][2])
            last_pos[] = Point2f(mouseposition(po.scene))
            return Consume(true)
        end
        return Consume(false)
    end

    on(po.blockscene, e.mouseposition) do _
        if drag_state[][1] || drag_state[][2]
            pos = Point2f(mouseposition(po.scene))
            diff = pos - last_pos[]
            r = norm(last_pos[])
            u_r = last_pos[] ./ r
            u_θ = Point2f(-u_r[2], u_r[1])
            Δr = dot(u_r, diff)
            Δθ = dot(u_θ, diff ./ r)
            if drag_state[][1]
                rmin, rmax = po.target_radius[]
                if rmin > 0
                    dr = min(rmin, Δr)
                    rmin = rmin - dr
                    rmax = rmax - dr
                else
                    rmax = r * rmax / (r + Δr)
                end
                po.target_radius[] = (rmin, rmax)
            end
            if drag_state[][2]
                thetamin, thetamax = po.thetalimits[] .- Δθ
                shift = 2pi * (max(0, div(thetamin, -2pi)) - max(0, div(thetamax, 2pi)))
                po.thetalimits[] = (thetamin, thetamax) .+ shift
                po.theta_0[] = mod(po.theta_0[] .+ Δθ, 0..2pi)
            end
            # Needs recomputation because target_radius may have changed
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
    if isnothing(po.rlimits[][2])
        if !isempty(po.scene.plots)
            # TODO: Why does this include child scenes by default?
            lims3d = data_limits(po.scene, p -> !(p in po.scene.plots))
            po.target_radius[] = (po.rlimits[][1], maximum(lims3d)[1])
        end
    elseif po.target_radius[] != po.rlimits[]
        po.target_radius[] = po.rlimits[]
    end
    return
end


################################################################################
### Axis visualization - grid lines, clip, ticks
################################################################################


# generates large square with circle sector cutout
function _polar_clip_polygon(
        thetamin, thetamax; step = 2pi/360, outer = 1e4,
        exterior = Makie.convert_arguments(PointBased(), Rect2f(-outer, -outer, 2outer, 2outer))[1]
    )
    # make sure we have 2+ points per arc
    N = max(2, ceil(Int, abs(thetamax - thetamin) / step) + 1)
    interior = map(theta -> polar2cartesian(1.0, theta), LinRange(thetamin, thetamax, N))
    (abs(thetamax - thetamin) ≈ 2pi) || push!(interior, Point2f(0))
    return [Makie.Polygon(exterior, [interior])]
end

function draw_axis!(po::PolarAxis, radius_at_origin)
    rtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    rtick_align = Observable{Point2f}()
    rtick_offset = Observable{Point2f}()
    rgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    rminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    # OPT: target_radius update triggers radius_at_origin update
    onany(
            po.blockscene,
            po.rticks, po.rminorticks, po.rtickformat, po.rtickangle,
            po.thetalimits, po.sample_density, radius_at_origin
        ) do rticks, rminorticks, rtickformat, rtickangle,
            thetalims, sample_density, radius_at_origin

        # For text:
        rlims = po.target_radius[]
        rmaxinv = 1.0 / (rlims[2] - radius_at_origin)
        _rtickvalues, _rticklabels = Makie.get_ticks(rticks, identity, rtickformat, rlims...)
        _rtickradius = (_rtickvalues .- radius_at_origin) .* rmaxinv
        _rtickangle = rtickangle === automatic ? thetalims[1] : rtickangle
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickradius, _rtickangle))

        # For grid lines
        thetas = LinRange(thetalims..., sample_density)
        rgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rtickradius])

        _rminortickvalues = Makie.get_minor_tickvalues(rminorticks, identity, _rtickvalues, rlims...)
        _rminortickvalues .= (_rminortickvalues .- radius_at_origin) .* rmaxinv
        rminorgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rminortickvalues])

        return
    end

    # doesn't have a lot of overlap with the inputs above so calculate this independently
    onany(
            po.overlay,
            po.direction, po.theta_0, po.rtickangle, po.thetalimits, po.rticklabelpad
        ) do dir, theta_0, rtickangle, thetalims, pad
        angle = (rtickangle === automatic ? thetalims[1] : rtickangle) - pi/2
        s, c = sincos(dir * (angle + theta_0))

        scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
        rtick_align[] = Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        rtick_offset[] = Point2f(pad * c, pad * s)
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
            po.direction, po.theta_0, po.target_radius, po.thetalimits, po.maximum_clip_radius
        ) do thetaticks, thetaminorticks, thetatickformat, px_pad, dir, theta_0, rlims, thetalims, max_clip

        _thetatickvalues, _thetaticklabels = Makie.get_ticks(thetaticks, identity, thetatickformat, thetalims...)

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

        _thetaminortickvalues = Makie.get_minor_tickvalues(thetaminorticks, identity, _thetatickvalues, thetalims...)
        thetaminorgridpoints[] = [Point2f(r, theta) for theta in _thetaminortickvalues for r in (rmin, 1)]

        return
    end

    notify(po.thetalimits)

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
        sc === automatic ? bg : Makie.to_color(sc)
    end

    rticklabelplot = text!(
        po.overlay, rtick_pos_lbl;
        fontsize = po.rticklabelsize,
        font = po.rticklabelfont,
        color = po.rticklabelcolor,
        strokewidth = po.rticklabelstrokewidth,
        strokecolor = rstrokecolor,
        align = rtick_align,
    )
    # OPT: skip glyphcollection update on offset changes
    rticklabelplot.plots[1].plots[1].offset = rtick_offset


    thetastrokecolor = map(po.blockscene, clipcolor, po.thetaticklabelstrokecolor) do bg, sc
        sc === automatic ? bg : Makie.to_color(sc)
    end

    thetaticklabelplot = text!(
        po.overlay, thetatick_pos_lbl;
        fontsize = po.thetaticklabelsize,
        font = po.thetaticklabelfont,
        color = po.thetaticklabelcolor,
        strokewidth = po.thetaticklabelstrokewidth,
        strokecolor = thetastrokecolor,
        align = thetatick_align[]
    )
    thetaticklabelplot.plots[1].plots[1].offset = thetatick_offset

    # Hack to deal with synchronous update problems
    on(thetaticklabelplot, thetatick_align) do align
        thetaticklabelplot.align.val = align
        if length(align) == length(thetatick_pos_lbl[])
            notify(thetaticklabelplot.align)
        end
        return
    end

    # Clipping

    # create large square with r=1 circle sector cutout
    # only regenerate if circle sector angle changes
    thetadiff = map(lims -> abs(lims[2] - lims[1]), po.overlay, po.thetalimits, ignore_equal_values = true)
    outer_clip = map(po.overlay, thetadiff) do diff
        return _polar_clip_polygon(0, diff)
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
    # handle placement with transform
    onany(po.overlay, po.thetalimits, po.direction, po.theta_0) do thetalims, dir, theta_0
        thetamin, thetamax = dir .* (thetalims .+ theta_0)
        rotate!(outer_clip_plot, Vec3f(0,0,1), dir > 0 ? thetamin : thetamax)
    end

    # inner clip is a plain circle which needs to be scaled to match rlimits
    inner_clip_plot = mesh!(
        po.overlay,
        Circle(Point2f(0), 1f0),
        color = clipcolor,
        visible = po.clip,
        fxaa = false,
        transformation = Transformation(),
        shading = false
    )
    onany(
            po.overlay, po.target_radius, po.maximum_clip_radius
        ) do lims, maxclip
        s = min(lims[1] / lims[2], maxclip)
        scale!(inner_clip_plot, Vec3f(s, s, 1))
    end
    notify(po.maximum_clip_radius)

    # spine traces circle sector - inner circle
    spine_points = map(
            po.target_radius, po.thetalimits, po.maximum_clip_radius
        ) do (rmin, rmax), thetalims, max_clip
        thetamin, thetamax = thetalims
        rmin = min(rmin/rmax, max_clip)
        rmax = 1.0
        step = 2pi/100

        # make sure we have 2+ points per arc
        N = max(2, ceil(Int, abs(thetamax - thetamin) / step) + 1)
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

    notify(po.thetalimits)

    translate!.((rgridplot, thetagridplot, rminorgridplot, thetaminorgridplot, rticklabelplot, thetaticklabelplot, spineplot), 0, 0, 9000)
    translate!.((outer_clip_plot, inner_clip_plot), 0, 0, 8990)

    return thetaticklabelplot
end


################################################################################
### Special sections
################################################################################


function calculate_polar_title_position(area, titlegap, align)
    w, h = area.widths

    x::Float32 = if align === :center
        area.origin[1] + w / 2
    elseif align === :left
        area.origin[1]
    elseif align === :right
        area.origin[1] + w
    else
        error("Title align $align not supported.")
    end

    # local subtitlespace::Float32 = if ax.subtitlevisible[] && !iswhitespace(ax.subtitle[])
    #     boundingbox(subtitlet).widths[2] + subtitlegap
    # else
    #     0f0
    # end

    # The scene area is a rectangle that can include a lot of empty space. With
    # this we allow the title to draw in that empty space
    mini = min(w, h)
    h = top(area) - 0.5 * (h - mini)

    yoffset::Float32 = h + titlegap

    return Point2f(x, yoffset)
end


################################################################################
### Plotting
################################################################################


function Makie.plot!(
    po::PolarAxis, P::Makie.PlotFunc,
    attributes::Makie.Attributes, args...;
    kw_attributes...)

    allattrs = merge(attributes, Attributes(kw_attributes))

    cycle = get_cycle_for_plottype(allattrs, P)
    add_cycle_attributes!(allattrs, P, cycle, po.cycler, po.palette)

    plot = Makie.plot!(po.scene, P, allattrs, args...)

    reset_limits!(po)

    plot
end


function Makie.plot!(P::Makie.PlotFunc, po::PolarAxis, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(po, P, attributes, args...)
end


################################################################################
### Utilities
################################################################################


function autolimits!(po::PolarAxis)
    po.rlimits[] = (0.0, nothing)
    return
end

rlims!(po::PolarAxis, r::Real) = rlims!(po, po.rlimits[][1], r)

function rlims!(po::PolarAxis, rmin::Real, rmax::Real)
    po.rlimits[] = (rmin, rmax)
    return
end

function thetalims!(po::PolarAxis, thetamin::Real, thetamax::Real)
    po.thetalimits[] = (thetamin, thetamax)
    return
end