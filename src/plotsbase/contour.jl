

@default function contour(backend, scene, kw_args)
    levels = to_int(levels)
    color = to_color(color)
    linewidth = to_float(1)
    fillrange = to_bool(fillrange)
end

function contour(b::makie, x, y, z, attributes)
    contour_defaults(b, default_scene(), attributes)
    if attributes[:fillrange]
        delete!(kw_args, :intensity)
        I = GLVisualize.Intensity{Float32}
        main = [I(z[j,i]) for i=1:size(z, 2), j=1:size(z, 1)]
        return visualize(main, Style(:default), kw_args)
    else
        levels = kw_args[:levels]
        T = eltype(z)
        contours = Contour.contours(T.(x), T.(y), z, h)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        col = attributes[:color]
        cols = if isa(col, AbstractVector)
            if length(col) != levels
                error("Please have one color per level. Found: $(length(col)) colors and $levels level")
            end
            col
        else
            repeated(col, levels)
        end
        for (color, c) in zip(cols, contours.contours)
            for elem in c.lines
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                append!(colors, fill(color, length(elem.vertices) + 1))
            end
        end
        attributes[:color] = colors
        return lines(b, result, attributes)
    end
end
