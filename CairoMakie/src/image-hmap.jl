#=
Image:
- positions_transformed_f32c are rect vertices
- orientation maps user-matrix axes onto the rect via a Cairo CTM
Heatmap:
- heatmap transform adds x_transformed_f32c, y_transformed_f32c
=#

function image_grid!(::typeof(heatmap), attr)
    Makie.add_computation!(attr, nothing, Val(:heatmap_transform))
    return map!(attr, [:x_transformed_f32c, :y_transformed_f32c], [:grid_x, :grid_y, :is_regular_grid]) do x, y
        is_regularly_spaced_grid = is_regularly_spaced(x) && is_regularly_spaced(y)
        return (collect(x), collect(y), is_regularly_spaced_grid)
    end
end

function image_grid!(::typeof(image), attr)
    return map!(
        attr, [:positions_transformed_f32c, :image, :orientation],
        [:grid_x, :grid_y, :is_regular_grid]
    ) do positions, image, orientation
        (x0, y0), _, (x1, y1), _ = positions
        nx_cells, ny_cells = Makie.image_rect_cells(orientation, size(image)...)
        xs = range(x0, x1, length = nx_cells + 1)
        ys = range(y0, y1, length = ny_cells + 1)
        return (xs, ys, true)
    end
end


function draw_atomic(scene::Scene, screen::Screen{RT}, plot::Heatmap) where {RT}
    attr = plot.attributes
    image_grid!(heatmap, attr)
    add_constant!(attr, :is_image, false)
    if !haskey(attr, :uv_transform)
        add_constant!(attr, :uv_transform, nothing)
    end
    heatmap_cairo_uv_transform!(attr)
    Makie.compute_colors!(attr)
    inputs = [
        :grid_x, :grid_y, :is_regular_grid,
        :interpolate, :space, :projectionview, :model_f32c,
        :clip_planes, :cairo_uv_transform, :resolution, :computed_color,
    ]
    extract_attributes!(attr, inputs, :cairo_attributes)
    return draw_heatmap_or_imagelike(screen.context, RT !== SVG, attr[:cairo_attributes][])
end

function draw_atomic(scene::Scene, screen::Screen{RT}, plot::Image) where {RT}
    attr = plot.attributes
    image_grid!(image, attr)
    Makie.compute_colors!(attr)
    inputs = [
        :grid_x, :grid_y, :is_regular_grid, :image, :orientation,
        :interpolate, :space, :projectionview, :model_f32c,
        :clip_planes, :resolution, :computed_color,
    ]
    extract_attributes!(attr, inputs, :cairo_attributes)
    return draw_image(screen.context, RT !== SVG, attr[:cairo_attributes][])
end

# Heatmap keeps the original pattern-matrix dance (no orientation).
function heatmap_cairo_uv_transform!(attr)
    return map!(attr, [:uv_transform, :is_image], :cairo_uv_transform) do _T, _is_image
        return Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0)
    end
end

# Compose two Cairo affine matrices: returns a * b (so applying the resulting matrix to a
# point is equivalent to applying b first, then a).
function cairo_matmul(a::Cairo.CairoMatrix, b::Cairo.CairoMatrix)
    return Cairo.CairoMatrix(
        a.xx * b.xx + a.xy * b.yx,
        a.yx * b.xx + a.yy * b.yx,
        a.xx * b.xy + a.xy * b.yy,
        a.yx * b.xy + a.yy * b.yy,
        a.xx * b.x0 + a.xy * b.y0 + a.x0,
        a.yx * b.x0 + a.yy * b.y0 + a.y0,
    )
end

# Local matrix that maps a source surface (width=nrows, height=ncols, after
# `to_cairo_image`'s `permutedims`) onto a rect spanning `[xy, xy+(w, h)]` in the current
# user space such that user-matrix cell `mat[i, j]` lands at the rect cell named by
# `orientation`. Returned matrix is meant to be COMPOSED onto the current CTM, not used
# as the full CTM (it doesn't include the per-axis projection). Sign of `h` accounts for
# y-axis convention (negative for y-up).
function image_orientation_local_matrix(orientation, nrows::Integer, ncols::Integer, xy, w, h)
    swap = Makie.image_orientation_swap(orientation)
    flip_x, flip_y = Makie.image_orientation_flips(orientation)
    if swap
        a = d = 0.0f0
        b = (flip_x ? -1 : 1) * (w / ncols)
        c = (flip_y ? -1 : 1) * (h / nrows)
    else
        b = c = 0.0f0
        a = (flip_x ? -1 : 1) * (w / nrows)
        d = (flip_y ? -1 : 1) * (h / ncols)
    end
    e = xy[1] + (flip_x ? w : 0.0f0)
    f = xy[2] + (flip_y ? h : 0.0f0)
    return Cairo.CairoMatrix(a, c, b, d, e, f)
end

function draw_image(ctx, not_svg, attr)
    model = attr.model_f32c
    xs = attr.grid_x
    ys = attr.grid_y
    projectionview = attr.projectionview
    resolution = attr.resolution
    interpolate = attr.interpolate
    clip_planes = attr.clip_planes
    color_image = attr.computed_color
    space = attr.space
    orientation = attr.orientation

    is_vector = is_vector_backend(ctx)
    is_identity_transform = Makie.is_translation_scale_matrix(model)
    is_regular_grid = attr.is_regular_grid
    is_xy_aligned = Makie.is_translation_scale_matrix(projectionview)

    if interpolate && !is_identity_transform
        error("image with interpolate = true and a non-identity transform is not supported right now.")
    end

    xy = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(first(xs), first(ys)))
    xymax = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(last(xs), last(ys)))
    w, h = xymax .- xy

    can_use_fast_path = !(is_vector && !interpolate) && is_identity_transform &&
        (interpolate || is_xy_aligned) && isempty(clip_planes)

    if can_use_fast_path
        nrows, ncols = size(color_image)
        s = to_cairo_image(color_image)
        weird_cairo_limit = (2^15) - 23
        if s.width > weird_cairo_limit || s.height > weird_cairo_limit
            error("Cairo stops rendering images bigger than $(weird_cairo_limit), which is likely a bug in Cairo. Please resample your image/heatmap with heatmap(Resampler(data)).")
        end
        Cairo.save(ctx)
        Cairo.set_matrix(
            ctx, cairo_matmul(
                Cairo.get_matrix(ctx),
                image_orientation_local_matrix(orientation, nrows, ncols, xy, w, h)
            )
        )
        Cairo.rectangle(ctx, 0, 0, nrows, ncols)
        Cairo.set_source_surface(ctx, s, 0, 0)
        p = Cairo.get_source(ctx)
        if not_svg
            Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
        end
        Cairo.pattern_set_filter(p, interpolate ? Cairo.FILTER_BILINEAR : Cairo.FILTER_NEAREST)
        Cairo.fill(ctx)
        Cairo.restore(ctx)
        Cairo.pattern_set_extend(p, Cairo.EXTEND_NONE)
        Cairo.pattern_set_filter(p, Cairo.FILTER_FAST)
    else
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
        nrows, ncols = size(color_image)
        nx_cells, ny_cells = Makie.image_rect_cells(orientation, nrows, ncols)
        if nx_cells + 1 != length(xs) || ny_cells + 1 != length(ys)
            error("Error in conversion pipeline. xs and ys should have size nx_cells+1, ny_cells+1. Found: xs: $(length(xs)), ys: $(length(ys)), nx: $(nx_cells), ny: $(ny_cells)")
        end
        indexer = Makie.image_cell_to_matrix_index(orientation, nrows, ncols)
        _draw_oriented_image_rects(ctx, xys, nx_cells, ny_cells, color_image, indexer)
    end
    return
end

# Heatmap and uv_transform-driven legacy path. Kept around for Heatmap which doesn't
# go through orientation.
function draw_heatmap_or_imagelike(ctx, not_svg, attr)
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

    is_vector = is_vector_backend(ctx)
    is_identity_transform = Makie.is_translation_scale_matrix(model)
    is_regular_grid = attr.is_regular_grid
    is_xy_aligned = Makie.is_translation_scale_matrix(projectionview)

    if interpolate
        if !is_regular_grid
            error("$(typeof(xs)) with interpolate = true with a non-regular grid is not supported right now.")
        end
        if !is_identity_transform
            error("$(typeof(xs)) with interpolate = true with a non-identity transform is not supported right now.")
        end
    end

    xy = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(first(xs), first(ys)))
    xymax = cairo_project_to_screen_impl(projectionview, resolution, model, Point2(last(xs), last(ys)))
    w, h = xymax .- xy

    can_use_fast_path = !(is_vector && !interpolate) && is_regular_grid && is_identity_transform &&
        (interpolate || is_xy_aligned) && isempty(clip_planes)

    if can_use_fast_path
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
            Cairo.pattern_set_extend(p, Cairo.EXTEND_PAD)
        end
        Cairo.pattern_set_filter(p, interpolate ? Cairo.FILTER_BILINEAR : Cairo.FILTER_NEAREST)
        Cairo.fill(ctx)
        Cairo.restore(ctx)
        Cairo.pattern_set_extend(p, Cairo.EXTEND_NONE)
        Cairo.pattern_set_filter(p, Cairo.FILTER_FAST)
    else
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
        if ni + 1 != length(xs) || nj + 1 != length(ys)
            error("Error in conversion pipeline. xs and ys should have size ni+1, nj+1. Found: xs: $(length(xs)), ys: $(length(ys)), ni: $(ni), nj: $(nj)")
        end
        _draw_rect_heatmap(ctx, xys, ni, nj, color_image)
    end
    return
end

is_regularly_spaced(::AbstractRange) = true

function is_regularly_spaced(arr)
    length(arr) < 2 && return true
    mindiff = Inf
    maxdiff = -Inf
    for i in 2:length(arr)
        diff = arr[i] - arr[i - 1]
        mindiff = min(mindiff, diff)
        maxdiff = max(maxdiff, diff)
    end
    return maxdiff ≈ mindiff
end

function _draw_oriented_image_rects(ctx, xys, nx_cells, ny_cells, colors, indexer)
    return @inbounds for cx in 1:nx_cells, cy in 1:ny_cells
        p1 = xys[cx, cy]
        p2 = xys[cx + 1, cy]
        p3 = xys[cx + 1, cy + 1]
        p4 = xys[cx, cy + 1]
        if isnan(p1) || isnan(p2) || isnan(p3) || isnan(p4)
            continue
        end
        color = colors[indexer(cx, cy)]
        if alpha(color) == 1
            v1 = normalize(p2 - p1)
            v2 = normalize(p4 - p1)
            p2 += Float32(cx != nx_cells) * v1
            p3 += Float32(cx != nx_cells) * v1 + Float32(cy != ny_cells) * v2
            p4 += Float32(cy != ny_cells) * v2
        end
        Cairo.set_line_width(ctx, 0)
        Cairo.move_to(ctx, p1[1], p1[2])
        Cairo.line_to(ctx, p2[1], p2[2])
        Cairo.line_to(ctx, p3[1], p3[2])
        Cairo.line_to(ctx, p4[1], p4[2])
        Cairo.close_path(ctx)
        Cairo.set_source_rgba(ctx, rgbatuple(color)...)
        Cairo.fill(ctx)
    end
end

function _draw_rect_heatmap(ctx, xys, ni, nj, colors)
    return @inbounds for i in 1:ni, j in 1:nj
        p1 = xys[i, j]
        p2 = xys[i + 1, j]
        p3 = xys[i + 1, j + 1]
        p4 = xys[i, j + 1]
        if isnan(p1) || isnan(p2) || isnan(p3) || isnan(p4)
            continue
        end
        if alpha(colors[i, j]) == 1
            v1 = normalize(p2 - p1)
            v2 = normalize(p4 - p1)
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
