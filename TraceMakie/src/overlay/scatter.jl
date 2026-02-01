# ============================================================================
# Scatter/Marker Rasterization
# ============================================================================
# GPU-ready marker rasterization using procedural SDFs

using LinearAlgebra: norm

"""
    rasterize_scatter!(overlay, depth_buffer, ctx, positions, colors, sizes, shape)

Rasterize scatter markers at 3D positions.

# Arguments
- `overlay`: RGBA output buffer (modified in place)
- `depth_buffer`: Ray-traced depth buffer for depth testing
- `ctx`: RasterContext with projection info
- `positions`: Vector of 3D world-space marker positions
- `colors`: Single color or per-marker colors
- `sizes`: Single size or per-marker sizes (in pixels)
- `shape`: Marker shape (CIRCLE, RECTANGLE, etc.)
"""
function rasterize_scatter!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    colors::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    sizes::Union{Float32, AbstractVector{Float32}},
    shape::UInt8=CIRCLE,
)
    n_markers = length(positions)
    n_markers == 0 && return

    for i in 1:n_markers
        pos = positions[i]
        color = colors isa AbstractVector ? colors[i] : colors
        marker_size = sizes isa AbstractVector ? sizes[i] : sizes

        # Project to screen space
        screen, depth, visible = project(ctx, pos)
        !visible && continue

        # Rasterize this marker
        rasterize_marker!(overlay, depth_buffer, ctx.resolution, screen, depth, color, marker_size, shape)
    end
end

"""
    rasterize_marker!(overlay, depth_buffer, resolution, screen, depth, color, size, shape)

Rasterize a single marker at screen position.
"""
function rasterize_marker!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    resolution::Vec2f,
    screen::Vec2f,
    depth::Float32,
    color::RGBA{Float32},
    marker_size::Float32,
    shape::UInt8,
)
    h, w = size(overlay)
    half_size = marker_size * 0.5f0

    # Bounding box with AA padding
    padding = AA_RADIUS + 1f0
    min_x = max(1, floor(Int, screen[1] - half_size - padding))
    max_x = min(w, ceil(Int, screen[1] + half_size + padding))
    min_y = max(1, floor(Int, screen[2] - half_size - padding))
    max_y = min(h, ceil(Int, screen[2] + half_size + padding))

    # Early exit if completely outside screen
    (max_x < min_x || max_y < min_y) && return

    # Rasterize bounding box
    for py in min_y:max_y
        for px in min_x:max_x
            # Compute UV in marker space [0, 1]
            uv = Vec2f(
                (Float32(px) - screen[1]) / marker_size + 0.5f0,
                (Float32(py) - screen[2]) / marker_size + 0.5f0
            )

            # Evaluate SDF (negative inside, positive outside)
            sdf = evaluate_shape_sdf(shape, uv)

            # Scale SDF to pixel units
            sdf_px = sdf * marker_size

            # Skip if too far outside
            sdf_px > AA_RADIUS && continue

            # Depth test
            rt_depth = depth_buffer[py, px]
            depth_bias = 0.001f0 * depth
            depth > rt_depth + depth_bias && continue

            # Compute coverage using anti-aliasing
            coverage = aastep(0f0, sdf_px)
            coverage < 0.001f0 && continue

            # Apply alpha and blend
            alpha = color.alpha * coverage
            overlay[py, px] = alpha_blend(
                RGBA{Float32}(color.r, color.g, color.b, alpha),
                overlay[py, px]
            )
        end
    end
end

"""
    rasterize_scatter_world_size!(overlay, depth_buffer, ctx, positions, colors, sizes, shape)

Rasterize scatter markers with world-space sizes (sizes scale with perspective).
"""
function rasterize_scatter_world_size!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    colors::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    world_sizes::Union{Float32, AbstractVector{Float32}},
    shape::UInt8=CIRCLE,
)
    n_markers = length(positions)
    n_markers == 0 && return

    for i in 1:n_markers
        pos = positions[i]
        color = colors isa AbstractVector ? colors[i] : colors
        world_size = world_sizes isa AbstractVector ? world_sizes[i] : world_sizes

        # Project to screen space with size
        screen, depth, visible, screen_size = project_with_scale(ctx, pos, world_size)
        !visible && continue

        # Use screen-space size for rasterization
        rasterize_marker!(overlay, depth_buffer, ctx.resolution, screen, depth, color, screen_size, shape)
    end
end

# ============================================================================
# GPU Kernel Version
# ============================================================================

"""
    rasterize_scatter_pixel!

Inner function for scatter rasterization at a single pixel.
Separated from kernel to allow normal control flow.
"""
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
    rt_depth = depth_buffer[py, px]

    # Check each marker
    @inbounds for i in 1:n_markers
        screen = screen_positions[i]
        depth = depths[i]
        color = colors[i]
        marker_size = sizes[i]
        half_size = marker_size * 0.5f0

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

"""
    rasterize_scatter_kernel!

GPU kernel for parallel scatter rasterization.
Each thread handles one pixel, checking all markers.
"""
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

"""
    rasterize_scatter_per_marker_kernel!

Alternative GPU kernel where each thread handles one marker.
Better for scenes with many markers but sparse coverage.
"""
@kernel function rasterize_scatter_per_marker_kernel!(
    overlay,
    @Const(depth_buffer),
    @Const(screen_positions),
    @Const(depths),
    @Const(colors),
    @Const(sizes),
    shape::UInt8,
)
    marker_idx = @index(Global)
    h, w = size(overlay)

    @inbounds begin
        screen = screen_positions[marker_idx]
        depth = depths[marker_idx]
        color = colors[marker_idx]
        marker_size = sizes[marker_idx]
        half_size = marker_size * 0.5f0

        # Bounding box
        padding = AA_RADIUS + 1f0
        min_x = max(Int32(1), floor(Int32, screen[1] - half_size - padding))
        max_x = min(Int32(w), ceil(Int32, screen[1] + half_size + padding))
        min_y = max(Int32(1), floor(Int32, screen[2] - half_size - padding))
        max_y = min(Int32(h), ceil(Int32, screen[2] + half_size + padding))

        # Rasterize bounding box
        for py in min_y:max_y
            for px in min_x:max_x
                p = Vec2f(Float32(px), Float32(py))

                # UV in marker space
                uv = Vec2f(
                    (p[1] - screen[1]) / marker_size + 0.5f0,
                    (p[2] - screen[2]) / marker_size + 0.5f0
                )

                # SDF evaluation
                sdf = evaluate_shape_sdf(shape, uv)
                sdf_px = sdf * marker_size

                sdf_px > AA_RADIUS && continue

                # Depth test
                rt_depth = depth_buffer[py, px]
                depth_bias = 0.001f0 * depth
                depth > rt_depth + depth_bias && continue

                # Coverage and blend
                coverage = aastep(0f0, sdf_px)
                coverage < 0.001f0 && continue

                alpha = color.alpha * coverage
                # Note: This has race conditions! Use atomics or sort by depth
                overlay[py, px] = alpha_blend(
                    RGBA{Float32}(color.r, color.g, color.b, alpha),
                    overlay[py, px]
                )
            end
        end
    end
end
