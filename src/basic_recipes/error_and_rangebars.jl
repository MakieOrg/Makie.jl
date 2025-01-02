"""
    errorbars(x, y, error_both; kwargs...)
    errorbars(x, y, error_low, error_high; kwargs...)
    errorbars(x, y, error_low_high; kwargs...)

    errorbars(xy, error_both; kwargs...)
    errorbars(xy, error_low, error_high; kwargs...)
    errorbars(xy, error_low_high; kwargs...)

    errorbars(xy_error_both; kwargs...)
    errorbars(xy_error_low_high; kwargs...)

Plots errorbars at xy positions, extending by errors in the given `direction`.

If you want to plot intervals from low to high values instead of relative errors, use `rangebars`.
"""
@recipe Errorbars (val_low_high::AbstractVector{<:Union{Vec3, Vec4}},) begin
    "The width of the whiskers or line caps in screen units."
    whiskerwidth = 0
    "The color of the lines. Can be an array to color each bar separately."
    color = @inherit linecolor
    "The thickness of the lines in screen units."
    linewidth = @inherit linewidth
    linecap = @inherit linecap
    "The direction in which the bars are drawn. Can be `:x` or `:y`."
    direction = :y
    cycle = [:color]
    MakieCore.mixin_colormap_attributes()...
    MakieCore.mixin_generic_plot_attributes()...
end

const RealOrVec = Union{Real, RealVector}

"""
    rangebars(val, low, high; kwargs...)
    rangebars(val, low_high; kwargs...)
    rangebars(val_low_high; kwargs...)

Plots rangebars at `val` in one dimension, extending from `low` to `high` in the other dimension
given the chosen `direction`.
The `low_high` argument can be a vector of tuples or intervals.

If you want to plot errors relative to a reference value, use `errorbars`.
"""
@recipe Rangebars begin
    "The width of the whiskers or line caps in screen units."
    whiskerwidth = 0
    "The color of the lines. Can be an array to color each bar separately."
    color = @inherit linecolor
    "The thickness of the lines in screen units."
    linewidth = @inherit linewidth
    linecap = @inherit linecap
    "The direction in which the bars are drawn. Can be `:x` or `:y`."
    direction = :y
    cycle = [:color]
    MakieCore.mixin_colormap_attributes()...
    MakieCore.mixin_generic_plot_attributes()...
end

### conversions for errorbars

function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_both::RealVector)
    T = float_type(x, y, error_both)
    xyerr = broadcast(x, y, error_both) do x, y, e
        Vec4{T}(x, y, e, e)
    end
    return (xyerr,)
end
RealOrVec
function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_low::RealOrVec, error_high::RealOrVec)
    T = float_type(x, y, error_low, error_high)
    xyerr = broadcast(Vec4{T}, x, y, error_low, error_high)
    return (xyerr,)
end


function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_low_high::AbstractVector{<:VecTypes{2, T}}) where {T}
    T_out = float_type(float_type(x, y), T)
    xyerr = broadcast(x, y, error_low_high) do x, y, (el, eh)
        Vec4{T_out}(x, y, el, eh)
    end
    return (xyerr,)
end

function convert_arguments(
        ::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2, T}},
        error_both::RealOrVec
    ) where {T}
    T_out = float_type(T, float_type(error_both))
    xyerr = broadcast(xy, error_both) do (x, y), e
        Vec4{T_out}(x, y, e, e)
    end
    return (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2, T}}, error_low::RealOrVec, error_high::RealOrVec) where {T}
    T_out = float_type(T, float_type(error_low, error_high))
    xyerr = broadcast(xy, error_low, error_high) do (x, y), el, eh
        Vec4{T_out}(x, y, el, eh)
    end
    return (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2, T1}}, error_low_high::AbstractVector{<:VecTypes{2, T2}}) where {T1, T2}
    T_out = float_type(T1, T2)
    xyerr = broadcast(xy, error_low_high) do (x, y), (el, eh)
        Vec4{T_out}(x, y, el, eh)
    end
    return (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy_error_both::AbstractVector{<:VecTypes{3, T}}) where {T}
    T_out = float_type(T)
    xyerr = broadcast(xy_error_both) do (x, y, e)
        Vec4{T_out}(x, y, e, e)
    end
    return (xyerr,)
end

### conversions for rangebars

function convert_arguments(::Type{<:Rangebars}, val::RealOrVec, low::RealOrVec, high::RealOrVec)
    T = float_type(val, low, high)
    val_low_high = broadcast(Vec3{T}, val, low, high)
    return (val_low_high,)
end

function convert_arguments(
        ::Type{<:Rangebars}, val::RealOrVec,
        low_high::AbstractVector{<:VecTypes{2, T}}
    ) where {T}
    T_out = float_type(float_type(val), T)
    val_low_high = broadcast(val, low_high) do val, (low, high)
        Vec3{T_out}(val, low, high)
    end
    return (val_low_high,)
end

Makie.convert_arguments(P::Type{<:Rangebars}, x::AbstractVector{<:Number}, y::AbstractVector{<:Interval}) =
    convert_arguments(P, x, endpoints.(y))

### the two plotting functions create linesegpairs in two different ways
### and then hit the same underlying implementation in `_plot_bars!`

function Makie.plot!(plot::Errorbars{<:Tuple{AbstractVector{<:Vec{4}}}})

    x_y_low_high = plot[1]

    is_in_y_direction = lift(plot, plot.direction) do dir
        if dir === :y
            true
        elseif dir === :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    linesegpairs = lift(plot, x_y_low_high, is_in_y_direction) do x_y_low_high, in_y
        output = sizehint!(Point2d[], 2length(x_y_low_high))
        for (x, y, l, h) in x_y_low_high
            if in_y
                push!(output, Point2d(x, y - l), Point2d(x, y + h))
            else
                push!(output, Point2d(x - l, y), Point2d(x + h, y))
            end
        end
        return output
    end

    return _plot_bars!(plot, linesegpairs, is_in_y_direction)
end


function Makie.plot!(plot::Rangebars{<:Tuple{AbstractVector{<:Vec{3}}}})

    val_low_high = plot[1]

    is_in_y_direction = lift(plot, plot.direction) do dir
        if dir === :y
            return true
        elseif dir === :x
            return false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    linesegpairs = lift(plot, val_low_high, is_in_y_direction) do vlh, in_y
        output = sizehint!(Point2d[], 2length(vlh))
        for (v, l, h) in vlh
            if in_y
                push!(output, Point2d(v, l), Point2d(v, h))
            else
                push!(output, Point2d(l, v), Point2d(h, v))
            end
        end
        return output
    end

    return _plot_bars!(plot, linesegpairs, is_in_y_direction)
end


function _plot_bars!(plot, linesegpairs, is_in_y_direction)

    f_if(condition, f, arg) = condition ? f(arg) : arg

    @extract plot (
        whiskerwidth, color, linewidth, linecap, visible, colormap, colorscale, colorrange,
        inspectable, transparency,
    )

    scene = parent_scene(plot)

    whiskers = lift(
        plot, linesegpairs, scene.camera.projectionview, plot.model,
        scene.viewport, transform_func(plot), whiskerwidth
    ) do endpoints, _, _, _, _, whiskerwidth

        screenendpoints = plot_to_screen(plot, endpoints)

        screenendpoints_shifted_pairs = map(screenendpoints) do sep
            (
                sep .+ f_if(is_in_y_direction[], reverse, Point(0, -whiskerwidth / 2)),
                sep .+ f_if(is_in_y_direction[], reverse, Point(0, whiskerwidth / 2)),
            )
        end

        return [p for pair in screenendpoints_shifted_pairs for p in pair]
    end
    whiskercolors = Observable{RGBColors}()
    lift!(plot, whiskercolors, color) do color
        # we have twice as many linesegments for whiskers as we have errorbars, so we
        # need to duplicate colors if a vector of colors is given
        if color isa AbstractVector
            return repeat(to_color(color), inner = 2)::RGBColors
        else
            return to_color(color)::RGBAf
        end
    end
    whiskerlinewidths = Observable{Union{Float32, Vector{Float32}}}()
    lift!(plot, whiskerlinewidths, linewidth) do linewidth
        # same for linewidth
        if linewidth isa AbstractVector
            return repeat(convert(Vector{Float32}, linewidth), inner = 2)::Vector{Float32}
        else
            return convert(Float32, linewidth)
        end
    end

    linesegments!(
        plot, linesegpairs, color = color, linewidth = linewidth, linecap = linecap, visible = visible,
        colormap = colormap, colorscale = colorscale, colorrange = colorrange, inspectable = inspectable,
        transparency = transparency
    )
    linesegments!(
        plot, whiskers, color = whiskercolors, linewidth = whiskerlinewidths, linecap = linecap,
        visible = visible, colormap = colormap, colorscale = colorscale, colorrange = colorrange,
        inspectable = inspectable, transparency = transparency, space = :pixel,
        model = Mat4f(I) # overwrite scale!() / translate!() / rotate!()
    )
    return plot
end

function plot_to_screen(plot, points::AbstractVector)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) *
        f32_convert_matrix(plot, space) * transformationmatrix(plot)[]

    return map(points) do p
        transformed = apply_transform(transform_func(plot), p, space)
        p4d = spvm * to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
        return Point2f(p4d) / p4d[4]
    end
end

function plot_to_screen(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) *
        f32_convert_matrix(plot, space) * transformationmatrix(plot)[]
    transformed = apply_transform(transform_func(plot), p, space)
    p4d = spvm * to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
    return Point2f(p4d) / p4d[4]
end

function screen_to_plot(plot, points::AbstractVector)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    mvps = inv(transformationmatrix(plot)[]) * inv_f32_convert_matrix(plot, space) *
        clip_to_space(cam, space) * space_to_clip(cam, :pixel)
    itf = inverse_transform(transform_func(plot))

    return map(points) do p
        pre_transform = mvps * to_ndim(Vec4d, to_ndim(Vec3d, p, 0.0), 1.0)
        p3 = Point3d(pre_transform) / pre_transform[4]
        return apply_transform(itf, p3, space)
    end
end

function screen_to_plot(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    mvps = inv(transformationmatrix(plot)[]) * inv_f32_convert_matrix(plot, space) *
        clip_to_space(cam, space) * space_to_clip(cam, :pixel)
    pre_transform = mvps * to_ndim(Vec4d, to_ndim(Vec3d, p, 0.0), 1.0)
    p3 = Point3d(pre_transform) / pre_transform[4]
    return apply_transform(itf, p3, space)
end

# ignore whiskers when determining data limits
data_limits(bars::Union{Errorbars, Rangebars}) = data_limits(bars.plots[1])
boundingbox(bars::Union{Errorbars, Rangebars}, space::Symbol = :data) = apply_transform_and_model(bars, data_limits(bars))
