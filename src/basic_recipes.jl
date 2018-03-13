
function default_theme(scene, ::Type{Contour})
    Theme(;
        default_theme(scene)...,
        colormap = scene.theme[:colormap],
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end

to_vector(x::AbstractVector, len, T) = convert(Vector{T}, x)
to_vector(x::ClosedInterval, len, T) = linspace(T.(extrema(x))..., len)

function resample(x::AbstractVector, len)
    length(x) == len && return x
    interpolated_getindex.((x,), linspace(0.0, 1.0, len))
end

function plot!(scene::Scene, ::Type{Contour}, attributes::Attributes, args...)
    attributes, rest = merged_get!(:contour, scene, attributes) do
        default_theme(scene, Contour)
    end
    calculate_values!(Contour, attributes, args)
    T = eltype(last(args))
    x, y, z = convert_arguments(Contour, args...)
    if value(attributes[:fillrange])
        attributes[:interpolate] = true
        return heatmap!(scene, attributes, x, y, z)
    else
        levels = round(Int, value(attributes[:levels]))
        T = eltype(z)
        contours = Main.Contour.contours(to_vector(x, size(z, 1), T), to_vector(y, size(z, 2), T), z, levels)
        result = Point2f0[]
        colors = RGBA{Float32}[]
        cols = if haskey(attributes, :color)
            c = attribute_convert(value(attributes[:color]), key"color"())
            repeated(c, levels)
        else
            c = attribute_convert(value(attributes[:colormap]), key"colormap"())
            resample(c, levels)
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
