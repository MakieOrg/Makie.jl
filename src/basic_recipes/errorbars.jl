"""
    errorbars(xs, low, high; kwargs...)

Plots errorbars at the given x coordinates, extending down by `low` and up by `high`.
The direction of the bars can be changed to horizontal by setting the `direction` attribute
to `:x`.

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



function AbstractPlotting.plot!(plot::Errorbars{T}) where T <: Tuple{Any, Any, Any}

    f_if(condition, f, arg) = condition ? f(arg) : arg

    xs, low, high = plot[1:3]
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

    linesegpairs = lift(xs, low, high, is_in_y_direction) do x, l, h, in_y

        broadcast(x, l, h) do xx, ll, hh
            in_y ?
                (Point2f0(xx, ll), Point2f0(xx, hh)) :
                (Point2f0(ll, xx), Point2f0(hh, xx))
        end
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

    whiskercolors = lift(color, typ = Any) do color
        # we have twice as many linesegments for whiskers as we have errorbars, so we
        # need to duplicate colors if a vector of colors is given
        if color isa AbstractVector
            repeat(color, inner = 2)
        else
            color
        end
    end

    whiskerlinewidths = lift(linewidth, typ = Any) do linewidth
        # same for linewidth
        if linewidth isa AbstractVector
            repeat(linewidth, inner = 2)
        else
            linewidth
        end
    end

    linesegments!(plot, linesegpairs, color = color, linewidth = linewidth, visible = visible)
    linesegments!(plot, whiskers, color = whiskercolors, linewidth = whiskerlinewidths, visible = visible)
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
