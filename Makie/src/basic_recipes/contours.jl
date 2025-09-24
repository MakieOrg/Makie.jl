function contour_label_formatter(level::Real)::String
    lev_short = round(level; digits = 2)
    return string(isinteger(lev_short) ? round(Int, lev_short) : lev_short)
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
    """
    Sets the tolerance for sampling of a `level` in 3D contour plots.
    """
    isorange = automatic
    mixin_colormap_attributes()...
    mixin_generic_plot_attributes()...
end

"""
    contour3d(x, y, z)

Creates a 3D contour plot of the plane spanning x::Vector, y::Vector, z::Matrix,
with z-elevation for each level.
"""
@recipe Contour3d begin
    documented_attributes(Contour)...
end

function label_info(lev, vertices, col)
    mid = ceil(Int, 0.5f0 * length(vertices))
    # take 3 pts around half segment
    pts = (vertices[max(firstindex(vertices), mid - 1)], vertices[mid], vertices[min(mid + 1, lastindex(vertices))])
    return to_ndim.(Point3f, pts, lev)..., col
end

function contourlines(::Type{<:T}, contours, cols, labels) where {T <: Union{Contour3d, Contour}}
    PT = T <: Contour3d ? Point3f : Point2f

    points = PT[]
    colors = RGBA{Float32}[]
    levels = Float32[]
    lbl_pos_low = PT[]
    lbl_pos_center = PT[]
    lbl_pos_high = PT[]
    lbl_color = RGBAf[]

    for (color, c) in zip(cols, Contours.levels(contours))
        for elem in Contours.lines(c)
            for p in elem.vertices
                push!(points, to_ndim(PT, p, c.level))
            end
            push!(points, PT(NaN32))
            append!(colors, fill(color, length(elem.vertices) + 1))

            if labels
                p1, p2, p3, col = label_info(c.level, elem.vertices, color)
                push!(levels, c.level)
                push!(lbl_pos_low, p1)
                push!(lbl_pos_center, p2)
                push!(lbl_pos_high, p3)
                push!(lbl_color, col)
            end
        end
    end
    return points, colors, levels, lbl_pos_low, lbl_pos_center, lbl_pos_high, lbl_color
end

to_levels(x::AbstractVector{<:Number}, cnorm) = x

function to_levels(n::Integer, cnorm)
    zmin, zmax = cnorm
    dz = (zmax - zmin) / (n + 1)
    return range(zmin + dz; step = dz, length = n)
end

conversion_trait(::Type{<:Contour3d}) = VertexGrid()
conversion_trait(::Type{<:Contour}) = VertexGrid()
conversion_trait(::Type{<:Contour}, x, y, z, ::Union{Function, AbstractArray{<:Number, 3}}) = VolumeLike()
conversion_trait(::Type{<:Contour}, ::AbstractArray{<:Number, 3}) = VolumeLike()

# 3D Contour

function plot!(plot::Contour{<:Tuple{X, Y, Z, Vol}}) where {X, Y, Z, Vol}
    map!(nan_extrema, plot, :converted_4, :value_range)
    map!(default_automatic, plot, [:colorrange, :value_range], :tight_colorrange)

    map!(to_levels, plot, [:levels, :value_range], :value_levels)

    # the default isorange should be smaller than the gap between levels, but not
    # so small that surfaces disappear/get skipped
    map!(plot, [:isorange, :value_levels, :value_range], :computed_isorange) do isorange, value_levels, (min, max)
        if isorange === automatic
            if length(value_levels) > 1
                minstep = minimum(value_levels[2:end] .- value_levels[1:(end - 1)])
                return 0.1 * minstep
            else
                return 0.1 * (max - min)
            end
        else
            return isorange
        end
    end

    # The colorrange and colormap needs to be padded with RGBAf(..., 0) so that
    # samples outside the colorrange are not drawn
    map!(plot, [:tight_colorrange, :computed_isorange], :padded_colorrange) do (min, max), isorange
        return (min - 2isorange, max + 2isorange)
    end

    map!(plot, [:value_levels, :tight_colorrange], :clamped_levels) do levels, (min, max)
        return filter(lvl -> min <= lvl <= max, levels)
    end

    map!(to_colormap, plot, :colormap, :input_colormap)

    map!(
        plot,
        [:clamped_levels, :tight_colorrange, :padded_colorrange, :computed_isorange, :alpha, :input_colormap],
        :computed_colormap
    ) do levels, tight_colorrange, (min, max), isorange, alpha, cmap
        # We need colormap values for the full color range (with padding)
        # We also need enough color values to have samples in
        # `level - isorange .. level + isorange`, otherwise we might skip over
        # isosurfaces
        # GLMakie texture size is typically limited 8192+
        # WGLMakie texture size may be limited to 4096+
        N = ceil(Int, 2.5 * (max - min) / isorange)
        if N > 4096
            min_isorange = (max - min) / 4096
            @warn "Isorange maybe too small to resolve iso surfaces. Try `isorange > $min_isorange`"
        end
        N = clamp(N, 100, 4096)

        clip_range = tight_colorrange[1] - isorange .. tight_colorrange[2] + isorange
        return map(1:N) do i
            isoval = min + (i - 1) / (N - 1) * (max - min)
            c = Colors.color(interpolated_getindex(cmap, isoval, tight_colorrange))
            if isoval in clip_range && any(lvl -> lvl - isorange < isoval < lvl + isorange, levels)
                return RGBAf(c, alpha)
            else
                return RGBAf(c, 0.0)
            end
        end
    end

    volume!(
        plot, Attributes(plot),
        plot.converted_1, plot.converted_2, plot.converted_3, plot.converted_4,
        alpha = 1.0, # don't apply alpha 2 times
        algorithm = 7, # contour algorithm
        colorrange = plot.padded_colorrange,
        colormap = plot.computed_colormap,
        isorange = 0.0 # unused, but needs to be a float
    )

    return plot
end

color_per_level(color, args...) = color_per_level(to_color(color), args...)
color_per_level(color::Colorant, _, _, _, _, levels) = fill(color, length(levels))
color_per_level(colors::AbstractVector, args...) = color_per_level(to_colormap(colors), args...)

function color_per_level(colors::AbstractVector{<:Colorant}, _, _, _, _, levels)
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
    return map(levels) do level
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
function contourlines(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, z::AbstractMatrix{ET}, levels, level_colors, labels, T) where {ET}
    contours = Contours.contours(x, y, z, convert(Vector{ET}, levels))
    return contourlines(T, contours, level_colors, labels)
end

function has_changed(old_args, new_args)
    length(old_args) === length(new_args) || return true
    for (old, new) in zip(old_args, new_args)
        old != new && return true
    end
    return false
end

function plot!(plot::T) where {T <: Union{Contour, Contour3d}}
    map!(nan_extrema, plot, :converted_3, :zrange)
    map!(plot, [:levels, :zrange], :zlevels) do levels, zrange
        if levels isa AbstractVector{<:Number}
            return levels
        elseif levels isa Integer
            to_levels(levels, zrange)
        else
            error("Level needs to be Vector of iso values, or a single integer to for a number of automatic levels")
        end
    end
    map!(default_automatic, plot, [:colorrange, :zrange], :computed_colorrange)

    map!(
        color_per_level, plot,
        [:color, :colormap, :colorscale, :computed_colorrange, :alpha, :zlevels],
        :level_colors
    )

    map!(
        plot,
        [:converted_1, :converted_2, :converted_3, :zlevels, :level_colors, :labels],
        [:contour_points, :contour_colors, :computed_levels, :lbl_pos1, :lbl_pos2, :lbl_pos3, :computed_lbl_colors]
    ) do args...
        return contourlines(args..., T)
    end

    # TODO:
    # Should we make yes/no labels a constructor-time decisions so we can avoid
    # all the extra work for it entirely?
    # (i.e. no text plot, no boundingboxes, no projections?)

    map!(plot, [:lbl_pos1, :lbl_pos2, :lbl_pos3], [:text_positions, :raw_lbl_directions]) do ps1, ps2, ps3
        # TODO: Is this necessary?
        pos = map(ps1, ps2, ps3) do p1, p2, p3
            p = ifelse(isnan(p2), p1, p2)
            return ifelse(isnan(p), p3, p)
        end
        return pos, ps3 .- ps1
    end

    map!(plot, [:computed_levels, :labelformatter], :text_strings) do levels, formatter
        return formatter.(levels)
    end

    map!(plot, [:labelcolor, :computed_lbl_colors], :text_color) do user_color, computed_color
        return ifelse(user_color === nothing, computed_color, to_color(user_color))
    end

    # transform directions to pixel-space angles
    register_projected_rotations_2d!(
        plot,
        position_name = :text_positions, direction_name = :raw_lbl_directions,
        output_name = :text_rotation,
        rotation_transform = to_upright_angle
    )

    texts = text!(
        plot,
        plot.text_positions;
        color = plot.text_color,
        rotation = plot.text_rotation,
        text = plot.text_strings,
        align = (:center, :center),
        fontsize = plot.labelsize,
        font = plot.labelfont,
        transform_marker = false
    )

    register_string_boundingboxes!(texts)
    add_input!(plot.attributes, :string_boundingboxes, texts.string_boundingboxes)

    P = T <: Contour ? Point2f : Point3f

    pixel_pos_node = register_projected_positions!(plot, Point2f, input_name = :contour_points, output_space = :pixel)

    map!(plot, [:labels, :string_boundingboxes, :contour_points], :masked_lines) do use_labels, bboxes, segments
        use_labels || return segments

        # simple heuristic to turn off masking segments (≈ less than 10 pts per contour)
        count(isnan, segments) > length(segments) / 10 && return segments

        # To avoid always projecting, pull these in indirectly.
        # string boundingboxes will already update on everything that could trigger
        # pixel_contour_points, so this should be fine
        pixel_pos = pixel_pos_node[]

        n = 1
        bb = Rect2(bboxes[n])
        nlab = length(bboxes)
        masked = copy(segments)
        nan = P(NaN32)
        for (i, p) in enumerate(segments)
            if isnan(p) && n < nlab
                bb = Rect2(bboxes[n += 1])  # next segment is materialized by a NaN, thus consider next label
            elseif pixel_pos[i] in bb
                masked[i] = nan
                for dir in (-1, +1)
                    j = i
                    while true
                        j += dir
                        checkbounds(Bool, segments, j) || break
                        pixel_pos[j] in bb || break
                        masked[j] = nan
                    end
                end
            end
        end

        return masked
    end


    lines!(
        plot, plot.masked_lines;
        color = plot.contour_colors,
        linewidth = plot.linewidth,
        linestyle = plot.linestyle,
        linecap = plot.linecap,
        joinstyle = plot.joinstyle,
        miter_limit = plot.miter_limit,
        visible = plot.visible,
        transparency = plot.transparency,
        overdraw = plot.overdraw,
        inspectable = plot.inspectable,
        depth_shift = plot.depth_shift,
        space = plot.space,
    )

    # toggle to debug labels
    # map!(bbs -> merge(map(GeometryBasics.mesh, bbs)), plot, texts.string_boundingboxes, :bbs2d)
    # wireframe!(plot, plot.bbs2d, space = :pixel)

    return plot
end

function data_limits(plot::Contour{<:Tuple{X, Y, Z}}) where {X, Y, Z}
    mini_maxi = extrema_nan.((plot[1][], plot[2][]))
    mini = Vec3d(first.(mini_maxi)..., 0)
    maxi = Vec3d(last.(mini_maxi)..., 0)
    return Rect3d(mini, maxi .- mini)
end

function boundingbox(plot::Union{Contour, Contour3d}, space::Symbol = :data)
    return apply_transform_and_model(plot, data_limits(plot))
end
