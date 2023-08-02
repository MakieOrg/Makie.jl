function contour_label_formatter(level::Real)::String
    lev_short = round(level; digits = 2)
    string(isinteger(lev_short) ? round(Int, lev_short) : lev_short)
end

"""
    contour(x, y, z)
    contour(z::Matrix)

Creates a contour plot of the plane spanning `x::Vector`, `y::Vector`, `z::Matrix`.
If only `z::Matrix` is supplied, the indices of the elements in `z` will be used as the `x` and `y` locations when plotting the contour.

The attribute levels can be either

    an Int that produces n equally wide levels or bands

    an AbstractVector{<:Real} that lists n consecutive edges from low to high, which result in n-1 levels or bands

To add contour labels, use `labels = true`, and pass additional label attributes such as `labelcolor`, `labelsize`, `labelfont` or `labelformatter`.

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
        colorscale = identity,
        colorrange = Makie.automatic,
        levels = 5,
        linewidth = 1.0,
        linestyle = nothing,
        alpha = 1.0,
        enable_depth = true,
        transparency = false,
        labels = false,
        labelfont = theme(scene, :font),
        labelcolor = nothing,  # matches color by default
        labelformatter = contour_label_formatter,
        labelsize = 10,  # arbitrary
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

angle(p1::Union{Vec2f,Point2f}, p2::Union{Vec2f,Point2f})::Float32 =
    atan(p2[2] - p1[2], p2[1] - p1[1])  # result in [-π, π]

function label_info(lev, vertices, col)
    mid = ceil(Int, 0.5f0 * length(vertices))
    pts = (vertices[max(firstindex(vertices), mid - 1)], vertices[mid], vertices[min(mid + 1, lastindex(vertices))])
    (
        lev,
        map(p -> to_ndim(Point3f, p, lev), Tuple(pts)),
        col,
    )
end

function contourlines(::Type{<: Contour}, contours, cols, labels)
    points = Point2f[]
    colors = RGBA{Float32}[]
    lev_pos_col = Tuple{Float32,NTuple{3,Point2f},RGBA{Float32}}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            append!(points, elem.vertices)
            push!(points, Point2f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
            labels && push!(lev_pos_col, label_info(c.level, elem.vertices, color))
        end
    end
    points, colors, lev_pos_col
end

function contourlines(::Type{<: Contour3d}, contours, cols, labels)
    points = Point3f[]
    colors = RGBA{Float32}[]
    lev_pos_col = Tuple{Float32,NTuple{3,Point3f},RGBA{Float32}}[]
    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            for p in elem.vertices
                push!(points, to_ndim(Point3f, p, c.level))
            end
            push!(points, Point3f(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))
            labels && push!(lev_pos_col, label_info(c.level, elem.vertices, color))
        end
    end
    points, colors, lev_pos_col
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
    valuerange = lift(nan_extrema, plot, volume)
    cliprange = replace_automatic!(()-> valuerange, plot, :colorrange)
    cmap = lift(plot, colormap, levels, alpha, cliprange, valuerange) do _cmap, l, alpha, cliprange, vrange
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
        map(1:N) do i
            i01 = (i-1) / (N - 1)
            c = Makie.interpolated_getindex(cmap, i01)
            isoval = vrange[1] + (i01 * (vrange[2] - vrange[1]))
            line = reduce(levels, init = false) do v0, level
                isoval in v_interval || return false
                v0 || abs(level - isoval) <= iso_eps
            end
            RGBAf(Colors.color(c), line ? alpha : 0.0)
        end
    end

    attr = Attributes(plot)
    attr[:colorrange] = cliprange
    attr[:colormap] = cmap
    attr[:algorithm] = 7
    pop!(attr, :levels)
    pop!(attr, :alpha) # don't apply alpha 2 times
    # unused attributes
    pop!(attr, :labels)
    pop!(attr, :labelfont)
    pop!(attr, :labelsize)
    pop!(attr, :labelcolor)
    pop!(attr, :labelformatter)
    volume!(plot, attr, x, y, z, volume)
end

color_per_level(color, args...) = color_per_level(to_color(color), args...)
color_per_level(color::Colorant, _, _, _, _, levels) = fill(color, length(levels))
color_per_level(colors::AbstractVector, args...) = color_per_level(to_colormap(colors), args...)

function color_per_level(colors::AbstractVector{<: Colorant}, _, _, _, _, levels)
    if length(levels) == length(colors)
        return colors
    else
        # TODO resample?!
        error("For a contour plot, `color` with an array of colors needs to
        have the same length as `levels`.
        Found $(length(colors)) colors, but $(length(levels)) levels")
    end
end

function color_per_level(::Nothing, colormap, colorscale, colorrange, a, levels)
    cmap = to_colormap(colormap)
    map(levels) do level
        c = interpolated_getindex(cmap, colorscale(level), colorscale.(colorrange))
        RGBAf(color(c), alpha(c) * a)
    end
end


function contourlines(x, y, z::AbstractMatrix{ET}, levels, level_colors, labels, T) where {ET}
    # Compute contours
    xv, yv = to_vector(x, size(z, 1), ET), to_vector(y, size(z, 2), ET)
    contours = Contours.contours(xv, yv, z, convert(Vector{ET}, levels))
    return contourlines(T, contours, level_colors, labels)
end

function has_changed(old_args, new_args)
    length(old_args) === length(new_args) || return true
    for (old, new) in zip(old_args, new_args)
        if old != new
            return true
        end
    end
    return false
end

function plot!(plot::T) where T <: Union{Contour, Contour3d}
    x, y, z = plot[1:3]
    zrange = lift(nan_extrema, plot, z)
    levels = lift(plot, plot.levels, zrange) do levels, zrange
        if levels isa AbstractVector{<: Number}
            return levels
        elseif levels isa Integer
            to_levels(levels, zrange)
        else
            error("Level needs to be Vector of iso values, or a single integer to for a number of automatic levels")
        end
    end

    replace_automatic!(()-> zrange, plot, :colorrange)

    @extract plot (labels, labelsize, labelfont, labelcolor, labelformatter)
    args = @extract plot (color, colormap, colorscale, colorrange, alpha)
    level_colors = lift(color_per_level, plot, args..., levels)
    args = (x, y, z, levels, level_colors, labels)
    arg_values = map(to_value, args)
    old_values = map(copy, arg_values)
    points, colors, lev_pos_col = Observable.(contourlines(arg_values..., T); ignore_equal_values=true)
    onany(plot, args...) do args...
        # contourlines is expensive enough, that it's worth to copy & check against old values
        # We need to copy, since the values may get mutated in place
        if has_changed(old_values, args)
            old_values = map(copy, args)
            _points, _colors, _lev_pos_col = contourlines(args..., T)
            points[] = _points; colors[] = _colors; lev_pos_col[] = _lev_pos_col
            return
        end
    end

    P = T <: Contour ? Point2f : Point3f
    scene = parent_scene(plot)
    space = plot.space[]

    texts = text!(
        plot,
        Observable(P[]);
        color = Observable(RGBA{Float32}[]),
        rotation = Observable(Float32[]),
        text = Observable(String[]),
        align = (:center, :center),
        fontsize = labelsize,
        font = labelfont,
    )

    lift(scene.camera.projectionview, scene.px_area, labels, labelcolor, labelformatter,
         lev_pos_col) do _, _, labels, labelcolor, labelformatter, lev_pos_col
        labels || return
        pos = texts.positions.val; empty!(pos)
        rot = texts.rotation.val; empty!(rot)
        col = texts.color.val; empty!(col)
        lbl = texts.text.val; empty!(lbl)
        for (lev, (p1, p2, p3), color) in lev_pos_col
            px_pos1 = project(scene, apply_transform(transform_func(plot), p1, space))
            px_pos3 = project(scene, apply_transform(transform_func(plot), p3, space))
            rot_from_horz::Float32 = angle(px_pos1, px_pos3)
            # transition from an angle from horizontal axis in [-π; π]
            # to a readable text with a rotation from vertical axis in [-π / 2; π / 2]
            rot_from_vert::Float32 = if abs(rot_from_horz) > 0.5f0 * π
                rot_from_horz - copysign(Float32(π), rot_from_horz)
            else
                rot_from_horz
            end
            push!(col, labelcolor === nothing ? color : to_color(labelcolor))
            push!(rot, rot_from_vert)
            push!(lbl, labelformatter(lev))
            push!(pos, p1)
        end
        notify(texts.text)
        return
    end

    bboxes = lift(labels, texts.text; ignore_equal_values=true) do labels, _
        labels || return
        return broadcast(texts.plots[1][1].val, texts.positions.val, texts.rotation.val) do gc, pt, rot
            # drop the depth component of the bounding box for 3D
            px_pos = project(scene, apply_transform(transform_func(plot), pt, space))
            Rect2f(boundingbox(gc, to_ndim(Point3f, px_pos, 0f0), to_rotation(rot)))
        end
    end

    masked_lines = lift(labels, bboxes, points) do labels, bboxes, segments
        labels || return segments
        n = 1
        bb = bboxes[n]
        nlab = length(bboxes)
        masked = copy(segments)
        nan = P(NaN32)
        for (i, p) in enumerate(segments)
            if isnan(p) && n < nlab
                bb = bboxes[n += 1]  # next segment is materialized by a NaN, thus consider next label
                # wireframe!(plot, bb, space = :pixel)  # toggle to debug labels
            elseif project(scene, apply_transform(transform_func(plot), p, space)) in bb
                masked[i] = nan
                for dir in (-1, +1)
                    j = i
                    while true
                        j += dir
                        checkbounds(Bool, segments, j) || break
                        project(scene, apply_transform(transform_func(plot), segments[j], space)) in bb || break
                        masked[j] = nan
                    end
                end
            end
        end
        masked
    end

    lines!(
        plot, masked_lines;
        color = colors,
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
