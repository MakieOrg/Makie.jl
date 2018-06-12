"""
    contour(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix
"""
@recipe(Contour) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end

@recipe(Contour3d) do scene
    Theme(;
        default_theme(scene)...,
        colormap = theme(scene, :colormap),
        colorrange = nothing,
        levels = 5,
        linewidth = 1.0,
        fillrange = false,
    )
end


"""
    contour3d(x, y, z)
Creates a contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z- elevation for each level
"""
function contourlines(::Type{Contour}, contours, cols)
    result = Point2f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, ContourLib.levels(contours))
        for elem in ContourLib.lines(c)
            append!(result, elem.vertices)
            push!(result, Point2f0(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end

function contourlines(::Type{Contour3d}, contours, cols)
    result = Point3f0[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, ContourLib.levels(contours))
        for elem in ContourLib.lines(c)
            for p in elem.vertices
                push!(result, Point3f0(p[1], p[2], c.level))
            end
            push!(result, Point3f0(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end


to_levels(x::AbstractVector{<: Number}, cnorm) = x
function to_levels(x::Integer, cnorm)
    linspace(cnorm..., x)
end

function plot!(plot::Contour{<: Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    replace_nothing!(()-> Signal(0.5), plot, :alpha)
    x, y, z, volume = plot[1:4]
    @extract plot (colormap, levels, linewidth, alpha)
    colorrange = replace_nothing!(plot, :colorrange) do
        map(x-> Vec2f0(extrema(x)), volume)
    end
    cmap = lift(colormap, levels, linewidth, alpha, colorrange) do _cmap, l, lw, alpha, cnorm
        levels = to_levels(l, cnorm)
        N = length(levels) * 50
        iso_eps = 0.1 # TODO calculate this
        cmap = to_colormap(_cmap)
        # resample colormap and make the empty area between iso surfaces transparent
        map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = AbstractPlotting.interpolated_getindex(cmap, i01)
            isoval = cnorm[1] + (i01 * (cnorm[2] - cnorm[1]))
            line = reduce(false, levels) do v0, level
                v0 || (abs(level - isoval) <= iso_eps)
            end
            RGBAf0(color(c), line ? alpha : 0.0)
        end
    end
    volume!(plot, x, y, z, volume, colormap = cmap, colorrange = colorrange, algorithm = :iso)
end

function plot!(plot::Contour)
    x, y, z = plot[1:3]
    if value(plot[:fillrange])
        plot[:interpolate] = true
        # TODO normalize linewidth for heatmap
        plot[:linewidth] = map(x-> x ./ 10f0, plot[:linewidth])
        heatmap!(plot, plot.attributes, x, y, z)
    else
        result = lift(x, y, z, plot[:levels]) do x, y, z, levels
            t = eltype(z)
            levels = round(Int, levels)
            contours = Main.Contour.contours(to_vector(x, size(z, 1), t), to_vector(y, size(z, 2), t), z, levels)
            cols = AbstractPlotting.resampled_colors(plot, levels)
            contourlines(Contour, contours, cols)
        end
        lines!(plot, lift(first, result); color = lift(last, result), raw = true)
    end
    plot
end

function AbstractPlotting.data_limits(x::Contour{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    AbstractPlotting._boundingbox(value.((x[1], x[2]))...)
end


@recipe(Poly) do scene
    Theme(
        linecolor = RGBAf0(0,0,0,0),
        linewidth = 0.0,
        linestyle = nothing
    )
end

 function plot!(plot::Poly{Tuple{P}}) where P <: AbstractVector
    bigmesh = map(positions) do p
        polys = GeometryTypes.split_intersections(p)
        merge(GLPlainMesh.(polys))
    end
    mesh!(plot, bigmesh, color = plot[:color])
    outline = map(positions) do p
        push!(copy(p), p[1]) # close path
    end
    lines!(
        plot, outline,
        color = plot[:linecolor], linestyle = plot[:linestyle],
        linewidth = plot[:linewidth],
    )
    return plot!(scene, plot, rest)
end

function plot!(plot::Poly{Tuple{<: AbstractVector{T}}}) where T <: Union{Circle, Rectangle}
    position = map(positions) do rects
        map(rects) do rect
            minimum(rect) .+ (widths(rect) ./ 2f0)
        end
    end
    attributes[:markersize] = map(positions, name = :markersize) do rects
        widths.(rects)
    end
    attributes[:marker] = T
    scatter!(plot, attributes, position)
    plot
end
