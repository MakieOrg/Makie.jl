
"""
    contour(x, y, z)
    contour(z::Matrix)

Creates a contour plot of the plane spanning `x::Vector`, `y::Vector`, `z::Matrix`.
If only `z::Matrix` is supplied, the indices of the elements in `z` will be used as the `x` and `y` locations when plotting the contour.

The attribute levels can be either

    an Int that produces n equally wide levels or bands

    an AbstractVector{<:Real} that lists n consecutive edges from low to high, which result in n-1 levels or bands

## Attributes
$(ATTRIBUTES)
"""
@recipe(Contour) do scene
    default = default_theme(scene)
    # pop!(default, :color)
    Attributes(;
        default...,
        color = nothing,
        colormap = theme(scene, :colormap),
        colorrange = Makie.automatic,
        levels = 5,
        linewidth = 1.0,
        linestyle = nothing,
        alpha = 1.0,
        enable_depth = true,
        transparency = false
    )
end

"""
    contour3d(x, y, z)

Creates a 3D contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z-elevation for each level.

## Attributes
$(ATTRIBUTES)
"""
@recipe(Contour3d) do scene
    default_theme(scene, Contour)
end

is_plot_3d(::Type{<: Contour3d}) = true

function contourlines(::Type{<: Contour}, contours, cols)
    result = Point2f[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            append!(result, elem.vertices)
            push!(result, Point2f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end

function contourlines(::Type{<: Contour3d}, contours, cols)
    result = Point3f[]
    colors = RGBA{Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            for p in elem.vertices
                push!(result, Point3f(p[1], p[2], c.level))
            end
            push!(result, Point3f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
        end
    end
    result, colors
end

to_levels(x::AbstractVector{<: Number}, cnorm) = x

function to_levels(n::Integer, cnorm)
    zmin, zmax = cnorm
    dz = (zmax - zmin) / (n + 1)
    range(zmin + dz; step = dz, length = n)
end

conversion_trait(::Type{<: Contour3d}) = ContinuousSurface()
conversion_trait(::Type{<: Contour}) = ContinuousSurface()
conversion_trait(::Type{<: Contour{<: Tuple{X, Y, Z, Vol}}}) where {X, Y, Z, Vol} = VolumeLike()
conversion_trait(::Type{<: Contour{<: Tuple{<: AbstractArray{T, 3}}}}) where T = VolumeLike()

function plot!(plot::Contour{<: Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    x, y, z, volume = plot[1:4]
    @extract plot (colormap, levels, linewidth, alpha)
    valuerange = lift(x->Vec2f(nan_extrema(x)), volume)
    cliprange = replace_automatic!(plot, :colorrange) do
        valuerange
    end
    cmap = lift(colormap, levels, alpha, cliprange, valuerange) do _cmap, l, alpha, cliprange, vrange
        levels = to_levels(l, vrange)
        nlevels = length(levels)
        N = 50 * nlevels

        iso_eps = if haskey(plot, :isorange)
            plot.isorange[]
        else
            nlevels * ((vrange[2] - vrange[1]) / N) # TODO calculate this
        end
        cmap = to_colormap(_cmap)
        v_interval = cliprange[1] .. cliprange[2]
        # resample colormap and make the empty area between iso surfaces transparent
        return map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = Makie.interpolated_getindex(cmap, i01)
            isoval = vrange[1] + (i01 * (vrange[2] - vrange[1]))
            line = reduce(levels, init = false) do v0, level
                (isoval in v_interval) || return false
                v0 || (abs(level - isoval) <= iso_eps)
            end
            return RGBAf(Colors.color(c), line ? alpha : 0.0)
        end
    end

    attr = Attributes(plot)
    attr[:colorrange] = cliprange
    attr[:colormap] = cmap
    attr[:algorithm] = 7
    pop!(attr, :levels)
    volume!(plot, attr, x, y, z, volume)
end

function color_per_level(color, colormap, colorrange, alpha, levels)
    color_per_level(to_color(color), colormap, colorrange, alpha, levels)
end

function color_per_level(color::Colorant, colormap, colorrange, alpha, levels)
    fill(color, length(levels))
end

function color_per_level(colors::AbstractVector, colormap, colorrange, alpha, levels)
    color_per_level(to_colormap(colors), colormap, colorrange, alpha, levels)
end

function color_per_level(colors::AbstractVector{<: Colorant}, colormap, colorrange, alpha, levels)
    if length(levels) == length(colors)
        return colors
    else
        # TODO resample?!
        error("For a contour plot, `color` with an array of colors needs to
        have the same length as `levels`.
        Found $(length(colors)) colors, but $(length(levels)) levels")
    end
end

function color_per_level(::Nothing, colormap, colorrange, a, levels)
    cmap = to_colormap(colormap)
    map(levels) do level
        c = interpolated_getindex(cmap, level, colorrange)
        RGBAf(color(c), alpha(c) * a)
    end
end

function plot!(plot::T) where T <: Union{Contour, Contour3d}
    x, y, z = plot[1:3]
    zrange = lift(nan_extrema, z)
    levels = lift(plot.levels, zrange) do levels, zrange
        if levels isa AbstractVector{<: Number}
            return levels
        elseif levels isa Integer
            to_levels(levels, zrange)
        else
            error("Level needs to be Vector of iso values, or a single integer to for a number of automatic levels")
        end
    end

    replace_automatic!(()-> zrange, plot, :colorrange)

    args = @extract plot (color, colormap, colorrange, alpha)
    level_colors = lift(color_per_level, args..., levels)
    result = lift(x, y, z, levels, level_colors) do x, y, z, levels, level_colors
        t = eltype(z)
        # Compute contours
        xv, yv = to_vector(x, size(z,1), t), to_vector(y, size(z,2), t)
        contours = Contours.contours(xv, yv, z,  convert(Vector{eltype(z)}, levels))
        contourlines(T, contours, level_colors)
    end
    lines!(
        plot, lift(first, result);
        color = lift(last, result),
        linewidth = plot.linewidth,
        inspectable = plot.inspectable,
        transparency = plot.transparency,
        linestyle = plot.linestyle
    )
    plot
end

function point_iterator(x::Contour{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    axes = (x[1], x[2])
    extremata = map(extrema∘to_value, axes)
    minpoint = Point2f(first.(extremata)...)
    widths = last.(extremata) .- first.(extremata)
    rect = Rect2f(minpoint, Vec2f(widths))
    return unique(decompose(Point, rect))
end
