function draw_atomic(::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    canvas = screen.canvas
    attr = plot.attributes
    add_constant!(attr, :is_lines_plot, plot isa Lines)
    if plot isa LineSegments
        add_constant!(attr, :joinstyle, nothing)
        add_constant!(attr, :miter_limit, nothing)
    end

    Makie.compute_colors!(attr)
    add_projected_line_points!(attr)
    extract_attributes!(
        plot.attributes, [
            :clipped_points, :clipped_linewidths, :clipped_colors,
            :linestyle, :linecap, :joinstyle, :miter_limit, :is_lines_plot,
        ], :skia_attributes
    )
    draw_lineplot(canvas, attr.skia_attributes[])
    return
end

function draw_lineplot(canvas, attributes)
    positions = attributes.clipped_points
    isempty(positions) && return

    linewidth = attributes.clipped_linewidths
    color = attributes.clipped_colors
    linestyle = attributes.linestyle
    miter_limit = attributes.miter_limit
    is_lines_plot = attributes.is_lines_plot
    linecap = attributes.linecap

    # Skia draws hairlines for linewidth=0, unlike Cairo which draws nothing.
    # Skip drawing if the uniform linewidth is effectively zero.
    if !(linewidth isa AbstractArray) && linewidth <= 0
        return
    end

    if color isa AbstractArray || linewidth isa AbstractArray
        draw_multi(
            is_lines_plot, canvas,
            positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        paint = new_paint(style = SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, color)
        sk_paint_set_stroke_width(paint, Float32(linewidth))
        sk_paint_set_stroke_cap(paint, to_skia_linecap(linecap))

        miter_angle = is_lines_plot ? miter_limit : 2pi / 3
        sk_paint_set_stroke_miter(paint, Float32(to_skia_miter_limit(miter_angle)))
        joinstyle = is_lines_plot ? attributes.joinstyle : 0
        sk_paint_set_stroke_join(paint, to_skia_joinstyle(joinstyle))

        dash_effect = to_skia_dash_effect(linestyle, linewidth)
        if dash_effect != C_NULL
            sk_paint_set_path_effect(paint, dash_effect)
        end

        draw_single(is_lines_plot, canvas, paint, positions)
        sk_paint_delete(paint)
    end
    return
end

function add_projected_line_points!(attr)
    inputs = [:positions_transformed_f32c, :model_f32c, :projectionview]
    map!(attr, inputs, :clipspace_points) do points, model_f32c, projectionview
        transform = projectionview * model_f32c
        return map(points) do point
            return transform * to_ndim(Vec4d, to_ndim(Vec3d, point, 0), 1)
        end
    end
    Makie.add_computation!(attr, Val(:uniform_clip_planes), :clip)
    inputs = [:clipspace_points, :computed_color, :linewidth, :is_lines_plot, :uniform_clip_planes, :resolution]
    outputs = [:clipped_points, :clipped_colors, :clipped_linewidths]
    return register_computation!(attr, inputs, outputs) do (clip_points, colors, linewidths, is_lines_plot, clip_planes, res), _, _
        return clip_line_points(clip_points, colors, linewidths, is_lines_plot, clip_planes, res)
    end
end

function clip_line_points(clip_points, colors, linewidths, is_lines_plot, clip_planesv4f, res)
    per_point_colors = colors isa AbstractArray
    per_point_linewidths = is_lines_plot && (linewidths isa AbstractArray)

    clip_planes = map(clip_planesv4f) do plane
        return Plane3f(plane[Vec(1, 2, 3)], plane[4])
    end
    push!(
        clip_planes,
        Plane3f(Vec3f(-1, 0, 0), -1.0f0), Plane3f(Vec3f(+1, 0, 0), -1.0f0),
        Plane3f(Vec3f(0, -1, 0), -1.0f0), Plane3f(Vec3f(0, +1, 0), -1.0f0)
    )

    screen_points = sizehint!(Vec2f[], length(clip_points))
    color_output = sizehint!(eltype(colors)[], length(clip_points))
    linewidth_output = sizehint!(eltype(linewidths)[], length(clip_points))

    if is_lines_plot
        clip_lines!(
            clip_points, colors, linewidths, clip_planes, res, per_point_colors, per_point_linewidths,
            screen_points, color_output, linewidth_output
        )
    else
        clip_linesegments!(
            clip_points, colors, clip_planes, res, per_point_colors,
            screen_points, color_output
        )
    end
    return screen_points, ifelse(per_point_colors, color_output, colors),
        ifelse(per_point_linewidths, linewidth_output, linewidths)
end

# Reuse the exact same clipping logic from CairoMakie
function clip_linesegments!(
        clip_points, colors, clip_planes, res, per_point_colors,
        screen_points, color_output
    )
    for i in 1:2:(length(clip_points) - 1)
        if per_point_colors
            c1 = colors[i]
            c2 = colors[i + 1]
        end
        p1 = clip_points[i]
        p2 = clip_points[i + 1]
        v = p2 - p1

        if p1[4] <= 0.0
            p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
            per_point_colors && (c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1))
        end
        if p2[4] <= 0.0
            p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
            per_point_colors && (c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1))
        end

        for plane in clip_planes
            d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
            d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]
            if (d1 < 0.0) && (d2 < 0.0)
                p1 = Vec4f(NaN); p2 = Vec4f(NaN); break
            elseif (d1 < 0.0)
                p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                per_point_colors && (c1 = c1 - d1 * (c2 - c1) / (d2 - d1))
            elseif (d2 < 0.0)
                p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                per_point_colors && (c2 = c2 - d2 * (c1 - c2) / (d1 - d2))
            end
        end

        push!(screen_points, clip2screen(p1, res), clip2screen(p2, res))
        per_point_colors && push!(color_output, c1, c2)
    end
    return
end

function clip_lines!(
        clip_points, colors, linewidths, clip_planes, res, per_point_colors, per_point_linewidths,
        screen_points, color_output, linewidth_output
    )
    last_is_nan = true
    for i in 1:(length(clip_points) - 1)
        hidden = false
        disconnect1 = false
        disconnect2 = false

        per_point_colors && (c1 = colors[i]; c2 = colors[i + 1])

        p1 = clip_points[i]
        p2 = clip_points[i + 1]
        v = p2 - p1

        if p1[4] <= 0.0
            disconnect1 = true
            p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
            per_point_colors && (c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1))
        end
        if p2[4] <= 0.0
            disconnect2 = true
            p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
            per_point_colors && (c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1))
        end

        for plane in clip_planes
            d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
            d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]
            if (d1 < 0.0) && (d2 < 0.0)
                hidden = true; break
            elseif (d1 < 0.0)
                disconnect1 = true
                p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                per_point_colors && (c1 = c1 - d1 * (c2 - c1) / (d2 - d1))
            elseif (d2 < 0.0)
                disconnect2 = true
                p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                per_point_colors && (c2 = c2 - d2 * (c1 - c2) / (d1 - d2))
            end
        end

        if hidden && !last_is_nan
            last_is_nan = true
            push!(screen_points, Vec2f(NaN))
            per_point_linewidths && push!(linewidth_output, linewidths[i])
            per_point_colors && push!(color_output, c1)
        elseif !hidden
            if disconnect1 && !last_is_nan
                push!(screen_points, Vec2f(NaN))
                per_point_linewidths && push!(linewidth_output, linewidths[i])
                per_point_colors && push!(color_output, c1)
            end
            last_is_nan = false
            push!(screen_points, clip2screen(p1, res))
            per_point_linewidths && push!(linewidth_output, linewidths[i])
            per_point_colors && push!(color_output, c1)
            if disconnect2
                last_is_nan = true
                push!(screen_points, clip2screen(p2, res), Vec2f(NaN))
                per_point_linewidths && push!(linewidth_output, linewidths[i + 1], linewidths[i + 1])
                per_point_colors && push!(color_output, c2, c2)
            end
        end
    end

    if !last_is_nan
        push!(screen_points, clip2screen(clip_points[end], res))
        per_point_linewidths && push!(linewidth_output, linewidths[end])
        per_point_colors && push!(color_output, colors[end])
    end
    return
end

function draw_multi(islines, canvas, positions, colors, linewidths, dash)
    if islines
        return draw_multi_lines(canvas, positions, colors, linewidths, dash)
    else
        return draw_multi_segments(canvas, positions, colors, linewidths, dash)
    end
end

function draw_multi_segments(canvas, positions, colors, linewidths, dash)
    @assert iseven(length(positions))
    paint = new_paint(style = SK_PAINT_STYLE_STROKE)

    for i in 1:2:length(positions)
        (isnan(positions[i + 1]) || isnan(positions[i])) && continue
        lw = sv_getindex(linewidths, i)

        sk_paint_set_stroke_width(paint, Float32(lw))
        if !isnothing(dash)
            effect = sk_path_effect_create_dash(Float32.(dash .* lw), Int32(length(dash)), 0.0f0)
            sk_paint_set_path_effect(paint, effect)
        end

        c1 = sv_getindex(colors, i)
        c2 = sv_getindex(colors, i + 1)
        if c1 == c2
            set_paint_color!(paint, c1)
        else
            # For gradient segments, use the average color (Skia has no direct line gradient)
            avg = RGBAf(
                (red(c1) + red(c2)) / 2, (green(c1) + green(c2)) / 2,
                (blue(c1) + blue(c2)) / 2, (alpha(c1) + alpha(c2)) / 2
            )
            set_paint_color!(paint, avg)
        end
        p1 = positions[i]
        p2 = positions[i + 1]
        sk_canvas_draw_line(canvas, Float32(p1[1]), Float32(p1[2]),
            Float32(p2[1]), Float32(p2[2]), paint)
    end
    sk_paint_delete(paint)
    return
end

function draw_multi_lines(canvas, positions, colors, linewidths, dash)
    isempty(positions) && return
    paint = new_paint(style = SK_PAINT_STYLE_STROKE)

    # Draw contiguous segments of the same color as paths
    prev_color = sv_getindex(colors, 1)
    prev_linewidth = sv_getindex(linewidths, 1)
    prev_nan = isnan(positions[begin])

    path = sk_path_new()
    path_started = false

    if !prev_nan
        sk_path_move_to(path, Float32(positions[begin][1]), Float32(positions[begin][2]))
        path_started = true
    end

    function flush_path!()
        if path_started
            set_paint_color!(paint, prev_color)
            sk_paint_set_stroke_width(paint, Float32(prev_linewidth))
            if !isnothing(dash)
                effect = sk_path_effect_create_dash(Float32.(dash .* prev_linewidth), Int32(length(dash)), 0.0f0)
                sk_paint_set_path_effect(paint, effect)
            end
            sk_canvas_draw_path(canvas, path, paint)
            sk_path_delete(path)
        end
    end

    for i in eachindex(positions)[(begin + 1):end]
        this_position = positions[i]
        this_color = sv_getindex(colors, i)
        this_nan = isnan(this_position)
        this_linewidth = sv_getindex(linewidths, i)

        if this_nan && path_started
            flush_path!()
            path = sk_path_new()
            path_started = false
        elseif prev_nan && !this_nan
            if !path_started
                path = sk_path_new()
            end
            sk_path_move_to(path, Float32(this_position[1]), Float32(this_position[2]))
            path_started = true
        elseif !prev_nan && !this_nan
            if this_color != prev_color
                # flush old color, start new path from previous position
                flush_path!()
                path = sk_path_new()
                sk_path_move_to(path, Float32(positions[i-1][1]), Float32(positions[i-1][2]))
                sk_path_line_to(path, Float32(this_position[1]), Float32(this_position[2]))
                path_started = true
            else
                sk_path_line_to(path, Float32(this_position[1]), Float32(this_position[2]))
            end
        end

        prev_nan = this_nan
        prev_color = this_color
        prev_linewidth = this_linewidth
    end

    flush_path!()
    sk_paint_delete(paint)
    return
end

function draw_single(is_lines_plot::Bool, canvas, paint, positions)
    if is_lines_plot
        return draw_single_lines(canvas, paint, positions)
    else
        return draw_single_segments(canvas, paint, positions)
    end
end

function draw_single_lines(canvas, paint, positions)
    isempty(positions) && return
    n = length(positions)
    path = sk_path_new()

    @inbounds for i in 1:n
        p = positions[i]
        if !isnan(p)
            if i == 1 || isnan(positions[i - 1])
                sk_path_move_to(path, Float32(p[1]), Float32(p[2]))
            else
                sk_path_line_to(path, Float32(p[1]), Float32(p[2]))
                if i == n || isnan(positions[i + 1])
                    sk_canvas_draw_path(canvas, path, paint)
                    sk_path_delete(path)
                    path = sk_path_new()
                end
            end
        end
    end
    sk_path_delete(path)
    return
end

function draw_single_segments(canvas, paint, positions)
    @assert iseven(length(positions))
    @inbounds for i in 1:2:(length(positions) - 1)
        p1 = positions[i]
        p2 = positions[i + 1]
        (isnan(p1) || isnan(p2)) && continue
        sk_canvas_draw_line(canvas, Float32(p1[1]), Float32(p1[2]),
            Float32(p2[1]), Float32(p2[2]), paint)
    end
    return
end
