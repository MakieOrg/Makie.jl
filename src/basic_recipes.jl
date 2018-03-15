
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




function plot!(scene::Scene, ::Type{Poly}, attributes::Attributes, positions::AbstractVector{<: VecTypes{2, T}}) where T <: AbstractFloat
    attributes, rest = merged_get!(:poly, scene, attributes) do
        Theme(;
            default_theme(scene)...,
            linecolor = RGBAf0(0,0,0,0),
            linewidth = 0.0,
            linestyle = nothing
        )
    end
    positions_n = to_node(positions)
    bigmesh = map(positions_n) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh!(scene, bigmesh, color = attributes[:color])
    outline = map(positions_n) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(scene, outline,
        color = attributes[:linecolor], linestyle = attributes[:linestyle],
        linewidth = attributes[:linewidth],
        visible = map(x-> x > 0.0, attributes[:linewidth])
    )
    return Poly(positions, attributes)
end
# function poly(scene::makie, points::AbstractVector{Point2f0}, attributes::Dict)
#     attributes[:positions] = points
#     _poly(scene, attributes)
# end
# function poly(scene::makie, x::AbstractVector{<: Number}, y::AbstractVector{<: Number}, attributes::Dict)
#     attributes[:x] = x
#     attributes[:y] = y
#     _poly(scene, attributes)
# end
function plot!(scene::Scene, ::Type{Poly}, attributes::Attributes, x::AbstractVector{T}) where T <: Union{Circle, Rectangle}
    position = map(to_node(x)) do rects
        map(rects) do rect
            minimum(rect) .+ (widths(rect) ./ 2f0)
        end
    end
    attributes[:markersize] = lift_node(to_node(x)) do rects
        widths.(rects)
    end
    attributes[:marker] = T
    plot!(scene, Scatter, attributes, position)
end
