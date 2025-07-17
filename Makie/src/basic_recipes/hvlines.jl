"""
    hlines(ys; xmin = 0.0, xmax = 1.0, attrs...)

Create horizontal lines across a `Scene` with 2D projection.
The lines will be placed at `ys` in data coordinates and `xmin` to `xmax`
in scene coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
@recipe HLines begin
    "The start of the lines in relative axis units (0 to 1) along the x dimension."
    xmin = 0
    "The end of the lines in relative axis units (0 to 1) along the x dimension."
    xmax = 1
    documented_attributes(LineSegments)...
    cycle = [:color]
end

"""
    vlines(xs; ymin = 0.0, ymax = 1.0, attrs...)

Create vertical lines across a `Scene` with 2D projection.
The lines will be placed at `xs` in data coordinates and `ymin` to `ymax`
in scene coordinates (0 to 1). All three of these can have single or multiple values because
they are broadcast to calculate the final line segments.
"""
@recipe VLines begin
    "The start of the lines in relative axis units (0 to 1) along the y dimension."
    ymin = 0
    "The start of the lines in relative axis units (0 to 1) along the y dimension."
    ymax = 1
    documented_attributes(LineSegments)...
    cycle = [:color]
end

function projview_to_2d_limits(plot::AbstractPlot)
    scene = parent_scene(plot)
    return lift(
        plot, f32_conversion_obs(scene), scene.camera.projectionview, ignore_equal_values = true
    ) do f32c, pv
        xmin, xmax = minmax((((-1, 1) .- pv[1, 4]) ./ pv[1, 1])...)
        ymin, ymax = minmax((((-1, 1) .- pv[2, 4]) ./ pv[2, 2])...)
        origin = Vec2d(xmin, ymin)
        return inv_f32_convert(f32c, Rect2d(origin, Vec2d(xmax, ymax) - origin))
    end
end

function Makie.plot!(p::Union{HLines, VLines})
    mi = p isa HLines ? (:xmin) : (:ymin)
    ma = p isa HLines ? (:xmax) : (:ymax)
    add_axis_limits!(p)
    map!(p.attributes, [:axis_limits_transformed, :converted_1, mi, ma, :transform_func], :points) do lims, vals, mi, ma, transf
        points = Point2d[]
        min_x, min_y = minimum(lims)
        max_x, max_y = maximum(lims)
        broadcast_foreach(vals, mi, ma) do val, mi, ma
            if p isa HLines
                x_mi = min_x + (max_x - min_x) * mi
                x_ma = min_x + (max_x - min_x) * ma
                val = _apply_y_transform(transf, val)
                push!(points, Point2d(x_mi, val))
                push!(points, Point2d(x_ma, val))
            elseif p isa VLines
                y_mi = min_y + (max_y - min_y) * mi
                y_ma = min_y + (max_y - min_y) * ma
                val = _apply_x_transform(transf, val)
                push!(points, Point2d(val, y_mi))
                push!(points, Point2d(val, y_ma))
            end
        end
        return points
    end
    linesegments!(p, Attributes(p), p.points, transformation = :inherit_model)
    return p
end

function data_limits(p::HLines)
    ymin, ymax = extrema(p[1][])
    return Rect3d(Point3d(NaN, ymin, 0), Vec3d(NaN, ymax - ymin, 0))
end

function data_limits(p::VLines)
    xmin, xmax = extrema(p[1][])
    return Rect3d(Point3d(xmin, NaN, 0), Vec3d(xmax - xmin, NaN, 0))
end

boundingbox(p::Union{HLines, VLines}, space::Symbol = :data) = apply_transform_and_model(p, data_limits(p))
