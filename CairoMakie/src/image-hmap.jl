#=
Image:
- positions_transformed_f32c are rect vertices
Heatmap:
- nope
- heatmap transform adds x_transformed_f32c, y_transformed_f32c
=#

function image_grid!(::typeof(heatmap), attr)
    Makie.add_computation!(attr, nothing, Val(:heatmap_transform))
    return register_computation!(attr, [:x_transformed_f32c, :y_transformed_f32c], [:grid_x, :grid_y]) do (x, y), _, _
        xs = regularly_spaced_array_to_range(x)
        ys = regularly_spaced_array_to_range(y)
        return (xs, ys)
    end
end

function image_grid!(::typeof(image), attr)
    # Rect vertices
    return register_computation!(attr, [:positions_transformed_f32c, :image], [:grid_x, :grid_y]) do (positions, image), _, _
        (x0, y0), _, (x1, y1), _ = positions
        xs = range(x0, x1, length = size(image, 1) + 1)
        ys = range(y0, y1, length = size(image, 2) + 1)
        return (xs, ys)
    end
end


# Note: Changed very little here
function draw_atomic(scene::Scene, screen::Screen{RT}, plot::Union{Heatmap, Image}) where {RT}
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
    extract_attributes!(attr, inputs, :cairo_attributes)
    ctx = screen.context
    not_svg = RT !== SVG
    return draw_image(ctx, not_svg, attr[:cairo_attributes][])
end

function imagelike_uv_transform!(attr)

    return map!(attr, [:uv_transform, :image, :is_image], :cairo_uv_transform) do T, image, is_image
        if is_image
            # Cairo uses pixel units so we need to transform those to a 0..1 range,
            # then apply uv_transform, then scale them back to pixel units.
            # Cairo also doesn't have the yflip we have in OpenGL, so we need to
            # invert y.
            T3 = Mat3f(T[1], T[2], 0, T[3], T[4], 0, T[5], T[6], 1)
            T3 = Makie.uv_transform(Vec2f(size(image))) * T3 *
                Makie.uv_transform(Vec2f(0, 1), 1.0f0 ./ Vec2f(size(image, 1), -size(image, 2)))
            return T3[Vec(1, 2), Vec(1, 2, 3)]
        else
            return Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0)
        end
    end
end

function draw_image(ctx, not_svg, attr)
    model = attr.model_f32c
    xs = attr.grid_x
    ys = attr.grid_y
    projectionview = attr.projectionview
    resolution = attr.resolution
    interpolate = attr.interpolate
    uv_transform = attr.cairo_uv_transform
    clip_planes = attr.clip_planes
    color_image = attr.computed_color
    space = attr.space

    # Vector backends don't support FILTER_NEAREST for interp == false, so in that case we also need to draw rects
    is_vector = is_vector_backend(ctx)
    # transform_func is already included in xs, ys, so we can see its effect in is_regular_grid
    is_identity_transform = Makie.is_translation_scale_matrix(model)
    is_regular_grid = xs isa AbstractRange && ys isa AbstractRange
    is_xy_aligned = Makie.is_translation_scale_matrix(projectionview)

    if interpolate
        if !is_regular_grid
            error("$(typeof(xs)) with interpolate = true with a non-regular grid is not supported right now.")
        end
        if !is_identity_transform
            error("$(typeof(xs)) with interpolate = true with a non-identity transform is not supported right now.")
        end
    end

    # find projected image corners
    # this already takes care of flipping the image to correct cairo orientation

    xy = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(first(xs), first(ys)))
    xymax = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(last(xs), last(ys)))

    w, h = xymax .- xy

    can_use_fast_path = !(is_vector && !interpolate) && is_regular_grid && is_identity_transform &&
        (interpolate || is_xy_aligned) && isempty(clip_planes)


    return if can_use_fast_path
        s = to_cairo_image(color_image)

        weird_cairo_limit = (2^15) - 23
        if s.width > weird_cairo_limit || s.height > weird_cairo_limit
            error("Cairo stops rendering images bigger than $(weird_cairo_limit), which is likely a bug in Cairo. Please resample your image/heatmap with heatmap(Resampler(data)).")
        end
        Cairo.rectangle(ctx, xy..., w, h)
        Cairo.save(ctx)
        Cairo.translate(ctx, xy...)
        Cairo.scale(ctx, w / s.width, h / s.height)
        Cairo.set_source_surface(ctx, s, 0, 0)
        p = Cairo.get_source(ctx)
        if not_svg
            # this is needed to avoid blurry edges in png renderings, however since Cairo 1.18 this
            # setting seems to create broken SVGs
            Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
        end
        filt = interpolate ? Cairo.FILTER_BILINEAR : Cairo.FILTER_NEAREST
        Cairo.pattern_set_filter(p, filt)
        pattern_set_matrix(p, Cairo.CairoMatrix(uv_transform...))
        Cairo.fill(ctx)
        Cairo.restore(ctx)
        pattern_set_matrix(p, Cairo.CairoMatrix(1, 0, 0, 1, 0, 0))
        Cairo.pattern_set_extend(p, Cairo.EXTEND_NONE)  # Reset pattern extend mode
        Cairo.pattern_set_filter(p, Cairo.FILTER_FAST)  # Reset to default filter
    else
        # find projected image corners
        # this already takes care of flipping the image to correct cairo orientation
        xys = let
            transformed = [Point2f(x, y) for x in xs, y in ys]

            # This should transform to the coordinate system transformed is in,
            # which is pre model_f32c application, not pre model application
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

        # Note: xs and ys should have size ni+1, nj+1
        ni, nj = size(color_image)
        if ni + 1 != length(xs) || nj + 1 != length(ys)
            error("Error in conversion pipeline. xs and ys should have size ni+1, nj+1. Found: xs: $(length(xs)), ys: $(length(ys)), ni: $(ni), nj: $(nj)")
        end
        _draw_rect_heatmap(ctx, xys, ni, nj, color_image)
    end
end


"""
    regularly_spaced_array_to_range(arr)
If possible, converts `arr` to a range.
If not, returns array unchanged.
"""
function regularly_spaced_array_to_range(arr)
    diffs = unique!(sort!(diff(arr)))
    step = sum(diffs) ./ length(diffs)
    if all(x -> x ≈ step, diffs)
        m, M = extrema(arr)
        if step < zero(step)
            m, M = M, m
        end
        # don't use stop=M, since that may not include M
        return range(m; step = step, length = length(arr))
    else
        return arr
    end
end

regularly_spaced_array_to_range(arr::AbstractRange) = arr

function _draw_rect_heatmap(ctx, xys, ni, nj, colors)
    return @inbounds for i in 1:ni, j in 1:nj
        p1 = xys[i, j]
        p2 = xys[i + 1, j]
        p3 = xys[i + 1, j + 1]
        p4 = xys[i, j + 1]
        if isnan(p1) || isnan(p2) || isnan(p3) || isnan(p4)
            continue
        end

        # Rectangles and polygons that are directly adjacent usually show
        # white lines between them due to anti aliasing. To avoid this we
        # increase their size slightly.

        if alpha(colors[i, j]) == 1
            # To avoid gaps between heatmap cells we pad cells.
            # For 3D compatibility (and rotation, inversion/mirror) we pad cells
            # using directional vectors, not along x/y directions.
            v1 = normalize(p2 - p1)
            v2 = normalize(p4 - p1)
            # To avoid shifting cells we only pad them on the +i, +j side, which
            # gets covered by later cells.
            # To avoid enlarging the final column and row of the heatmap, the
            # last set of cells is not padded. (i != ni), (j != nj)
            p2 += Float32(i != ni) * v1
            p3 += Float32(i != ni) * v1 + Float32(j != nj) * v2
            p4 += Float32(j != nj) * v2
        end

        Cairo.set_line_width(ctx, 0)
        Cairo.move_to(ctx, p1[1], p1[2])
        Cairo.line_to(ctx, p2[1], p2[2])
        Cairo.line_to(ctx, p3[1], p3[2])
        Cairo.line_to(ctx, p4[1], p4[2])
        Cairo.close_path(ctx)
        Cairo.set_source_rgba(ctx, rgbatuple(colors[i, j])...)
        Cairo.fill(ctx)
    end
end
