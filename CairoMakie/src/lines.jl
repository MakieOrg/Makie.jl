function draw_atomic(::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    ctx = screen.context
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
        ], :cairo_attributes
    )
    draw_lineplot(ctx, attr.cairo_attributes[])
    return
end

function draw_lineplot(ctx, attributes)
    positions = attributes.clipped_points
    isempty(positions) && return

    linewidth = attributes.clipped_linewidths
    color = attributes.clipped_colors
    linestyle = attributes.linestyle
    miter_limit = attributes.miter_limit
    is_lines_plot = attributes.is_lines_plot
    linecap = attributes.linecap

    # The linestyle can be set globally, as we do here.
    # However, there is a discrepancy between Makie
    # and Cairo when it comes to linestyles.
    # For Makie, the linestyle array is cumulative,
    # and defines the "absolute" endpoints of segments.
    # However, for Cairo, each value provides the length of
    # alternate "on" and "off" portions of the stroke.
    # Therefore, we take the diff of the given linestyle,
    # to convert the "absolute" coordinates into "relative" ones.
    if !isnothing(linestyle) && !(linewidth isa AbstractArray)
        pattern = diff(Float64.(linestyle)) .* linewidth
        isodd(length(pattern)) && push!(pattern, 0)
        Cairo.set_dash(ctx, pattern)
    end
    # linecap
    if linecap == 1
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_SQUARE)
    elseif linecap == 2
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
    elseif linecap == 0
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_BUTT)
    else
        error("$linecap is not a valid linecap. Valid: 0 (:butt), 1 (:square), 2 (:round)")
    end

    miter_angle = is_lines_plot ? miter_limit : 2pi / 3
    set_miter_limit(ctx, 2.0 * Makie.miter_angle_to_distance(miter_angle))
    joinstyle = is_lines_plot ? attributes.joinstyle : 0
    if joinstyle == 2
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
    elseif joinstyle == 3
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_BEVEL)
    elseif joinstyle == 0
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_MITER)
    else
        error("$joinstyle is not a valid linecap. Valid: 0 (:miter), 2 (:round), 3 (:bevel)")
    end

    # TODO, how do we allow this conversion?s
    # if is_lines_plot && to_value(plot.attributes) isa BezierPath
    #     return draw_bezierpath_lines(ctx, to_value(plot.attributes), plot, color, space, model, linewidth)
    # end
    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short
        draw_multi(
            is_lines_plot, ctx,
            positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(is_lines_plot, ctx, positions)
    end
    return if !isnothing(linestyle)
        Cairo.set_dash(ctx, Float64[])  # Reset dash pattern
    end
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
    # If colors are defined per point they need to be interpolated like positions
    # at clip planes
    per_point_colors = colors isa AbstractArray
    per_point_linewidths = is_lines_plot && (linewidths isa AbstractArray)

    clip_planes = map(clip_planesv4f) do plane
        # TODO, just not unwrap planes immediately in backend-functinality?
        return Plane3f(plane[Vec(1, 2, 3)], plane[4])
    end

    # Fix lines with points far outside the clipped region not drawing at all
    # TODO this can probably be done more efficiently by checking -1 ≤ x, y ≤ 1
    #      directly and calculating intersections directly (1D)
    push!(
        clip_planes,
        Plane3f(Vec3f(-1, 0, 0), -1.0f0), Plane3f(Vec3f(+1, 0, 0), -1.0f0),
        Plane3f(Vec3f(0, -1, 0), -1.0f0), Plane3f(Vec3f(0, +1, 0), -1.0f0)
    )

    # outputs
    screen_points = sizehint!(Vec2f[], length(clip_points))
    color_output = sizehint!(eltype(colors)[], length(clip_points))
    linewidth_output = sizehint!(eltype(linewidths)[], length(clip_points))

    # Handling one segment per iteration
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

        # Handle near/far clipping
        if p1[4] <= 0.0
            p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
            if per_point_colors
                c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1)
            end
        end
        if p2[4] <= 0.0
            p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
            if per_point_colors
                c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1)
            end
        end

        for plane in clip_planes
            d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
            d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]

            if (d1 < 0.0) && (d2 < 0.0)
                # start and end clipped by one plane -> not visible
                # to keep index order we just set p1 and p2 to NaN and insert anyway
                p1 = Vec4f(NaN)
                p2 = Vec4f(NaN)
                break
            elseif (d1 < 0.0)
                # p1 clipped, move it towards p2 until unclipped
                p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                if per_point_colors
                    c1 = c1 - d1 * (c2 - c1) / (d2 - d1)
                end
            elseif (d2 < 0.0)
                # p2 clipped, move it towards p1 until unclipped
                p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                if per_point_colors
                    c2 = c2 - d2 * (c1 - c2) / (d1 - d2)
                end
            end
        end

        # no need to disconnected segments, just insert adjusted points
        push!(screen_points, clip2screen(p1, res), clip2screen(p2, res))
        if per_point_colors
            push!(color_output, c1, c2)
        end
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

        if per_point_colors
            c1 = colors[i]
            c2 = colors[i + 1]
        end

        p1 = clip_points[i]
        p2 = clip_points[i + 1]
        v = p2 - p1

        # Handle near/far clipping
        if p1[4] <= 0.0
            disconnect1 = true
            p1 = p1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * v
            if per_point_colors
                c1 = c1 + (-p1[4] - p1[3]) / (v[3] + v[4]) * (c2 - c1)
            end
        end
        if p2[4] <= 0.0
            disconnect2 = true
            p2 = p2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * v
            if per_point_colors
                c2 = c2 + (-p2[4] - p2[3]) / (v[3] + v[4]) * (c2 - c1)
            end
        end

        for plane in clip_planes
            d1 = dot(plane.normal, Vec3f(p1)) - plane.distance * p1[4]
            d2 = dot(plane.normal, Vec3f(p2)) - plane.distance * p2[4]

            if (d1 < 0.0) && (d2 < 0.0)
                # start and end clipped by one plane -> not visible
                hidden = true
                break
            elseif (d1 < 0.0)
                # p1 clipped, move it towards p2 until unclipped
                disconnect1 = true
                p1 = p1 - d1 * (p2 - p1) / (d2 - d1)
                if per_point_colors
                    c1 = c1 - d1 * (c2 - c1) / (d2 - d1)
                end
            elseif (d2 < 0.0)
                # p2 clipped, move it towards p1 until unclipped
                disconnect2 = true
                p2 = p2 - d2 * (p1 - p2) / (d1 - d2)
                if per_point_colors
                    c2 = c2 - d2 * (c1 - c2) / (d1 - d2)
                end
            end
        end

        if hidden && !last_is_nan
            # if segment hidden make sure the line separates
            last_is_nan = true
            push!(screen_points, Vec2f(NaN))
            if per_point_linewidths
                push!(linewidth_output, linewidths[i])
            end
            if per_point_colors
                push!(color_output, c1)
            end
        elseif !hidden
            # if not hidden, always push the first element to 1:end-1 line points

            # if the start of the segment is disconnected (moved), make sure the
            # line separates before it
            if disconnect1 && !last_is_nan
                push!(screen_points, Vec2f(NaN))
                if per_point_linewidths
                    push!(linewidth_output, linewidths[i])
                end
                if per_point_colors
                    push!(color_output, c1)
                end
            end

            last_is_nan = false
            push!(screen_points, clip2screen(p1, res))
            if per_point_linewidths
                push!(linewidth_output, linewidths[i])
            end
            if per_point_colors
                push!(color_output, c1)
            end

            # if the end of the segment is disconnected (moved), add the adjusted
            # point and separate it from from the next segment
            if disconnect2
                last_is_nan = true
                push!(screen_points, clip2screen(p2, res), Vec2f(NaN))
                if per_point_linewidths
                    push!(linewidth_output, linewidths[i + 1], linewidths[i + 1])
                end
                if per_point_colors
                    push!(color_output, c2, c2) # relevant, irrelevant
                end
            end
        end
    end

    # If last_is_nan == true, the last segment is either hidden or the moved
    # end point has been added. If it is false we're missing the last regular
    # clip_points
    return if !last_is_nan
        push!(screen_points, clip2screen(clip_points[end], res))
        if per_point_linewidths
            push!(linewidth_output, linewidths[end])
        end
        if per_point_colors
            push!(color_output, colors[end])
        end
    end
end


function draw_multi(islines, ctx, positions, colors, linewidths, dash)
    if islines
        return draw_multi_lines(ctx, positions, colors, linewidths, dash)
    else
        return draw_multi_segments(ctx, positions, colors, linewidths, dash)
    end
end

function draw_multi_segments(ctx, positions, colors, linewidths, dash)
    @assert iseven(length(positions))

    for i in 1:2:length(positions)
        if isnan(positions[i + 1]) || isnan(positions[i])
            continue
        end
        lw = sv_getindex(linewidths, i)
        if lw != sv_getindex(linewidths, i + 1)
            error("Cairo doesn't support two different line widths ($lw and $(sv_getindex(linewidths, i + 1)) at the endpoints of a line.")
        end
        Cairo.move_to(ctx, positions[i]...)
        Cairo.line_to(ctx, positions[i + 1]...)
        Cairo.set_line_width(ctx, lw)

        !isnothing(dash) && Cairo.set_dash(ctx, dash .* lw)
        c1 = sv_getindex(colors, i)
        c2 = sv_getindex(colors, i + 1)
        # we can avoid the more expensive gradient if the colors are the same
        # this happens if one color was given for each segment
        if c1 == c2
            Cairo.set_source_rgba(ctx, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.stroke(ctx)
        else
            pat = Cairo.pattern_create_linear(positions[i]..., positions[i + 1]...)
            Cairo.pattern_add_color_stop_rgba(pat, 0, red(c1), green(c1), blue(c1), alpha(c1))
            Cairo.pattern_add_color_stop_rgba(pat, 1, red(c2), green(c2), blue(c2), alpha(c2))
            Cairo.set_source(ctx, pat)
            Cairo.stroke(ctx)
            Cairo.destroy(pat)
        end
    end
    return
end


function draw_multi_lines(ctx, positions, colors, linewidths, dash)
    isempty(positions) && return

    @assert !(colors isa AbstractVector) || length(colors) == length(positions) "Found: $(length(positions)) positions, $(typeof(colors)) colors"
    @assert !(linewidths isa AbstractVector) || length(linewidths) == length(positions) "Found: $(length(positions)) positions, $(typeof(linewidths)) linewidths"

    prev_color = sv_getindex(colors, 1)
    prev_linewidth = sv_getindex(linewidths, 1)
    prev_position = positions[begin]
    prev_nan = isnan(prev_position)
    prev_continued = false
    start = positions[begin]

    if !prev_nan
        # first is not nan, move_to
        Cairo.move_to(ctx, positions[begin]...)
    else
        # first is nan, do nothing
    end

    for i in eachindex(positions)[(begin + 1):end]
        this_position = positions[i]
        this_color = sv_getindex(colors, i)
        this_nan = isnan(this_position)
        this_linewidth = sv_getindex(linewidths, i)
        if this_nan
            # this is nan
            if prev_continued
                # and this is prev_continued, so set source and stroke to finish previous line
                (prev_position ≈ start) && Cairo.close_path(ctx)
                Cairo.set_line_width(ctx, this_linewidth)
                !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                Cairo.set_source_rgba(ctx, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                Cairo.stroke(ctx)
            else
                # but this is not prev_continued, so do nothing
            end
        end
        if prev_nan
            # previous was nan
            if !this_nan
                # but this is not nan, so move to this position
                Cairo.move_to(ctx, this_position...)
                start = this_position
            else
                # and this is also nan, do nothing
            end
        else
            if this_color == prev_color
                # this color is like the previous
                if !this_nan
                    # and this is not nan, so line_to and set prev_continued
                    this_linewidth != prev_linewidth && error("Encountered two different linewidth values $prev_linewidth and $this_linewidth in `lines` at index $(i - 1). Different linewidths in one line are only permitted in CairoMakie when separated by a NaN point.")
                    Cairo.line_to(ctx, this_position...)
                    prev_continued = true

                    if i == lastindex(positions)
                        # this is the last element so stroke this
                        (this_position ≈ start) && Cairo.close_path(ctx)
                        Cairo.set_line_width(ctx, this_linewidth)
                        !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                        Cairo.set_source_rgba(ctx, red(this_color), green(this_color), blue(this_color), alpha(this_color))
                        Cairo.stroke(ctx)
                    end
                else
                    # but this is nan, so do nothing
                end
            else
                prev_continued = false

                # finish previous line segment
                Cairo.set_line_width(ctx, prev_linewidth)
                !isnothing(dash) && Cairo.set_dash(ctx, dash .* prev_linewidth)
                Cairo.set_source_rgba(ctx, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                Cairo.stroke(ctx)

                if !this_nan
                    this_linewidth != prev_linewidth && error("Encountered two different linewidth values $prev_linewidth and $this_linewidth in `lines` at index $(i - 1). Different linewidths in one line are only permitted in CairoMakie when separated by a NaN point.")
                    # this is not nan
                    # and this color is different than the previous, so move_to prev and line_to this
                    # create gradient pattern and stroke
                    Cairo.move_to(ctx, prev_position...)
                    Cairo.line_to(ctx, this_position...)
                    !isnothing(dash) && Cairo.set_dash(ctx, dash .* this_linewidth)
                    Cairo.set_line_width(ctx, this_linewidth)

                    pat = Cairo.pattern_create_linear(prev_position..., this_position...)
                    Cairo.pattern_add_color_stop_rgba(pat, 0, red(prev_color), green(prev_color), blue(prev_color), alpha(prev_color))
                    Cairo.pattern_add_color_stop_rgba(pat, 1, red(this_color), green(this_color), blue(this_color), alpha(this_color))
                    Cairo.set_source(ctx, pat)
                    Cairo.stroke(ctx)
                    Cairo.destroy(pat)

                    Cairo.move_to(ctx, this_position...)
                else
                    # this is nan, do nothing
                end
            end
        end
        prev_nan = this_nan
        prev_color = this_color
        prev_linewidth = this_linewidth
        prev_position = this_position
    end
    return
end


function draw_single(is_lines_plot::Bool, ctx, positions)
    if is_lines_plot
        return draw_single_lines(ctx, positions)
    else
        return draw_single_segments(ctx, positions)
    end
end

function draw_single_lines(ctx, positions)
    isempty(positions) && return

    n = length(positions)
    start = positions[begin]

    @inbounds for i in 1:n
        p = positions[i]
        # only take action for non-NaNs
        if !isnan(p)
            # new line segment at beginning or if previously NaN
            if i == 1 || isnan(positions[i - 1])
                Cairo.move_to(ctx, p...)
                start = p
            else
                Cairo.line_to(ctx, p...)
                # complete line segment at end or if next point is NaN
                if i == n || isnan(positions[i + 1])
                    if p ≈ start
                        Cairo.close_path(ctx)
                    end
                    Cairo.stroke(ctx)
                end
            end
        end
    end
    # force clearing of path in case of skipped NaN
    return Cairo.new_path(ctx)
end

function draw_single_segments(ctx, positions)

    @assert iseven(length(positions))

    @inbounds for i in 1:2:(length(positions) - 1)
        p1 = positions[i]
        p2 = positions[i + 1]

        if isnan(p1) || isnan(p2)
            continue
        else
            Cairo.move_to(ctx, p1...)
            Cairo.line_to(ctx, p2...)
            Cairo.stroke(ctx)
        end
    end
    # force clearing of path in case of skipped NaN
    return Cairo.new_path(ctx)
end

function draw_bezierpath_lines(ctx, bezierpath::BezierPath, scene, color, space, model, linewidth)
    for c in bezierpath.commands
        if c isa EllipticalArc
            bp = Makie.elliptical_arc_to_beziers(c)
            for bezier in bp.commands
                proj_comm = project_command(bezier, scene, space, model)
                path_command(ctx, proj_comm)
            end
        else
            proj_comm = project_command(c, scene, space, model)
            path_command(ctx, proj_comm)
        end
    end
    Cairo.set_source_rgba(ctx, rgbatuple(color)...)
    Cairo.set_line_width(ctx, linewidth)
    Cairo.stroke(ctx)
    return
end

function project_command(m::MoveTo, scene, space, model)
    return MoveTo(project_position(scene, space, m.p, model))
end

function project_command(l::LineTo, scene, space, model)
    return LineTo(project_position(scene, space, l.p, model))
end

function project_command(c::CurveTo, scene, space, model)
    return CurveTo(
        project_position(scene, space, c.c1, model),
        project_position(scene, space, c.c2, model),
        project_position(scene, space, c.p, model),
    )
end

project_command(c::ClosePath, scene, space, model) = c
