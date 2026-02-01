# ============================================================================
# Primitive SDF Functions and Anti-Aliasing Utilities
# ============================================================================

# Anti-aliasing radius in pixels
const AA_RADIUS = 0.8f0

# Use norm from LinearAlgebra for vector length
using LinearAlgebra: norm, dot

# ============================================================================
# Smoothstep and AA utilities
# ============================================================================

"""
Smooth Hermite interpolation between 0 and 1 when x is in [edge0, edge1].
"""
@inline function smoothstep(edge0::Float32, edge1::Float32, x::Float32)
    t = clamp((x - edge0) / (edge1 - edge0), 0f0, 1f0)
    return t * t * (3f0 - 2f0 * t)
end

"""
Anti-aliased step function: smooth transition from 1 to 0 around threshold.
Returns 1 when dist << threshold, 0 when dist >> threshold.
"""
@inline function aastep(threshold::Float32, dist::Float32)
    return 1f0 - smoothstep(threshold - AA_RADIUS, threshold + AA_RADIUS, dist)
end

"""
Alpha blending using Porter-Duff "over" compositing.
Blends src over dst with the given source alpha.
"""
@inline function alpha_blend(src::RGBA{Float32}, dst::RGBA{Float32}, src_alpha::Float32)
    inv_alpha = 1f0 - src_alpha
    return RGBA{Float32}(
        src.r * src_alpha + dst.r * dst.alpha * inv_alpha,
        src.g * src_alpha + dst.g * dst.alpha * inv_alpha,
        src.b * src_alpha + dst.b * dst.alpha * inv_alpha,
        src_alpha + dst.alpha * inv_alpha  # Porter-Duff over
    )
end

@inline function alpha_blend(src::RGBA{Float32}, dst::RGBA{Float32})
    return alpha_blend(src, dst, src.alpha)
end

# ============================================================================
# Procedural SDF Functions
# ============================================================================
# All SDFs return negative values inside the shape, positive outside.
# The magnitude is the distance to the shape boundary in UV space [0,1].

"""
Circle SDF centered at (0.5, 0.5) with radius 0.5.
Returns negative inside, positive outside.
"""
@inline function circle_sdf(uv::Vec2f)
    return norm(uv - Vec2f(0.5f0, 0.5f0)) - 0.5f0
end

"""
Rectangle SDF centered at (0.5, 0.5) filling [0,1]x[0,1].
Returns negative inside, positive outside.
"""
@inline function rectangle_sdf(uv::Vec2f)
    d = abs.(uv - Vec2f(0.5f0, 0.5f0)) - Vec2f(0.5f0, 0.5f0)
    return norm(max.(d, Vec2f(0f0, 0f0))) + min(max(d[1], d[2]), 0f0)
end

"""
Rounded rectangle SDF with corner radius (in UV space).
"""
@inline function rounded_rect_sdf(uv::Vec2f, radius::Float32)
    r = min(radius, 0.5f0)
    d = abs.(uv - Vec2f(0.5f0, 0.5f0)) - Vec2f(0.5f0 - r, 0.5f0 - r)
    return norm(max.(d, Vec2f(0f0, 0f0))) + min(max(d[1], d[2]), 0f0) - r
end

"""
Diamond (rotated square) SDF centered at (0.5, 0.5).
"""
@inline function diamond_sdf(uv::Vec2f)
    p = abs.(uv - Vec2f(0.5f0, 0.5f0))
    return (p[1] + p[2] - 0.5f0) * 0.7071067811865476f0  # 1/sqrt(2)
end

"""
Triangle SDF pointing up, centered at (0.5, 0.5).
"""
@inline function triangle_sdf(uv::Vec2f)
    p = uv - Vec2f(0.5f0, 0.5f0)
    # Equilateral triangle pointing up
    k = 1.7320508075688772f0  # sqrt(3)
    px = abs(p[1]) - 0.5f0
    py = p[2] + 0.5f0 / k
    if px + k * py > 0f0
        p = Vec2f(px - k * py, -k * px - py) / 2f0
        px, py = p[1], p[2]
    end
    px = px - clamp(px, -1f0, 0f0)
    return -norm(Vec2f(px, py)) * sign(py)
end

"""
Cross/plus SDF centered at (0.5, 0.5).
"""
@inline function cross_sdf(uv::Vec2f, arm_width::Float32=0.15f0)
    p = abs.(uv - Vec2f(0.5f0, 0.5f0))
    # Union of horizontal and vertical rectangles
    h = rectangle_sdf(Vec2f(p[1] / 0.5f0 * 0.5f0, p[2] / arm_width * 0.5f0 + 0.5f0 - 0.5f0 * 0.5f0 / arm_width))
    v = rectangle_sdf(Vec2f(p[1] / arm_width * 0.5f0 + 0.5f0 - 0.5f0 * 0.5f0 / arm_width, p[2] / 0.5f0 * 0.5f0))
    return min(h, v)
end

"""
Hexagon SDF centered at (0.5, 0.5).
"""
@inline function hexagon_sdf(uv::Vec2f)
    p = abs.(uv - Vec2f(0.5f0, 0.5f0))
    k = Vec2f(-0.8660254037844387f0, 0.5f0)  # (-sqrt(3)/2, 0.5)
    p = p - 2f0 * min(dot(k, p), 0f0) * k
    p = p - Vec2f(clamp(p[1], -0.4f0, 0.4f0), 0.4f0)
    return norm(p) * sign(p[2])
end

"""
5-pointed star SDF centered at (0.5, 0.5).
"""
@inline function star_sdf(uv::Vec2f, inner_radius::Float32=0.2f0)
    p = uv - Vec2f(0.5f0, 0.5f0)
    # Polar coordinates
    angle = atan(p[2], p[1])
    r = norm(p)

    # Star shape: modulate radius based on angle (5 points)
    n = 5f0
    star_angle = mod(angle, 2f0 * Float32(pi) / n) - Float32(pi) / n
    star_r = 0.5f0 * (inner_radius + (0.5f0 - inner_radius) * cos(star_angle * n / 2f0))

    return r - star_r
end

# ============================================================================
# Line Distance Functions
# ============================================================================

"""
Distance from point p to line segment from a to b.
All coordinates in screen space (pixels).
"""
@inline function line_segment_distance(p::Vec2f, a::Vec2f, b::Vec2f)
    pa = p - a
    ba = b - a
    ba_len_sq = dot(ba, ba)
    # Handle degenerate segment (point)
    if ba_len_sq < 1f-10
        return norm(pa)
    end
    t = clamp(dot(pa, ba) / ba_len_sq, 0f0, 1f0)
    return norm(pa - t * ba)
end

"""
Signed distance from point p to infinite line through a and b.
Positive on one side, negative on the other.
"""
@inline function line_signed_distance(p::Vec2f, a::Vec2f, b::Vec2f)
    ba = b - a
    pa = p - a
    # Cross product in 2D gives signed area
    return (ba[1] * pa[2] - ba[2] * pa[1]) / norm(ba)
end

# ============================================================================
# Shape Evaluation
# ============================================================================

"""
Evaluate SDF for the given shape type.
Returns negative inside, positive outside (in UV space [0,1]).
"""
@inline function evaluate_shape_sdf(shape::UInt8, uv::Vec2f)
    if shape == CIRCLE
        return circle_sdf(uv)
    elseif shape == RECTANGLE
        return rectangle_sdf(uv)
    elseif shape == ROUNDED_RECTANGLE
        return rounded_rect_sdf(uv, 0.1f0)
    elseif shape == TRIANGLE
        return triangle_sdf(uv)
    elseif shape == CROSS
        return cross_sdf(uv)
    elseif shape == DIAMOND
        return diamond_sdf(uv)
    elseif shape == HEXAGON
        return hexagon_sdf(uv)
    elseif shape == STAR
        return star_sdf(uv)
    else
        # Default to circle
        return circle_sdf(uv)
    end
end
