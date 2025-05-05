################################################################################
### Generic
################################################################################


# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!


struct ArrowLike <: ConversionTrait end

# vec(::Point) and vec(::Vec) works (returns input), but vec(::Tuple) errors
convert_arguments(::ArrowLike, pos::VecTypes{N}, dir::VecTypes{N}) where {N} = ([pos], [dir])

function convert_arguments(::ArrowLike, pos::AbstractArray, dir::AbstractArray)
    return (
        convert_arguments(PointBased(), vec(pos))[1],
        convert_arguments(PointBased(), vec(dir))[1]
    )
end

function convert_arguments(::ArrowLike, x, y, u, v)
    return (
        convert_arguments(PointBased(), vec(x), vec(y))[1],
        convert_arguments(PointBased(), vec(u), vec(v))[1]
    )
end
function convert_arguments(::ArrowLike, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    return (
        vec(Point{2, float_type(x, y)}.(x, y')),
        convert_arguments(PointBased(), vec(u), vec(v))[1]
    )
end
function convert_arguments(::ArrowLike, x, y, z, u, v, w)
    return (
        convert_arguments(PointBased(), vec(x), vec(y), vec(z))[1],
        convert_arguments(PointBased(), vec(u), vec(v), vec(w))[1]
    )
end

function convert_arguments(::ArrowLike, pos::AbstractArray, f::Function)
    points = convert_arguments(PointBased(), pos)[1]
    f_out = Vec2{eltype(points)}.(f.(points))
    return (vec(points), vec(f_out))
end

function convert_arguments(::ArrowLike, x::RealVector, y::RealVector, f::Function)
    points = Point2{float_type(x, y)}.(x, y')
    f_out = Vec2{float_type(x, y)}.(f.(points))
    return (vec(points), vec(f_out))
end

function convert_arguments(::ArrowLike, x::RealVector, y::RealVector, z::RealVector,
                           f::Function)
    points = [Point3{float_type(x, y, z)}(x, y, z) for x in x, y in y, z in z]
    f_out = Vec3{float_type(x, y, z)}.(f.(points))
    return (vec(points), vec(f_out))
end

function _arrow_align_val(align::Symbol)
    if align === :tail
        return 0.0
    elseif align === :center
        return 0.5
    elseif align === :tip
        return 1.0
    else
        error("align = $align not recognized. Use :tail, :center, :tip or a fraction.")
    end
end
_arrow_align_val(align::Real) = Float64(align)


function _process_arrow_arguments(pos, pos_or_dir, align, lengthscale, norm, argmode)
    align_val = _arrow_align_val(align)
    if argmode in (:endpoint, :endpoints)
        # keep lerp(plot[1], plot[2], align_val) consistent, i.e.
        # that point is corresponds to the align_val fraction of the drawn arrow
        dirs = pos_or_dir .- pos
        origins = pos .+ align_val .* dirs
        if norm
            dirs .= normalize(dirs)
        end
        dirs .*= lengthscale
        startpoints = origins .- align_val .* dirs
        return startpoints, dirs

    elseif argmode in (:direction, :directions)
        # compute startpoint such that plot[1] is at the align_val fraction of the drawn arrow
        dirs = lengthscale .* (norm ? normalize.(pos_or_dir) : pos_or_dir)
        startpoints = pos .- align_val .* dirs
        return startpoints, dirs

    else
        error("Did not recognize argmode = :$argmode - must be :endpoint or :direction")
    end
end

function mixin_arrow_attributes()
    MakieCore.@DocumentedAttributes begin
        "Sets the color of the arrow. Can be overridden separately using `tailcolor`, `shaftcolor` and `tipcolor`."
        color = :black
        "Sets the color of the arrow tail. Defaults to `color`"
        tailcolor = automatic
        "Sets the color of the arrow shaft. Defaults to `color`"
        shaftcolor = automatic
        "Sets the color of the arrow tip. Defaults to `color`"
        tipcolor = automatic

        """
        Sets the alignment of the arrow, i.e. which part of the arrow is placed at the given positions.
        - `align = :tail` or `align = 0` places the arrow tail at the given position. This makes the arrow point away from that position.
        - `align = :center` or `align = 0.5` places the arrow center (based on its total length) at the given position
        - `align = :tip` or `align = 1.0` places the tip of the arrow at the given position. This makes the arrow point to that position.

        Values outside of (0, 1) can also be used to create gaps between the arrow and its anchor position.

        With `argmode = :endpoint` alignment is not relative to the first argument passed to arrows.
        Instead the given fraction of the arrow marker is aligned to the fraction between the start
        and end point of the arrow. So `align = :center` will align the center of the arrow marker
        with the center between the passed positions. Because of this `align` only has an effect
        here if `normalize = true` or if `lengthscale != 1`.
        """
        align = :tail
        """
        Scales the length of the arrow (as calculated from directions) by some factor.
        """
        lengthscale = 1f0
        "If set to true, normalizes `directions`."
        normalize = false
        "Controls whether the second argument is interpreted as a :direction or as an :endpoint."
        argmode = :direction
    end
end

const _arrow_args_docs = """
Their positions are given by a vector of `points` or component vectors `x`, `y`
and optionally `z`. A single point or value of `x`, `y` and `z` is also allowed.
Which part of the arrow is aligned with the position depends on the `align` attribute.

Their directions are given by a vector of `directions` or component vectors `u`,
`v` and optionally `w` just like positions. Additionally they can also be
calculated by a function `f` which should return a `Point` or `Vec` for each
arrow `position::Point`.
Note that direction can also be interpreted as end points with `argmode = :endpoint`.
"""


################################################################################
### 2D Arrows
################################################################################


"""
    arrows2d(points, directions; kwargs...)
    arrows2d(x, y, [z], u, v, [w])
    arrows2d(x, y, [z], f::Function)

Plots arrows as 2D shapes.

$_arrow_args_docs
"""
@recipe Arrows2D (points, directions) begin
    """
    Sets the shape of the arrow tail in units relative to the tailwidth and taillength.
    The arrow shape extends left to right (towards increasing x) and should be defined
    from 0..1 in both dimensions.
    """
    tail = Rect2f(0,0,1,1)
    """
    Sets the shape of the arrow shaft in units relative to the shaftwidth and shaftlength.
    The arrow shape extends left to right (towards increasing x) and should be defined
    from 0..1 in both dimensions.
    """
    shaft = Rect2f(0,0,1,1)
    """
    Sets the shape of the arrow tip in units relative to the tipwidth and tiplength.
    The arrow shape extends left to right (towards increasing x) and should be defined
    from 0..1 in both dimensions.
    """
    tip = Point2f[(0, 0), (1, 0.5), (0, 1)]

    """
    Sets the width of the arrow tail. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tailwidth = 14
    """
    Sets the length of the arrow tail. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tail being drawn.
    """
    taillength = 0
    """
    Sets the width of the arrow shaft. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    shaftwidth = 3
    """
    Sets the length of the arrow shaft. When set to `automatic` the length of the shaft will be
    derived from the length of the arrow, the `taillength` and the `tiplength`. If the results falls
    outside `minshaftlength` to `maxshaftlength` it is clamped and  all lengths and widths are scaled to fit.
    If the `shaftlength` is set to a value, the lengths and widths of the arrow are always scaled.
    """
    shaftlength = automatic
    "Sets the minimum shaft length, see `shaftlength`."
    minshaftlength = 10
    "Sets the maximum shaft length, see `shaftlength`."
    maxshaftlength = Inf
    """
    Sets the width of the arrow tip. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tipwidth = 14
    """
    Sets the length of the arrow tip. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tip being drawn.
    """
    tiplength = 8

    mixin_arrow_attributes()...
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
end

conversion_trait(::Type{<: Arrows2D}) = ArrowLike()



function _get_arrow_shape(x, len, width, shaftwidth)
    if len == 0 || width == 0
        return GeometryBasics.Mesh(Point2f[], GLTriangleFace[])
    else
        m = __get_arrow_shape(x, len, width, shaftwidth)
        for i in eachindex(m.position)
            m.position[i] -= Vec2f(0, 0.5 * width) # center width
        end
        return m
    end
end

__get_arrow_shape(f::Function, length, width, shaftwidth) = poly_convert(f(length, width, shaftwidth))
function __get_arrow_shape(polylike, length, width, shaftwidth)
    # deepcopy so each each meshes positions are independent
    mesh = deepcopy(poly_convert(polylike))
    for i in eachindex(mesh.position)
        mesh.position[i] = (length, width) .* mesh.position[i] # scale
    end
    return mesh
end

function _apply_arrow_transform!(m::GeometryBasics.Mesh, R::Mat2, origin, offset)
    for i in eachindex(m.position)
        m.position[i] = origin + R * (m.position[i] .+ (offset, 0))
    end
    return
end

function plot!(plot::Arrows2D)
    @extract plot (
        colormap, colorscale, normalize, align, lengthscale,
        tail, taillength, tailwidth,
        shaft, shaftlength, minshaftlength, maxshaftlength, shaftwidth,
        tip, tiplength, tipwidth,
        transparency, visible, inspectable
    )

    generic_attributes = copy(Attributes(plot))
    foreach(k -> delete!(generic_attributes, k), [
        :normalize, :align, :lengthscale, :markerscale, :argmode,
        :tail, :taillength, :tailwidth,
        :shaft, :shaftlength, :minshaftlength, :maxshaftlength, :shaftwidth,
        :tip, :tiplength, :tipwidth,
        :space,
        :tailcolor, :shaftcolor, :tipcolor, :color
    ])

    tailcolor = map(default_automatic, plot, plot.tailcolor, plot.color)
    shaftcolor = map(default_automatic, plot, plot.shaftcolor, plot.color)
    tipcolor = map(default_automatic, plot, plot.tipcolor, plot.color)

    startpoints_directions = map(
        _process_arrow_arguments, plot,
        plot[1], plot[2], plot.align, plot.lengthscale, plot.normalize, plot.argmode
    )

    scene = parent_scene(plot)
    arrowpoints_px = map(plot,
            startpoints_directions, transform_func_obs(plot), plot.model, plot.space,
            scene.camera.projectionview, scene.viewport
        ) do (ps, dirs), tf, model, space, pv, vp
        startpoints = plot_to_screen(plot, ps)
        endpoints = plot_to_screen(plot, ps .+ dirs)
        return (startpoints, endpoints .- startpoints)
    end

    arrow_metrics = map(
        plot, arrowpoints_px,
        taillength, tailwidth,
        shaftlength, minshaftlength, maxshaftlength, shaftwidth,
        tiplength, tipwidth,
    ) do (startpoints, directions), taillength, tailwidth,
        shaftlength, minshaftlength, maxshaftlength, shaftwidth,
        tiplength, tipwidth

        metrics = Vector{NTuple{6, Float64}}(undef, length(startpoints))
        for i in eachindex(metrics)
            target_length = norm(directions[i])
            target_shaftlength = if shaftlength === automatic
                clamp(target_length - taillength - tiplength, minshaftlength, maxshaftlength)
            else
                shaftlength
            end
            arrow_length = target_shaftlength + taillength + tiplength
            arrow_scaling = target_length / arrow_length
            metrics[i] = arrow_scaling .* (taillength, tailwidth, target_shaftlength, shaftwidth, tiplength, tipwidth)
        end

        return metrics
    end

    meshes = map(plot, arrow_metrics, tail, shaft, tip) do metrics, tail, shaft, tip
        ps, dirs = arrowpoints_px[]
        meshes = GeometryBasics.Mesh[]

        for i in eachindex(metrics)
            # scale and add color
            taillength, tailwidth, shaftlength, shaftwidth, tiplength, tipwidth = metrics[i]
            tail_m  = _get_arrow_shape(tail,  taillength,  tailwidth,  shaftwidth)
            shaft_m = _get_arrow_shape(shaft, shaftlength, shaftwidth, shaftwidth)
            tip_m   = _get_arrow_shape(tip,   tiplength,   tipwidth,   shaftwidth)

            # rotate + translate
            startpoint = ps[i]
            direction = dirs[i]
            angle = atan(direction[2], direction[1])
            R = rotmatrix2d(angle)

            _apply_arrow_transform!(tail_m, R, startpoint, 0.0)
            _apply_arrow_transform!(shaft_m, R, startpoint, taillength)
            _apply_arrow_transform!(tip_m, R, startpoint, taillength + shaftlength)

            for m in (tail_m, shaft_m, tip_m)
                if !isempty(coordinates(m))
                    push!(meshes, m)
                end
            end
        end

        return meshes
    end

    colors = map(plot, arrow_metrics, tailcolor, shaftcolor, tipcolor) do metrics, cs...
        output = []
        for i in eachindex(metrics)
            for j in 1:3
                len = metrics[i][2j-1]
                width = metrics[i][2j]
                if len != 0 && width != 0
                    push!(output, sv_getindex(cs[j], i))
                end
            end
        end
        return output
    end

    poly!(plot, meshes, space = :pixel, color = colors; generic_attributes...)

    return plot
end


################################################################################


"""
    arrows3d(points, directions; kwargs...)
    arrows3d(x, y, [z], u, v, [w])
    arrows3d(x, y, [z], f::Function)

Plots arrows as 3D shapes.

$_arrow_args_docs
"""
@recipe Arrows3D (points, directions) begin
    """
    Sets the mesh of the arrow tail. The mesh should be defined in a
    Rect3(-0.5, -0.5, 0.0, 1, 1, 1) where +z is direction of the arrow. Anything
    outside this box will extend outside the area designated to the arrow tail.
    """
    tail = Cylinder(Point3f(0,0,0), Point3f(0,0,1), 0.5)
    """
    Sets the mesh of the arrow shaft. The mesh should be defined in a
    Rect3(-0.5, -0.5, 0.0, 1, 1, 1) where +z is direction of the arrow. Anything
    outside this box will extend outside the area designated to the arrow shaft.
    """
    shaft = Cylinder(Point3f(0,0,0), Point3f(0,0,1), 0.5)
    """
    Sets the mesh of the arrow tip. The mesh should be defined in a
    Rect3(-0.5, -0.5, 0.0, 1, 1, 1) where +z is direction of the arrow. Anything
    outside this box will extend outside the area designated to the arrow tip.
    """
    tip = Cone(Point3f(0,0,0), Point3f(0,0,1), 0.5)

    """
    Sets the width of the arrow tail. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tailradius = 0.15
    """
    Sets the length of the arrow tail. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tail being drawn.
    """
    taillength = 0
    """
    Sets the width of the arrow shaft. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    shaftradius = 0.05
    """
    Sets the length of the arrow shaft. When set to `automatic` the length of the shaft will be
    derived from the length of the arrow, the `taillength` and the `tiplength`. If the results falls
    outside `minshaftlength` to `maxshaftlength` it is clamped and  all lengths and widths are scaled to fit.
    If the `shaftlength` is set to a value, the lengths and widths of the arrow are always scaled.
    """
    shaftlength = automatic
    "Sets the minimum shaft length, see `shaftlength`."
    minshaftlength = 0.6
    "Sets the maximum shaft length, see `shaftlength`"
    maxshaftlength = Inf
    """
    Sets the width of the arrow tip. This width may get scaled down if the total arrow length
    exceeds the available space for the arrow.
    """
    tipradius = 0.15
    """
    Sets the length of the arrow tip. This length may get scaled down if the total arrow length
    exceeds the available space for the arrow. Setting this to 0 will result in no tip being drawn.
    """
    tiplength = 0.4

    """
    Scales all arrow components, i.e. all radii and lengths (including min/maxshaftlength).
    When set to `automatic` the scaling factor is based on the boundingbox of the given data.
    This does not affect the mapping between arrows and directions.
    """
    markerscale = automatic
    """
    Sets the number of vertices used when generating meshes for the arrow tail, shaft and cone.
    More vertices will improve the roundness of the mesh but be more costly.
    """
    quality = 32

    mixin_arrow_attributes()...
    MakieCore.mixin_generic_plot_attributes()...
    MakieCore.mixin_colormap_attributes()...
end

conversion_trait(::Type{<: Arrows3D}) = ArrowLike()

to_mesh(m::GeometryBasics.Mesh, n) = m
to_mesh(prim::GeometryBasics.GeometryPrimitive, n) = normal_mesh(Tessellation(prim, n))

function plot!(plot::Arrows3D)
    @extract plot (
        normalize, align, lengthscale, markerscale, quality,
        tail, taillength, tailradius,
        shaft, shaftlength, minshaftlength, maxshaftlength, shaftradius,
        tip, tiplength, tipradius,
        visible
    )

    generic_attributes = copy(Attributes(plot))
    foreach(k -> delete!(generic_attributes, k), [
        :normalize, :align, :lengthscale, :markerscale, :argmode, :quality,
        :tail, :taillength, :tailradius,
        :shaft, :shaftlength, :minshaftlength, :maxshaftlength, :shaftradius,
        :tip, :tiplength, :tipradius,
        :visible,
        :tailcolor, :shaftcolor, :tipcolor, :color
    ])

    tailcolor = map(default_automatic, plot, plot.tailcolor, plot.color)
    shaftcolor = map(default_automatic, plot, plot.shaftcolor, plot.color)
    tipcolor = map(default_automatic, plot, plot.tipcolor, plot.color)

    startpoints_directions = map(
        _process_arrow_arguments, plot,
        plot[1], plot[2], plot.align, plot.lengthscale, plot.normalize, plot.argmode
    )

    arrowscale = map(plot, startpoints_directions, markerscale) do (ps, dirs), ms
        if ms === automatic
            # TODO: maybe maximum? or max of each 2d norm?
            bbox = update_boundingbox(Rect3d(ps), Rect3d(ps .+ dirs))
            scale = norm(widths(bbox))
            return ifelse(scale == 0.0, 1.0, scale)
        else
            return Float64(ms)
        end
    end

    arrow_metrics = map(
        plot, startpoints_directions, arrowscale, shaftlength,
        taillength, tailradius,
        minshaftlength, maxshaftlength, shaftradius,
        tiplength, tipradius,
    ) do (_, directions), arrowscale, _shaftlength, user_metrics...

        # apply scaling factor to all user metrics
        taillength, tailradius, minshaftlength, maxshaftlength, shaftradius,
            tiplength, tipradius = arrowscale .* user_metrics
        shaftlength = _shaftlength === automatic ? _shaftlength : arrowscale * _shaftlength

        constlength = taillength + tiplength

        # scale arrow matrics to direction, either by scaling shaftlength or all metrics
        metrics = Vector{NTuple{6, Float64}}(undef, length(directions))
        for i in eachindex(metrics)
            target_length = norm(directions[i])
            target_shaftlength = if shaftlength === automatic
                clamp(target_length - constlength, minshaftlength, maxshaftlength)
            else
                shaftlength
            end
            arrow_length = target_shaftlength + constlength
            arrow_scaling = target_length / arrow_length
            metrics[i] = arrow_scaling .*
                (taillength, tailradius, target_shaftlength, shaftradius, tiplength, tipradius)
        end

        return metrics
    end

    # normalize if not yet normalized
    rot = map(plot, startpoints_directions, normalize) do (pos, dirs), normalized
        return normalized ? dirs : LinearAlgebra.normalize.(dirs)
    end

    tail_scale = map(metrics -> [Vec3f(2r, 2r, l) for (l, r, _, _, _, _) in metrics], plot, arrow_metrics)
    tail_visible = map((l, v) -> !iszero(l) && v, plot, plot.taillength, visible)

    # Skip startpoints, directions inputs to avoid double update (let arrow metrics trigger)
    shaft_pos = map(plot, arrow_metrics) do metrics
        map(metrics, startpoints_directions[][1], rot[]) do metric, pos, dir
            taillength, tailradius, shaftlength, shaftradius, tiplength, tipradius = metric
            return pos + taillength * dir
        end
    end
    shaft_scale = map(metrics -> [Vec3f(2r, 2r, l) for (_, _, l, r, _, _) in metrics], plot, arrow_metrics)

    tip_pos = map(plot, arrow_metrics) do metrics
        map(metrics, startpoints_directions[][1], rot[]) do metric, pos, dir
            taillength, tailradius, shaftlength, shaftradius, tiplength, tipradius = metric
            return pos + (taillength + shaftlength) * dir
        end
    end
    tip_scale = map(metrics -> [Vec3f(2r, 2r, l) for (_, _, _, _, l, r) in metrics], plot, arrow_metrics)
    tip_visible = map((l, v) -> !iszero(l) && v, plot, plot.tiplength, visible)

    tail_m = map(to_mesh, plot, tail, quality)
    shaft_m = map(to_mesh, plot, shaft, quality)
    tip_m = map(to_mesh, plot, tip, quality)

    meshscatter!(plot,
        map(first, plot, startpoints_directions), marker = tail_m, markersize = tail_scale, rotation = rot,
        color = tailcolor, visible = tail_visible; generic_attributes...
    )
    meshscatter!(plot,
        shaft_pos, marker = shaft_m, markersize = shaft_scale, rotation = rot,
        color = shaftcolor, visible = visible; generic_attributes...
    )
    meshscatter!(plot,
        tip_pos, marker = tip_m, markersize = tip_scale, rotation = rot,
        color = tipcolor, visible = tip_visible; generic_attributes...
    )

    return plot
end

function data_limits(plot::Union{Arrows2D, Arrows3D})
    startpoints, directions = _process_arrow_arguments(
        plot[1][], plot[2][], plot.align[], plot.lengthscale[], plot.normalize[], plot.argmode[]
    )

    return update_boundingbox(
        Rect3d(startpoints),
        Rect3d(startpoints .+ directions)
    )
end
boundingbox(p::Union{Arrows2D, Arrows3D}, space::Symbol) = apply_transform_and_model(p, data_limits(p))