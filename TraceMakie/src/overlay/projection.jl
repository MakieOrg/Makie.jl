# ============================================================================
# Projection Utilities for Overlay Rasterization
# ============================================================================

"""
    RasterContext

Holds camera projection information for rasterizing 3D primitives to screen space.
"""
struct RasterContext
    # Combined view-projection matrix (used by lines and position projection)
    view_proj::Mat4f
    # Inverse view-projection for unprojection (if needed)
    inv_view_proj::Mat4f
    # Separate projection and view matrices (used by sprite transform pipeline)
    projection::Mat4f
    view_mat::Mat4f
    # Screen resolution (width, height)
    resolution::Vec2f
    # Pixels per unit (display scaling)
    px_per_unit::Float32
    # Camera near/far planes
    near::Float32
    far::Float32
end

function RasterContext(
    view_proj::Mat4f, projection::Mat4f, view_mat::Mat4f,
    resolution::Vec2f;
    px_per_unit::Float32=1f0, near::Float32=0.1f0, far::Float32=1000f0,
)
    inv_vp = Mat4f(inv(view_proj))
    return RasterContext(view_proj, inv_vp, projection, view_mat, resolution, px_per_unit, near, far)
end

# Convenience constructor for lines-only use (no separate proj/view needed)
function RasterContext(view_proj::Mat4f, resolution::Vec2f; near::Float32=0.1f0, far::Float32=1000f0)
    inv_vp = Mat4f(inv(view_proj))
    proj = Mat4f(I)
    view_m = Mat4f(I)
    return RasterContext(view_proj, inv_vp, proj, view_m, resolution, 1f0, near, far)
end

"""
    project(ctx::RasterContext, p::Point3f) -> (screen::Vec2f, depth::Float32, visible::Bool)

Project a 3D world-space point to screen coordinates.

Returns:
- `screen`: Screen-space position (x, y) in pixels, origin at top-left
- `depth`: View-space depth (positive = in front of camera)
- `visible`: Whether the point is in front of the camera
"""
@inline function project(ctx::RasterContext, p::Point3f)
    # Transform to clip space
    p4 = Vec4f(p[1], p[2], p[3], 1f0)
    clip = ctx.view_proj * p4

    # Check if behind camera (w <= 0 means behind or at camera plane)
    visible = clip[4] > 0f0

    # Perspective divide to NDC [-1, 1]
    # Guard against division by zero
    inv_w = ifelse(abs(clip[4]) > 1f-10, 1f0 / clip[4], 0f0)
    ndc_x = clip[1] * inv_w
    ndc_y = clip[2] * inv_w

    # NDC to screen coordinates
    # Makie's NDC: Y=1 at top, Y=-1 at bottom
    # We need Y flip: NDC Y=1 -> screen Y=0 (top row)
    screen_x = (ndc_x * 0.5f0 + 0.5f0) * ctx.resolution[1]
    screen_y = (1f0 - (ndc_y * 0.5f0 + 0.5f0)) * ctx.resolution[2]

    # Use clip.w as depth (view-space Z, positive in front)
    # This matches the ray-traced depth buffer format
    depth = clip[4]

    return Vec2f(screen_x, screen_y), depth, visible
end

"""
    project_with_scale(ctx::RasterContext, p::Point3f, world_size::Float32) -> (screen, depth, visible, screen_size)

Project a point and also compute how a world-space size transforms to screen-space.
Useful for markers that have a world-space size.
"""
@inline function project_with_scale(ctx::RasterContext, p::Point3f, world_size::Float32)
    screen, depth, visible = project(ctx, p)

    # Compute screen-space size by projecting a nearby point
    # Use a point offset in the camera-right direction
    p2 = Point3f(p[1] + world_size, p[2], p[3])
    screen2, _, _ = project(ctx, p2)
    screen_size = norm(screen2 - screen)

    return screen, depth, visible, screen_size
end

"""
    is_in_screen(screen::Vec2f, resolution::Vec2f, margin::Float32=0f0) -> Bool

Check if a screen-space point is within the screen bounds (with optional margin).
"""
@inline function is_in_screen(screen::Vec2f, resolution::Vec2f, margin::Float32=0f0)
    return screen[1] >= -margin &&
           screen[1] <= resolution[1] + margin &&
           screen[2] >= -margin &&
           screen[2] <= resolution[2] + margin
end

# ============================================================================
# GPU Projection Kernel
# ============================================================================

@kernel function project_positions_kernel!(
    screen_out,
    depth_out,
    visible_out,
    @Const(positions),
    view_proj::Mat4f,
    resolution_x::Float32,
    resolution_y::Float32,
)
    i = @index(Global)
    @inbounds begin
        p = positions[i]
        p4 = Vec4f(p[1], p[2], p[3], 1f0)
        clip = view_proj * p4

        vis = clip[4] > 0f0
        inv_w = ifelse(abs(clip[4]) > 1f-10, 1f0 / clip[4], 0f0)
        ndc_x = clip[1] * inv_w
        ndc_y = clip[2] * inv_w

        screen_x = (ndc_x * 0.5f0 + 0.5f0) * resolution_x
        screen_y = (1f0 - (ndc_y * 0.5f0 + 0.5f0)) * resolution_y

        screen_out[i] = Vec2f(screen_x, screen_y)
        depth_out[i] = clip[4]
        visible_out[i] = UInt32(vis)
    end
end

"""
    clip_line_to_screen(a::Vec2f, b::Vec2f, resolution::Vec2f) -> (a_clipped, b_clipped, visible)

Clip a line segment to the screen bounds using Cohen-Sutherland algorithm.
Returns clipped endpoints and whether any part of the line is visible.
"""
function clip_line_to_screen(a::Vec2f, b::Vec2f, resolution::Vec2f)
    # Cohen-Sutherland outcodes
    LEFT = 0x01
    RIGHT = 0x02
    BOTTOM = 0x04
    TOP = 0x08

    function outcode(p::Vec2f)
        code = 0x00
        if p[1] < 0f0
            code |= LEFT
        elseif p[1] > resolution[1]
            code |= RIGHT
        end
        if p[2] < 0f0
            code |= TOP
        elseif p[2] > resolution[2]
            code |= BOTTOM
        end
        return code
    end

    x0, y0 = a[1], a[2]
    x1, y1 = b[1], b[2]
    xmin, ymin = 0f0, 0f0
    xmax, ymax = resolution[1], resolution[2]

    outcode0 = outcode(Vec2f(x0, y0))
    outcode1 = outcode(Vec2f(x1, y1))

    while true
        if (outcode0 | outcode1) == 0x00
            # Both inside
            return Vec2f(x0, y0), Vec2f(x1, y1), true
        elseif (outcode0 & outcode1) != 0x00
            # Both outside same region
            return a, b, false
        else
            # Some clipping needed
            outcodeOut = outcode0 != 0x00 ? outcode0 : outcode1
            x, y = 0f0, 0f0

            if (outcodeOut & TOP) != 0x00
                x = x0 + (x1 - x0) * (ymin - y0) / (y1 - y0)
                y = ymin
            elseif (outcodeOut & BOTTOM) != 0x00
                x = x0 + (x1 - x0) * (ymax - y0) / (y1 - y0)
                y = ymax
            elseif (outcodeOut & RIGHT) != 0x00
                y = y0 + (y1 - y0) * (xmax - x0) / (x1 - x0)
                x = xmax
            elseif (outcodeOut & LEFT) != 0x00
                y = y0 + (y1 - y0) * (xmin - x0) / (x1 - x0)
                x = xmin
            end

            if outcodeOut == outcode0
                x0, y0 = x, y
                outcode0 = outcode(Vec2f(x0, y0))
            else
                x1, y1 = x, y
                outcode1 = outcode(Vec2f(x1, y1))
            end
        end
    end
end
