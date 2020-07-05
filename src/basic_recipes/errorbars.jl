@recipe(Errorbars) do scene
    Theme(
        whiskerwidth = 5,
        color = :black,
        linewidth = 1,
        direction = :y
    )
end


function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:Any, <:Any, <:Any, <:Any}

    xs, ys, low, high = plot[1:4]
    xys = lift((x, y) -> Point2.(x, y), xs, ys)
    _plot_errorbars!(plot, xys, low, high)
end

function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:Any, <:Any, <:Any}
    xys, low, high = plot[1:3]
    _plot_errorbars!(plot, xys, low, high)
end

function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{<:Any, <:Any}
    xys, lowhigh = plot[1:2]
    _plot_errorbars!(plot, xys, lowhigh, lowhigh)
end

f_if(condition, f, arg) = condition ? f(arg) : arg

function _plot_errorbars!(plot, xys, low, high)

    @extract plot (whiskerwidth, color, linewidth, direction)

    is_in_y_direction = lift(direction) do dir
        if dir == :y
            true
        elseif dir == :x
            false
        else
            error("Invalid direction $dir. Options are :x and :y.")
        end
    end

    linesegpairs = lift(xys, low, high, is_in_y_direction) do xys, low, high, is_in_y_direction

        [(xy .+ f_if(is_in_y_direction, reverse, Point2f0(-lo, 0)),
          xy .+ f_if(is_in_y_direction, reverse, Point2f0( hi, 0)),)
                for (xy, lo, hi) in zip(xys, low, high)]
    end

    scene = plot.parent

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

    linesegments!(plot, linesegpairs, color = color, linewidth = linewidth)
    linesegments!(plot, whiskers, color = color, linewidth = linewidth)
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
