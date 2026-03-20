function draw_atomic(scene::Scene, screen::Screen, plot::Scatter)
    attr = plot.attributes
    isempty(attr.positions[]) && return
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    skia_unclipped_indices!(attr)
    Makie.compute_colors!(attr)
    Makie.register_positions_projected!(
        scene.compute, attr, Point3d;
        input_name = :positions_transformed_f32c, output_name = :positions_in_markerspace,
        input_space = :space, output_space = :markerspace, apply_clip_planes = false
    )
    map!(skia_scatter_marker, attr, :marker, :skia_marker)
    size_model!(attr)
    if !haskey(attr, :eye_to_clip)
        add_input!(attr, :eye_to_clip, scene.compute.projection)
        add_input!(attr, :cam_view, scene.compute.view)
    end
    inputs = [
        :positions_in_markerspace, :projectionview, :eye_to_clip, :cam_view,
        :markersize, :strokewidth, :skia_marker, :marker_offset,
        :converted_rotation, :billboard, :transform_marker, :size_model, :markerspace,
        :space, :clip_planes, :unclipped_indices, :font,
        :strokecolor, :computed_color, :resolution,
    ]
    extract_attributes!(attr, inputs, :skia_attributes)
    canvas = screen.canvas
    return draw_atomic_scatter(canvas, attr[:skia_attributes][])
end

function draw_atomic(scene::Scene, screen::Screen, plot::Text)
    attr = plot.attributes
    skia_unclipped_indices!(attr, :per_char_positions_transformed_f32c)
    Makie.register_positions_projected!(
        scene.compute, attr, Point3d;
        input_name = :positions_transformed_f32c, output_name = :positions_in_markerspace,
        input_space = :space, output_space = :markerspace, apply_clip_planes = false
    )
    Makie.add_computation!(attr, scene, Val(:meshscatter_f32c_scale))
    size_model!(attr)
    if !haskey(attr, :eye_to_clip)
        add_input!(attr, :eye_to_clip, scene.compute.projection)
        add_input!(attr, :cam_view, scene.compute.view)
    end
    inputs = [
        :text_blocks, :font_per_char, :glyphindices, :marker_offset, :text_rotation,
        :text_scales, :text_strokewidth, :text_strokecolor, :markerspace,
        :text_color,
        :positions_in_markerspace, :projectionview, :eye_to_clip, :cam_view, :resolution,
        :transform_marker, :size_model, :unclipped_indices,
    ]
    extract_attributes!(attr, inputs, :skia_attributes)
    canvas = screen.canvas
    return draw_text(canvas, attr[:skia_attributes][])
end

function draw_atomic_scatter(canvas, attr::NamedTuple)
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
        attr.skia_marker,
        attr.marker_offset,
        attr.converted_rotation,
    )

    Makie.broadcast_foreach_index(args...) do position, col, markersize, strokecolor, strokewidth, marker, marker_offset, rot
        isnan(position) && return
        isnan(rot) && return
        (isnan(markersize) || is_approx_zero(markersize)) && return
        rotation = remove_billboard(rot)
        origin = position .+ size_model * to_ndim(Vec3d, marker_offset, 0)

        proj_pos, jl_mat = project_marker(
            cam, markerspace, origin, markersize, rotation, size_model, billboard
        )
        is_degenerate(jl_mat) && return

        sk_canvas_save(canvas)
        if marker isa Char
            draw_marker(canvas, marker, best_font(marker, font), proj_pos, col, strokecolor, strokewidth, jl_mat)
        else
            draw_marker(canvas, marker, proj_pos, col, strokecolor, strokewidth, jl_mat)
        end
        sk_canvas_restore(canvas)
    end
    return
end

function flush_glyph_batch!(canvas, glyph_ids, glyph_positions, ft_font, color, strokewidth, strokecolor, mat)
    isempty(glyph_ids) && return

    # Extract the actual font size from the transformation matrix so Skia
    # rasterizes glyphs at the correct target size (not at size=1 then scaled).
    # mat columns are the projected x/y basis vectors in screen space.
    # The y-column magnitude gives the em-height in pixels.
    yscale = norm(mat[:, 2])
    yscale ≈ 0 && return
    # Normalized matrix: only encodes rotation/shear, no scaling
    norm_mat = mat * Mat2f(1/yscale, 0, 0, 1/yscale)

    sk_font = make_skia_font(ft_font, yscale)

    sk_canvas_save(canvas)

    # Apply only the rotation/shear part to the canvas (scaling is in the font size)
    concat_canvas_matrix!(canvas, sk_matrix_t(
        norm_mat[1, 1], norm_mat[1, 2], 0.0f0,
        norm_mat[2, 1], norm_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))

    # Glyph positions are in screen space — transform them into the
    # canvas coordinate system (which has norm_mat applied).
    inv_norm = inv(norm_mat)
    pos_flat = Float32[]
    for (x, y) in glyph_positions
        tp = inv_norm * Vec2f(x, y)
        push!(pos_flat, Float32(tp[1]), Float32(tp[2]))
    end

    blob = make_positioned_glyph_blob(sk_font, glyph_ids, pos_flat)
    if blob != C_NULL
        # Fill
        paint = new_paint(color = to_skia_color(color))
        sk_canvas_draw_text_blob(canvas, blob, 0.0f0, 0.0f0, paint)

        # Stroke
        if strokewidth > 0 && strokecolor != RGBAf(0, 0, 0, 0)
            sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
            set_paint_color!(paint, strokecolor)
            sk_paint_set_stroke_width(paint, Float32(strokewidth))
            sk_canvas_draw_text_blob(canvas, blob, 0.0f0, 0.0f0, paint)
        end
        sk_paint_delete(paint)
    end

    sk_canvas_restore(canvas)
    sk_font_delete(sk_font)
    empty!(glyph_ids)
    empty!(glyph_positions)
    return
end

function draw_text(canvas, attr::NamedTuple)
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

    glyph_ids = UInt16[]
    glyph_positions = Tuple{Float32, Float32}[]

    for (block_idx, glyph_indices) in enumerate(text_blocks)
        glyph_pos = positions[block_idx]
        local batch_font, batch_color, batch_mat, batch_strokewidth, batch_strokecolor

        for glyph_idx in glyph_indices
            glyph_idx in valid_indices || continue

            glyph = glyphindices[glyph_idx]
            glyph == 0 && continue

            offset = marker_offset[glyph_idx]
            font = font_per_char[glyph_idx]
            rotation = Makie.sv_getindex(text_rotation, glyph_idx)
            color = Makie.sv_getindex(text_color, glyph_idx)
            strokewidth = Makie.sv_getindex(text_strokewidth, glyph_idx)
            strokecolor = Makie.sv_getindex(text_strokecolor, glyph_idx)
            scale = Makie.sv_getindex(text_scales, glyph_idx)

            gp3 = glyph_pos .+ size_model * offset
            any(isnan, gp3) && continue

            glyphpos, jl_mat = project_marker(cam, markerspace, Point3d(gp3), scale, rotation, size_model)

            if !isempty(glyph_ids) && (
                    font !== batch_font ||
                    color != batch_color ||
                    jl_mat != batch_mat ||
                    strokewidth != batch_strokewidth ||
                    strokecolor != batch_strokecolor
                )
                flush_glyph_batch!(canvas, glyph_ids, glyph_positions, batch_font, batch_color, batch_strokewidth, batch_strokecolor, batch_mat)
            end

            if isempty(glyph_ids)
                batch_font = font
                batch_color = color
                batch_mat = jl_mat
                batch_strokewidth = strokewidth
                batch_strokecolor = strokecolor
            end

            # Glyph IDs from Makie are UInt64, Skia wants UInt16
            push!(glyph_ids, UInt16(glyph & 0xFFFF))
            push!(glyph_positions, (Float32(glyphpos[1]), Float32(glyphpos[2])))
        end

        if !isempty(glyph_ids)
            flush_glyph_batch!(canvas, glyph_ids, glyph_positions, batch_font, batch_color, batch_strokewidth, batch_strokecolor, batch_mat)
        end
    end
    return
end

function skia_unclipped_indices!(attr::Makie.ComputeGraph, position_name = :positions_transformed_f32c)
    return Makie.register_computation!(
        attr,
        [position_name, :model_f32c, :space, :clip_planes],
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

    xdiff = xproj - proj_pos
    ydiff = yproj - proj_pos

    return proj_pos, Mat2f(xdiff..., ydiff...)
end

function project_flipped(trans::Mat4, res, point::Union{Point3, Vec3}, yflip::Bool)
    p4d = to_ndim(Vec4d, to_ndim(Vec3d, point, 0.0), 1.0)
    clip = trans * p4d
    p = clip[Vec(1, 2)] ./ clip[4]
    p_yflip = Vec2d(p[1], (1.0 - 2.0 * yflip) * p[2])
    p_0_to_1 = (p_yflip .+ 1.0) ./ 2.0
    return p_0_to_1 .* res
end

########################################
#           Marker drawing             #
########################################

function draw_marker(canvas, marker::Char, font, pos, color, strokecolor, strokewidth, jl_mat)
    # Get glyph index for this character
    FT = Makie.FreeType
    glyph_id = Base.@lock font.lock FT.FT_Get_Char_Index(font, UInt32(marker))

    # Get character extent for centering
    charextent = Makie.FreeTypeAbstraction.get_extent(font, marker)
    inkbb = Makie.FreeTypeAbstraction.inkboundingbox(charextent)
    centering_offset = Makie.origin(inkbb) .+ 0.5f0 .* widths(inkbb)
    # Transform centering offset from marker space to screen space (yflip for Skia)
    char_offset = Vec2f(jl_mat * ((1, -1) .* centering_offset))
    charorigin = pos - char_offset

    # Extract actual font size from mat and normalize (same as flush_glyph_batch!)
    yscale = norm(jl_mat[:, 2])
    yscale ≈ 0 && return
    norm_mat = jl_mat * Mat2f(1/yscale, 0, 0, 1/yscale)
    sk_font = make_skia_font(font, yscale)

    sk_canvas_save(canvas)
    sk_canvas_translate(canvas, Float32(charorigin[1]), Float32(charorigin[2]))
    concat_canvas_matrix!(canvas, sk_matrix_t(
        norm_mat[1, 1], norm_mat[1, 2], 0.0f0,
        norm_mat[2, 1], norm_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))

    # Build a single-glyph blob at origin
    glyph_ids = UInt16[UInt16(glyph_id & 0xFFFF)]
    pos_flat = Float32[0.0f0, 0.0f0]
    blob = make_positioned_glyph_blob(sk_font, glyph_ids, pos_flat)

    if blob != C_NULL
        paint = new_paint(color = to_skia_color(color))
        sk_canvas_draw_text_blob(canvas, blob, 0.0f0, 0.0f0, paint)

        if strokewidth > 0
            sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
            set_paint_color!(paint, strokecolor)
            sk_paint_set_stroke_width(paint, Float32(strokewidth))
            sk_canvas_draw_text_blob(canvas, blob, 0.0f0, 0.0f0, paint)
        end
        sk_paint_delete(paint)
    end

    sk_canvas_restore(canvas)
    sk_font_delete(sk_font)
    return
end

function draw_marker(canvas, ::Type{<:Circle}, pos, color, strokecolor, strokewidth, jl_mat)
    sk_canvas_translate(canvas, Float32(pos[1]), Float32(pos[2]))
    concat_canvas_matrix!(canvas, sk_matrix_t(
        jl_mat[1, 1], jl_mat[1, 2], 0.0f0,
        jl_mat[2, 1], jl_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))
    paint = new_paint(color = to_skia_color(color))
    sk_canvas_draw_circle(canvas, 0.0f0, 0.0f0, 0.5f0, paint)
    if strokewidth > 0
        sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, to_color(strokecolor))
        sk_paint_set_stroke_width(paint, Float32(strokewidth))
        sk_canvas_draw_circle(canvas, 0.0f0, 0.0f0, 0.5f0, paint)
    end
    sk_paint_delete(paint)
    return
end

function draw_marker(canvas, ::Union{Makie.FastPixel, <:Type{<:Rect}}, pos, color, strokecolor, strokewidth, jl_mat)
    sk_canvas_translate(canvas, Float32(pos[1]), Float32(pos[2]))
    concat_canvas_matrix!(canvas, sk_matrix_t(
        jl_mat[1, 1], jl_mat[1, 2], 0.0f0,
        jl_mat[2, 1], jl_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))
    rect = Ref(sk_rect_t(-0.5f0, -0.5f0, 0.5f0, 0.5f0))
    paint = new_paint(color = to_skia_color(color))
    sk_canvas_draw_rect(canvas, rect, paint)
    if strokewidth > 0
        sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, to_color(strokecolor))
        sk_paint_set_stroke_width(paint, Float32(strokewidth))
        sk_canvas_draw_rect(canvas, rect, paint)
    end
    sk_paint_delete(paint)
    return
end

function draw_marker(canvas, beziermarker::BezierPath, pos, color, strokecolor, strokewidth, jl_mat)
    sk_canvas_save(canvas)
    sk_canvas_translate(canvas, Float32(pos[1]), Float32(pos[2]))
    concat_canvas_matrix!(canvas, sk_matrix_t(
        jl_mat[1, 1], jl_mat[1, 2], 0.0f0,
        jl_mat[2, 1], jl_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))
    sk_canvas_scale(canvas, 1.0f0, -1.0f0)

    path = bezierpath_to_skia_path(beziermarker)
    paint = new_paint(color = to_skia_color(color))
    sk_canvas_draw_path(canvas, path, paint)
    if strokewidth > 0
        sk_paint_set_style(paint, SK_PAINT_STYLE_STROKE)
        set_paint_color!(paint, to_color(strokecolor))
        sk_paint_set_stroke_width(paint, Float32(strokewidth))
        sk_canvas_draw_path(canvas, path, paint)
    end
    sk_paint_delete(paint)
    sk_path_delete(path)
    sk_canvas_restore(canvas)
    return
end

function draw_marker(
        canvas, marker::Matrix{T}, pos, color, strokecolor, strokewidth, jl_mat
    ) where {T <: Colorant}
    sk_canvas_save(canvas)
    sk_canvas_translate(canvas, Float32(pos[1]), Float32(pos[2]))
    concat_canvas_matrix!(canvas, sk_matrix_t(
        jl_mat[1, 1], jl_mat[1, 2], 0.0f0,
        jl_mat[2, 1], jl_mat[2, 2], 0.0f0,
        0.0f0, 0.0f0, 1.0f0,
    ))
    w, h = size(marker)
    sk_canvas_scale(canvas, 1.0f0 / w, 1.0f0 / h)

    skia_img, _pixels = colormatrix_to_skia_image(permutedims(marker, (2, 1)))
    src_rect = Ref(sk_rect_t(0.0f0, 0.0f0, Float32(w), Float32(h)))
    dst_rect = Ref(sk_rect_t(Float32(-w / 2), Float32(-h / 2), Float32(w / 2), Float32(h / 2)))
    paint = new_paint()
    cubic = Skia.sk_cubic_resampler_t(0.0f0, 0.0f0)
    sampling = Ref(sk_sampling_options_t(Int32(0), false, cubic, SK_FILTER_MODE_LINEAR, SK_MIPMAP_MODE_NONE))
    sk_canvas_draw_image_rect(canvas, skia_img, src_rect, dst_rect, sampling, paint, SRC_RECT_CONSTRAINT_STRICT)
    sk_paint_delete(paint)
    sk_canvas_restore(canvas)
    return
end

function bezierpath_to_skia_path(bp::BezierPath)
    path = sk_path_new()
    for cmd in bp.commands
        if cmd isa MoveTo
            sk_path_move_to(path, Float32(cmd.p[1]), Float32(cmd.p[2]))
        elseif cmd isa LineTo
            sk_path_line_to(path, Float32(cmd.p[1]), Float32(cmd.p[2]))
        elseif cmd isa CurveTo
            sk_path_cubic_to(path,
                Float32(cmd.c1[1]), Float32(cmd.c1[2]),
                Float32(cmd.c2[1]), Float32(cmd.c2[2]),
                Float32(cmd.p[1]), Float32(cmd.p[2]))
        elseif cmd isa ClosePath
            sk_path_close(path)
        elseif cmd isa EllipticalArc
            beziers = Makie.elliptical_arc_to_beziers(cmd)
            for b in beziers.commands
                if b isa MoveTo
                    sk_path_move_to(path, Float32(b.p[1]), Float32(b.p[2]))
                elseif b isa LineTo
                    sk_path_line_to(path, Float32(b.p[1]), Float32(b.p[2]))
                elseif b isa CurveTo
                    sk_path_cubic_to(path,
                        Float32(b.c1[1]), Float32(b.c1[2]),
                        Float32(b.c2[1]), Float32(b.c2[2]),
                        Float32(b.p[1]), Float32(b.p[2]))
                elseif b isa ClosePath
                    sk_path_close(path)
                end
            end
        end
    end
    return path
end
