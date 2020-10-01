"""
    errorbars(xs, ys, low, high; kwargs...)
    errorbars(points, low, high; kwargs...)
    errorbars(points, lowhigh; kwargs...)

Plots errorbars at the given points, extending down (left) by `low` and up 
(right) by `high`.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Errorbars) do scene
    Theme(
        whiskerwidth = 10,
        color = :black,
        linewidth = 1,
        direction = :y,
        visible = theme(scene, :visible)
    )
end


function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:AbstractVector{<:Real}, <:AbstractVector{<:Real}, <:AbstractVector{<:Real}, <:AbstractVector{<:Real}}

    xs, ys, low, high = plot[1:4]
    lowhigh = @lift(Point2f0.($low, $high))
    xys = lift((x, y) -> Point2f0.(x, y), xs, ys)
    _plot_errorbars!(plot, xys, lowhigh)
end

function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:AbstractVector{<:Point2}, <:AbstractVector{<:Real}, <:AbstractVector{<:Real}}
    xys, low, high = plot[1:3]
    lowhigh = @lift(Point2f0.($low, $high))
    _plot_errorbars!(plot, xys, lowhigh)
end

function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:AbstractVector{<:Point2}, <:AbstractVector{<:Real}}
    xys, same_lowhigh = plot[1:2]
    lowhigh = @lift(Point2f0.($same_lowhigh, $same_lowhigh))
    _plot_errorbars!(plot, xys, lowhigh)
end

f_if(condition, f, arg) = condition ? f(arg) : arg

function _plot_errorbars!(plot, xys, lowhigh)

    @extract plot (whiskerwidth, color, linewidth, direction, visible)

    is_in_y_direction = lift(direction) do dir
        if dir == :y
            true
        elseif dir == :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    linesegpairs = lift(xys, lowhigh, is_in_y_direction) do xys, lowhigh, is_in_y_direction

        [(xy .+ f_if(is_in_y_direction, reverse, Point2f0(-lohi[1], 0)),
          xy .+ f_if(is_in_y_direction, reverse, Point2f0( lohi[2], 0)),)
                for (xy, lohi) in zip(xys, lowhigh)]
    end

    scene = parent_scene(plot)

    whiskers = lift(linesegpairs, scene.camera.projectionview,
        scene.camera.pixel_space, whiskerwidth) do pairs, _, _, whiskerwidth

        endpoints = [p for pair in pairs for p in pair]

        screenendpoints = scene_to_screen(endpoints, scene)

        screenendpoints_shifted_pairs = map(screenendpoints) do sep
            (sep .+ f_if(is_in_y_direction[], reverse, Point(0, -whiskerwidth/2)),
             sep .+ f_if(is_in_y_direction[], reverse, Point(0,  whiskerwidth/2)))
        end

        screen_to_scene([p for pair in screenendpoints_shifted_pairs for p in pair], scene)
    end

    linesegments!(plot, linesegpairs, color = color, linewidth = linewidth, visible = visible)
    linesegments!(plot, whiskers, color = color, linewidth = linewidth, visible = visible)
    plot
end

function scene_to_screen(pts, scene)
    p4 = to_ndim.(Vec4f0, to_ndim.(Vec3f0, pts, 0.0), 1.0)
    p1m1 = Ref(scene.camera.projectionview[]) .* p4
    projected = Ref(inv(scene.camera.pixel_space[])) .* p1m1
    [Point2.(p[1:2]...) for p in projected]
end

function screen_to_scene(pts, scene)
    p4 = to_ndim.(Vec4f0, to_ndim.(Vec3f0, pts, 0.0), 1.0)
    p1m1 = Ref(scene.camera.pixel_space[]) .* p4
    projected = Ref(inv(scene.camera.projectionview[])) .* p1m1
    [Point2.(p[1:2]...) for p in projected]
end

function scene_to_screen(p::T, scene) where T <: Point
    p4 = to_ndim(Vec4f0, to_ndim(Vec3f0, p, 0.0), 1.0)
    p1m1 = scene.camera.projectionview[] * p4
    projected = inv(scene.camera.pixel_space[]) * p1m1
    T(projected[1:2]...)
end

function screen_to_scene(p::T, scene) where T <: Point
    p4 = to_ndim(Vec4f0, to_ndim(Vec3f0, p, 0.0), 1.0)
    p1m1 = scene.camera.pixel_space[] * p4
    projected = inv(scene.camera.projectionview[]) * p1m1
    T(projected[1:2]...)
end
