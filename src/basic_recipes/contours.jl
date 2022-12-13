
"""
    contour(x, y, z)
    contour(z::Matrix)

Creates a contour plot of the plane spanning `x::Vector`, `y::Vector`, `z::Matrix`.
If only `z::Matrix` is supplied, the indices of the elements in `z` will be used as the `x` and `y` locations when plotting the contour.

The attribute levels can be either

    an Int that produces n equally wide levels or bands

    an AbstractVector{<:Real} that lists n consecutive edges from low to high, which result in n-1 levels or bands

To add contour labels, use `labels = true`, and pass additional text attributes via the `label_attributes` namedtuple.

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
        transparency = false,
        labels = false,
        label_attributes = (;),
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

nice_label(x) = string(isinteger(x) ? round(Int, x) : x)

angle(p1, p2) = mod(atan(p2[2] - p1[2], p2[1] - p1[1]), -π)

function contourlines(::Type{<: Contour}, contours, cols, labels)
    result = Point2f[]
    colors = RGBA{Float32}[]
    str_pos_ang = Tuple{String,Point2f,Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            append!(result, elem.vertices)
            push!(result, Point2f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
            labels && let p1 = elem.vertices[1], p2 = elem.vertices[2]
                push!(str_pos_ang, (nice_label(c.level), p1, angle(p1, p2)))
            end
        end
    end
    result, colors, str_pos_ang
end

function contourlines(::Type{<: Contour3d}, contours, cols, labels)
    result = Point3f[]
    colors = RGBA{Float32}[]
    str_pos_ang = Tuple{String,Point3f,Float32}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            for p in elem.vertices
                push!(result, Point3f(p[1], p[2], c.level))
            end
            push!(result, Point3f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
            labels && let p1 = elem.vertices[1], p2 = elem.vertices[2]
                push!(str_pos_ang, (nice_label(c.level), Point3f(p1[1], p1[2], c.level), angle(p1, p2)))
            end
        end
    end
    result, colors, str_pos_ang
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
    valuerange = lift(nan_extrema, volume)
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

    labels, label_attributes, args... = @extract plot (labels, label_attributes, color, colormap, colorrange, alpha)
    level_colors = lift(color_per_level, args..., levels)
    result = lift(x, y, z, levels, level_colors, labels) do x, y, z, levels, level_colors, labels
        t = eltype(z)
        # Compute contours
        xv, yv = to_vector(x, size(z,1), t), to_vector(y, size(z,2), t)
        contours = Contours.contours(xv, yv, z,  convert(Vector{eltype(z)}, levels))
        contourlines(T, contours, level_colors, labels)
    end

    masked_lines = lift(labels, label_attributes, color, result) do labels, label_attributes, color, (segments, _, str_pos_ang)
        labels || return segments  # `labels = false`, early return
        P = eltype(segments)
        masked = sizehint!(P[], length(segments))
        sc = parent_scene(plot)
        transf, space = transform_func_obs(sc), get(plot, :space, :data)
        nseg, nlab = length(segments), length(str_pos_ang)
        # FIXME: it doesn't seem to be possible to access the child
        # glyphcollections after using `text!(plot, labels; kw...)`
        texts = map(x -> text!(plot, [x[1:2]]; rotation = x[3], align = (:center, :center), color = color, label_attributes...), str_pos_ang)
        bboxes = map(Rect2f ∘ boundingbox, texts)
        bb, n = nothing, 0
        for (i, p_curr) in enumerate(segments)
            p_prev = segments[i > 1 ? i - 1 : i]
            p_next = segments[i < nseg ? i + 1 : i]
            if (i == 1 || isnan(p_next)) && n < nlab
                bb = bboxes[n += 1]  # consider the next label
            end
            if bb !== nothing && (
                scene_to_screen(apply_transform(transf, p_prev, space), sc) in bb || 
                scene_to_screen(apply_transform(transf, p_curr, space), sc) in bb ||
                scene_to_screen(apply_transform(transf, p_next, space), sc) in bb
            )
                push!(masked, P(NaN32))
            else
                push!(masked, p_curr)
            end
        end
        masked
    end

    lines!(
        plot, masked_lines;
        color = lift(x -> x[2], result),
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
