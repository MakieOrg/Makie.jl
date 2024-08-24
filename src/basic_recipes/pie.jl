"""
    pie(values; kwargs...)
    pie(point, values; kwargs...)
    pie(x, y, values; kwargs...)

Creates a pie chart from the given `values`.
"""
@recipe Pie (xs, ys, values) begin
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

convert_arguments(PT::Type{<:Pie}, values::RealVector) = convert_arguments(PT, 0.0, 0.0, values)
convert_arguments(PT::Type{<:Pie}, point::VecTypes{2}, values::RealVector) = convert_arguments(PT, point[1], point[2], values)
convert_arguments(PT::Type{<:Pie}, ps::AbstractVector{<:VecTypes{2}}, values::RealVector) = convert_arguments(PT, getindex.(ps, 1), getindex.(ps, 2), values)

function convert_arguments(::Type{<:Pie}, xs::Union{Real,RealVector}, ys::Union{Real,RealVector}, values::RealVector)
    xs = length(xs) == 1 ? fill(only(xs), length(values)) : xs
    ys = length(ys) == 1 ? fill(only(ys), length(values)) : ys
    return (float_convert(xs), float_convert(ys), float_convert(values))
end

function plot!(plot::Pie)
    xs = plot[1]
    ys = plot[2]
    values = plot[3]

    polys = lift(plot, xs, ys, values, plot.vertex_per_deg, plot.radius, plot.inner_radius, plot.offset_radius, plot.offset, plot.normalize) do xs, ys, vals, vertex_per_deg, radius, inner_radius, offset_radius, offset, normalize
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
                Point2(cos(rad + offset) * radius + x, sin(rad + offset) * radius + y)
            end

            # add inner points (either curve or one point)
            if inner_radius != 0
                inner_points = map(LinRange(en, sta, nvertices)) do rad
                    Point2(cos(rad + offset) * inner_radius + x, sin(rad + offset) * inner_radius + y)
                end
                append!(points, inner_points)
            else
                push!(points, Point2(x, y))
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
