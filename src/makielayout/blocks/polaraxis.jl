################################################################################
### Main Block Intialization
################################################################################


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

    po.overlay = Scene(po.scene, scenearea, clear = false, backgroundcolor = :transparent)


    # Setup Cycler
    po.cycler = Cycler()
    if palette === nothing
        palette = fast_deepcopy(get(po.blockscene.theme, :palette, Makie.DEFAULT_PALETTES))
    end
    po.palette = palette isa Attributes ? palette : Attributes(palette)

    # Setup camera/limits
    axis_radius = setup_camera_matrices!(po)

    # TODO - theta_0 should affect ticks?
    Observables.connect!(
        po.scene.transformation.transform_func,
        @lift(Polar($(po.theta_0), $(po.direction)))
    )

    # Outsource to `draw_axis` function
    thetaticklabelplot = draw_axis!(po, axis_radius)

    # Handle tick label spacing by axis radius adjustments
    onany(
            po.blockscene, thetaticklabelplot.plots[1].plots[1][1],
            po.thetaticklabelpad, po.overlay.px_area
        ) do glyph_collections, pad, area

        # get maximum size of tick label (each boundingbox represents a string without text.position applied)
        max_widths = Vec2f(0)
        for gc in glyph_collections
            bbox = boundingbox(gc, Quaternionf(0, 0, 0, 1)) # no rotation
            max_widths = max.(max_widths, widths(bbox)[Vec(1,2)])
        end

        max_width, max_height = max_widths

        space_from_center = 0.5 .* widths(area)
        space_for_ticks = 2pad .+ (max_width, max_height)
        space_for_axis = space_from_center .- space_for_ticks
        axis_radius[] = max(0, minimum(space_for_axis) / space_from_center[1])
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
        GridLayoutBase.RectSides(
            0f0, 0f0, 0f0,
            (title_position[][2] + boundingbox(titleplot).widths[2]/2 - top(pixelarea(po.scene)[])),
        )
    end

    connect!(po.layoutobservables.protrusions, protrusions)

    return
end

function draw_axis!(po::PolarAxis, axis_radius)
    thetalims = (0, 2pi)

    rtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    rgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    rminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    onany(
            po.blockscene,
            po.rticks, po.rminorticks, po.rtickformat, po.rticklabelpad,
            po.rtickangle, po.target_radius, axis_radius, po.sample_density,
            po.overlay.px_area
        ) do rticks, rminorticks, rtickformat, px_pad, rtickangle, data_radius, axis_radius, sample_density, pixelarea

        _rtickvalues, _rticklabels = Makie.get_ticks(rticks, identity, rtickformat, 0, data_radius)
        _rtickpos = _rtickvalues .* (axis_radius / data_radius) # we still need the values
        pad = let
            w2, h2 = (0.5 .* widths(pixelarea)).^2
            s, c = sincos(rtickangle)
            axis_radius * px_pad / sqrt(w2 * c * c + h2 * s * s)
        end
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickpos .+ pad, rtickangle))

        thetas = LinRange(thetalims..., sample_density)
        rgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rtickpos])

        _rminortickvalues = Makie.get_minor_tickvalues(rminorticks, identity, _rtickvalues, 0, data_radius)
        _rminortickvalues .*= (axis_radius / data_radius)
        rminorgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rminortickvalues])

        return
    end

    thetatick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    thetatick_align = Observable{Vector{Point2f}}()
    thetagridpoints = Observable{Vector{Point2f}}()
    thetaminorgridpoints = Observable{Vector{Point2f}}()

    onany(
            po.blockscene,
            po.thetaticks, po.thetaminorticks, po.thetatickformat, po.thetaticklabelpad,
            po.direction, po.theta_0, axis_radius, po.overlay.px_area
        ) do thetaticks, thetaminorticks, thetatickformat, px_pad, dir, theta_0, axis_radius, pixelarea

        _thetatickvalues, _thetaticklabels = Makie.get_ticks(thetaticks, identity, thetatickformat, 0, 2pi)

        # Since theta = 0 is at the same position as theta = 2π, we remove the last tick
        # iff the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_thetatickvalues[end] - _thetatickvalues[begin]) == 2π
            pop!(_thetatickvalues)
            pop!(_thetaticklabels)
        end

        thetatick_align[] = map(_thetatickvalues) do angle
            s, c = sincos(dir * (angle + theta_0))
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end

        # transform px_pad to radial pad
        w2, h2 = (0.5 .* widths(pixelarea)).^2
        tick_positions = map(_thetatickvalues) do angle
            s, c = sincos(angle)
            pad_mult = 1.0 + px_pad / sqrt(w2 * c * c + h2 * s * s)
            Point2f(pad_mult * axis_radius, angle)
        end

        thetatick_pos_lbl[] = tuple.(_thetaticklabels, tick_positions)

        thetagridpoints[] = [Point2f(r, theta) for theta in _thetatickvalues for r in (0, axis_radius)]

        _thetaminortickvalues = Makie.get_minor_tickvalues(thetaminorticks, identity, _thetatickvalues, thetalims...)
        thetaminorgridpoints[] = [Point2f(r, theta) for theta in _thetaminortickvalues for r in (0, axis_radius)]

        return
    end

    spinepoints = Observable{Vector{Point2f}}()

    onany(
            po.blockscene, po.sample_density, axis_radius
        ) do sample_density, axis_radius

        thetas = LinRange(thetalims..., sample_density)
        spinepoints[] = Point2f.(axis_radius, thetas)

        return
    end

    # TODO - compute this based on text bb (which would replace this trigger)
    notify(axis_radius)

    # plot using the created observables
    # spine
    spineplot = lines!(
        po.overlay, spinepoints;
        color = po.spinecolor,
        linestyle = po.spinestyle,
        linewidth = po.spinewidth,
        visible = po.spinevisible,
    )
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

    clipcolor = map(po.blockscene, po.backgroundcolor) do bgc
        bgc = to_color(bgc)
        if alpha(bgc) == 0f0
            return to_color(:white)
        else
            return bgc
        end
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
        align = map(po.direction, po.theta_0, po.rtickangle) do dir, theta_0, angle
            s, c = sincos(dir * (angle + theta_0))
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end
    )

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

    # Hack to deal with synchronous update problems
    on(thetatick_align) do align
        thetaticklabelplot.align.val = align
    end

    # inner clip
    # scatter shouldn't interfere with lines and text in GLMakie, so this should
    # look a bit cleaner
    inverse_circle =  BezierPath([
        MoveTo(Point( 1,  1)),
        LineTo(Point( 1, -1)),
        LineTo(Point(-1, -1)),
        LineTo(Point(-1,  1)),
        MoveTo(Point(1, 0)),
        EllipticalArc(Point(0.0, 0), 0.5, 0.5, 0.0, 0.0, 2pi),
        ClosePath(),
    ])

    ms = map(
        (rect, radius) -> radius * widths(rect)[1],
        po.blockscene, po.overlay.px_area, axis_radius
    )

    clipplot = scatter!(
        po.overlay,
        Point2f(0),
        color = clipcolor,
        markersize = ms,
        marker = inverse_circle,
        visible = po.clip,
    )

    # outer clip
    # for when aspect ratios get extreme (> 2) or the axis very small
    clippoints = let
        v = 1000 # should keep `scene` covered up to this aspect ratio
        exterior = Point2f[(-v, -v), (v, -v), (v, v), (-v, v)]
        v = 0.99 # at edge of scattered marker (slightly less because of AA)
        interior = Point2f[(-v, -v), (v, -v), (v, v), (-v, v)]
        GeometryBasics.Polygon(exterior, [interior])
    end

    clipouter = poly!(
        po.overlay,
        clippoints,
        color = clipcolor,
        visible = po.clip,
        fxaa = false,
        transformation = Transformation() # no polar transform for this
    )
    on(po.blockscene, axis_radius) do radius
        scale!(clipouter, 2 * Vec3f(radius, radius, 1))
    end

    translate!.((spineplot, rgridplot, thetagridplot, rminorgridplot, thetaminorgridplot, rticklabelplot, thetaticklabelplot), 0, 0, 9000)
    translate!.((clipplot, clipouter), 0, 0, 8990)

    return thetaticklabelplot
end

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
### Limits and Camera
################################################################################


function setup_camera_matrices!(po::PolarAxis)
    # Initialization
    axis_radius = Observable(0.8)
    init = Observable{Float64}(isnothing(po.radius[]) ? 10.0 : po.radius[])
    setfield!(po, :target_radius, init)
    on(_ -> reset_limits!(po), po.blockscene, po.radius)
    camera(po.overlay).view[] = Mat4f(I)

    e = events(po.scene)

    # scroll to zoom
    on(po.blockscene, e.scroll) do scroll
        if Makie.is_mouseinside(po.scene)
            po.target_radius[] = po.target_radius[] *  (1.1 ^ (-scroll[2]))
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

    # update view matrix
    onany(po.blockscene, axis_radius, po.target_radius) do ar, radius
        ratio = ar / radius
        camera(po.scene).view[] = Makie.scalematrix(Vec3f(ratio, ratio, 1))
        return
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

    return axis_radius
end

function reset_limits!(po::PolarAxis)
    if isnothing(po.radius[])
        if !isempty(po.scene.plots)
            # WTF, why does this include child scenes by default?
            lims3d = data_limits(po.scene, p -> !(p in po.scene.plots))
            po.target_radius[] = maximum(lims3d)[1]
        end
    elseif po.target_radius[] != po.radius[]
        po.target_radius[] = po.radius[]
    end
    return
end

function autolimits!(po::PolarAxis)
    po.radius[] = nothing
    return
end

function rlims!(po::PolarAxis, r::Real)
    po.radius[] = r
    return
end
