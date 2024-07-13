"""
    pie(values; kwargs...)

Creates a pie chart from the given `values`.
"""
@recipe Pie (values,) begin
    "If `true`, the sum of all values is normalized to 2π (a full circle)."
    normalize = true
    color = :gray
    strokecolor = :black
    strokewidth = 1
    "Controls how many polygon vertices are used for one degree of rotation."
    vertex_per_deg = 1
    "The outer radius of the pie segments."
    radius = 1
    "The inner radius of the pie segments. If this is larger than zero, the pie pieces become ring sections."
    inner_radius = 0
    "The angular offset of the first pie segment from the (1, 0) vector in radians."
    offset = 0
    "Position of pie segments (x-value, scalar or `length(values)` vector)"
    x = 0
    "Position of pie segments (y-value, scalar or `length(values)` vector)"
    y = 0
    "Position of pie segments (r-value as polar coordinate, scalar or `length(values)` vector)"
    r = 0
    MakieCore.mixin_generic_plot_attributes()...
end

function plot!(plot::Pie)

    values = plot[1]

    polys = lift(plot, values, plot.vertex_per_deg, plot.radius, plot.inner_radius, plot.offset, plot.normalize, plot.x, plot.y, plot.r) do vals, vertex_per_deg, radius, inner_radius, offset, normalize, x, y, r
        xs = length(x) == 1 ? fill(only(x), length(vals)) : x
        ys = length(y) == 1 ? fill(only(y), length(vals)) : y
        rs = length(r) == 1 ? fill(only(r), length(vals)) : r

        T = eltype(vals)

        # find start and end angles of all pie pieces
        summed = cumsum([zero(T); vals])
        boundaries = if normalize
            summed ./ summed[end] .* 2pi
        else
            summed
        end

        # create vector of a vector of points for each piece
        vertex_arrays = map(boundaries[1:end-1], boundaries[2:end], xs, ys, rs) do sta, en, x, y, r
            x += cos((en + sta) / 2 + offset) * r
            y += sin((en + sta) / 2 + offset) * r
            distance = en - sta
            # how many vertices are needed for the curve?
            nvertices = max(2, ceil(Int, rad2deg(distance) * vertex_per_deg))

            # curve points
            points = map(LinRange(sta, en, nvertices)) do rad
                Point2f(cos(rad + offset) * radius + x, sin(rad + offset) * radius + y)
            end

            # add inner points (either curve or one point)
            if inner_radius != 0
                inner_points = map(LinRange(en, sta, nvertices)) do rad
                    Point2f(cos(rad + offset) * inner_radius + x, sin(rad + offset) * inner_radius + y)
                end
                append!(points, inner_points)
            else
                push!(points, Point2f(x, y))
            end

            points
        end
    end

    # plot pieces as polys
    poly!(
        plot, polys,
        color = plot.color, strokewidth = plot.strokewidth,
        strokecolor = plot.strokecolor, inspectable = plot.inspectable,
        visible = plot.visible, transparency = plot.transparency
    )

    plot
end
