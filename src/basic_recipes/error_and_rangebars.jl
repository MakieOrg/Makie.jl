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

## Attributes
$(ATTRIBUTES)
"""
@recipe(Errorbars) do scene
    Theme(
        whiskerwidth = 0,
        color = theme(scene, :linecolor),
        linewidth = theme(scene, :linewidth),
        direction = :y,
        visible = theme(scene, :visible),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        inspectable = theme(scene, :inspectable),
        transparency = false
    )
end


"""
    rangebars(val, low, high; kwargs...)
    rangebars(val, low_high; kwargs...)
    rangebars(val_low_high; kwargs...)

Plots rangebars at `val` in one dimension, extending from `low` to `high` in the other dimension
given the chosen `direction`.

If you want to plot errors relative to a reference value, use `errorbars`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Rangebars) do scene
    Theme(
        whiskerwidth = 0,
        color = theme(scene, :linecolor),
        linewidth = theme(scene, :linewidth),
        direction = :y,
        visible = theme(scene, :visible),
        colormap = theme(scene, :colormap),
        colorrange = automatic,
        inspectable = theme(scene, :inspectable),
        transparency = false
    )
end

### conversions for errorbars

function Makie.convert_arguments(::Type{<:Errorbars}, x, y, error_both)
    xyerr = broadcast(x, y, error_both) do x, y, e
        Vec4f(x, y, e, e)
    end
    (xyerr,)
end

function Makie.convert_arguments(::Type{<:Errorbars}, x, y, error_low, error_high)
    xyerr = broadcast(Vec4f, x, y, error_low, error_high)
    (xyerr,)
end


function Makie.convert_arguments(::Type{<:Errorbars}, x, y, error_low_high::AbstractVector{<:VecTypes{2}})
    xyerr = broadcast(x, y, error_low_high) do x, y, (el, eh)
        Vec4f(x, y, el, eh)
    end
    (xyerr,)
end

function Makie.convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2}}, error_both)
    xyerr = broadcast(xy, error_both) do (x, y), e
        Vec4f(x, y, e, e)
    end
    (xyerr,)
end

function Makie.convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2}}, error_low, error_high)
    xyerr = broadcast(xy, error_low, error_high) do (x, y), el, eh
        Vec4f(x, y, el, eh)
    end
    (xyerr,)
end

function Makie.convert_arguments(::Type{<:Errorbars}, xy::AbstractVector{<:VecTypes{2}}, error_low_high::AbstractVector{<:VecTypes{2}})
    xyerr = broadcast(xy, error_low_high) do (x, y), (el, eh)
        Vec4f(x, y, el, eh)
    end
    (xyerr,)
end

function Makie.convert_arguments(::Type{<:Errorbars}, xy_error_both::AbstractVector{<:VecTypes{3}})
    xyerr = broadcast(xy_error_both) do (x, y, e)
        Vec4f(x, y, e, e)
    end
    (xyerr,)
end

### conversions for rangebars

function Makie.convert_arguments(::Type{<:Rangebars}, val, low, high)
    val_low_high = broadcast(Vec3f, val, low, high)
    (val_low_high,)
end

function Makie.convert_arguments(::Type{<:Rangebars}, val, low_high)
    val_low_high = broadcast(val, low_high) do val, (low, high)
        Vec3f(val, low, high)
    end
    (val_low_high,)
end

### the two plotting functions create linesegpairs in two different ways
### and then hit the same underlying implementation in `_plot_bars!`

function Makie.plot!(plot::Errorbars{T}) where T <: Tuple{AbstractVector{<:VecTypes{4}}}

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
        return map(x_y_low_high) do (x, y, l, h)
            in_y ?
                (Point2f(x, y - l), Point2f(x, y + h)) :
                (Point2f(x - l, y), Point2f(x + h, y))
        end
    end

    _plot_bars!(plot, linesegpairs, is_in_y_direction)
end


function Makie.plot!(plot::Rangebars{T}) where T <: Tuple{AbstractVector{<:VecTypes{3}}}

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
        return map(vlh) do (v, l, h)
            in_y ?
                (Point2f(v, l), Point2f(v, h)) :
                (Point2f(l, v), Point2f(h, v))
        end
    end

    _plot_bars!(plot, linesegpairs, is_in_y_direction)
end



function _plot_bars!(plot, linesegpairs, is_in_y_direction)

    f_if(condition, f, arg) = condition ? f(arg) : arg

    @extract plot (whiskerwidth, color, linewidth, visible, colormap, colorrange, inspectable, transparency)

    scene = parent_scene(plot)

    whiskers = lift(plot, linesegpairs, scene.camera.projectionview,
        scene.camera.pixel_space, whiskerwidth) do pairs, _, _, whiskerwidth

        endpoints = [p for pair in pairs for p in pair]

        screenendpoints = plot_to_screen(plot, endpoints)
        @info screenendpoints

        screenendpoints_shifted_pairs = map(screenendpoints) do sep
            (sep .+ f_if(is_in_y_direction[], reverse, Point(0, -whiskerwidth/2)),
             sep .+ f_if(is_in_y_direction[], reverse, Point(0,  whiskerwidth/2)))
        end

        return [p for pair in screenendpoints_shifted_pairs for p in pair]
    end
    whiskercolors = Observable{RGBColors}()
    map!(plot, whiskercolors, color) do color
        # we have twice as many linesegments for whiskers as we have errorbars, so we
        # need to duplicate colors if a vector of colors is given
        if color isa AbstractVector
            return repeat(to_color(color), inner = 2)::RGBColors
        else
            return to_color(color)::RGBAf
        end
    end
    whiskerlinewidths = Observable{Union{Float32, Vector{Float32}}}()
    map!(plot, whiskerlinewidths, linewidth) do linewidth
        # same for linewidth
        if linewidth isa AbstractVector
            return repeat(convert(Vector{Float32}, linewidth), inner = 2)::Vector{Float32}
        else
            return convert(Float32, linewidth)
        end
    end

    linesegments!(
        plot, linesegpairs, color = color, linewidth = linewidth, visible = visible,
        colormap = colormap, colorrange = colorrange, inspectable = inspectable,
        transparency = transparency
    )
    linesegments!(
        plot, whiskers, color = whiskercolors, linewidth = whiskerlinewidths,
        visible = visible, colormap = colormap, colorrange = colorrange,
        inspectable = inspectable, transparency = transparency, space = :pixel
    )
    plot
end

function plot_to_screen(plot, points::AbstractVector)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) * transformationmatrix(plot)[]

    return map(points) do p
        transformed = apply_transform(transform_func(plot), p, space)
        p4d = spvm * to_ndim(Point4f, to_ndim(Point3f, transformed, 0), 1)
        return Point2f(p4d) / p4d[4]
    end
end

function plot_to_screen(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    spvm = clip_to_space(cam, :pixel) * space_to_clip(cam, space) * transformationmatrix(plot)[]
    transformed = apply_transform(transform_func(plot), p, space)
    p4d = spvm * to_ndim(Point4f, to_ndim(Point3f, transformed, 0), 1)
    return Point2f(p4d) / p4d[4]
end

function screen_to_plot(plot, points::AbstractVector)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    mvps = inv(transformationmatrix(plot)[]) * clip_to_space(cam, space) * space_to_clip(cam, :pixel)
    itf = inverse_transform(transform_func(plot))

    return map(points) do p
        pre_transform = mvps * to_ndim(Vec4f, to_ndim(Vec3f, p, 0.0), 1.0)
        p3 = Point3f(pre_transform) / pre_transform[4]
        return apply_transform(itf, p3, space)
    end
end

function screen_to_plot(plot, p::VecTypes)
    cam = parent_scene(plot).camera
    space = to_value(get(plot, :space, :data))
    mvps = inv(transformationmatrix(plot)[]) * clip_to_space(cam, space) * space_to_clip(cam, :pixel)
    pre_transform = mvps * to_ndim(Vec4f, to_ndim(Vec3f, p, 0.0), 1.0)
    p3 = Point3f(pre_transform) / pre_transform[4]
    return apply_transform(itf, p3, space)
end

# ignore whiskers when determining data limits
function data_limits(bars::Union{Errorbars, Rangebars})
    data_limits(bars.plots[1])
end
