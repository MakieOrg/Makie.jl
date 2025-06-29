function draw_atomic(scene::Scene, screen::Screen, plot::Scatter)
    attr = plot.attributes
    isempty(attr.positions[]) && return
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    cairo_unclipped_indices!(attr)
    Makie.compute_colors!(attr)
    Makie.register_positions_projected!(
        scene.compute, attr, Point3d;
        input_name = :positions_transformed_f32c, output_name = :positions_in_markerspace,
        input_space = :space, output_space = :markerspace, apply_clip_planes = false
    )
    map!(cairo_scatter_marker, attr, :marker, :cairo_marker)
    size_model!(attr)
    if !haskey(attr, :eye_to_clip)
        add_input!(attr, :eye_to_clip, scene.compute.projection)
        add_input!(attr, :cam_view, scene.compute.view) # different from plot.view
    end
    inputs = [
        :positions_in_markerspace, :projectionview, :eye_to_clip, :cam_view,
        :markersize, :strokewidth, :cairo_marker, :marker_offset,
        :converted_rotation, :billboard, :transform_marker, :size_model, :markerspace,
        :space, :clip_planes, :unclipped_indices, :font,
        :strokecolor, :computed_color, :resolution,
    ]
    extract_attributes!(attr, inputs, :cairo_attributes)
    ctx = screen.context
    return draw_atomic_scatter(ctx, attr[:cairo_attributes][])
end

function draw_atomic(scene::Scene, screen::Screen, plot::Text)
    # :text_strokewidth # TODO: missing, but does per-glyph strokewidth even work? Same for strokecolor?
    attr = plot.attributes
    # input -> markerspace
    # TODO: We're doing per-string/glyphcollection work per glyph here
    cairo_unclipped_indices!(attr)
    Makie.register_positions_projected!(
        scene.compute, attr, Point3d;
        input_name = :positions_transformed_f32c, output_name = :positions_in_markerspace,
        input_space = :space, output_space = :markerspace, apply_clip_planes = false
    )
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    size_model!(attr)
    if !haskey(attr, :eye_to_clip)
        add_input!(attr, :eye_to_clip, scene.compute.projection)
        add_input!(attr, :cam_view, scene.compute.view) # different from plot.view
    end
    inputs = [
        :text_blocks, :font_per_char, :glyphindices, :marker_offset, :text_rotation,
        :text_scales, :text_strokewidth, :text_strokecolor, :markerspace,
        :text_color,
        :positions_in_markerspace, :projectionview, :eye_to_clip, :cam_view, :resolution,
        :transform_marker, :size_model, :unclipped_indices,
    ]
    extract_attributes!(attr, inputs, :cairo_attributes)
    ctx = screen.context
    return draw_text(ctx, attr[:cairo_attributes][])
end


function draw_atomic_scatter(ctx, attr::NamedTuple)
    size_model = attr.size_model
    font = attr.font
    markerspace = attr.markerspace
    billboard = attr.billboard
    cam = (
        resolution = attr.resolution,
        projectionview = attr.projectionview,
        eye_to_clip = attr.eye_to_clip,
        view = attr.cam_view,
    )
    args = (
        attr.unclipped_indices,
        attr.positions_in_markerspace,
        attr.computed_color,
        attr.markersize,
        attr.strokecolor,
        attr.strokewidth,
        attr.cairo_marker,
        attr.marker_offset,
        attr.converted_rotation,
    )

    Makie.broadcast_foreach_index(args...) do position, col, markersize, strokecolor, strokewidth, marker, marker_offset, rot
        isnan(position) && return
        isnan(rot) && return # matches GLMakie
        (isnan(markersize) || is_approx_zero(markersize)) && return
        rotation = remove_billboard(rot)
        origin = position .+ size_model * to_ndim(Vec3d, marker_offset, 0)

        proj_pos, mat, jl_mat = project_marker(
            cam, markerspace, origin, markersize, rotation, size_model, billboard
        )

        # mat and jl_mat are the same matrix, once as a CairoMatrix, once as a Mat2f
        # They both describe an approximate basis transformation matrix from
        # marker space to pixel space with scaling appropriate to markersize.
        # Markers that can be drawn from points/vertices of shape (e.g. Rect)
        # could be projected more accurately by projecting each point individually
        # and then building the shape.

        # make sure the matrix is not degenerate
        is_degenerate(jl_mat) && return

        Cairo.set_source_rgba(ctx, rgbatuple(col)...)
        Cairo.save(ctx)
        if marker isa Char
            draw_marker(ctx, marker, best_font(marker, font), proj_pos, strokecolor, strokewidth, jl_mat, mat)
        else
            draw_marker(ctx, marker, proj_pos, strokecolor, strokewidth, mat)
        end
        Cairo.restore(ctx)
    end
    return
end

function draw_text(ctx, attr::NamedTuple)
    positions = attr.positions_in_markerspace
    text_blocks = attr.text_blocks
    font_per_char = attr.font_per_char
    glyphindices = attr.glyphindices
    marker_offset = attr.marker_offset
    text_rotation = attr.text_rotation
    text_scales = attr.text_scales
    text_strokewidth = attr.text_strokewidth
    text_strokecolor = attr.text_strokecolor
    text_color = attr.text_color
    markerspace = attr.markerspace
    valid_indices = attr.unclipped_indices
    size_model = attr.size_model
    cam = (
        resolution = attr.resolution,
        projectionview = attr.projectionview,
        eye_to_clip = attr.eye_to_clip,
        view = attr.cam_view,
    )

    for (block_idx, glyph_indices) in enumerate(text_blocks)
        Cairo.save(ctx)  # Block save

        for glyph_idx in glyph_indices
            glyph_idx in valid_indices || continue

            glyph = glyphindices[glyph_idx]
            offset = marker_offset[glyph_idx]
            font = font_per_char[glyph_idx]
            rotation = Makie.sv_getindex(text_rotation, glyph_idx)
            color = Makie.sv_getindex(text_color, glyph_idx)
            strokewidth = Makie.sv_getindex(text_strokewidth, glyph_idx)
            strokecolor = Makie.sv_getindex(text_strokecolor, glyph_idx)
            scale = Makie.sv_getindex(text_scales, glyph_idx)

            glyph_pos = positions[glyph_idx]

            # Not renderable by font (e.g. '\n')
            glyph == 0 && continue

            # offsets and scale apply in markerspace
            gp3 = glyph_pos .+ size_model * offset

            any(isnan, gp3) && continue

            glyphpos, mat, _ = project_marker(cam, markerspace, Point3d(gp3), scale, rotation, size_model)

            cairoface = set_ft_font(ctx, font)
            old_matrix = get_font_matrix(ctx)

            Cairo.save(ctx)  # Glyph save
            Cairo.set_source_rgba(ctx, rgbatuple(color)...)

            Cairo.save(ctx)  # Glyph rendering save
            set_font_matrix(ctx, mat)
            show_glyph(ctx, glyph, glyphpos...)
            Cairo.restore(ctx)  # Glyph rendering restore

            if strokewidth > 0 && strokecolor != RGBAf(0, 0, 0, 0)
                Cairo.save(ctx)  # Stroke save
                Cairo.move_to(ctx, glyphpos...)
                set_font_matrix(ctx, mat)
                glyph_path(ctx, glyph, glyphpos...)
                Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
                Cairo.set_line_width(ctx, strokewidth)
                Cairo.stroke(ctx)
                Cairo.restore(ctx)  # Stroke restore
            end

            Cairo.restore(ctx)  # Glyph restore (matches glyph save above)
            cairo_font_face_destroy(cairoface)
            set_font_matrix(ctx, old_matrix)
        end

        Cairo.restore(ctx)  # Block restore
    end
    return
end

function cairo_unclipped_indices!(attr::Makie.ComputeGraph)
    return Makie.register_computation!(
        attr,
        [:positions_transformed_f32c, :model_f32c, :space, :clip_planes],
        [:unclipped_indices]
    ) do (transformed, model, space, clip_planes), changed, outputs
        return (unclipped_indices(to_model_space(model, clip_planes), transformed, space),)
    end
end

function size_model!(attr)
    return map!(attr, [:f32c_scale, :model, :markerspace, :transform_marker], :size_model) do f32c_scale, model, markerspace, transform_marker
        size_model = transform_marker ? model[Vec(1, 2, 3), Vec(1, 2, 3)] : Mat3d(I)
        return Mat3d(f32c_scale[1], 0, 0, 0, f32c_scale[2], 0, 0, 0, f32c_scale[3]) * size_model
    end
end


function project_marker(cam, markerspace::Symbol, origin::Point3, scale::Vec, rotation, model33::Mat3, billboard = false)
    # the CairoMatrix is found by transforming the right and up vector
    # of the marker into screen space and then subtracting the projected
    # origin. The resulting vectors give the directions in which the character
    # needs to be stretched in order to match the 3D projection

    xvec = rotation * (model33 * (scale[1] * Point3d(1, 0, 0)))
    yvec = rotation * (model33 * (scale[2] * Point3d(0, -1, 0)))
    pv = cam.projectionview
    resolution = cam.resolution
    proj_pos = project_flipped(pv, resolution, origin, true)
    if billboard && Makie.is_data_space(markerspace)
        p4d = cam.view * to_ndim(Point4d, origin, 1)
        p4d_clip = p4d[Vec(1, 2, 3)] / p4d[4]
        xproj = project_flipped(cam.eye_to_clip, resolution, p4d_clip + xvec, true)
        yproj = project_flipped(cam.eye_to_clip, resolution, p4d_clip + yvec, true)
    else
        xproj = project_flipped(pv, resolution, origin + xvec, true)
        yproj = project_flipped(pv, resolution, origin + yvec, true)
    end

    # CairoMatrix somehow has a bug if the precision is too high
    # Where in rare cases a glyph becomes suddenly really large
    xdiff = xproj - proj_pos
    ydiff = yproj - proj_pos

    mat = Cairo.CairoMatrix(
        xdiff[1], xdiff[2],
        ydiff[1], ydiff[2],
        0, 0,
    )

    return proj_pos, mat, Mat2f(xdiff..., ydiff...)
end

function project_flipped(trans::Mat4, res, point::Union{Point3, Vec3}, yflip::Bool)
    p4d = to_ndim(Vec4d, to_ndim(Vec3d, point, 0.0), 1.0)
    clip = trans * p4d
    # between -1 and 1
    p = clip[Vec(1, 2)] ./ clip[4]
    # flip y to match cairo
    p_yflip = Vec2d(p[1], (1.0 - 2.0 * yflip) * p[2])
    # normalize to between 0 and 1
    p_0_to_1 = (p_yflip .+ 1.0) ./ 2.0
    # multiply with scene resolution for final position
    return p_0_to_1 .* res
end

function draw_marker(ctx, marker::Char, font, pos, strokecolor, strokewidth, jl_mat, mat)
    cairoface = set_ft_font(ctx, font)

    # The given pos includes the user position which corresponds to the center
    # of the marker and the user marker_offset which may shift the position.
    # At this point we still need to center the character we draw. For that we
    # get the character boundingbox where (0,0) is the anchor point:
    charextent = Makie.FreeTypeAbstraction.get_extent(font, marker)
    inkbb = Makie.FreeTypeAbstraction.inkboundingbox(charextent)

    # And calculate an offset to the the center of the marker
    centering_offset = Makie.origin(inkbb) .+ 0.5f0 .* widths(inkbb)
    # which we then transform from marker space to screen space using the
    # local coordinate transform derived by project_marker()
    # (Need yflip because Cairo's y coordinates are reversed)
    char_offset = Vec2f(jl_mat * ((1, -1) .* centering_offset))

    # The offset is then applied to pos and the marker placement is set
    charorigin = pos - char_offset
    Cairo.translate(ctx, charorigin[1], charorigin[2])

    # The font matrix takes care of rotation, scaling and shearing of the marker
    old_matrix = get_font_matrix(ctx)
    set_font_matrix(ctx, mat)

    Cairo.move_to(ctx, 0, 0)
    Cairo.text_path(ctx, string(marker))
    Cairo.fill_preserve(ctx)
    # stroke
    Cairo.set_line_width(ctx, strokewidth)
    Cairo.set_source_rgba(ctx, rgbatuple(strokecolor)...)
    Cairo.stroke(ctx)

    # if we use set_ft_font we should destroy the pointer it returns
    cairo_font_face_destroy(cairoface)

    set_font_matrix(ctx, old_matrix)
    return
end

function draw_marker(ctx, ::Type{<:Circle}, pos, strokecolor, strokewidth, mat)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.arc(ctx, 0, 0, 0.5, 0, 2 * pi)
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.stroke(ctx)
    return
end

function draw_marker(ctx, ::Union{Makie.FastPixel, <:Type{<:Rect}}, pos, strokecolor, strokewidth, mat)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.rectangle(ctx, -0.5, -0.5, 1, 1)
    Cairo.fill_preserve(ctx)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.stroke(ctx)
    return
end

function draw_marker(ctx, beziermarker::BezierPath, pos, strokecolor, strokewidth, mat)
    Cairo.save(ctx)
    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.scale(ctx, 1, -1) # maybe to transition BezierPath y to Cairo y?
    draw_path(ctx, beziermarker)
    Cairo.fill_preserve(ctx)
    sc = to_color(strokecolor)
    Cairo.set_source_rgba(ctx, rgbatuple(sc)...)
    Cairo.set_line_width(ctx, Float64(strokewidth))
    Cairo.stroke(ctx)
    Cairo.restore(ctx)
    return
end

function draw_path(ctx, bp::BezierPath)
    for i in eachindex(bp.commands)
        @inbounds command = bp.commands[i]
        if command isa MoveTo
            path_command(ctx, command)
        elseif command isa LineTo
            path_command(ctx, command)
        elseif command isa CurveTo
            path_command(ctx, command)
        elseif command isa ClosePath
            path_command(ctx, command)
        elseif command isa EllipticalArc
            path_command(ctx, command)
        end
    end
    return
end
path_command(ctx, c::MoveTo) = Cairo.move_to(ctx, c.p...)
path_command(ctx, c::LineTo) = Cairo.line_to(ctx, c.p...)
path_command(ctx, c::CurveTo) = Cairo.curve_to(ctx, c.c1..., c.c2..., c.p...)
path_command(ctx, ::ClosePath) = Cairo.close_path(ctx)
function path_command(ctx, c::EllipticalArc)
    Cairo.save(ctx)
    Cairo.translate(ctx, c.c...)
    Cairo.rotate(ctx, c.angle)
    Cairo.scale(ctx, 1, c.r2 / c.r1)
    if c.a2 > c.a1
        Cairo.arc(ctx, 0, 0, c.r1, c.a1, c.a2)
    else
        Cairo.arc_negative(ctx, 0, 0, c.r1, c.a1, c.a2)
    end
    return Cairo.restore(ctx)
end


function draw_marker(
        ctx, marker::Matrix{T}, pos,
        strokecolor #= unused =#, strokewidth #= unused =#,
        mat
    ) where {T <: Colorant}

    # convert marker to Cairo compatible image data
    marker = permutedims(marker, (2, 1))
    marker_surf = to_cairo_image(marker)

    w, h = size(marker)

    # There are already active transforms so we can't Cairo.set_matrix() here
    Cairo.translate(ctx, pos[1], pos[2])
    cairo_transform(ctx, mat)
    Cairo.scale(ctx, 1.0 / w, 1.0 / h)
    Cairo.set_source_surface(ctx, marker_surf, -w / 2, -h / 2)
    Cairo.paint(ctx)
    return
end
