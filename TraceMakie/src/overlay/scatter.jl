# ============================================================================
# Scatter/Marker Rasterization (KA Kernel Path)
# ============================================================================
# Uses KernelAbstractions for both CPU and GPU backends.
# Flow: project positions → prepare marker data → rasterize per-pixel kernel.

using LinearAlgebra: norm

# ============================================================================
# Prepare Scatter Data Kernel
# ============================================================================

# Set invisible markers to zero size so they are skipped by the pixel kernel
@kernel function prepare_scatter_data_kernel!(
    colors_out, sizes_out,
    @Const(visible),
    color::RGBA{Float32},
    marker_size::Float32,
)
    i = @index(Global)
    @inbounds begin
        if visible[i] == UInt32(1)
            colors_out[i] = color
            sizes_out[i] = marker_size
        else
            colors_out[i] = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
            sizes_out[i] = 0f0
        end
    end
end

# ============================================================================
# Per-Pixel Rasterization Kernel
# ============================================================================

@inline function rasterize_scatter_pixel!(
    overlay,
    depth_buffer,
    screen_positions,
    depths,
    colors,
    sizes,
    shape::UInt8,
    n_markers::Int32,
    px::Int,
    py::Int,
)
    h, w = size(overlay)

    # Bounds check
    (px < 1 || px > w || py < 1 || py > h) && return

    p = Vec2f(Float32(px), Float32(py))
    result_color = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    rt_depth = @inbounds depth_buffer[h - py + 1, px]  # depth is bottom-up, screen is top-down

    # Check each marker
    @inbounds for i in 1:n_markers
        screen = screen_positions[i]
        depth = depths[i]
        color = colors[i]
        marker_size = sizes[i]
        half_size = marker_size * 0.5f0

        # Skip invisible markers (size == 0)
        marker_size < 0.001f0 && continue

        # Quick bounding box rejection
        margin = half_size + AA_RADIUS
        (abs(p[1] - screen[1]) > margin) && continue
        (abs(p[2] - screen[2]) > margin) && continue

        # Compute UV in marker space [0, 1]
        uv = Vec2f(
            (p[1] - screen[1]) / marker_size + 0.5f0,
            (p[2] - screen[2]) / marker_size + 0.5f0
        )

        # Evaluate SDF
        sdf = evaluate_shape_sdf(shape, uv)
        sdf_px = sdf * marker_size

        # Skip if too far
        sdf_px > AA_RADIUS && continue

        # Depth test
        depth_bias = 0.001f0 * depth
        depth > rt_depth + depth_bias && continue

        # Coverage
        coverage = aastep(0f0, sdf_px)
        coverage < 0.001f0 && continue

        # Blend (accumulate)
        alpha = color.alpha * coverage
        result_color = alpha_blend(
            RGBA{Float32}(color.r, color.g, color.b, alpha),
            result_color
        )
    end

    # Write result if any coverage
    @inbounds if result_color.alpha > 0.001f0
        overlay[py, px] = alpha_blend(result_color, overlay[py, px])
    end
    return
end

@kernel function rasterize_scatter_kernel!(
    overlay,
    @Const(depth_buffer),
    @Const(screen_positions),
    @Const(depths),
    @Const(colors),
    @Const(sizes),
    shape::UInt8,
    n_markers::Int32,
)
    px, py = @index(Global, NTuple)
    rasterize_scatter_pixel!(
        overlay, depth_buffer, screen_positions, depths,
        colors, sizes, shape, n_markers, px, py
    )
end

# ============================================================================
# High-Level API: rasterize_scatter!
# ============================================================================

function rasterize_scatter!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    color::RGBA{Float32},
    marker_size::Float32,
    shape::UInt8=CIRCLE,
)
    n = length(positions)
    n == 0 && return

    backend = KernelAbstractions.get_backend(overlay)

    # 1. Project positions
    screen_pos = KernelAbstractions.allocate(backend, Vec2f, n)
    depths = KernelAbstractions.allocate(backend, Float32, n)
    vis = KernelAbstractions.allocate(backend, UInt32, n)

    project_positions_kernel!(backend)(
        screen_pos, depths, vis, positions,
        ctx.view_proj, ctx.resolution[1], ctx.resolution[2];
        ndrange=n
    )

    # 2. Prepare per-marker data (set invisible markers to zero size)
    colors_arr = KernelAbstractions.allocate(backend, RGBA{Float32}, n)
    sizes_arr = KernelAbstractions.allocate(backend, Float32, n)

    prepare_scatter_data_kernel!(backend)(
        colors_arr, sizes_arr, vis, color, marker_size;
        ndrange=n
    )

    # 3. Rasterize (per-pixel kernel)
    h, w = size(overlay)
    rasterize_scatter_kernel!(backend)(
        overlay, depth_buffer, screen_pos, depths,
        colors_arr, sizes_arr, shape, Int32(n);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end

# Pre-allocated buffer variant
function rasterize_scatter!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    color::RGBA{Float32},
    marker_size::Float32,
    shape::UInt8,
    buffers::NamedTuple,
)
    n = length(positions)
    n == 0 && return

    backend = KernelAbstractions.get_backend(overlay)

    # 1. Project positions (reuse buffers)
    project_positions_kernel!(backend)(
        buffers.screen_pos, buffers.depth, buffers.visible, positions,
        ctx.view_proj, ctx.resolution[1], ctx.resolution[2];
        ndrange=n
    )

    # 2. Prepare per-marker data (reuse buffers)
    prepare_scatter_data_kernel!(backend)(
        buffers.colors, buffers.sizes, buffers.visible, color, marker_size;
        ndrange=n
    )

    # 3. Rasterize (per-pixel kernel)
    h, w = size(overlay)
    rasterize_scatter_kernel!(backend)(
        overlay, depth_buffer, buffers.screen_pos, buffers.depth,
        buffers.colors, buffers.sizes, shape, Int32(n);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end

# Allocate reusable buffers for scatter rasterization
function allocate_scatter_buffers(backend, n_positions::Int)
    return (
        screen_pos = KernelAbstractions.allocate(backend, Vec2f, n_positions),
        depth = KernelAbstractions.allocate(backend, Float32, n_positions),
        visible = KernelAbstractions.allocate(backend, UInt32, n_positions),
        colors = KernelAbstractions.allocate(backend, RGBA{Float32}, n_positions),
        sizes = KernelAbstractions.allocate(backend, Float32, n_positions),
    )
end
