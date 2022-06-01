# First, define the polar-to-cartesian transformation as a Makie transformation
# which is fully compliant with the interface

struct PolarAxisTransformation
    θ_0::Float64
    direction::Int
end

Base.broadcastable(x::PolarAxisTransformation) = (x,)

# original implementation - somewhat inflexible
# PolarAxisTransformation = Makie.PointTrans{2}() do point
#     #@assert point isa Point2
#     y, x = point[1] .* sincos((point[2] + trans.θ_0) * trans.direction)
#     return Point2f(x, y)
# end

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
        mins = Point2f(-rmax * sqrt(2))#Makie.apply_transform(f, Point2f(xmin, ymin))
        maxs = Point2f(rmax * sqrt(2) * 2)#Makie.apply_transform(f, Point2f(xmax - xmin, prevfloat(2f0π)))
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

function project_to_pixelspace(scene, point::Point{N, T}) where {N, T}
    @assert N ≤ 3
    return Point{N, T}(
        Makie.project(
            # obtain the camera of the Scene which will project to its screenspace
            camera(scene),
            # go from dataspace (transformation applied to inputspace) to pixelspace
            :data, :pixel,
            # apply the transform to go from inputspace to dataspace
            Makie.apply_transform(
                scene.transformation.transform_func[],
                point
            )
        )
    )
end

function project_to_pixelspace(scene, points::AbstractVector{Point{N, T}}) where {N, T}
    Point{N, T}.(
        Makie.project.(
            # obtain the camera of the Scene which will project to its screenspace
            Ref(Makie.camera(scene)),
            # go from dataspace (transformation applied to inputspace) to pixelspace
            Ref(:data), Ref(:pixel),
            # apply the transform to go from inputspace to dataspace
            Makie.apply_transform(
                scene.transformation.transform_func[],
                points
            )
        )
    )
end


function text_bbox(textstring::AbstractString, textsize::Union{AbstractVector, Number}, font, align, rotation, justification, lineheight, word_wrap_width = -1)
    glyph_collection = Makie.layout_text(
            textstring, textsize,
            font, align, rotation, justification, lineheight,
            RGBAf(0,0,0,0), RGBAf(0,0,0,0), 0f0, word_wrap_width
        )

    return Rect2f(Makie.boundingbox(glyph_collection, Point3f(0), Makie.to_rotation(rotation)))
end

# MakieLayout.can_be_current_axis(ax::PolarAxis) = true

function MakieLayout.initialize_block!(po::PolarAxis)
    cb = po.layoutobservables.computedbbox

    square = lift(cb) do cb
        ws = widths(cb)
        min_w = minimum(ws)
        new_ws = Vec2f(min_w, min_w)
        diff = ws - new_ws
        new_o = cb.origin + 0.5diff
        Rect(round.(Int, new_o), round.(Int, new_ws))
    end

    scene = Scene(po.blockscene, square, camera = cam2d!, backgroundcolor = :white)

    Makie.Observables.connect!(
        scene.transformation.transform_func,
        @lift(PolarAxisTransformation($(po.θ_0), $(po.direction)))
    )

    notify(po.limits)

    po.scene = scene

    draw_axis!(po)

    # debug statements
    # @show boundingbox(scene) data_limits(scene)
    # @infiltrate
    # display(scene)

    return
end

function draw_axis!(po::PolarAxis)

    θtick_pos_lbl = Observable{Vector{<:Tuple{AbstractString, Point2f}}}()

    rgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    θgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    rminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()
    θminorgridpoints = Observable{Vector{Makie.GeometryBasics.LineString}}()

    spinepoints = Observable{Vector{Point2f}}()

    onany(po.rticks, po.θticks, po.rminorticks, po.θminorticks, po.rtickformat, po.θtickformat, po.limits, po.sample_density, po.scene.px_area, po.scene.transformation.transform_func) do rticks, θticks, rminorticks, θminorticks, rtickformat, θtickformat, limits, sample_density, pixelarea, trans

        rs = LinRange(limits..., sample_density)
        θs = LinRange(0, 2π, sample_density)

        _rtickvalues, _rticklabels = Makie.MakieLayout.get_ticks(rticks, identity, rtickformat, limits...)
        _θtickvalues, _θticklabels = Makie.MakieLayout.get_ticks(θticks, identity, θtickformat, 0, 2π)

        # Since θ=0 is at the same position as θ = 2π, we remove the last tick
        # if the difference between the first and last tick is exactly 2π
        # This is a special case, since it's the only possible instance of colocation
        if (_θtickvalues[end] - _θtickvalues[begin]) == 2π
            pop!(_θtickvalues)
            pop!(_θticklabels)
        end

        θtextbboxes = text_bbox.(
            _θticklabels, Ref(po.θticklabelsize[]), Ref(po.θticklabelfont[]), Ref((:center, :center)), #=θticklabelrotation=#0f0, #=θticklabeljustification=#0f0, #=θticklabellineheight=#0f0, #=θticklabelword_wrap_width=# -1
        )

        θdiags = map(sqrt ∘ sum ∘ (x -> x .^ 2), widths.(θtextbboxes))

        θgaps = θdiags ./ 2 .* (x -> Vec2f(cos(x), sin(x))).((_θtickvalues .+ trans.θ_0) .* trans.direction)

        θtickpos = project_to_pixelspace(po.scene, Point2f.(limits[end], _θtickvalues)) .+ θgaps .+ Ref(pixelarea.origin)

        _rminortickvalues = Makie.MakieLayout.get_minor_tickvalues(rminorticks, identity, _rtickvalues, limits...)
        _θminortickvalues = Makie.MakieLayout.get_minor_tickvalues(θminorticks, identity, _θtickvalues, 0, 2π)

        _rgridpoints = [project_to_pixelspace(po.scene, Point2f.(r, θs)) .+ Ref(pixelarea.origin) for r in _rtickvalues]
        _θgridpoints = [project_to_pixelspace(po.scene, Point2f.(rs, θ)) .+ Ref(pixelarea.origin) for θ in _θtickvalues]

        _rminorgridpoints = [project_to_pixelspace(po.scene, Point2f.(r, θs)) .+ Ref(pixelarea.origin) for r in _rminortickvalues]
        _θminorgridpoints = [project_to_pixelspace(po.scene, Point2f.(rs, θ)) .+ Ref(pixelarea.origin) for θ in _θminortickvalues]

        θtick_pos_lbl[] = tuple.(_θticklabels, θtickpos)

        spinepoints[] = project_to_pixelspace(po.scene, Point2f.(limits[end], θs)) .+ Ref(pixelarea.origin)

        rgridpoints[] = Makie.GeometryBasics.LineString.(_rgridpoints)
        θgridpoints[] = Makie.GeometryBasics.LineString.(_θgridpoints)

        rminorgridpoints[] = Makie.GeometryBasics.LineString.(_rminorgridpoints)
        θminorgridpoints[] = Makie.GeometryBasics.LineString.(_θminorgridpoints)

    end

    # on(po.scene.px_area) do pxarea
    #     adjustcam!(po)
    # end

    notify(po.sample_density)

    spineplot = lines!(
        po.blockscene, spinepoints;
        color = po.spinecolor,
        linestyle = po.spinestyle,
        linewidth = po.spinewidth,
        visible = po.spinevisible
    )

    rgridplot = lines!(
        po.blockscene, rgridpoints;
        color = po.rgridcolor,
        linestyle = po.rgridstyle,
        linewidth = po.rgridwidth,
        visible = po.rgridvisible
    )

    θgridplot = lines!(
        po.blockscene, θgridpoints;
        color = po.θgridcolor,
        linestyle = po.θgridstyle,
        linewidth = po.θgridwidth,
        visible = po.θgridvisible
    )

    rminorgridplot = lines!(
        po.blockscene, rminorgridpoints;
        color = po.minorgridcolor,
        linestyle = po.minorgridstyle,
        linewidth = po.minorgridwidth,
        visible = po.minorgridvisible
    )

    θminorgridplot = lines!(
        po.blockscene, θminorgridpoints;
        color = po.minorgridcolor,
        linestyle = po.minorgridstyle,
        linewidth = po.minorgridwidth,
        visible = po.minorgridvisible
    )

    θtickplot = text!(
        po.blockscene, θtick_pos_lbl;
        textsize = po.θticklabelsize,
        font = po.θticklabelfont,
        color = po.θticklabelcolor,
        align = (:center, :center),
    )

    translate!.((spineplot, rgridplot, θgridplot, rminorgridplot, θminorgridplot, θtickplot), 0, 0, 100_000)

end

# allow it to be plotted to
# the below causes a stack overflow
# MakieLayout.can_be_current_axis(po::PolarAxis) = true

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


function MakieLayout.autolimits!(po::PolarAxis)
    datalims = Rect2f(data_limits(po.scene))
    projected_datalims = Makie.apply_transform(po.scene.transformation.transform_func[], datalims)
    po.limits[] = (datalims.origin[1], datalims.origin[1] + datalims.widths[1])
    adjustcam!(po, po.limits[])
    notify(po.limits)
end

function rlims!(po::PolarAxis, rs::NTuple{2, <: Real})
    po.limits[] = rs
    adjustcam!(po, po.limits[])
    notify(po.limits)
end

function rlims!(po::PolarAxis, rmin::Real, rmax::Real)
    po.limits[] = (rmin, rmax)
    adjustcam!(po, po.limits[])
    notify(po.limits)
end


"Adjust the axis's scene's camera to conform to the given r-limits"
function adjustcam!(po::PolarAxis, limits)
    scene = po.scene
    # We transform our limits to transformed space, since we can
    # operate linearly there
    # @show boundingbox(scene)
    target = Makie.apply_transform((scene.transformation.transform_func[]), BBox(limits..., 0, 2π))
    area = scene.px_area[]
    Makie.update_cam!(scene, target)
    return
end
