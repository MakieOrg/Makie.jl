"""
    pie(values; kwargs...)
    pie(x, y, values; kwargs...)

Creates a pie chart from the given `values`.
"""
@recipe Pie (points,) begin
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
    "The offset of each pie segment from the center along the radius"
    offset_radius = 0
    MakieCore.mixin_generic_plot_attributes()...
end

conversion_trait(::Type{<:Pie}) = PointBased()
convert_arguments(::Type{<:Pie}, values::Vector) = (Point3d.(0, 0, getindex.(values, 1)),)
convert_arguments(::Type{<:Pie}, xs, ys, values::Vector) = begin
    xs = length(xs) == 1 ? fill(only(xs), length(values)) : xs
    ys = length(ys) == 1 ? fill(only(ys), length(values)) : ys
    return (Point3d.(xs, ys, values),)
end

function plot!(plot::Pie)
    values = plot[1]

    polys = lift(plot, values, plot.vertex_per_deg, plot.radius, plot.inner_radius, plot.offset_radius, plot.offset, plot.normalize) do vals, vertex_per_deg, radius, inner_radius, offset_radius, offset, normalize
        xs = getindex.(vals, 1)
        ys = getindex.(vals, 2)
        vals = getindex.(vals, 3)
        offset_radius = length(offset_radius) == 1 ? fill(only(offset_radius), length(vals)) : offset_radius

        T = eltype(vals)

        # find start and end angles of all pie pieces
        summed = cumsum([zero(T); vals])
        boundaries = if normalize
            summed ./ summed[end] .* 2pi
        else
            summed
        end

        # create vector of a vector of points for each piece
        vertex_arrays = map(boundaries[1:end-1], boundaries[2:end], xs, ys, offset_radius) do sta, en, x, y, r
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
