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
@recipe Rangebars (val_low_high::AbstractVector{<:Union{Vec3, Vec4}},) begin
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

function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_both::RealOrVec)
    T = float_type(x, y, error_both)
    xyerr = broadcast(x, y, error_both) do x, y, e
        Vec4{T}(x, y, e, e)
    end
    (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_low::RealOrVec, error_high::RealOrVec)
    T = float_type(x, y, error_low, error_high)
    xyerr = broadcast(Vec4{T}, x, y, error_low, error_high)
    (xyerr,)
end


function convert_arguments(::Type{<:Errorbars}, x::RealOrVec, y::RealOrVec, error_low_high::AbstractVector{<:VecTypes{2, T}}) where T
    T_out = float_type(float_type(x, y), T)
    xyerr = broadcast(x, y, error_low_high) do x, y, (el, eh)
        Vec4{T_out}(x, y, el, eh)
    end
    (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2,T}},
                           error_both::RealOrVec) where {T}
    T_out = float_type(T, float_type(error_both))
    xyerr = broadcast(xy, error_both) do (x, y), e
        Vec4{T_out}(x, y, e, e)
    end
    (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2, T}}, error_low::RealOrVec, error_high::RealOrVec) where T
    T_out = float_type(T, float_type(error_low, error_high))
    xyerr = broadcast(xy, error_low, error_high) do (x, y), el, eh
        Vec4{T_out}(x, y, el, eh)
    end
    (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2, T1}}, error_low_high::AbstractVector{<:VecTypes{2, T2}}) where {T1, T2}
    T_out = float_type(T1, T2)
    xyerr = broadcast(xy, error_low_high) do (x, y), (el, eh)
        Vec4{T_out}(x, y, el, eh)
    end
    (xyerr,)
end

function convert_arguments(::Type{<:Errorbars}, xy_error_both::AbstractVector{<:VecTypes{3, T}}) where T
    T_out = float_type(T)
    xyerr = broadcast(xy_error_both) do (x, y, e)
        Vec4{T_out}(x, y, e, e)
    end
    (xyerr,)
end

### conversions for rangebars

function convert_arguments(::Type{<:Rangebars}, val::RealOrVec, low::RealOrVec, high::RealOrVec)
    T = float_type(val, low, high)
    val_low_high = broadcast(Vec3{T}, val, low, high)
    return (val_low_high,)
end

function convert_arguments(::Type{<:Rangebars}, val::RealOrVec,
                           low_high::AbstractVector{<:VecTypes{2,T}}) where {T}
    T_out = float_type(float_type(val), T)
    T_out_ref = Ref{Type{T_out}}(T_out)  # for type-stable capture in the closure below
    val_low_high = broadcast(val, low_high) do val, (low, high)
        Vec3{T_out_ref[]}(val, low, high)
    end
    (val_low_high,)
end

Makie.convert_arguments(P::Type{<:Rangebars}, x::AbstractVector{<:Number}, y::AbstractVector{<:Interval}) =
    convert_arguments(P, x, endpoints.(y))

### the two plotting functions create linesegpairs in two different ways
### and then hit the same underlying implementation in `_plot_bars!`

function to_ydirection(dir)
    if dir === :y
        return true
    elseif dir === :x
        return false
    else
        error("Invalid direction $dir. Options are :x and :y.")
    end
end

function Makie.plot!(plot::Errorbars{<:Tuple{AbstractVector{<:Vec{4}}}})

    map!(to_ydirection, plot.attributes, [:direction], :is_in_y_direction)

    map!(plot.attributes, [:val_low_high, :is_in_y_direction], :linesegpairs) do x_y_low_high, in_y
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

    _plot_bars!(plot)
end


function Makie.plot!(plot::Rangebars{<:Tuple{AbstractVector{<:Vec{3}}}})

    map!(to_ydirection, plot.attributes, [:direction], :is_in_y_direction)

    map!(plot.attributes, [:val_low_high, :is_in_y_direction], :linesegpairs) do vlh, in_y
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
    _plot_bars!(plot)
end

reverse_if(cond, vec) = cond ? reverse(vec) : vec


function _plot_bars!(plot)
    attr = plot.attributes
    map!(attr, [:linewidth, :whiskerwidth, :is_in_y_direction], [:whisker_size, :whisker_visible]) do linewidth, whiskerwidth, dir
        isvisible = !(linewidth == 0 || whiskerwidth == 0)
        widths = reverse_if.(!dir, Vec2f.(whiskerwidth, linewidth))
        if widths isa Vec2f
            return widths, isvisible
        end
        [widths[i] for i in 1:length(widths) for j in 1:2], isvisible
    end

    map!(attr, [:color], :whiskercolors) do color
        # we have twice as many linesegments for whiskers as we have errorbars, so we
        # need to duplicate colors if a vector of colors is given
        if color isa AbstractVector
            return repeat(to_color(color), inner = 2)::RGBColors
        else
            return to_color(color)::RGBAf
        end
    end
    lattr = shared_attributes(plot, LineSegments)
    linesegments!(plot, lattr, attr.linesegpairs)
    sattr = shared_attributes(plot, Scatter)
    scatter!(
        plot, sattr, attr.linesegpairs; color=attr.whiskercolors,
        markersize = attr.whisker_size, marker=Rect, visible=attr.whisker_visible,
        markerspace=:pixel,
    )
    plot
end

function plot_to_screen(plot, points::AbstractVector)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) *
        f32_convert_matrix(plot, space) * transformationmatrix(plot)[]

    transfunc = transform_func(plot)
    return map(points) do p
        transformed = apply_transform(transfunc, p)
        p4d = spvm * to_ndim(Point4d, to_ndim(Point3d, transformed, 0), 1)
        return Point2f(p4d) / p4d[4]
    end
end

function plot_to_screen(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) *
        f32_convert_matrix(plot, space) * transformationmatrix(plot)[]
    transformed = apply_transform(transform_func(plot), p)
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
        return apply_transform(itf, p3)
    end
end

function screen_to_plot(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    mvps = inv(transformationmatrix(plot)[]) * inv_f32_convert_matrix(plot, space) *
        clip_to_space(cam, space) * space_to_clip(cam, :pixel)
    pre_transform = mvps * to_ndim(Vec4d, to_ndim(Vec3d, p, 0.0), 1.0)
    p3 = Point3d(pre_transform) / pre_transform[4]
    return apply_transform(itf, p3)
end

# ignore whiskers when determining data limits
data_limits(bars::Union{Errorbars, Rangebars}) = data_limits(bars.plots[1])
boundingbox(bars::Union{Errorbars, Rangebars}, space::Symbol = :data) = apply_transform_and_model(bars, data_limits(bars))
