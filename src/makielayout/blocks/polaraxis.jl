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
### Camera Setup
################################################################################


# struct PolarAxisCamera
#     data_origin::Observable{Point2f} # or axis, these should map into each other?
#     data_radius::
#     axis_radius
#     rotation_angle
    

#     controls
#         rotation_key
#         zoom_key
#         axis_translation_key (combo)
#         axis_zoom_key (combo)
#         data_reset # autolimits data to axis area
#         axis_reset # fit axis into area
#     settings
#         zoom_speed
#         rotation_speed

# end


################################################################################
### Space transformation
################################################################################


# Some useful code to transform from data (transformed) space to pixelspace

function project_to_pixelspace(scene, point::VT) where {N, T, VT <: VecTypes{N, T}}
    @assert N ≤ 3
    transformed = Makie.apply_transform(Makie.transform_func(scene), point)
    return Makie.to_ndim(VT, Makie.project(scene, transformed), 0f0)
end

function project_to_pixelspace(scene, points::AbstractVector{VT}) where {N, T, VT <: VecTypes{N, T}}
    transformed = Makie.apply_transform(Makie.transform_func(scene), points)
    return @. Makie.to_ndim(VT, Makie.project(scene, transformed), 0f0)
end

# A function which redoes text layouting, to provide a bbox for arbitrary text.

function text_bbox(textstring::AbstractString, fontsize::Union{AbstractVector, Number}, font, fonts, align, rotation, justification, lineheight, word_wrap_width = -1)
    glyph_collection = Makie.layout_text(
            textstring, fontsize,
            to_font(fonts, font), fonts, align, rotation, justification, lineheight,
            RGBAf(0,0,0,0), RGBAf(0,0,0,0), 0f0, word_wrap_width
        )

    return Rect2f(Makie.boundingbox(glyph_collection, Point3f(0), Makie.to_rotation(rotation)))
end

function text_bbox(plot::Text)
    return text_bbox(
        plot.text[],
        plot.fontsize[],
        plot.font[],
        plot.fonts,
        plot.align[],
        plot.rotation[],
        plot.justification[],
        plot.lineheight[],
        RGBAf(0,0,0,0), RGBAf(0,0,0,0), 0f0,
        plot.word_wrap_width[]
    )
end


################################################################################
### Main Block Intialization
################################################################################


Makie.can_be_current_axis(ax::PolarAxis) = true

function Makie.initialize_block!(po::PolarAxis)
    cb = po.layoutobservables.computedbbox

    scenearea = lift(cb) do cb
        return Rect(round.(Int, minimum(cb)), round.(Int, widths(cb)))
    end

    po.scene = Scene(
        po.blockscene, scenearea, backgroundcolor = RGBf(1, 1, 0.8), clear = true
    )

    po.overlay = Scene(po.scene, scenearea, clear = false, backgroundcolor = :transparent)


    # Camera information
    axis_radius = Observable(0.8)
    on(events(po.scene).scroll, priority = 100) do scroll
        if Makie.is_mouseinside(po.scene)
            rlims!(po, po.limits[][2] * (1.1 ^ (-scroll[2])))
            return Consume(true)
        end
        return Consume(false)
    end

    onany(po.scene, axis_radius, po.limits) do ar, lims
        ratio = ar / lims[2]
        camera(po.scene).view[] = Makie.scalematrix(Vec3f(ratio, ratio, 1))
        return
    end

    camera(po.scene).view[] = Mat4f(I)
    on(po.scene.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.scene).projection[] = Makie.orthographicprojection(-w, w, -h, h, -100f0, 100f0)
    end

    camera(po.overlay).view[] = Mat4f(I)
    on(po.overlay.px_area) do area
        aspect = Float32((/)(widths(area)...))
        w = 1f0
        h = 1f0 / aspect
        camera(po.overlay).projection[] = Makie.orthographicprojection(-w, w, -h, h, -100f0, 100f0)
    end
    # translate!(po.scene, 0, 0, -100)

    Observables.connect!(
        po.scene.transformation.transform_func,
        @lift(PolarAxisTransformation($(po.theta_0), $(po.direction)))
    )

    notify(po.limits)


    # Whenever the limits change or the po.scene is resized,
    # update the camera.
    onany(po.limits, po.scene.px_area) do lims, px_area
        adjustcam!(po, lims, (0.0, 2π))
    end

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

    onany(thetaticklabelprotrusions, po.thetaticklabelpad, po.overlay.px_area) do rectsides, pad, area
        space_from_center = 0.5 .* widths(area)
        space_for_ticks = 2pad .+ (rectsides.left, rectsides.bottom)
        space_for_axis = space_from_center .- space_for_ticks
        axis_radius[] = max(0, minimum(space_for_axis) / space_from_center[1])
    end

    # Set up the title position
    title_position = lift(pixelarea(po.scene), po.titlegap, po.titlealign, thetaticklabelprotrusions) do area, titlegap, titlealign, thetatlprot
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
    title_update_obs = lift((x...) -> true, po.title, po.titlefont, po.titlegap, po.titlealign, po.titlevisible, po.titlesize)
    #
    protrusions = lift(thetaticklabelprotrusions, title_update_obs) do thetatlprot, _
        GridLayoutBase.RectSides(
            thetatlprot.left,
            thetatlprot.right,
            thetatlprot.bottom,
            (title_position[][2] + boundingbox(titleplot).widths[2]/2 - top(pixelarea(po.scene)[])),
        )
    end

    connect!(po.layoutobservables.protrusions, protrusions)


    # debug statements
    # @show boundingbox(scene) data_limits(scene)
    # Main.@infiltrate
    # display(scene)

    return
end

function draw_axis!(po::PolarAxis, axis_radius)
    thetalims = (0, 2pi)

    rtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    rgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    rminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    onany(
            po.rticks, po.rminorticks, po.rtickformat,
            po.rtickangle, po.limits, axis_radius, po.sample_density, 
            # po.scene.px_area, po.scene.transformation.transform_func, po.scene.camera_controls.area
        ) do rticks, rminorticks, rtickformat, rtickangle, limits, axis_radius, sample_density#, pixelarea, trans, area
        
        _rtickvalues, _rticklabels = Makie.get_ticks(rticks, identity, rtickformat, limits...)
        _rtickpos = _rtickvalues .* (axis_radius / limits[2]) # we still need the values
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickpos, rtickangle))
        
        thetas = LinRange(thetalims..., sample_density)
        rgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rtickpos])
        
        _rminortickvalues = Makie.get_minor_tickvalues(rminorticks, identity, _rtickvalues, limits...)
        _rminortickvalues .*= (axis_radius / limits[2])
        rminorgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, thetas) for r in _rminortickvalues])

        return
    end
    
    thetatick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    thetatick_align = Observable{Vector{Point2f}}()
    thetagridpoints = Observable{Vector{Point2f}}()
    thetaminorgridpoints = Observable{Vector{Point2f}}()

    # to avoid unneccessary updates we split this up into a couple parts
    theta_value_labels = map(po.thetaticks, po.thetatickformat) do thetaticks, thetatickformat
        
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
    on(theta_value_labels) do (_thetatickvalues, _)
        thetatick_align.val = map(_thetatickvalues) do angle
            s, c = sincos(angle)
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end
        return
    end

    # only theta positions rely on the px_area of the scene for padding
    onany(
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
            theta_value_labels, po.thetaminorticks, axis_radius
        ) do (_thetatickvalues, _), thetaminorticks, axis_radius
        
        thetagridpoints[] = [Point2f(r, theta) for theta in _thetatickvalues for r in (0, axis_radius)]
        
        _thetaminortickvalues = Makie.get_minor_tickvalues(thetaminorticks, identity, _thetatickvalues, thetalims...)
        thetaminorgridpoints[] = [Point2f(r, theta) for theta in _thetaminortickvalues for r in (0, axis_radius)]

        return
    end

    onany(
            po.thetaticks, po.thetaminorticks, po.thetatickformat, po.thetaticklabelpad,
            axis_radius, po.overlay.px_area
            # po.scene.px_area, po.scene.transformation.transform_func, po.scene.camera_controls.area
        ) do thetaticks, thetaminorticks, thetatickformat, px_pad, axis_radius, pixelarea #, pixelarea, trans, area
        
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

    onany(po.sample_density, axis_radius
        ) do sample_density, axis_radius #, pixelarea, trans, area
        
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

    clipcolor = lift(po.scene.backgroundcolor) do bgc
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

    clipplot = scatter!(
        po.overlay,
        Point2f(0),
        color = clipcolor,
        markersize = map((rect, radius) -> radius * widths(rect)[1], po.overlay.px_area, axis_radius),
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
    on(axis_radius) do radius
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

    autolimits!(po)

    # # some area-like plots basically always look better if they cover the whole plot area.
    # # adjust the limit margins in those cases automatically.
    # needs_tight_limits(plot) && tightlimits!(po)

    # reset_limits!(po)
    plot
end


function Makie.plot!(P::Makie.PlotFunc, po::PolarAxis, args...; kw_attributes...)
    attributes = Makie.Attributes(kw_attributes)
    Makie.plot!(po, P, attributes, args...)
end


################################################################################
### Limits and Camera
################################################################################


# TODO
# - r lims should always start at 0 so drop rmin?

function Makie.autolimits!(po::PolarAxis)
    # lims3d = data_limits(po.scene, p -> !to_value(get(p.attributes, :update_limits, true)))
    
    # WTF, why does this include child scenes by default?
    lims3d = data_limits(po.scene, p -> !(p in po.scene.plots))
    @info lims3d
    po.limits[] = (0, maximum(lims3d)[1])
    return
end

function rlims!(po::PolarAxis, rs::NTuple{2, <: Real})
    po.limits[] = rs
end

function rlims!(po::PolarAxis, rmin::Real, rmax::Real)
    po.limits[] = (rmin, rmax)
end

function rlims!(po::PolarAxis, r::Real)
    po.limits[] = (0, r)
end




"Adjust the axis's scene's camera to conform to the given r-limits"
function adjustcam!(po::PolarAxis, limits::NTuple{2, <: Real}, thetalims::NTuple{2, <: Real} = (0.0, 2π))
    @assert limits[1] ≤ limits[2]
    scene = po.scene
    # We transform our limits to transformed space, since we can
    # operate linearly there
    # @show boundingbox(scene)
    # target = Makie.apply_transform((scene.transformation.transform_func[]), BBox(limits..., thetalims...))
    # @show target
    # area = scene.px_area[]
    # Makie.update_cam!(scene, target)
    # notify(scene.camera_controls.area)
    return
end
