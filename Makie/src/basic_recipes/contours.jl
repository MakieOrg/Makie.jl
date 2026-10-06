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
    "Sets the width of contour lines. Can be set per level."
    linewidth = 1.0
    "Sets the dash pattern of contour lines. See `?lines`."
    linestyle = nothing
    """
    Sets the type of line cap used for contour lines. Options are `:butt` (flat without extrusion),
    `:square` (flat with half a linewidth extrusion) or `:round`.
    """
    linecap = @inherit linecap
    """
    Controls the rendering at line corners. Options are `:miter` for sharp corners,
    `:bevel` for cut-off corners, and `:round` for rounded corners. If the corner angle
    is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.
    """
    joinstyle = @inherit joinstyle
    """"
    Sets the minimum inner line join angle below which miter joins truncate. See
    also `Makie.miter_distance_to_angle`.
    """
    miter_limit = @inherit miter_limit
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
    Position of the contour labels along their lines, from -1 to 1, either one value
    or one per level. On an open line, 0 is the middle of its longest visible piece
    and -1 and 1 are its ends, with 1 the end further right on screen. On a closed
    loop, 0 is its top on screen, positive values move the label clockwise and -1
    and 1 both lead to the point opposite the top.
    """
    labelposition = 0.0
    "Distance in pixels between a contour label and the ends of the line around it."
    labelpadding = 5
    """
    Sets the tolerance for sampling of a `level` in 3D contour plots.
    """
    isorange = automatic
    "Controls whether 3D contours consider depth. Turning this off may improve performance."
    enable_depth = true
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

"""
    label_anchor(pixel_line, labelposition)

Find where to put the label of a contour line, given its vertices projected to
pixel space. Returns `(; from, to, t, direction)`: the label sits at fraction `t`
between the vertices `from` and `to` and is oriented along the pixel space vector
`direction`. Returns `nothing` if no segment is visible.

`labelposition` ranges from -1 to 1. On an open line, 0 is the middle by arc length
of its longest finite piece and -1 and 1 are its ends, with 1 the end further
right. On a closed loop, 0 is the top, where the label is horizontal, positive
values move clockwise and -1 and 1 both lead to the point opposite the top. The top
is the peak of the parabola through the highest vertex and its neighbors, or the
middle of the top edge if that is flat. The result does not depend on the start
point or direction of the line.
"""
function label_anchor(pixel_line, labelposition)
    is_closed_line(pixel_line) || return open_line_anchor(pixel_line, collect(eachindex(pixel_line)), labelposition)
    cycle = collect(firstindex(pixel_line):(lastindex(pixel_line) - 1))
    gap = findfirst(i -> !is_finite_point(pixel_line[i]), cycle)
    gap === nothing && return loop_anchor(pixel_line, cycle, labelposition)
    return open_line_anchor(pixel_line, rotate_cycle(cycle, gap), labelposition)
end

is_finite_point(p) = all(isfinite, p)

is_closed_line(vertices) = length(vertices) > 2 && first(vertices) == last(vertices)

function open_line_anchor(pixel_line, path, labelposition)
    pieces = [path[run] for run in finite_runs(view(pixel_line, path))]
    filter!(piece -> path_length(pixel_line, piece) > 0, pieces)
    isempty(pieces) && return nothing
    anchors = map(pieces) do piece
        rightward = left_to_right(pixel_line, piece)
        return anchor_at_distance(pixel_line, rightward, (1 + labelposition) / 2 * path_length(pixel_line, piece))
    end
    longest = argmin(eachindex(pieces)) do i
        return (-path_length(pixel_line, pieces[i]), Tuple(anchor_point(pixel_line, anchors[i])))
    end
    return anchors[longest]
end

function loop_anchor(pixel_line, cycle, labelposition)
    top_y = maximum(i -> pixel_line[i][2], cycle)
    leftmost_top = argmin(i -> Tuple(pixel_line[i]), filter(i -> pixel_line[i][2] == top_y, cycle))
    from_top = rotate_cycle(cycle, findfirst(==(leftmost_top), cycle))
    clockwise = is_counterclockwise(pixel_line, from_top) ? [first(from_top); reverse(from_top[2:end])] : from_top
    path = push!(clockwise, leftmost_top)

    total_length = path_length(pixel_line, path)
    total_length > 0 || return nothing
    top_distance = loop_top_distance(pixel_line, path, total_length)
    distance = mod(top_distance + labelposition * total_length / 2, total_length)
    anchor = anchor_at_distance(pixel_line, path, distance)
    return labelposition == 0 ? merge(anchor, (; direction = Vec2d(1, 0))) : anchor
end

function loop_top_distance(pixel_line, path, total_length)
    top = pixel_line[path[1]]
    flat_top = collect(Iterators.takewhile(i -> pixel_line[i][2] == top[2], path))
    length(flat_top) > 1 && return path_length(pixel_line, flat_top) / 2

    previous, next = pixel_line[path[end - 1]], pixel_line[path[2]]
    peak_x = parabola_peak_x(previous, top, next)
    if previous[1] < peak_x < top[1]
        return total_length - (top[1] - peak_x) / (top[1] - previous[1]) * norm(top - previous)
    elseif top[1] < peak_x < next[1]
        return (peak_x - top[1]) / (next[1] - top[1]) * norm(next - top)
    end
    return 0.0
end

function parabola_peak_x(p0, p1, p2)
    slope01 = (p1[2] - p0[2]) / (p1[1] - p0[1])
    slope12 = (p2[2] - p1[2]) / (p2[1] - p1[1])
    curvature = (slope12 - slope01) / (p2[1] - p0[1])
    return (p0[1] + p1[1]) / 2 - slope01 / (2 * curvature)
end

function is_counterclockwise(pixel_line, cycle)
    ps = [pixel_line[i] for i in cycle]
    signed_double_area = sum(eachindex(ps)) do i
        a, b = ps[i], ps[mod1(i + 1, length(ps))]
        return a[1] * b[2] - a[2] * b[1]
    end
    return signed_double_area > 0
end

left_to_right(pixel_line, path) = isless(Tuple(pixel_line[last(path)]), Tuple(pixel_line[first(path)])) ? reverse(path) : path

function finite_runs(vertices)
    runs = UnitRange{Int}[]
    run_start = nothing
    for i in eachindex(vertices)
        if !is_finite_point(vertices[i])
            run_start === nothing || push!(runs, run_start:(i - 1))
            run_start = nothing
        elseif run_start === nothing
            run_start = i
        end
    end
    run_start === nothing || push!(runs, run_start:lastindex(vertices))
    return runs
end

segment_length(pixel_line, from, to) = Float64(norm(pixel_line[to] - pixel_line[from]))

path_length(pixel_line, path) = sum(segment_length(pixel_line, path[j], path[j + 1]) for j in 1:(length(path) - 1); init = 0.0)

function anchor_at_distance(pixel_line, path, distance)
    covered = 0.0
    for j in 1:(length(path) - 1)
        from, to = path[j], path[j + 1]
        len = segment_length(pixel_line, from, to)
        if len > 0 && covered + len >= distance
            t = (distance - covered) / len
            t <= 0 && return vertex_anchor(pixel_line, path, j)
            t >= 1 && return vertex_anchor(pixel_line, path, j + 1)
            return (; from, to, t, direction = Vec2d(pixel_line[to] - pixel_line[from]))
        end
        covered += len
    end
    return vertex_anchor(pixel_line, path, length(path))
end

function vertex_anchor(pixel_line, path, j)
    closed = first(path) == last(path)
    before = j > 1 ? path[j - 1] : closed ? path[end - 1] : path[j]
    after = j < length(path) ? path[j + 1] : closed ? path[2] : path[j]
    return (; from = path[j], to = path[j], t = 0.0, direction = Vec2d(pixel_line[after] - pixel_line[before]))
end

anchor_point(line, anchor) = lerp_points(line[anchor.from], line[anchor.to], anchor.t)

lerp_points(a, b, t) = a + t * (b - a)

anchor_angle(anchor) = to_upright_angle(atan(anchor.direction[2], anchor.direction[1]))

function contourlines(::Type{<:T}, contours, labels) where {T <: Union{Contour3d, Contour}}
    PT = T <: Contour3d ? Point3f : Point2f

    points = PT[]
    # index relates to the drawn line segments, outputs is (level, count)
    elements_per_segment = Pair{UInt32, UInt32}[]
    levels = Float32[]

    for (lvl, c) in enumerate(Contours.levels(contours))
        for elem in Contours.lines(c)
            # Contours.jl traces cells in `Dict` order, so a line starts anywhere and runs either way
            vertices = canonical_line_order(elem.vertices)
            for p in vertices
                push!(points, to_ndim(PT, p, c.level))
            end
            push!(points, PT(NaN32))
            push!(elements_per_segment, lvl => length(vertices) + 1)
            labels && push!(levels, c.level)
        end
    end
    return points, elements_per_segment, levels
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
        N_raw = ceil(Int, 2.5 * (max - min) / isorange)
        if N_raw > 4096
            min_isorange = (max - min) / 4096
            @warn "Isorange maybe too small to resolve iso surfaces. Try `isorange > $min_isorange`"
        end
        N = clamp(N_raw, 100, 4096)

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
        plot, plot.attributes,
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

function contourlines(x, y, z::AbstractMatrix{ET}, levels, labels, T) where {ET}
    # Compute contours
    xv, yv = to_vector(x, size(z, 1), ET), to_vector(y, size(z, 2), ET)
    contours = Contours.contours(xv, yv, z, convert(Vector{ET}, levels))
    return contourlines(T, contours, labels)
end

# Overload for matrix-like x and y lookups for contours
# Just removes the `to_vector` invocation
function contourlines(x::AbstractMatrix{<:Real}, y::AbstractMatrix{<:Real}, z::AbstractMatrix{ET}, levels, labels, T) where {ET}
    contours = Contours.contours(x, y, z, convert(Vector{ET}, levels))
    return contourlines(T, contours, labels)
end

function has_changed(old_args, new_args)
    length(old_args) === length(new_args) || return true
    for (old, new) in zip(old_args, new_args)
        old != new && return true
    end
    return false
end

function line_ranges(elements_per_segment)
    counts = Int.(last.(elements_per_segment))
    return [(level, (stop - count + 1):stop) for ((level, _), count, stop) in zip(elements_per_segment, counts, cumsum(counts))]
end

level_value(x::Real, level) = x
level_value(x::AbstractVector, level) = x[level]

repeat_level_data_per_vertex(counts, x) = x
function repeat_level_data_per_vertex(counts, x::AbstractVector{T}) where {T}
    output = T[]
    for (lvl, count) in counts
        append!(output, fill(x[lvl], count))
    end
    return output
end

"""
    register_label_frame_boxes!(texts::Text)

Register `:label_frame_boxes`, the unrotated bounding box of each string relative
to its position, i.e. in the frame of the rotated label.
"""
function register_label_frame_boxes!(texts)
    register_raw_glyph_boundingboxes!(texts)
    map!(
        texts.attributes,
        [:text_blocks, :raw_glyph_boundingboxes, :glyph_origins, :text_rotation],
        :label_frame_boxes
    ) do blocks, glyph_boxes, origins, rotations
        return map(blocks) do glyph_indices
            isempty(glyph_indices) && return Rect2d(Point2d(NaN), Vec2d(0))
            return mapreduce(union, glyph_indices) do i
                unrotated_origin = inv(rotations[i]) * to_ndim(Vec3d, origins[i], 0)
                return Rect2d(glyph_boxes[i]) + Point2d(unrotated_origin[1], unrotated_origin[2])
            end
        end
    end
    return texts.label_frame_boxes
end

pad_label_box(box, padding) = Rect2d(minimum(box) .- padding, widths(box) .+ 2padding)

"""
    label_gap_masked_line(line, pixel_line, center, angle, box)

Cut the part of `line` out that lies inside `box`, the label box in the frame of a
label at `center` rotated by `angle`. Positions are compared in pixel space via
`pixel_line`, and the line is cut exactly at the box edges, so the gap does not
depend on where the vertices of the line are.
"""
function label_gap_masked_line(line, pixel_line, center, angle, box)
    local_line = to_label_frame.(pixel_line, Ref(center), angle)

    masked = empty(line)
    push_gap!() = (isempty(masked) || isnan(last(masked))) || push!(masked, eltype(line)(NaN))
    for i in eachindex(line, local_line)
        if i > firstindex(line)
            t_enter, t_exit = segment_box_overlap(local_line[i - 1], local_line[i], box)
            if t_enter < t_exit
                a, b = line[i - 1], line[i]
                t_enter > 0 && push!(masked, a + t_enter * (b - a))
                push_gap!()
                t_exit < 1 && push!(masked, a + t_exit * (b - a))
            end
        end
        if is_inside_box(local_line[i], box) || !is_finite_point(line[i])
            push_gap!()
        else
            push!(masked, line[i])
        end
    end
    return masked
end

function to_label_frame(p, center, angle)
    dx, dy = p[1] - center[1], p[2] - center[2]
    return Point2d(cos(angle) * dx + sin(angle) * dy, cos(angle) * dy - sin(angle) * dx)
end

is_inside_box(p, box) = all(minimum(box) .< p .< maximum(box))

function segment_box_overlap(a, b, box)
    t_enter, t_exit = 0.0, 1.0
    direction = b - a
    for k in 1:2
        low, high = minimum(box)[k] - a[k], maximum(box)[k] - a[k]
        if direction[k] == 0
            low < 0 < high || return (1.0, 0.0)
        else
            t1, t2 = minmax(low / direction[k], high / direction[k])
            t_enter, t_exit = max(t_enter, t1), min(t_exit, t2)
        end
    end
    return t_enter, t_exit
end

function plot!(plot::T) where {T <: Union{Contour, Contour3d}}
    map!(nan_extrema, plot, :converted_3, :zrange)
    map!(plot, [:levels, :zrange], :zlevels) do levels, zrange
        zmin, zmax = zrange
        isapprox(zmin, zmax) && return eltype(zrange)[]
        if levels isa AbstractVector{<:Number}
            return levels
        elseif levels isa Integer
            to_levels(levels, zrange)
        else
            error("Level needs to be Vector of iso values, or a single integer to for a number of automatic levels")
        end
    end
    map!(plot, [:colorrange, :zrange], :computed_colorrange) do colorrange, zrange
        zmin, zmax = default_automatic(colorrange, zrange)
        isapprox(zmin, zmax) || return (zmin, zmax)
        delta = max(one(zmin), abs(zmin))
        return (zmin - delta, zmax + delta)
    end

    map!(
        color_per_level, plot,
        [:color, :colormap, :colorscale, :computed_colorrange, :alpha, :zlevels],
        :level_colors
    )

    map!(
        plot,
        [:converted_1, :converted_2, :converted_3, :zlevels, :labels],
        [:contour_points, :elements_per_segment, :computed_levels]
    ) do args...
        return contourlines(args..., T)
    end

    map!(plot, [:elements_per_segment, :level_colors, :labels], :computed_lbl_colors) do counts, colors, labels
        return labels ? [colors[i] for (i, _) in counts] : RGBAf[]
    end

    # TODO:
    # Should we make yes/no labels a constructor-time decisions so we can avoid
    # all the extra work for it entirely?
    # (i.e. no text plot, no boundingboxes, no projections?)

    register_projected_positions!(plot, Point2f, input_name = :contour_points, output_space = :pixel)

    map!(
        plot,
        [:labels, :labelposition, :contour_points, :pixel_contour_points, :elements_per_segment],
        [:text_positions, :text_rotation, :label_pixel_positions]
    ) do use_labels, labelposition, points, pixel_points, elements_per_segment
        positions = eltype(points)[]
        rotations = Float32[]
        pixel_positions = Point2f[]
        use_labels || return positions, rotations, pixel_positions

        for (level, line_range) in line_ranges(elements_per_segment)
            line_without_separator = line_range[begin:(end - 1)]
            pixel_line = view(pixel_points, line_without_separator)
            anchor = label_anchor(pixel_line, level_value(labelposition, level))
            if anchor === nothing
                push!(positions, eltype(points)(NaN))
                push!(rotations, 0.0f0)
                push!(pixel_positions, Point2f(NaN))
            else
                push!(positions, anchor_point(view(points, line_without_separator), anchor))
                push!(rotations, anchor_angle(anchor))
                push!(pixel_positions, anchor_point(pixel_line, anchor))
            end
        end
        return positions, rotations, pixel_positions
    end

    map!(plot, [:computed_levels, :labelformatter], :text_strings) do levels, formatter
        # Allow inconsistent output types (String, LaTexString, RichText) from formatter
        return Ref{Any}(formatter.(levels))
    end

    map!(plot, [:labelcolor, :computed_lbl_colors], :text_color) do user_color, computed_color
        return ifelse(user_color === nothing, computed_color, to_color(user_color))
    end

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

    register_label_frame_boxes!(texts)
    add_input!(plot.attributes, :label_frame_boxes, texts.label_frame_boxes)

    map!(
        plot,
        [:labels, :label_pixel_positions, :label_frame_boxes, :text_rotation, :labelpadding, :contour_points, :pixel_contour_points, :elements_per_segment],
        [:masked_lines, :masked_elements_per_segment]
    ) do use_labels, centers, boxes, angles, padding, points, pixel_points, elements_per_segment
        use_labels || return points, elements_per_segment

        masked = empty(points)
        masked_elements_per_segment = empty(elements_per_segment)
        for (n, (level, line_range)) in enumerate(line_ranges(elements_per_segment))
            line = view(points, line_range)
            pixel_line = view(pixel_points, line_range)

            # simple heuristic to turn off masking segments when it has few
            # points, to avoid removing short contour lines entirely.
            if count(!isnan, pixel_line) >= 10
                box = pad_label_box(boxes[n], padding)
                line = label_gap_masked_line(line, pixel_line, centers[n], angles[n], box)
            end
            append!(masked, line)
            push!(masked_elements_per_segment, level => length(line))
        end

        return masked, masked_elements_per_segment
    end

    map!(repeat_level_data_per_vertex, plot, [:masked_elements_per_segment, :level_colors], :contour_colors)
    map!(repeat_level_data_per_vertex, plot, [:masked_elements_per_segment, :linewidth], :contour_linewidth)


    lines!(
        plot, plot.masked_lines;
        color = plot.contour_colors,
        linewidth = plot.contour_linewidth,
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
