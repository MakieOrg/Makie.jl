################################################################################
### Polar Transformation
################################################################################

# First, define the polar-to-cartesian transformation as a Makie transformation
# which is fully compliant with the interface

"""
    PolarAxisTransformation(θ_0::Float64, direction::Int)

This struct defines a general polar-to-cartesian transformation, i.e.,
```math
(r, θ) -> (r \\cos(direction * (θ + θ_0)), r \\sin(direction * (θ + θ_0)))
```

where θ is assumed to be in radians.

`direction` should be either -1 or +1, and `θ_0` may be any value.
"""
struct PolarAxisTransformation
    θ_0::Float64
    direction::Int
end

Base.broadcastable(x::PolarAxisTransformation) = (x,)

function Makie.apply_transform(trans::PolarAxisTransformation, point::VecTypes{2, T}) where T <: Real
    y, x = point[1] .* sincos((point[2] + trans.θ_0) * trans.direction)
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
    Point2f(hypot(point[1], point[2]), -trans.direction * (atan(point[2], point[1]) - trans.θ_0))
end


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

    square = lift(cb) do cb
        # find the widths of the computed bbox
        ws = widths(cb)
        # get the minimum width
        min_w = minimum(ws)
        # the scene must be a square, so the width must be the same
        new_ws = Vec2f(min_w, min_w)
        # center the scene
        diff = new_ws - ws
        new_o = cb.origin - 0.5diff
        return Rect(round.(Int, new_o), round.(Int, new_ws))
    end

    po.scene = scene = Scene(po.blockscene, square, camera = cam2d!, backgroundcolor = RGBf(1, 1, 0.8), clear = true)

    # translate!(scene, 0, 0, -100)

    Observables.connect!(
        scene.transformation.transform_func,
        @lift(PolarAxisTransformation($(po.θ_0), $(po.direction)))
    )

    notify(po.limits)


    # Whenever the limits change or the scene is resized,
    # update the camera.
    onany(po.limits, scene.px_area) do lims, px_area
        adjustcam!(po, lims, (0.0, 2π))
    end

    # Outsource to `draw_axis` function
    (spineplot, rgridplot, θgridplot, rminorgridplot, θminorgridplot, rticklabelplot, θticklabelplot) = 
        draw_axis!(po)

    # Handle protrusions

    θticklabelprotrusions = Observable(GridLayoutBase.RectSides(0f0,0f0,0f0,0f0))

    old_input = Ref(Vector{Tuple{String, Point2f}}(undef, 0))

    onany(θticklabelplot[1]) do input
        # Only if the tick labels have changed, should we recompute the tick label
        # protrusions.
        # This should be changed by removing the call to `first`
        # when the call types are changed to the text, position=positions format
        # introduced in #.
        if length(old_input[]) == length(input) && all(first.(input) .== first.(old_input[]))
            return
        else
            # px_area = pixelarea(scene)[]
            # calculate text boundingboxes individually and select the maximum boundingbox
            text_bboxes = text_bbox.(
                first.(θticklabelplot[1][]),
                Ref(θticklabelplot.fontsize[]),
                θticklabelplot.font[],
                θticklabelplot.fonts,
                θticklabelplot.align[] isa Tuple ? Ref(θticklabelplot.align[]) : θticklabelplot.align[],
                θticklabelplot.rotation[],
                0.0,
                0.0,
                θticklabelplot.word_wrap_width[]
            )
            maxbox = maximum(widths.(text_bboxes))
            # box = data_limits(θticklabelplot)
            # @show maxbox px_area
            # box = Rect2(
            #     to_ndim(Point2f, project_to_pixelspace(po.blockscene, box.origin), 0),
            #     to_ndim(Point2f, project_to_pixelspace(po.blockscene, box.widths), 0)
            # )
            # @show box
            old_input[] = input


            θticklabelprotrusions[] = GridLayoutBase.RectSides(
                maxbox[1],#max(0, left(box) - left(px_area)),
                maxbox[1],#max(0, right(box) - right(px_area)),
                maxbox[2],#max(0, bottom(box) - bottom(px_area)),
                maxbox[2],#max(0, top(box) - top(px_area))
            )
        end
    end

    notify(θticklabelplot[1])


    # Set up the title position
    title_position = lift(pixelarea(scene), po.titlegap, po.titlealign, θticklabelprotrusions) do area, titlegap, titlealign, θtlprot
        calculate_polar_title_position(area, titlegap, titlealign, θtlprot)
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
    protrusions = lift(θticklabelprotrusions, title_update_obs) do θtlprot, _
        GridLayoutBase.RectSides(
            θtlprot.left,
            θtlprot.right,
            θtlprot.bottom,
            (title_position[][2] + boundingbox(titleplot).widths[2]/2 - top(pixelarea(scene)[])),
        )
    end

    connect!(po.layoutobservables.protrusions, protrusions)


    # debug statements
    # @show boundingbox(scene) data_limits(scene)
    # Main.@infiltrate
    # display(scene)

    return
end

function draw_axis!(po::PolarAxis)
    θlims = (0, 2pi)

    rtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    rgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    rminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    onany(
            po.rticks, po.rminorticks,po.rtickformat,
            po.rtickangle, po.limits, po.sample_density, 
            # po.scene.px_area, po.scene.transformation.transform_func, po.scene.camera_controls.area
        ) do rticks, rminorticks, rtickformat, rtickangle, limits, sample_density#, pixelarea, trans, area
        
        _rtickvalues, _rticklabels = Makie.get_ticks(rticks, identity, rtickformat, limits...)
        rtick_pos_lbl[] = tuple.(_rticklabels, Point2f.(_rtickvalues, rtickangle))
        
        θs = LinRange(θlims..., sample_density)
        rgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, θs) for r in _rtickvalues])
        
        _rminortickvalues = Makie.get_minor_tickvalues(rminorticks, identity, _rtickvalues, limits...)
        rminorgridpoints[] = Makie.GeometryBasics.LineString.([Point2f.(r, θs) for r in _rminortickvalues])

        return
    end
    
    θtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()
    θtick_align = Observable{Vector{Point2f}}()
    θgridpoints = Observable{Vector{Point2f}}()
    θminorgridpoints = Observable{Vector{Point2f}}()

    onany(
            po.θticks, po.θminorticks, po.θtickformat, 
            po.limits,
            # po.scene.px_area, po.scene.transformation.transform_func, po.scene.camera_controls.area
        ) do θticks, θminorticks, θtickformat, limits #, pixelarea, trans, area
        
        _θtickvalues, _θticklabels = Makie.get_ticks(θticks, identity, θtickformat, θlims...)
        
        # Since θ = 0 is at the same position as θ = 2π, we remove the last tick
        # iff the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_θtickvalues[end] - _θtickvalues[begin]) == 2π
            pop!(_θtickvalues)
            pop!(_θticklabels)
        end
        
        θtick_align.val = map(_θtickvalues) do angle
            s, c = sincos(angle)
            scale = 1 / max(abs(s), abs(c)) # point on ellipse -> point on bbox
            Point2f(0.5 - 0.5scale * c, 0.5 - 0.5scale * s)
        end
        
        # TODO - think about this more carefully
        px_gap = 10
        gap = 1.0 + px_gap / maximum(widths(po.scene.px_area[]))
        
        θtick_pos_lbl[] = tuple.(_θticklabels, Point2f.(gap * limits[end], _θtickvalues))
        
        θgridpoints[] = [Point2f(r, θ) for θ in _θtickvalues for r in limits]
        
        _θminortickvalues = Makie.get_minor_tickvalues(θminorticks, identity, _θtickvalues, θlims...)
        θminorgridpoints[] = [Point2f(r, θ) for θ in _θminortickvalues for r in limits]

        return
    end

    spinepoints = Observable{Vector{Point2f}}()

    onany(
            po.limits, po.sample_density, 
            # po.scene.px_area, po.scene.transformation.transform_func, po.scene.camera_controls.area
        ) do limits, sample_density#, pixelarea, trans, area
        
        θs = LinRange(θlims..., sample_density)
        spinepoints[] = Point2f.(limits[end], θs)

        return
    end




    # on() do i
    #     adjustcam!(po, po.limits[])
    # end

    notify(po.limits)

    # plot using the created observables
    # spine
    spineplot = lines!(
        po.scene, spinepoints;
        color = po.spinecolor,
        linestyle = po.spinestyle,
        linewidth = po.spinewidth,
        visible = po.spinevisible,
        update_limits = false
    )
    # major grids
    rgridplot = lines!(
        po.scene, rgridpoints;
        color = po.rgridcolor,
        linestyle = po.rgridstyle,
        linewidth = po.rgridwidth,
        visible = po.rgridvisible,
        update_limits = false
    )

    θgridplot = linesegments!(
        po.scene, θgridpoints;
        color = po.θgridcolor,
        linestyle = po.θgridstyle,
        linewidth = po.θgridwidth,
        visible = po.θgridvisible,
        update_limits = false
    )
    # minor grids
    rminorgridplot = lines!(
        po.scene, rminorgridpoints;
        color = po.rminorgridcolor,
        linestyle = po.rminorgridstyle,
        linewidth = po.rminorgridwidth,
        visible = po.rminorgridvisible,
        update_limits = false
    )

    θminorgridplot = linesegments!(
        po.scene, θminorgridpoints;
        color = po.θminorgridcolor,
        linestyle = po.θminorgridstyle,
        linewidth = po.θminorgridwidth,
        visible = po.θminorgridvisible,
        update_limits = false
    )
    # tick labels
    rticklabelplot = text!(
        po.scene, rtick_pos_lbl;
        fontsize = po.rticklabelsize,
        font = po.rticklabelfont,
        color = po.rticklabelcolor,
        align = (:left, :bottom),
        update_limits = false
    )

    θticklabelplot = text!(
        po.scene, θtick_pos_lbl;
        fontsize = po.θticklabelsize,
        font = po.θticklabelfont,
        color = po.θticklabelcolor,
        align = θtick_align,
        update_limits = false
        # align = (:center, :center),
    )

    clippoints = lift(spinepoints) do spinepoints
        area = pixelarea(po.scene)[]
        ext_points = Point2f[
            (left(area), bottom(area)),
            (right(area), bottom(area)),
            (right(area), top(area)),
            (left(area), top(area)),
        ]
        return GeometryBasics.Polygon(ext_points, [spinepoints])
    end

    clipcolor = lift(parent(po.blockscene).theme.backgroundcolor) do bgc
        bgc = to_color(bgc)
        if alpha(bgc) == 0f0
            return to_color(:white)
        else
            return RGBf(red(bgc), blue(bgc), green(bgc))
        end
    end

    clipplot = poly!(
        po.blockscene,
        clippoints,
        color = (:red, 0.5), #clipcolor,
        space = :pixel,
        strokewidth = 0,
        visible = false, #po.clip,
        update_limits = false
    )

    translate!.((spineplot, rgridplot, θgridplot, rminorgridplot, θminorgridplot, rticklabelplot, θticklabelplot), 0, 0, 100)
    translate!(clipplot, 0, 0, 99)

    return (spineplot, rgridplot, θgridplot, rminorgridplot, θminorgridplot, rticklabelplot, θticklabelplot)

end

function calculate_polar_title_position(area, titlegap, align, θaxisprotrusion)
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

    yoffset::Float32 = top(area) + titlegap + θaxisprotrusion.top #=+
        subtitlespace=#

    return Point2f(x, yoffset)
end

# allow it to be plotted to
# the below causes a stack overflow
# Makie.can_be_current_axis(po::PolarAxis) = true

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
function Makie.autolimits!(po::PolarAxis)
    lims3d = data_limits(po.scene, p -> !to_value(get(p.attributes, :update_limits, true)))
    @info "limits = $lims3d"
    po.limits[] = (0, maximum(lims3d)[1])

    # projected_datalims = Makie.apply_transform(po.scene.transformation.transform_func[], datalims)
    # @show projected_datalims
    # @show po.limits[]
    # adjustcam!(po, po.limits[])
    # notify(po.limits)
end

function rlims!(po::PolarAxis, rs::NTuple{2, <: Real})
    po.limits[] = rs
end

function rlims!(po::PolarAxis, rmin::Real, rmax::Real)
    po.limits[] = (rmin, rmax)
end


"Adjust the axis's scene's camera to conform to the given r-limits"
function adjustcam!(po::PolarAxis, limits::NTuple{2, <: Real}, θlims::NTuple{2, <: Real} = (0.0, 2π))
    @assert limits[1] ≤ limits[2]
    scene = po.scene
    # We transform our limits to transformed space, since we can
    # operate linearly there
    # @show boundingbox(scene)
    target = Makie.apply_transform((scene.transformation.transform_func[]), BBox(limits..., θlims...))
    # @show target
    area = scene.px_area[]
    Makie.update_cam!(scene, target)
    notify(scene.camera_controls.area)
    return
end
