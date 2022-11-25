"""
    hlines(ys; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal lines across a `Scene` with 2D projection.
The lines will be placed at `ys` in data coordinates and `xmin` to `xmax`
in scene coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.

All style attributes are the same as for `LineSegments`.
"""
@recipe(HLines) do scene
    Theme(;
        xautolimits = false,
        xmin = 0,
        xmax = 1,
        default_theme(scene, LineSegments)...,
        cycle = :color,
    )
end

"""
    vlines(xs; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical lines across a `Scene` with 2D projection.
The lines will be placed at `xs` in data coordinates and `ymin` to `ymax`
in scene coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.

All style attributes are the same as for `LineSegments`.
"""
@recipe(VLines) do scene
    Theme(;
        yautolimits = false,
        ymin = 0,
        ymax = 1,
        default_theme(LineSegments, scene)...,
        cycle = :color,
    )
end

function projview_to_2d_limits(pv)
    xmin, xmax = minmax((((-1, 1) .- pv[1, 4]) ./ pv[1, 1])...)
    ymin, ymax = minmax((((-1, 1) .- pv[2, 4]) ./ pv[2, 2])...)
    origin = Vec2f(xmin, ymin)
    return Rect2f(origin, Vec2f(xmax, ymax) - origin)
end

function Makie.plot!(p::Union{HLines, VLines})
    scene = parent_scene(p)
    transf = transform_func_obs(scene)

    limits = lift(projview_to_2d_limits, scene.camera.projectionview)

    points = Observable(Point2f[])

    mi = p isa HLines ? p.xmin : p.ymin
    ma = p isa HLines ? p.xmax : p.ymax

    onany(limits, p[1], mi, ma, transf) do lims, vals, mi, ma, transf
        inv = inverse_transform(transf)
        empty!(points[])
        min_x, min_y = minimum(lims)
        max_x, max_y = maximum(lims)
        broadcast_foreach(vals, mi, ma) do val, mi, ma
            if p isa HLines
                x_mi = min_x + (max_x - min_x) * mi
                x_ma = min_x + (max_x - min_x) * ma
                x_mi = _apply_x_transform(inv, x_mi)
                x_ma = _apply_x_transform(inv, x_ma)
                push!(points[], Point2f(x_mi, val))
                push!(points[], Point2f(x_ma, val))
            elseif p isa VLines
                y_mi = min_y + (max_y - min_y) * mi
                y_ma = min_y + (max_y - min_y) * ma
                y_mi = _apply_y_transform(inv, y_mi)
                y_ma = _apply_y_transform(inv, y_ma)
                push!(points[], Point2f(val, y_mi))
                push!(points[], Point2f(val, y_ma))
            end
        end
        notify(points)
    end

    notify(p[1])

    line_attributes = extract_keys(p.attributes, [
        :linewidth,
        :color,
        :colormap,
        :colorrange,
        :linestyle,
        :fxaa,
        :cycle,
        :transparency,
        :inspectable])

    linesegments!(p, line_attributes, points)
    p
end
