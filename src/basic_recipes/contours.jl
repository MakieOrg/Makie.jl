function contour_label_formatter(level::Real)::String
    lev_short = round(level; digits = 2)
    string(isinteger(lev_short) ? round(Int, lev_short) : lev_short)
end

"""
    contour(x, y, z)
    contour(z::Matrix)

Creates a contour plot of the plane spanning `x::Vector`, `y::Vector`, `z::Matrix`.
If only `z::Matrix` is supplied, the indices of the elements in `z` will be used as the `x` and `y` locations when plotting the contour.

`x` and `y` can also be Matrices that define a curvilinear grid, similar to how [`surface`](@ref) works.
"""
@recipe Contour begin
    """
    The color of the contour lines. If `nothing`, the color is determined by the numerical values of the
    contour levels in combination with `colormap` and `colorrange`.
    """
    color = nothing
    """
    Controls the number and location of the contour lines. Can be either

    - an `Int` that produces n equally wide levels or bands
    - an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands
    """
    levels = 5
    linewidth = 1.0
    linestyle = nothing
    linecap = @inherit linecap
    joinstyle = @inherit joinstyle
    miter_limit = @inherit miter_limit
    enable_depth = true
    """
    If `true`, adds text labels to the contour lines.
    """
    labels = false
    "The font of the contour labels."
    labelfont = @inherit font
    "Color of the contour labels, if `nothing` it matches `color` by default."
    labelcolor = nothing  # matches color by default
    """
    Formats the numeric values of the contour levels to strings.
    """
    labelformatter = contour_label_formatter
    "Font size of the contour labels"
    labelsize = 10 # arbitrary
    MakieCore.mixin_colormap_attributes()...
    MakieCore.mixin_generic_plot_attributes()...
end

"""
    contour3d(x, y, z)

Creates a 3D contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z-elevation for each level.
"""
@recipe Contour3d begin
    MakieCore.documented_attributes(Contour)...
end

# result in [-π, π]
angle(p1::VecTypes{2}, p2::VecTypes{2}) = Float32(atan(p2[2] - p1[2], p2[1] - p1[1]))

function label_info(lev, vertices, col)
    mid = ceil(Int, 0.5f0 * length(vertices))
    # take 3 pts around half segment
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

conversion_trait(::Type{<: Contour3d}) = VertexGrid()
conversion_trait(::Type{<: Contour}) = VertexGrid()
conversion_trait(::Type{<:Contour}, x, y, z, ::Union{Function, AbstractArray{<: Number, 3}}) = VolumeLike()
conversion_trait(::Type{<: Contour}, ::AbstractArray{<: Number, 3}) = VolumeLike()

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

    attr = copy(Attributes(plot))

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
    pop!(attr, :color)
    pop!(attr, :linestyle)
    pop!(attr, :linewidth)
    pop!(attr, :linecap)
    pop!(attr, :joinstyle)
    pop!(attr, :miter_limit)
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

# Overload for matrix-like x and y lookups for contours
# Just removes the `to_vector` invocation
function contourlines(x::AbstractMatrix{<: Real}, y::AbstractMatrix{<: Real}, z::AbstractMatrix{ET}, levels, level_colors, labels, T) where {ET}
    contours = Contours.contours(x, y, z, convert(Vector{ET}, levels))
    return contourlines(T, contours, level_colors, labels)
end

function has_changed(old_args, new_args)
    length(old_args) === length(new_args) || return true
    for (old, new) in zip(old_args, new_args)
        old != new && return true
    end
    false
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
            points[], colors[], lev_pos_col[] = contourlines(args..., T)
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
        transform_marker = false
    )

    lift(plot, scene.camera.projectionview, transformationmatrix(plot), scene.viewport,
            labels, labelcolor, labelformatter, lev_pos_col
        ) do _, _, _, labels, labelcolor, labelformatter, lev_pos_col
        labels || return
        pos = texts.positions[]; empty!(pos)
        rot = texts.rotation[]; empty!(rot)
        col = texts.color[]; empty!(col)
        lbl = texts.text[]; empty!(lbl)
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
            p = p2  # try to position label around center
            isnan(p) && (p = p1)
            isnan(p) && (p = p3)
            push!(pos, p)
        end
        notify(texts.text)
        return
    end

    bboxes = lift(plot, labels, texts.text; ignore_equal_values=true) do labels, _
        labels || return
        return broadcast(texts.plots[1][1].val, texts.positions.val, texts.rotation.val) do gc, pt, rot
            # drop the depth component of the bounding box for 3D
            px_pos = project(scene, apply_transform(transform_func(plot), pt, space))
            bb = unchecked_boundingbox(gc, to_ndim(Point3f, px_pos, 0f0), to_rotation(rot))
            isfinite_rect(bb) || return Rect2f()
            Rect2f(bb)
        end
    end

    masked_lines = lift(plot, labels, bboxes, points) do labels, bboxes, segments
        labels || return segments
        # simple heuristic to turn off masking segments (≈ less than 10 pts per contour)
        count(isnan, segments) > length(segments) / 10 && return segments
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
        linestyle = plot.linestyle,
        linecap = plot.linecap,
        joinstyle = plot.joinstyle,
        miter_limit = plot.miter_limit,
        visible=plot.visible,
        transparency=plot.transparency,
        overdraw=plot.overdraw,
        inspectable=plot.inspectable,
        depth_shift=plot.depth_shift,
        space=plot.space
    )
    plot
end

function data_limits(plot::Contour{<: Tuple{X, Y, Z}}) where {X, Y, Z}
    mini_maxi = extrema_nan.((plot[1][], plot[2][]))
    mini = Vec3d(first.(mini_maxi)..., 0)
    maxi = Vec3d(last.(mini_maxi)..., 0)
    return Rect3d(mini, maxi .- mini)
end
function boundingbox(plot::Contour{<: Tuple{X, Y, Z}}, space::Symbol = :data) where {X, Y, Z}
    return apply_transform_and_model(plot, data_limits(plot))
end
# TODO: should this have a data_limits overload?
function boundingbox(plot::Contour3d, space::Symbol = :data)
    return apply_transform_and_model(plot, data_limits(plot))
end
