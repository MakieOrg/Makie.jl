
@default function contour(backend, scene, kw_args)
    levels = to_float(levels)
    color = to_color(color)
    linewidth = to_float(1)
    fillrange = to_bool(fillrange)
end

function contour(b::makie, x, y, z, attributes)
    scene = get_global_scene()
    attributes = contour_defaults(b, scene, attributes)

    if to_value(attributes[:fillrange])
        return heatmap(b, x, y, z, attributes)
    else
        levels = round(Int, to_value(attributes[:levels]))
        T = eltype(z)

        contours = Contour.contours(T.(x), T.(y), z, levels)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        col = to_value(attributes[:color])
        cols = if isa(col, AbstractVector)
            if length(col) != levels
                error("Please have one color per level. Found: $(length(col)) colors and $levels level")
            end
            col
        else
            repeated(col, levels)
        end
        for (color, c) in zip(cols, Contour.levels(contours))
            for elem in Contour.lines(c)
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                append!(colors, fill(color, length(elem.vertices) + 1))
            end
        end
        attributes[:color] = colors
        return lines(b, result, attributes)
    end
end
