################################################################################
### Polar Transformation
################################################################################

# First, define the polar-to-cartesian transformation as a Makie transformation
# which is fully compliant with the interface

"""
    PolarAxisTransformation(theta_0::Float64, direction::Int)

This struct defines a general polar-to-cartesian transformation, i.e.,
```math
(r, theta) -> (r \\cos(direction * (theta + theta_0)), r \\sin(direction * (theta + theta_0)))
```

where theta is assumed to be in radians.

`direction` should be either -1 or +1, and `theta_0` may be any value.
"""
struct PolarAxisTransformation
    theta_0::Float64
    direction::Int
end

Base.broadcastable(x::PolarAxisTransformation) = (x,)

function Makie.apply_transform(trans::PolarAxisTransformation, point::VecTypes{2, T}) where T <: Real
    y, x = point[1] .* sincos((point[2] + trans.theta_0) * trans.direction)
    return Point2f(x, y)
end

function Makie.apply_transform(f::PolarAxisTransformation, point::VecTypes{N2, T}) where {N2, T}
    p_dim = to_ndim(Point2f, point, 0.0)
    p_trans = Makie.apply_transform(f, p_dim)
    if 2 < N2
        p_large = ntuple(i-> i <= 2 ? p_trans[i] : point[i], N2)
        return Point{N2, Float32}(p_large)
    else
        return to_ndim(Point{N2, Float32}, p_trans, 0.0)
    end
end

# Define a method to transform boxes from input space to transformed space
function Makie.apply_transform(f::PolarAxisTransformation, r::Rect2{T}) where {T}
    # TODO: once Proj4.jl is updated to PROJ 8.2, we can use
    # proj_trans_bounds (https://proj.org/development/reference/functions.html#c.proj_trans_bounds)
    N = 21
    umin = vmin = T(Inf)
    umax = vmax = T(-Inf)
    xmin, ymin = minimum(r)
    xmax, ymax = maximum(r)
    # If ymax is 2π away from ymin, then the limits
    # are a circle, meaning that we only need the max radius
    # which is trivial to find.
    # @show r
    if abs(ymax - ymin) ≈ 2π
        @assert xmin ≥ 0
        rmax = xmax
        # the diagonal of a square is sqrt(2) * side
        # the radius of a circle inscribed within that square is side/2
        mins = Point2f(-rmax)#Makie.apply_transform(f, Point2f(xmin, ymin))
        maxs = Point2f(rmax*2)#Makie.apply_transform(f, Point2f(xmax - xmin, prevfloat(2f0π)))
        @show(mins, maxs)
        return Rect2f(mins,maxs)
    end
    for x in range(xmin, xmax; length = N)
        for y in range(ymin, ymax; length = N)
            u, v = Makie.apply_transform(f, Point(x, y))
            umin = min(umin, u)
            umax = max(umax, u)
            vmin = min(vmin, v)
            vmax = max(vmax, v)
        end
    end

    return Rect(Vec2(umin, vmin), Vec2(umax-umin, vmax-vmin))
end


# Define its inverse (for interactivity)
Makie.inverse_transform(trans::PolarAxisTransformation) = Makie.PointTrans{2}() do point
    Point2f(hypot(point[1], point[2]), -trans.direction * (atan(point[2], point[1]) - trans.theta_0))
end


################################################################################
### Main Block Intialization
################################################################################


Makie.can_be_current_axis(ax::PolarAxis) = true

function Makie.initialize_block!(po::PolarAxis)
    # Setup Scenes
    
    cb = po.layoutobservables.computedbbox
    scenearea = map(po.blockscene, cb) do cb
        return Rect(round.(Int, minimum(cb)), round.(Int, widths(cb)))
    end

    po.scene = Scene(
        po.blockscene, scenearea, backgroundcolor = RGBf(1, 1, 0.8), clear = true
    )

    po.overlay = Scene(po.scene, scenearea, clear = false, backgroundcolor = :transparent)


    # Setup camera/limits
    axis_radius = setup_camera_matrices!(po)

    # TODO - theta_0 should affect ticks?
    Observables.connect!(
        po.scene.transformation.transform_func,
        @lift(PolarAxisTransformation($(po.theta_0), $(po.direction)))
    )

    

    # Outsource to `draw_axis` function
    thetaticklabelplot = draw_axis!(po, axis_radius)

    # Handle protrusions
    # TODO - what do these do again?

    thetaticklabelprotrusions = map(thetaticklabelplot.plots[1].plots[1][1]) do glyph_collections
        # get maximum size of tick label (each boundingbox represents a string without text.position applied)
        max_widths = Vec2f(0)
        for gc in glyph_collections
            bbox = boundingbox(gc, Quaternionf(0, 0, 0, 1)) # no rotation
            max_widths = max.(max_widths, widths(bbox)[Vec(1,2)])
        end

        max_width, max_height = max_widths
        
        GridLayoutBase.RectSides(max_width, max_width, max_height, max_height)
    end

    onany(po.blockscene, thetaticklabelprotrusions, po.thetaticklabelpad, po.overlay.px_area) do rectsides, pad, area
        space_from_center = 0.5 .* widths(area)
        space_for_ticks = 2pad .+ (rectsides.left, rectsides.bottom)
        space_for_axis = space_from_center .- space_for_ticks
        axis_radius[] = max(0, minimum(space_for_axis) / space_from_center[1])
    end

    # Set up the title position
    title_position = map(
            po.blockscene, pixelarea(po.scene), po.titlegap, po.titlealign, thetaticklabelprotrusions
        ) do area, titlegap, titlealign, thetatlprot
        calculate_polar_title_position(area, titlegap, titlealign, thetatlprot)
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

    # We only need to update the title protrusion calculation when some parameter
    # which affects the glyph collection changes.  But, we don't want to update
    # the protrusion when the position changes.
    title_update_obs = map(
        (x...) -> true, 
        po.blockscene,
        po.title, po.titlefont, po.titlegap, po.titlealign, po.titlevisible, po.titlesize
    )
    #
    protrusions = map(po.blockscene, thetaticklabelprotrusions, title_update_obs) do thetatlprot, _
        GridLayoutBase.RectSides(
            thetatlprot.left,
            thetatlprot.right,
            thetatlprot.bottom,
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
            po.rticks, po.rminorticks, po.rtickformat,
            po.rtickangle, po.target_radius, axis_radius, po.sample_density, 
        ) do rticks, rminorticks, rtickformat, rtickangle, data_radius, axis_radius, sample_density
        
        _rtickvalues, _rticklabels = Makie.get_ticks(rticks, identity, rtickformat, 0, data_radius)
        _rtickpos = _rtickvalues .* (axis_radius / data_radius) # we still need the values
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickpos, rtickangle))
        
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

    # to avoid unneccessary updates we split this up into a couple parts
    theta_value_labels = map(
            po.blockscene, po.thetaticks, po.thetatickformat
        ) do thetaticks, thetatickformat
        
        _thetatickvalues, _thetaticklabels = Makie.get_ticks(thetaticks, identity, thetatickformat, 0, 2pi)
        
        # Since theta = 0 is at the same position as theta = 2π, we remove the last tick
        # iff the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_thetatickvalues[end] - _thetatickvalues[begin]) == 2π
            pop!(_thetatickvalues)
            pop!(_thetaticklabels)
        end

        return (_thetatickvalues, _thetaticklabels)
    end
        
    # align never updates alone so it doesn't need to trigger
    # running this seperately from pos_lbl updates should allow us to resize
    # without recomputing padding for ticks
    on(po.blockscene, theta_value_labels) do (_thetatickvalues, _)
        thetatick_align.val = map(_thetatickvalues) do angle
            s, c = sincos(angle)
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end
        return
    end

    # only theta positions rely on the px_area of the scene for padding
    onany(
            po.blockscene,
            theta_value_labels, po.thetaticklabelpad, axis_radius, po.overlay.px_area
        ) do (_thetatickvalues, _thetaticklabels), px_pad, axis_radius, pixelarea

        # transform px_pad to radial pad
        w2, h2 = (0.5 .* widths(pixelarea)).^2
        tick_positions = map(_thetatickvalues) do angle
            s, c = sincos(angle)
            pad_mult = 1.0 + px_pad / sqrt(w2 * c * c + h2 * s * s)
            Point2f(pad_mult * axis_radius, angle)
        end
        
        thetatick_pos_lbl[] = tuple.(_thetaticklabels, tick_positions)
    end

    # remainign grid lines
    onany(
            po.blockscene,
            theta_value_labels, po.thetaminorticks, axis_radius
        ) do (_thetatickvalues, _), thetaminorticks, axis_radius
        
        thetagridpoints[] = [Point2f(r, theta) for theta in _thetatickvalues for r in (0, axis_radius)]
        
        _thetaminortickvalues = Makie.get_minor_tickvalues(thetaminorticks, identity, _thetatickvalues, thetalims...)
        thetaminorgridpoints[] = [Point2f(r, theta) for theta in _thetaminortickvalues for r in (0, axis_radius)]

        return
    end

    onany(
            po.blockscene,
            po.thetaticks, po.thetaminorticks, po.thetatickformat, po.thetaticklabelpad,
            axis_radius, po.overlay.px_area
        ) do thetaticks, thetaminorticks, thetatickformat, px_pad, axis_radius, pixelarea
        
        _thetatickvalues, _thetaticklabels = Makie.get_ticks(thetaticks, identity, thetatickformat, 0, 2pi)
        
        # Since theta = 0 is at the same position as theta = 2π, we remove the last tick
        # iff the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_thetatickvalues[end] - _thetatickvalues[begin]) == 2π
            pop!(_thetatickvalues)
            pop!(_thetaticklabels)
        end
        
        thetatick_align.val = map(_thetatickvalues) do angle
            s, c = sincos(angle)
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
    rticklabelplot = text!(
        po.overlay, rtick_pos_lbl;
        fontsize = po.rticklabelsize,
        font = po.rticklabelfont,
        color = po.rticklabelcolor,
        align = (:left, :bottom),
    )

    thetaticklabelplot = text!(
        po.overlay, thetatick_pos_lbl;
        fontsize = po.thetaticklabelsize,
        font = po.thetaticklabelfont,
        color = po.thetaticklabelcolor,
        align = thetatick_align,
    )

    clipcolor = map(po.blockscene, po.scene.backgroundcolor) do bgc
        return RGBAf(1, 0, 1, 0.5)
        bgc = to_color(bgc)
        if alpha(bgc) == 0f0
            return to_color(:white)
        else
            return bgc
        end
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
        color = (:green, 0.5), # clipcolor
        visible = po.clip,
        fxaa = false,
        transformation = Transformation() # no polar pls thanks
    )
    on(po.blockscene, axis_radius) do radius
        scale!(clipouter, 2 * Vec3f(radius, radius, 1))
    end

    translate!.((spineplot, rgridplot, thetagridplot, rminorgridplot, thetaminorgridplot, rticklabelplot, thetaticklabelplot), 0, 0, 100)
    translate!.((clipplot, clipouter), 0, 0, 99)

    return thetaticklabelplot
end

function calculate_polar_title_position(area, titlegap, align, thetaaxisprotrusion)
    x::Float32 = if align === :center
        area.origin[1] + area.widths[1] / 2
    elseif align === :left
        area.origin[1]
    elseif align === :right
        area.origin[1] + area.widths[1]
    else
        error("Title align $align not supported.")
    end

    # local subtitlespace::Float32 = if ax.subtitlevisible[] && !iswhitespace(ax.subtitle[])
    #     boundingbox(subtitlet).widths[2] + subtitlegap
    # else
    #     0f0
    # end

    yoffset::Float32 = top(area) + titlegap + thetaaxisprotrusion.top #=+
        subtitlespace=#

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

    # cycle = get_cycle_for_plottype(allattrs, P)
    # add_cycle_attributes!(allattrs, P, cycle, po.cycler, po.palette)

    plot = Makie.plot!(po.scene, P, allattrs, args...)

    reset_limits!(po)

    plot
end


function Makie.plot!(P::Makie.PlotFunc, po::PolarAxis, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(po, P, attributes, args...)
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

    # update projection matrices
    # this just aspect-aware clip space (-1 .. 1, -h/w ... h/w, -100 ... 100)
    on(po.blockscene, po.scene.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.scene).projection[] = Makie.orthographicprojection(-w, w, -h, h, -100f0, 100f0)
    end

    on(po.blockscene, po.overlay.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.overlay).projection[] = Makie.orthographicprojection(-w, w, -h, h, -100f0, 100f0)
    end

    return axis_radius
end

function reset_limits!(po::PolarAxis)
    if isnothing(po.radius[])
        if !isempty(po.scene.plots)
            # WTF, why does this include child scenes by default?
            lims3d = data_limits(po.scene, p -> !(p in po.scene.plots))
            @info lims3d
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