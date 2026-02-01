# ============================================================================
# Line Rasterization
# ============================================================================
# GPU-ready line segment rasterization with anti-aliasing and depth testing

using LinearAlgebra: norm, dot

"""
    LineSegment

A single line segment with screen-space coordinates and depth.
"""
struct LineSegment
    # Screen-space endpoints
    p1::Vec2f
    p2::Vec2f
    # View-space depths at endpoints
    d1::Float32
    d2::Float32
    # Color (with alpha)
    color::RGBA{Float32}
    # Line width in pixels
    linewidth::Float32
end

"""
    rasterize_lines!(overlay, depth_buffer, ctx, positions, colors, linewidth; connect=true)

Rasterize connected line strip or individual segments.

# Arguments
- `overlay`: RGBA output buffer (modified in place)
- `depth_buffer`: Ray-traced depth buffer for depth testing
- `ctx`: RasterContext with projection info
- `positions`: Vector of 3D world-space points
- `colors`: Single color or per-vertex colors
- `linewidth`: Line width in pixels
- `connect`: If true, treat as connected line strip; if false, treat as pairs of segments
"""
function rasterize_lines!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    colors::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    linewidth::Float32;
    connect::Bool=true,
)
    n_points = length(positions)
    n_points < 2 && return

    # Project all points to screen space
    screen_points = Vector{Vec2f}(undef, n_points)
    depths = Vector{Float32}(undef, n_points)
    visible = Vector{Bool}(undef, n_points)

    for i in 1:n_points
        screen_points[i], depths[i], visible[i] = project(ctx, positions[i])
    end

    # Determine segments based on connect mode
    if connect
        # Connected line strip: n-1 segments
        for i in 1:(n_points - 1)
            # Skip if either endpoint is behind camera
            (!visible[i] || !visible[i + 1]) && continue

            color = colors isa AbstractVector ? colors[i] : colors
            seg = LineSegment(
                screen_points[i], screen_points[i + 1],
                depths[i], depths[i + 1],
                color, linewidth
            )
            rasterize_segment!(overlay, depth_buffer, ctx.resolution, seg)
        end
    else
        # Disconnected segments: pairs of points
        for i in 1:2:(n_points - 1)
            (!visible[i] || !visible[i + 1]) && continue

            color = colors isa AbstractVector ? colors[i] : colors
            seg = LineSegment(
                screen_points[i], screen_points[i + 1],
                depths[i], depths[i + 1],
                color, linewidth
            )
            rasterize_segment!(overlay, depth_buffer, ctx.resolution, seg)
        end
    end
end

"""
    rasterize_linesegments!(overlay, depth_buffer, ctx, positions, colors, linewidth)

Rasterize disconnected line segments (pairs of points).
"""
function rasterize_linesegments!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    colors::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    linewidth::Float32,
)
    rasterize_lines!(overlay, depth_buffer, ctx, positions, colors, linewidth; connect=false)
end

"""
    rasterize_segment!(overlay, depth_buffer, resolution, seg)

Rasterize a single line segment with anti-aliasing and depth testing.
Uses analytical line distance for smooth edges.
"""
function rasterize_segment!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    resolution::Vec2f,
    seg::LineSegment,
)
    h, w = size(overlay)

    # Compute bounding box with AA padding
    half_width = seg.linewidth * 0.5f0 + AA_RADIUS + 1f0
    min_x = max(1, floor(Int, min(seg.p1[1], seg.p2[1]) - half_width))
    max_x = min(w, ceil(Int, max(seg.p1[1], seg.p2[1]) + half_width))
    min_y = max(1, floor(Int, min(seg.p1[2], seg.p2[2]) - half_width))
    max_y = min(h, ceil(Int, max(seg.p1[2], seg.p2[2]) + half_width))

    # Early exit if completely outside screen
    (max_x < min_x || max_y < min_y) && return

    # Line direction and length
    dir = seg.p2 - seg.p1
    line_len_sq = dot(dir, dir)
    line_len = sqrt(line_len_sq)

    # Handle degenerate line (point)
    if line_len < 1f-6
        # Just draw a circle at p1
        rasterize_point!(overlay, depth_buffer, seg.p1, seg.d1, seg.color, seg.linewidth)
        return
    end

    # Normalized direction
    dir_norm = dir / line_len

    # Rasterize bounding box
    for py in min_y:max_y
        for px in min_x:max_x
            p = Vec2f(Float32(px), Float32(py))

            # Compute distance to line segment
            pa = p - seg.p1
            t = clamp(dot(pa, dir) / line_len_sq, 0f0, 1f0)

            # Closest point on segment
            closest = seg.p1 + t * dir
            dist = norm(p - closest)

            # Line half-width
            half_lw = seg.linewidth * 0.5f0

            # Skip if too far from line
            dist > half_lw + AA_RADIUS && continue

            # Interpolate depth along segment
            depth = seg.d1 + t * (seg.d2 - seg.d1)

            # Depth test (with small bias)
            rt_depth = depth_buffer[py, px]
            depth_bias = 0.001f0 * depth
            depth > rt_depth + depth_bias && continue

            # Compute coverage using SDF-based anti-aliasing
            sdf = dist - half_lw
            coverage = aastep(0f0, sdf)

            # Skip if no coverage
            coverage < 0.001f0 && continue

            # Apply alpha and blend
            alpha = seg.color.alpha * coverage
            overlay[py, px] = alpha_blend(
                RGBA{Float32}(seg.color.r, seg.color.g, seg.color.b, alpha),
                overlay[py, px]
            )
        end
    end
end

"""
    rasterize_point!(overlay, depth_buffer, center, depth, color, size)

Rasterize a single point as a filled circle (helper for degenerate lines).
"""
function rasterize_point!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    center::Vec2f,
    depth::Float32,
    color::RGBA{Float32},
    size::Float32,
)
    h, w = size(overlay)
    radius = size * 0.5f0

    min_x = max(1, floor(Int, center[1] - radius - AA_RADIUS))
    max_x = min(w, ceil(Int, center[1] + radius + AA_RADIUS))
    min_y = max(1, floor(Int, center[2] - radius - AA_RADIUS))
    max_y = min(h, ceil(Int, center[2] + radius + AA_RADIUS))

    for py in min_y:max_y
        for px in min_x:max_x
            p = Vec2f(Float32(px), Float32(py))
            dist = norm(p - center)

            sdf = dist - radius
            sdf > AA_RADIUS && continue

            rt_depth = depth_buffer[py, px]
            depth > rt_depth + 0.001f0 * depth && continue

            coverage = aastep(0f0, sdf)
            coverage < 0.001f0 && continue

            alpha = color.alpha * coverage
            overlay[py, px] = alpha_blend(
                RGBA{Float32}(color.r, color.g, color.b, alpha),
                overlay[py, px]
            )
        end
    end
end

# ============================================================================
# GPU Kernel Version (for KernelAbstractions)
# ============================================================================

"""
    rasterize_lines_pixel!

Inner function for line rasterization at a single pixel.
Separated from kernel to allow normal control flow.
"""
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

    p = Vec2f(Float32(px), Float32(py))
    result_color = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    half_lw = linewidth * 0.5f0
    rt_depth = depth_buffer[py, px]

    # Check each segment
    @inbounds for seg_idx in 1:n_segments
        p1 = screen_p1[seg_idx]
        p2 = screen_p2[seg_idx]
        d1 = depth1[seg_idx]
        d2 = depth2[seg_idx]
        color = colors[seg_idx]

        # Quick bounding box rejection
        margin = half_lw + AA_RADIUS
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
        dist > half_lw + AA_RADIUS && continue

        # Interpolate depth
        depth = d1 + t * (d2 - d1)

        # Depth test
        depth_bias = 0.001f0 * depth
        depth > rt_depth + depth_bias && continue

        # Coverage
        sdf = dist - half_lw
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

"""
    rasterize_lines_kernel!

GPU kernel for parallel line rasterization.
Each thread handles one pixel in the bounding box of all lines.
"""
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
