################################################################################
### Generic
################################################################################

struct ArrowLike <: ConversionTrait end

# vec(::Point) and vec(::Vec) works (returns input), but vec(::Tuple) errors
convert_arguments(::ArrowLike, pos::VecTypes{N}, dir::VecTypes{N}) where {N} = ([pos], [dir])

function convert_arguments(::ArrowLike, pos::AbstractArray, dir::AbstractArray)
    return (
        convert_arguments(PointBased(), vec(pos))[1],
        convert_arguments(PointBased(), vec(dir))[1],
    )
end

function convert_arguments(::ArrowLike, x, y, u, v)
    return (
        convert_arguments(PointBased(), vec(x), vec(y))[1],
        convert_arguments(PointBased(), vec(u), vec(v))[1],
    )
end
function convert_arguments(::ArrowLike, x::AbstractVector, y::AbstractVector, u::AbstractMatrix, v::AbstractMatrix)
    return (
        vec(Point{2, float_type(x, y)}.(x, y')),
        convert_arguments(PointBased(), vec(u), vec(v))[1],
    )
end
function convert_arguments(::ArrowLike, x, y, z, u, v, w)
    return (
        convert_arguments(PointBased(), vec(x), vec(y), vec(z))[1],
        convert_arguments(PointBased(), vec(u), vec(v), vec(w))[1],
    )
end

function convert_arguments(::ArrowLike, pos::AbstractArray, f::Function)
    points = convert_arguments(PointBased(), vec(pos))[1]
    f_out = eltype(points).(f.(points))
    return (points, f_out)
end

function convert_arguments(::ArrowLike, x::RealVector, y::RealVector, f::Function)
    points = Point2{float_type(x, y)}.(x, y')
    f_out = Point2{float_type(x, y)}.(f.(points))
    return (vec(points), vec(f_out))
end

function convert_arguments(
        ::ArrowLike, x::RealVector, y::RealVector, z::RealVector,
        f::Function
    )
    points = [Point3{float_type(x, y, z)}(x, y, z) for x in x, y in y, z in z]
    f_out = Point3{float_type(x, y, z)}.(f.(points))
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
        return startpoints, startpoints .+ dirs

    elseif argmode in (:direction, :directions)
        # compute startpoint such that plot[1] is at the align_val fraction of the drawn arrow
        dirs = lengthscale .* (norm ? normalize.(pos_or_dir) : pos_or_dir)
        startpoints = pos .- align_val .* dirs
        return startpoints, startpoints .+ dirs

    else
        error("Did not recognize argmode = :$argmode - must be :endpoint or :direction")
    end
end

function mixin_arrow_attributes()
    return @DocumentedAttributes begin
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
        lengthscale = 1.0f0
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

arrows(args...; kwargs...) = resolve_arrows_deprecation(false, args, Dict{Symbol, Any}(kwargs))
arrows!(args...; kwargs...) = resolve_arrows_deprecation(true, args, Dict{Symbol, Any}(kwargs))

# For the matlab/matplotlib users
const quiver = arrows
const quiver! = arrows!
export quiver, quiver!

_is_3d_arrows(::Union{Scene, Block, GridLayoutBase.GridPosition}, args...) = _is_3d_arrows(args...)
_is_3d_arrows(::VecTypes{2}, ::VecTypes{2}) = false
_is_3d_arrows(::VecTypes{3}, ::VecTypes{3}) = true
_is_3d_arrows(::AbstractArray{<:VecTypes{2}}, ::AbstractArray{<:VecTypes{2}}) = false
_is_3d_arrows(::AbstractArray{<:VecTypes{3}}, ::AbstractArray{<:VecTypes{3}}) = true
_is_3d_arrows(::AbstractArray, ::AbstractArray, ::AbstractArray, ::AbstractArray) = false
_is_3d_arrows(::AbstractArray, ::AbstractArray, ::AbstractArray, ::AbstractArray, ::AbstractArray, ::AbstractArray) = true
_is_3d_arrows(::AbstractArray{<:VecTypes{2}}, ::Function) = false
_is_3d_arrows(::AbstractArray{<:VecTypes{3}}, ::Function) = true
_is_3d_arrows(::AbstractArray, ::AbstractArray, ::Function) = false
_is_3d_arrows(::AbstractArray, ::AbstractArray, ::AbstractArray, ::Function) = true

function resolve_arrows_deprecation(mutating, args, kwargs)
    @warn "`arrows` are deprecated in favor of `arrows2d` and `arrows3d`."

    is3d = _is_3d_arrows(args...)
    if is3d
        func = mutating ? arrows3d! : arrows3d
        removed = Set([:markerspace, :linestyle, :transform_marker])

        # Old 3d defaults
        get!(kwargs, :markerscale, 1.0)
        get!(kwargs, :tipradius, 0.1)
        get!(kwargs, :tiplength, 0.3)
    else
        func = mutating ? arrows2d! : arrows2d
        removed = Set([:quality, :markerspace, :linestyle, :transform_marker])

        # Old 2d defaults
        theme = current_default_theme()
        get!(kwargs, :shaftwidth, 1.0)
        get!(kwargs, :tipwidth, 0.45 * theme[:markersize][])
        get!(kwargs, :tiplength, 0.45 * theme[:markersize][])
    end

    renamed = Dict(
        :arrowhead => :tip, :arrowtail => :shaft,
        :arrowcolor => :tipcolor, :linecolor => :shaftcolor,
    )

    for k in keys(kwargs)
        if k in removed
            @warn "Attribute $k has been removed."
        elseif haskey(renamed, k)
            new = renamed[k]
            @warn "$k has been renamed to $new."
            kwargs[new] = pop!(kwargs, k)
        elseif k === :linewidth
            radius = is3d ? (:shaftradius) : (:shaftwidth)
            obs = convert(Observable{Any}, pop!(kwargs, :linewidth))
            kwargs[radius] = map(x -> 0.5 * first(x), obs)
        elseif k === :arrowsize
            radius = is3d ? (:tipradius) : (:tipwidth)
            @warn "arrowsize has been deprecated in favor of $radius and tiplength."
            size3d = map(to_3d_scale, convert(Observable{Any}, pop!(kwargs, :arrowsize)))
            kwargs[radius] = map(x -> (is3d ? 0.5 : 0.75) * first(x), size3d)
            kwargs[:tiplength] = map(x -> (is3d ? 1.0 : 0.75) * last(x), size3d)
        end
    end

    # Set up some old defaults
    if is3d
        get!(kwargs, :shaftradius, map(x -> 0.5 * x, kwargs[:tipradius]))
    end
    get!(kwargs, :minshaftlength, 0.0)

    return func(args...; kwargs...)
end

################################################################################
### 2D Arrows
################################################################################

function arrowtail2d(l, W, metrics)
    w = metrics.shaftwidth
    return Point2f[
        (0, 0), (-0.3W, -0.5W), (l - 0.3W, -0.5W), (l, 0 - 0.5w),
        (l, 0.5w), (l - 0.3W, 0.5W), (-0.3W, 0.5W),
    ]
end

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
    in a 0..1 by -0.5..0.5 range.
    """
    tail = arrowtail2d
    """
    Sets the shape of the arrow shaft in units relative to the shaftwidth and shaftlength.
    The arrow shape extends left to right (towards increasing x) and should be defined
    in a 0..1 by -0.5..0.5 range.
    """
    shaft = Rect2f(0, -0.5, 1, 1)
    """
    Sets the shape of the arrow tip in units relative to the tipwidth and tiplength.
    The arrow shape extends left to right (towards increasing x) and should be defined
    in a 0..1 by -0.5..0.5 range.
    """
    tip = Point2f[(0, -0.5), (1, 0), (0, 0.5)]

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

    """
    Arrows2D relies on mesh rendering to draw arrows, which doesn't anti-alias well when the
    mesh gets thin. To mask this issue an outline is drawn over the mesh with lines. The width
    of that outline is given by `strokemask`. Setting this to `0` may improve transparent arrows.
    """
    strokemask = 0.75

    "Sets the space of arrow metrics like tipwidth, tiplength, etc."
    markerspace = :pixel

    mixin_arrow_attributes()...
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

conversion_trait(::Type{<:Arrows2D}) = ArrowLike()

function _get_arrow_shape(f::Function, length, width, metrics)
    nt = NamedTuple{(:taillength, :tailwidth, :shaftlength, :shaftwidth, :tiplength, :tipwidth)}(metrics)
    return poly_convert(f(length, width, nt))
end

function _get_arrow_shape(polylike, length, width, metrics)
    # deepcopy so each each meshes positions are independent
    mesh = deepcopy(poly_convert(polylike))
    for i in eachindex(mesh.position)
        mesh.position[i] = (length, width) .* mesh.position[i] # scale
    end
    return mesh
end

function _apply_arrow_transform(m::GeometryBasics.Mesh, R::Mat2, origin, offset)
    ps = [origin + to_ndim(Point3f, R * (p .+ (offset, 0)), 0) for p in coordinates(m)]
    return GeometryBasics.mesh(m, position = ps, pointtype = Point3f)
end

function Makie.plot!(plot::Arrows2D)
    map!(
        _process_arrow_arguments, plot,
        [:points, :directions, :align, :lengthscale, :normalize, :argmode],
        [:startpoints, :endpoints]
    )

    # TODO: Doesn't dropping the third dimension here break z order?
    register_projected_positions!(
        plot, Point3f, input_name = :startpoints, output_name = :pixel_startpoints, output_space = :pixel
    )
    register_projected_positions!(
        plot, Point3f, input_name = :endpoints, output_name = :pixel_endpoints, output_space = :pixel
    )

    map!(plot, [:pixel_startpoints, :pixel_endpoints], :pixel_directions) do startpoints, endpoints
        return Point2f.(endpoints) .- Point2f.(startpoints)
    end

    map!(
        plot,
        [
            :pixel_directions, :taillength, :tailwidth, :shaftlength,
            :minshaftlength, :maxshaftlength, :shaftwidth, :tiplength, :tipwidth,
        ],
        :arrow_metrics
    ) do directions, taillength, tailwidth, shaftlength, minshaftlength, maxshaftlength, shaftwidth, tiplength, tipwidth

        metrics = Vector{NTuple{6, Float64}}(undef, length(directions))
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

    map!(
        plot,
        [:taillength, :tailwidth, :shaftwidth, :tiplength, :tipwidth],
        :should_component_render
    ) do taillength, tailwidth, shaftwidth, tiplength, tipwidth
        return (
            taillength > 0 && tailwidth > 0,
            shaftwidth > 0,
            tiplength > 0 && tipwidth > 0,
        )
    end

    map!(
        plot,
        [
            :pixel_startpoints, :pixel_directions, :arrow_metrics, :strokemask,
            :should_component_render, :tail, :shaft, :tip,
        ],
        :meshes
    ) do ps, dirs, metrics, mask, should_render, shapes...
        meshes = GeometryBasics.Mesh[]

        for i in eachindex(metrics)
            # rotate + translate
            startpoint = ps[i]
            direction = dirs[i]
            angle = atan(direction[2], direction[1])
            R = rotmatrix2d(angle)
            offset = 0.0

            for (shape, len, width, render) in zip(shapes, metrics[i][1:2:6], metrics[i][2:2:6], should_render)
                render || continue
                mesh = _get_arrow_shape(shape, len, max(0, width - mask), metrics[i])
                push!(meshes, _apply_arrow_transform(mesh, R, startpoint, offset))

                offset += len
            end
        end

        return meshes
    end

    # Similar to register_colormapping, but for each color
    register_colormapping_without_color!(plot.attributes)
    map!(to_color, plot, :nan_color, :converted_nan_color)

    for key in [:tailcolor, :shaftcolor, :tipcolor]
        map!(
            plot, [key, :color, :colorscale, :alpha], Symbol(:scaled_, key)
        ) do maybe_color, default, colorscale, alpha

            color = to_color(default_automatic(maybe_color, default))
            return if color isa Union{Real, AbstractArray{<:Real}}
                clamp.(el32convert(apply_scale(colorscale, color)), -floatmax(Float32), floatmax(Float32))
            elseif color isa AbstractArray
                add_alpha.(color, alpha)
            else
                add_alpha(color, alpha)
            end
        end
    end

    map!(
        plot,
        [:colorrange, :colorscale, :scaled_tailcolor, :scaled_shaftcolor, :scaled_tipcolor],
        :scaled_colorrange
    ) do colorrange, colorscale, colors...

        if !any(c -> c isa Union{Real, AbstractArray{<:Real}}, colors)
            return nothing
        elseif colorrange === automatic
            final_colorrange = Vec2f(Inf, -Inf)
            for color in colors
                if (color isa Union{Real, AbstractArray{<:Real}}) && !isempty(color)
                    cr = distinct_extrema_nan(color)
                    final_colorrange = Vec2f(min(cr[1], final_colorrange[1]), max(cr[2], final_colorrange[2]))
                end
            end
            return final_colorrange[1] < final_colorrange[2] ? final_colorrange : Vec2f(0, 10)
        else
            return Vec2f(apply_scale(colorscale, colorrange))
        end
    end

    # Convert to actual RGBA colors
    for key in [:tailcolor, :shaftcolor, :tipcolor]
        add_computation!(
            plot.attributes, Val(:computed_color), Symbol(:scaled_, key),
            output_name = Symbol(:calculated_, key), nan_color = :converted_nan_color
        )
    end

    # map to poly vertices
    map!(
        plot,
        [:arrow_metrics, :should_component_render, :calculated_tailcolor, :calculated_shaftcolor, :calculated_tipcolor],
        :merged_colors
    ) do metrics, should_render, colors...

        output = RGBA[]
        for i in eachindex(metrics)
            for j in 1:3
                if should_render[j]
                    push!(output, sv_getindex(colors[j], i))
                end
            end
        end
        return output
    end

    # mesh anti-aliasing in GLMakie gets pretty bad when the mesh becomes very
    # thin (e.g. if shaftwidth is small). To hide this, we reduce the mesh width
    # further and add some stroke (lines) instead.
    poly!(
        plot, plot.attributes, plot.meshes, space = plot.markerspace,
        color = plot.merged_colors,
        strokecolor = plot.merged_colors, strokewidth = plot.strokemask;
        transformation = :nothing, alpha = 1
    )

    return plot
end

function data_limits(plot::Arrows2D)
    return update_boundingbox(Rect3d(plot.startpoints[]), Rect3d(plot.endpoints[]))
end
boundingbox(p::Arrows2D, space::Symbol) = apply_transform_and_model(p, data_limits(p))


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
    tail = Cylinder(Point3f(0, 0, 0), Point3f(0, 0, 1), 0.5)
    """
    Sets the mesh of the arrow shaft. The mesh should be defined in a
    Rect3(-0.5, -0.5, 0.0, 1, 1, 1) where +z is direction of the arrow. Anything
    outside this box will extend outside the area designated to the arrow shaft.
    """
    shaft = Cylinder(Point3f(0, 0, 0), Point3f(0, 0, 1), 0.5)
    """
    Sets the mesh of the arrow tip. The mesh should be defined in a
    Rect3(-0.5, -0.5, 0.0, 1, 1, 1) where +z is direction of the arrow. Anything
    outside this box will extend outside the area designated to the arrow tip.
    """
    tip = Cone(Point3f(0, 0, 0), Point3f(0, 0, 1), 0.5)

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

    mixin_shading_attributes()...
    mixin_arrow_attributes()...
    mixin_generic_plot_attributes()...
    mixin_colormap_attributes()...
end

conversion_trait(::Type{<:Arrows3D}) = ArrowLike()

to_mesh(m::GeometryBasics.Mesh, n) = m
function to_mesh(prim::GeometryBasics.GeometryPrimitive, n)
    return try
        normal_mesh(Tessellation(prim, n))
    catch e
        normal_mesh(prim)
    end
end

function Makie.plot!(plot::Arrows3D)
    map!(default_automatic, plot, [:tailcolor, :color], :resolved_tailcolor)
    map!(default_automatic, plot, [:shaftcolor, :color], :resolved_shaftcolor)
    map!(default_automatic, plot, [:tipcolor, :color], :resolved_tipcolor)

    map!(
        _process_arrow_arguments, plot,
        [:points, :directions, :align, :lengthscale, :normalize, :argmode],
        [:startpoints, :endpoints]
    )

    register_projected_positions!(
        plot, input_name = :startpoints, output_name = :world_startpoints, output_space = :data
    )
    register_projected_positions!(
        plot, input_name = :endpoints, output_name = :world_endpoints, output_space = :data
    )

    map!(plot, [:world_startpoints, :world_endpoints], :world_directions) do startpoints, endpoints
        return endpoints .- startpoints
    end

    map!(plot, [:world_startpoints, :world_endpoints, :markerscale], :arrowscale) do startpoints, endpoints, ms
        if ms === automatic
            # This bbox does not include the size of the arrow mesh, which
            # `boundingbox()` does include. So we can't reuse it
            bbox = update_boundingbox(Rect3d(startpoints), Rect3d(endpoints))
            # TODO: maybe maximum? or max of each 2d norm?
            scale = norm(widths(bbox))
            return ifelse(scale == 0.0, 1.0, scale)
        else
            return Float64(ms)
        end
    end

    map!(
        plot,
        [
            :world_directions, :arrowscale, :shaftlength, :taillength, :tailradius,
            :minshaftlength, :maxshaftlength, :shaftradius, :tiplength, :tipradius,
        ],
        :arrow_metrics
    ) do directions, arrowscale, _shaftlength, user_metrics...

        # apply scaling factor to all user metrics
        taillength, tailradius, minshaftlength, maxshaftlength, shaftradius,
            tiplength, tipradius = arrowscale .* user_metrics
        shaftlength = _shaftlength === automatic ? _shaftlength : arrowscale * _shaftlength

        constlength = taillength + tiplength

        # scale arrow metrics to direction, either by scaling shaftlength or all metrics
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
    map!(plot, [:world_directions, :normalize], :normalized_dir) do dirs, normalized
        return normalized ? dirs : LinearAlgebra.normalize.(dirs)
    end
    map!(dirs -> to_ndim.(Vec3f, dirs, 0), plot, :normalized_dir, :rot)

    map!(metrics -> [Vec3f(2r, 2r, l) for (l, r, _, _, _, _) in metrics], plot, :arrow_metrics, :tail_scale)
    map!((l, v) -> !iszero(l) && v, plot, [:taillength, :visible], :tail_visible)

    # Skip startpoints, directions inputs to avoid double update (let arrow metrics trigger)
    map!(plot, [:arrow_metrics, :world_startpoints, :normalized_dir], :shaft_pos) do metrics, startpoints, dirs
        map(metrics, startpoints, dirs) do metric, pos, dir
            taillength, tailradius, shaftlength, shaftradius, tiplength, tipradius = metric
            return pos + taillength * dir
        end
    end
    map!(metrics -> [Vec3f(2r, 2r, l) for (_, _, l, r, _, _) in metrics], plot, :arrow_metrics, :shaft_scale)

    map!(plot, [:arrow_metrics, :world_startpoints, :normalized_dir], :tip_pos) do metrics, startpoints, dirs
        map(metrics, startpoints, dirs) do metric, pos, dir
            taillength, tailradius, shaftlength, shaftradius, tiplength, tipradius = metric
            return pos + (taillength + shaftlength) * dir
        end
    end
    map!(metrics -> [Vec3f(2r, 2r, l) for (_, _, _, _, l, r) in metrics], plot, [:arrow_metrics], :tip_scale)
    map!((l, v) -> !iszero(l) && v, plot, [:tiplength, :visible], :tip_visible)

    map!(to_mesh, plot, [:tail, :quality], :tail_m)
    map!(to_mesh, plot, [:shaft, :quality], :shaft_m)
    map!(to_mesh, plot, [:tip, :quality], :tip_m)

    meshscatter!(
        plot, plot.attributes,
        plot.world_startpoints, markersize = plot.tail_scale, rotation = plot.rot,
        marker = plot.tail_m, color = plot.resolved_tailcolor, visible = plot.tail_visible,
        transformation = :nothing, transform_marker = false,
    )
    meshscatter!(
        plot, plot.attributes,
        plot.shaft_pos, markersize = plot.shaft_scale, rotation = plot.rot,
        marker = plot.shaft_m, color = plot.resolved_shaftcolor, visible = plot.visible,
        transformation = :nothing, transform_marker = false,
    )
    meshscatter!(
        plot, plot.attributes,
        plot.tip_pos, markersize = plot.tip_scale, rotation = plot.rot,
        marker = plot.tip_m, color = plot.resolved_tipcolor, visible = plot.tip_visible,
        transformation = :nothing, transform_marker = false,
    )

    return plot
end

function data_limits(plot::Arrows3D)
    return update_boundingbox(Rect3d(plot.startpoints[]), Rect3d(plot.endpoints[]))
end

function boundingbox(plot::Arrows3D, space::Symbol)
    bb = Rect3d()
    for p in plot.plots
        p.visible[] || continue
        bb = update_boundingbox(bb, data_limits(p))
    end
    return bb
end

# compat
const Arrows{T} = Union{Arrows2D{T}, Arrows3D{T}}
export Arrows
