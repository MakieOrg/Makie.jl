

function get_colors(p::Plot, color = p.scaled_color[])
    if isnothing(p.scaled_colorrange[])
        return color
    else
        sampler = Makie.Sampler(
            p.alpha_colormap[],
            color,
            1.0,
            # interpolation method for sampling
            Makie.Linear,
            Makie.Scaling(identity, p.scaled_colorrange[])
        )
        collect(sampler)
    end
end



function draw_atomic(scene::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    linewidth = PT <: Lines ? plot.linewidth[] : plot.synched_linewidth[]
    color = PT <: Lines ? plot.scaled_color[] : plot.synched_color[]
    linestyle, space, model = plot.linestyle[], plot.space[], plot.model[]
    ctx = screen.context
    positions = plot.positions[]

    isempty(positions) && return

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately
    color = get_colors(plot, color)

    # Lines need to be handled more carefully with perspective projections to
    # avoid them inverting.
    # TODO: If we have neither perspective projection not clip_planes we can
    #       use the normal projection_position() here
    projected_positions, color, linewidth = project_line_points(scene, plot, positions, color, linewidth)

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
    linecap = plot.linecap[]
    if linecap == 1
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_SQUARE)
    elseif linecap == 2
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_ROUND)
    elseif linecap == 0
        Cairo.set_line_cap(ctx, Cairo.CAIRO_LINE_CAP_BUTT)
    else
        error("$linecap is not a valid linecap. Valid: 0 (:butt), 1 (:square), 2 (:round)")
    end

    # joinstyle
    attr = plot.args[1]
    miter_angle = plot isa Lines ? attr.outputs[:miter_limit][] : 2pi/3
    set_miter_limit(ctx, 2.0 * Makie.miter_angle_to_distance(miter_angle))

    joinstyle = plot isa Lines ? attr.outputs[:joinstyle][] : linecap
    if joinstyle == 2
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_ROUND)
    elseif joinstyle == 3
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_BEVEL)
    elseif joinstyle == 0
        Cairo.set_line_join(ctx, Cairo.CAIRO_LINE_JOIN_MITER)
    else
        error("$linecap is not a valid linecap. Valid: 0 (:miter), 2 (:round), 3 (:bevel)")
    end

    # TODO, how do we allow this conversion?s
    if plot isa Lines && to_value(plot.args[1]) isa BezierPath
        return draw_bezierpath_lines(ctx, to_value(plot.args[1]), plot, color, space, model, linewidth)
    end

    if color isa AbstractArray || linewidth isa AbstractArray
        # stroke each segment separately, this means disjointed segments with probably
        # wonky dash patterns if segments are short
        draw_multi(
            plot, ctx,
            projected_positions,
            color, linewidth,
            isnothing(linestyle) ? nothing : diff(Float64.(linestyle))
        )
    else
        # stroke the whole line at once if it has only one color
        # this allows correct linestyles and line joins as well and will be the
        # most common case
        Cairo.set_line_width(ctx, linewidth)
        Cairo.set_source_rgba(ctx, red(color), green(color), blue(color), alpha(color))
        draw_single(plot, ctx, projected_positions)
    end
    nothing
end





function draw_atomic(scene::Scene, screen::Screen, @nospecialize(p::Scatter))
    args = p.markersize[], p.strokecolor[], p.strokewidth[], p.marker[], p._marker_offset[], p.rotation[],
           p.transform_marker[], p.model[], p.markerspace[], p.space[], p.clip_planes[]

    attr = p.args[1]
    Makie.register_computation!(attr, [:marker], [:cairo_marker]) do (marker,), changed, outputs
        return (cairo_scatter_marker(marker[]),)
    end

    Makie.register_computation!(attr, [:positions_transformed_f32c, :model, :space, :clip_planes], [:clipped_transformed_positions]) do (transformed, model, space, clip_planes), changed, outputs
        indices = unclipped_indices(to_model_space(model[], clip_planes[]), transformed[], space[])
        pos = project_position(scene, space[], transformed[], indices, model[])
        return (view(pos, indices),)
    end

    markersize, strokecolor, strokewidth, marker, marker_offset, rotation,
        transform_marker, model, markerspace, space, clip_planes = args

    marker = p.cairo_marker[] # this goes through CairoMakie's conversion system and not Makie's...
    ctx = screen.context
    positions = p.clipped_transformed_positions[]
    isempty(positions) && return
    size_model = transform_marker ? model : Mat4d(I)

    font = p.font[]
    colors = get_colors(p)
    markerspace = p.markerspace[]
    space = p.space[]

    return draw_atomic_scatter(scene, ctx, positions, colors, markersize, strokecolor, strokewidth, marker,
                               marker_offset, rotation, size_model, font, markerspace)
end

function draw_atomic_scatter(
        scene, ctx, positions, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font,
        markerspace
    )

    Makie.broadcast_foreach(positions, colors, markersize, strokecolor,
            strokewidth, marker, marker_offset, remove_billboard(rotation)) do pos, col,
            markersize, strokecolor, strokewidth, m, mo, rotation

        isnan(pos) && return
        isnan(rotation) && return # matches GLMakie

        scale = project_scale(scene, markerspace, markersize, size_model)
        offset = project_scale(scene, markerspace, mo, size_model)

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)

        Cairo.save(ctx)
        # Setting a markersize of 0.0 somehow seems to break Cairos global state?
        # At least it stops drawing any marker afterwards
        # TODO, maybe there's something wrong somewhere else?
        if !(isnan(scale) || norm(scale) ≈ 0.0)
            if m isa Char
                draw_marker(ctx, m, best_font(m, font), pos, scale, strokecolor, strokewidth, offset, rotation)
            else
                draw_marker(ctx, m, pos, scale, strokecolor, strokewidth, offset, rotation)
            end
        end
        Cairo.restore(ctx)
    end

    return
end