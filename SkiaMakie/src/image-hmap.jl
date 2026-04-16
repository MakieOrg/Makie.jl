function image_grid!(::typeof(heatmap), attr)
    Makie.add_computation!(attr, nothing, Val(:heatmap_transform))
    return register_computation!(attr, [:x_transformed_f32c, :y_transformed_f32c], [:grid_x, :grid_y]) do (x, y), _, _
        xs = regularly_spaced_array_to_range(x)
        ys = regularly_spaced_array_to_range(y)
        return (xs, ys)
    end
end

function image_grid!(::typeof(image), attr)
    return register_computation!(attr, [:positions_transformed_f32c, :image], [:grid_x, :grid_y]) do (positions, image), _, _
        (x0, y0), _, (x1, y1), _ = positions
        xs = range(x0, x1, length = size(image, 1) + 1)
        ys = range(y0, y1, length = size(image, 2) + 1)
        return (xs, ys)
    end
end

function draw_atomic(scene::Scene, screen::Screen, plot::Union{Heatmap, Image})
    attr = plot.attributes
    image_grid!(Makie.plotfunc(plot), attr)
    add_constant!(attr, :is_image, plot isa Image)
    if plot isa Heatmap && !haskey(attr, :uv_transform)
        add_constant!(attr, :uv_transform, nothing)
    end
    imagelike_uv_transform!(attr)
    Makie.compute_colors!(attr)
    inputs = [
        :grid_x, :grid_y, :image,
        :interpolate, :space, :projectionview, :model_f32c,
        :clip_planes, :cairo_uv_transform, :resolution, :computed_color,
    ]
    extract_attributes!(attr, inputs, :skia_attributes)
    canvas = screen.canvas
    is_vector = is_vector_backend(screen)
    return draw_image(canvas, is_vector, attr[:skia_attributes][])
end

function imagelike_uv_transform!(attr)
    return map!(attr, [:uv_transform, :image, :is_image], :cairo_uv_transform) do T, image, is_image
        if is_image
            T3 = Mat3f(T[1], T[2], 0, T[3], T[4], 0, T[5], T[6], 1)
            T3 = Makie.uv_transform(Vec2f(size(image))) * T3 *
                Makie.uv_transform(Vec2f(0, 1), 1.0f0 ./ Vec2f(size(image, 1), -size(image, 2)))
            return T3[Vec(1, 2), Vec(1, 2, 3)]
        else
            return Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0)
        end
    end
end

function draw_image(canvas, is_vector, attr)
    model = attr.model_f32c
    xs = attr.grid_x
    ys = attr.grid_y
    projectionview = attr.projectionview
    resolution = attr.resolution
    interpolate = attr.interpolate
    clip_planes = attr.clip_planes
    color_image = attr.computed_color
    space = attr.space

    is_identity_transform = Makie.is_translation_scale_matrix(model)
    is_regular_grid = xs isa AbstractRange && ys isa AbstractRange

    xy = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(first(xs), first(ys)))
    xymax = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(last(xs), last(ys)))
    w, h = xymax .- xy

    can_use_fast_path = !(is_vector && !interpolate) && is_regular_grid && is_identity_transform && isempty(clip_planes)

    if can_use_fast_path
        # Create Skia image from color data
        skia_img, _pixels = colormatrix_to_skia_image(color_image)
        iw = size(color_image, 1)
        ih = size(color_image, 2)

        # Skia requires left < right and top < bottom in dst_rect.
        # When h < 0 (y-flipped projection), we normalize the rect and
        # apply a canvas transform to flip the image content.
        x1, x2 = minmax(Float32(xy[1]), Float32(xy[1] + w))
        y1, y2 = minmax(Float32(xy[2]), Float32(xy[2] + h))
        need_yflip = h < 0

        src_rect = Ref(sk_rect_t(0.0f0, 0.0f0, Float32(iw), Float32(ih)))
        dst_rect = Ref(sk_rect_t(x1, y1, x2, y2))

        paint = new_paint()
        filter_mode = interpolate ? SK_FILTER_MODE_LINEAR : SK_FILTER_MODE_NEAREST
        cubic = Skia.sk_cubic_resampler_t(0.0f0, 0.0f0)
        sampling = Ref(sk_sampling_options_t(Int32(0), false, cubic, filter_mode, SK_MIPMAP_MODE_NONE))

        sk_canvas_save(canvas)
        if need_yflip
            # Flip vertically around the center of the dst rect
            cy = (y1 + y2) / 2
            sk_canvas_translate(canvas, 0.0f0, cy)
            sk_canvas_scale(canvas, 1.0f0, -1.0f0)
            sk_canvas_translate(canvas, 0.0f0, -cy)
        end
        sk_canvas_draw_image_rect(canvas, skia_img, src_rect, dst_rect, sampling, paint,
            SRC_RECT_CONSTRAINT_STRICT)
        sk_canvas_restore(canvas)
        sk_paint_delete(paint)
    else
        # Slow path: draw per-pixel rectangles
        xys = let
            transformed = [Point2f(x, y) for x in xs, y in ys]
            planes = if Makie.is_data_space(space)
                to_model_space(model, clip_planes)
            else
                Plane3f[]
            end
            for i in eachindex(transformed)
                if is_clipped(planes, transformed[i])
                    transformed[i] = Point2f(NaN)
                end
            end
            cairo_project_to_screen_impl(projectionview, resolution, model, transformed)
        end

        ni, nj = size(color_image)
        _draw_rect_heatmap(canvas, xys, ni, nj, color_image)
    end
    return
end

function regularly_spaced_array_to_range(arr)
    diffs = unique!(sort!(diff(arr)))
    step = sum(diffs) ./ length(diffs)
    if all(x -> x ≈ step, diffs)
        m, M = extrema(arr)
        if step < zero(step)
            m, M = M, m
        end
        return range(m; step = step, length = length(arr))
    else
        return arr
    end
end
regularly_spaced_array_to_range(arr::AbstractRange) = arr

function _draw_rect_heatmap(canvas, xys, ni, nj, colors)
    paint = new_paint()
    @inbounds for i in 1:ni, j in 1:nj
        p1 = xys[i, j]
        p2 = xys[i + 1, j]
        p3 = xys[i + 1, j + 1]
        p4 = xys[i, j + 1]
        if isnan(p1) || isnan(p2) || isnan(p3) || isnan(p4)
            continue
        end

        # Pad to avoid antialiasing gaps
        if alpha(colors[i, j]) == 1
            v1 = normalize(p2 - p1)
            v2 = normalize(p4 - p1)
            p2 += Float32(i != ni) * v1
            p3 += Float32(i != ni) * v1 + Float32(j != nj) * v2
            p4 += Float32(j != nj) * v2
        end

        set_paint_color!(paint, colors[i, j])
        # Draw as a quad path
        path = sk_path_new()
        sk_path_move_to(path, Float32(p1[1]), Float32(p1[2]))
        sk_path_line_to(path, Float32(p2[1]), Float32(p2[2]))
        sk_path_line_to(path, Float32(p3[1]), Float32(p3[2]))
        sk_path_line_to(path, Float32(p4[1]), Float32(p4[2]))
        sk_path_close(path)
        sk_canvas_draw_path(canvas, path, paint)
        sk_path_delete(path)
    end
    sk_paint_delete(paint)
    return
end
