# TODO:
#   - Embed camera matrices in compute pipeline so we can easily and consistently
#     do projections here

# TODO: update Makie.Sampler to include lowclip, highclip, nan_color
#       and maybe also just RGBAf color types?
#       Or just move this to make as a more generic function?
# Note: This assumes to be called with data from ComputePipeline, i.e.
#       alpha and colorscale already applied
function sample_color(
        colormap::Vector{RGBAf}, value::Real, colorrange::VecTypes{2},
        lowclip::RGBAf = first(colormap), highclip::RGBAf = last(colormap),
        nan_color::RGBAf = RGBAf(0,0,0,0), interpolation = Makie.Linear
    )
    isnan(value) && return nan_color
    value < colorrange[1] && return lowclip
    value > colorrange[2] && return highclip
    if interpolation == Makie.Linear
        return Makie.interpolated_getindex(colormap, value, colorrange)
    else
        return Makie.nearest_getindex(colormap, value, colorrange)
    end
end

function cairo_colors(@nospecialize(plot), color_name = :scaled_color)
    Makie.register_computation!(plot.args[1]::Makie.ComputeGraph,
            [color_name, :scaled_colorrange, :alpha_colormap, :nan_color, :lowclip_color, :highclip_color],
            [:cairo_colors]
        ) do inputs, changed, cached
        (color, colorrange, colormap, nan_color, lowclip, highclip) = inputs
        # colormapping
        if color isa AbstractArray{<:Real} || color isa Real
            output = map(color) do v
                return sample_color(colormap, v, colorrange, lowclip, highclip, nan_color)
            end
            return (output,)
        else # Raw colors
            # Avoid update propagation if nothing changed
            !isnothing(last) && !changed[1] && return nothing
            return (color,)
        end
    end

    return plot.cairo_colors[]
end



################################################################################
#                             Lines, LineSegments                              #
################################################################################

function draw_atomic(scene::Scene, screen::Screen, plot::PT) where {PT <: Union{Lines, LineSegments}}
    linewidth = PT <: Lines ? plot.linewidth[] : plot.synched_linewidth[]
    color = PT <: Lines ? plot.scaled_color[] : plot.synched_color[]
    linestyle, space, model = plot.linestyle[], plot.space[], plot.model[]
    ctx = screen.context
    positions = plot.positions[]

    isempty(positions) && return

    # color is now a color or an array of colors
    # if it's an array of colors, each segment must be stroked separately
    color = cairo_colors(plot, ifelse(PT <: Lines, :scaled_color, :synched_color))

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

################################################################################
#                                   Scatter                                    #
################################################################################

function draw_atomic(scene::Scene, screen::Screen, @nospecialize(p::Scatter))
    args = p.markersize[], p.strokecolor[], p.strokewidth[], p.marker[], p.marker_offset[], p.rotation[],
           p.transform_marker[], p.model[], p.markerspace[], p.space[], p.clip_planes[]

    markersize, strokecolor, strokewidth, marker, marker_offset, rotation,
    transform_marker, model, markerspace, space, clip_planes = args

    attr = p.args[1]
    Makie.register_computation!(attr, [:marker], [:cairo_marker]) do (marker,), changed, outputs
        return (cairo_scatter_marker(marker),)
    end

    if !haskey(attr.outputs, :cairo_indices) # TODO: Why is this necessary? Is it still necessary?
        Makie.register_computation!(attr,
            [:positions_transformed_f32c, :model_f32c, :space, :clip_planes],
            [:cairo_indices]
        ) do (transformed, model, space, clip_planes), changed, outputs
            return (unclipped_indices(to_model_space(model, clip_planes), transformed, space),)
        end
    end

    # TODO: This requires (cam.projectionview, resolution) as inputs otherwise
    #       the output can becomes invalid from render to render.
    # Makie.register_computation!(attr,
    #     [:positions_transformed_f32c, :cairo_indices, :model_f32c, :projectionview, :resolution, :space],
    #     [:cairo_positions_px]
    # ) do (transformed, indices, model, pv, res, space), changed, outputs
    #     pos = project_position(scene, space[], transformed[], indices[], model[])
    #     return (pos,)
    # end
    indices = p.cairo_indices[]
    transform = Makie.clip_to_space(scene.camera, p.markerspace[]) *
        Makie.space_to_clip(scene.camera, p.space[]) * p.model_f32c[]
    positions = p.positions_transformed_f32c[]
    isempty(positions) && return

    marker = p.cairo_marker[] # this goes through CairoMakie's conversion system and not Makie's...
    ctx = screen.context
    size_model = transform_marker ? model[Vec(1,2,3), Vec(1,2,3)] : Mat3d(I)

    font = p.font[]
    colors = cairo_colors(p)
    billboard = p.rotation[] isa Billboard

    return draw_atomic_scatter(
        scene, ctx, transform, positions, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font, markerspace, billboard
        )
end

is_approx_zero(x) = isapprox(x, 0)
is_approx_zero(v::VecTypes) = any(x -> isapprox(x, 0), v)

function draw_atomic_scatter(
        scene, ctx, transform, positions, indices, colors, markersize, strokecolor, strokewidth,
        marker, marker_offset, rotation, size_model, font, markerspace, billboard
    )

    Makie.broadcast_foreach_index(positions, indices, colors, markersize, strokecolor,
        strokewidth, marker, marker_offset, remove_billboard(rotation)) do pos, col,
        markersize, strokecolor, strokewidth, m, mo, rotation

        isnan(pos) && return
        isnan(rotation) && return # matches GLMakie
        (isnan(markersize) || is_approx_zero(markersize)) && return

        p4d = transform * to_ndim(Point4d, to_ndim(Point3d, pos, 0), 1) # to markerspace
        o = p4d[Vec(1, 2, 3)] ./ p4d[4] .+ size_model * to_ndim(Vec3d, mo, 0)
        proj_pos, mat, jl_mat = project_marker(scene, markerspace, o,
            markersize, rotation, size_model, billboard) # to pixel space

        # mat and jl_mat are the same matrix, once as a CairoMatrix, once as a Mat2f
        # They both describe an approximate basis transformation matrix from
        # marker space to pixel space with scaling appropriate to markersize.
        # Markers that can be drawn from points/vertices of shape (e.g. Rect)
        # could be projected more accurately by projecting each point individually
        # and then building the shape.

        # Enclosed area of the marker must be at least 1 pixel?
        (abs(det(jl_mat)) < 1) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        Cairo.save(ctx)
        if m isa Char
            draw_marker(ctx, m, best_font(m, font), proj_pos, strokecolor, strokewidth, jl_mat, mat)
        else
            draw_marker(ctx, m, proj_pos, strokecolor, strokewidth, mat)
        end
        Cairo.restore(ctx)
    end

    return
end
