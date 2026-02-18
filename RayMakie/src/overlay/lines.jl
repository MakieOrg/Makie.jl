# ============================================================================
# Line Rasterization (KA Kernel Path)
# ============================================================================
# Uses KernelAbstractions for both CPU and GPU backends.
# Flow: project positions → build segments → rasterize per-pixel kernel.

using LinearAlgebra: norm, dot

# ============================================================================
# Segment Build Kernels
# ============================================================================

# Build segments for connected line strip: n-1 segments from n points
@kernel function build_line_strip_segments_kernel!(
    screen_p1, screen_p2, d1, d2, seg_colors,
    @Const(screen_pos), @Const(depths), @Const(visible),
    color::RGBA{Float32},
)
    i = @index(Global)
    @inbounds begin
        screen_p1[i] = screen_pos[i]
        screen_p2[i] = screen_pos[i + 1]
        d1[i] = depths[i]
        d2[i] = depths[i + 1]
        # Zero-alpha color for invisible segments (skipped by pixel kernel)
        vis = visible[i] == UInt32(1) && visible[i + 1] == UInt32(1)
        seg_colors[i] = ifelse(vis, color, RGBA{Float32}(0f0, 0f0, 0f0, 0f0))
    end
end

# Build segments for disconnected pairs: n/2 segments from n points
@kernel function build_line_pair_segments_kernel!(
    screen_p1, screen_p2, d1, d2, seg_colors,
    @Const(screen_pos), @Const(depths), @Const(visible),
    color::RGBA{Float32},
)
    i = @index(Global)
    @inbounds begin
        idx1 = 2 * i - 1
        idx2 = 2 * i
        screen_p1[i] = screen_pos[idx1]
        screen_p2[i] = screen_pos[idx2]
        d1[i] = depths[idx1]
        d2[i] = depths[idx2]
        vis = visible[idx1] == UInt32(1) && visible[idx2] == UInt32(1)
        seg_colors[i] = ifelse(vis, color, RGBA{Float32}(0f0, 0f0, 0f0, 0f0))
    end
end

# Per-vertex color variants
@kernel function build_line_strip_segments_percolor_kernel!(
    screen_p1, screen_p2, d1, d2, seg_colors,
    @Const(screen_pos), @Const(depths), @Const(visible),
    @Const(colors),
)
    i = @index(Global)
    @inbounds begin
        screen_p1[i] = screen_pos[i]
        screen_p2[i] = screen_pos[i + 1]
        d1[i] = depths[i]
        d2[i] = depths[i + 1]
        vis = visible[i] == UInt32(1) && visible[i + 1] == UInt32(1)
        seg_colors[i] = ifelse(vis, colors[i], RGBA{Float32}(0f0, 0f0, 0f0, 0f0))
    end
end

@kernel function build_line_pair_segments_percolor_kernel!(
    screen_p1, screen_p2, d1, d2, seg_colors,
    @Const(screen_pos), @Const(depths), @Const(visible),
    @Const(colors),
)
    i = @index(Global)
    @inbounds begin
        idx1 = 2 * i - 1
        idx2 = 2 * i
        screen_p1[i] = screen_pos[idx1]
        screen_p2[i] = screen_pos[idx2]
        d1[i] = depths[idx1]
        d2[i] = depths[idx2]
        vis = visible[idx1] == UInt32(1) && visible[idx2] == UInt32(1)
        seg_colors[i] = ifelse(vis, colors[idx1], RGBA{Float32}(0f0, 0f0, 0f0, 0f0))
    end
end

# ============================================================================
# Per-Pixel Rasterization Kernel
# ============================================================================

@inline function rasterize_lines_pixel!(
    overlay,
    depth_buffer,
    screen_p1,
    screen_p2,
    depth1,
    depth2,
    colors,
    linewidth::Float32,
    n_segments::Int32,
    px::Int,
    py::Int,
)
    h, w = size(overlay)

    # Bounds check
    (px < 1 || px > w || py < 1 || py > h) && return

    # Pixel centers at half-integer coords (matching OpenGL convention)
    p = Vec2f(Float32(px) - 0.5f0, Float32(py) - 0.5f0)
    result_color = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    half_lw = linewidth * 0.5f0
    rt_depth = @inbounds depth_buffer[h - py + 1, px]  # depth is bottom-up, screen is top-down

    # Check each segment
    @inbounds for seg_idx in 1:n_segments
        p1 = screen_p1[seg_idx]
        p2 = screen_p2[seg_idx]
        d1 = depth1[seg_idx]
        d2 = depth2[seg_idx]
        color = colors[seg_idx]

        # Skip invisible segments (alpha == 0)
        color.alpha < 0.001f0 && continue

        # Quick bounding box rejection
        margin = half_lw + ANTIALIAS_RADIUS
        min_x = min(p1[1], p2[1]) - margin
        max_x = max(p1[1], p2[1]) + margin
        min_y = min(p1[2], p2[2]) - margin
        max_y = max(p1[2], p2[2]) + margin

        (Float32(px) < min_x || Float32(px) > max_x) && continue
        (Float32(py) < min_y || Float32(py) > max_y) && continue

        # Compute distance to segment
        dir = p2 - p1
        line_len_sq = dot(dir, dir)

        t = if line_len_sq < 1f-10
            0f0
        else
            clamp(dot(p - p1, dir) / line_len_sq, 0f0, 1f0)
        end

        closest = p1 + t * dir
        dist = norm(p - closest)

        # Skip if too far
        dist > half_lw + ANTIALIAS_RADIUS && continue

        # Interpolate depth
        depth = d1 + t * (d2 - d1)

        # Depth test
        depth_bias = 0.001f0 * depth
        depth > rt_depth + depth_bias && continue

        # Coverage (positive inside: half_lw - dist > 0 means inside line)
        sdf = half_lw - dist
        coverage = aastep(0f0, sdf)
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

@kernel function rasterize_lines_kernel!(
    overlay,
    @Const(depth_buffer),
    @Const(screen_p1),
    @Const(screen_p2),
    @Const(depth1),
    @Const(depth2),
    @Const(colors),
    linewidth::Float32,
    n_segments::Int32,
)
    px, py = @index(Global, NTuple)
    rasterize_lines_pixel!(
        overlay, depth_buffer, screen_p1, screen_p2,
        depth1, depth2, colors, linewidth, n_segments, px, py
    )
end

# ============================================================================
# High-Level API: rasterize_lines! / rasterize_linesegments!
# ============================================================================
# These are the main entry points. They use KA kernels for both CPU and GPU,
# providing a single code path.

function rasterize_lines!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    color::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    linewidth::Float32;
    connect::Bool=true,
)
    n_points = length(positions)
    n_points < 2 && return

    backend = KernelAbstractions.get_backend(overlay)
    n_segs = connect ? (n_points - 1) : (n_points ÷ 2)
    n_segs < 1 && return

    # 1. Project positions
    screen_pos = KernelAbstractions.allocate(backend, Vec2f, n_points)
    depths = KernelAbstractions.allocate(backend, Float32, n_points)
    vis = KernelAbstractions.allocate(backend, UInt32, n_points)

    project_positions_kernel!(backend)(
        screen_pos, depths, vis, positions,
        ctx.view_proj, ctx.resolution[1], ctx.resolution[2];
        ndrange=n_points
    )

    # 2. Build segment arrays — dispatch scalar vs per-vertex color
    sp1 = KernelAbstractions.allocate(backend, Vec2f, n_segs)
    sp2 = KernelAbstractions.allocate(backend, Vec2f, n_segs)
    d1 = KernelAbstractions.allocate(backend, Float32, n_segs)
    d2 = KernelAbstractions.allocate(backend, Float32, n_segs)
    seg_colors = KernelAbstractions.allocate(backend, RGBA{Float32}, n_segs)

    if color isa RGBA{Float32}
        kernel = connect ? build_line_strip_segments_kernel! : build_line_pair_segments_kernel!
        kernel(backend)(
            sp1, sp2, d1, d2, seg_colors,
            screen_pos, depths, vis, color;
            ndrange=n_segs
        )
    else
        kernel = connect ? build_line_strip_segments_percolor_kernel! : build_line_pair_segments_percolor_kernel!
        kernel(backend)(
            sp1, sp2, d1, d2, seg_colors,
            screen_pos, depths, vis, color;
            ndrange=n_segs
        )
    end

    # 3. Rasterize (per-pixel kernel)
    h, w = size(overlay)
    rasterize_lines_kernel!(backend)(
        overlay, depth_buffer, sp1, sp2, d1, d2, seg_colors,
        linewidth, Int32(n_segs);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end

function rasterize_linesegments!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    color::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    linewidth::Float32,
)
    rasterize_lines!(overlay, depth_buffer, ctx, positions, color, linewidth; connect=false)
end

# Pre-allocated buffer variant: avoids per-frame GPU allocation.
# color can be a single RGBA{Float32} or a per-vertex AbstractVector{RGBA{Float32}}.
function rasterize_lines!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    color::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    linewidth::Float32,
    buffers::NamedTuple;
    connect::Bool=true,
)
    n_points = length(positions)
    n_points < 2 && return

    backend = KernelAbstractions.get_backend(overlay)
    n_segs = connect ? (n_points - 1) : (n_points ÷ 2)
    n_segs < 1 && return

    # 1. Project positions (reuse buffers)
    project_positions_kernel!(backend)(
        buffers.screen_pos, buffers.depth, buffers.visible, positions,
        ctx.view_proj, ctx.resolution[1], ctx.resolution[2];
        ndrange=n_points
    )

    # 2. Build segment arrays — dispatch scalar vs per-vertex color kernel
    if color isa RGBA{Float32}
        kernel = connect ? build_line_strip_segments_kernel! : build_line_pair_segments_kernel!
        kernel(backend)(
            buffers.screen_p1, buffers.screen_p2,
            buffers.d1, buffers.d2, buffers.seg_colors,
            buffers.screen_pos, buffers.depth, buffers.visible, color;
            ndrange=n_segs
        )
    else
        kernel = connect ? build_line_strip_segments_percolor_kernel! : build_line_pair_segments_percolor_kernel!
        kernel(backend)(
            buffers.screen_p1, buffers.screen_p2,
            buffers.d1, buffers.d2, buffers.seg_colors,
            buffers.screen_pos, buffers.depth, buffers.visible, color;
            ndrange=n_segs
        )
    end

    # 3. Rasterize (per-pixel kernel — same for both color modes)
    h, w = size(overlay)
    rasterize_lines_kernel!(backend)(
        overlay, depth_buffer,
        buffers.screen_p1, buffers.screen_p2,
        buffers.d1, buffers.d2, buffers.seg_colors,
        linewidth, Int32(n_segs);
        ndrange=(w, h)
    )
    KernelAbstractions.synchronize(backend)
end

# Allocate reusable buffers for line rasterization
function allocate_line_buffers(backend, n_positions::Int, connect::Bool)
    n_segs = connect ? (n_positions - 1) : (n_positions ÷ 2)
    return (
        screen_pos = KernelAbstractions.allocate(backend, Vec2f, n_positions),
        depth = KernelAbstractions.allocate(backend, Float32, n_positions),
        visible = KernelAbstractions.allocate(backend, UInt32, n_positions),
        screen_p1 = KernelAbstractions.allocate(backend, Vec2f, n_segs),
        screen_p2 = KernelAbstractions.allocate(backend, Vec2f, n_segs),
        d1 = KernelAbstractions.allocate(backend, Float32, n_segs),
        d2 = KernelAbstractions.allocate(backend, Float32, n_segs),
        seg_colors = KernelAbstractions.allocate(backend, RGBA{Float32}, n_segs),
    )
end
