
function default_theme(scene, ::Type{Contour})
    Theme(;
        default_theme(scene)...,
        color = scene.theme[:color],
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end

function plot!(scene::Scene, ::Type{Contour}, attributes::Attributes, args...)
    attributes, rest = merged_get!(:contour, scene, attributes) do
        default_theme(scene, Contour)
    end
    calculate_values!(Contour, attributes, args)
    T = eltype(last(args))
    x, y, z = convert_arguments(Contour, args...)
    if value(attributes[:fillrange])
        return heatmap!(scene, attributes, x, y, z)
    else
        levels = round(Int, value(attributes[:levels]))
        T = eltype(z)
        contours = Main.Contour.contours(T.(x), T.(y), z, levels)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        col = attribute_convert(value(attributes[:color]), key"color"())
        cols = if isa(col, AbstractVector)
            if length(col) != levels
                error("Please have one color per level. Found: $(length(col)) colors and $levels level")
            end
            col
        else
            repeated(col, levels)
        end
        for (color, c) in zip(cols, Main.Contour.levels(contours))
            for elem in Main.Contour.lines(c)
                append!(result, elem.vertices)
                push!(result, Point2f0(NaN32))
                append!(colors, fill(color, length(elem.vertices) + 1))
            end
        end
        attributes[:color] = colors
        return lines!(scene, attributes, result)
    end
end
