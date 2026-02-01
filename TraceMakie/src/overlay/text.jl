# ============================================================================
# Text Rasterization
# ============================================================================
# GPU-ready text rasterization using Makie's glyph SDF atlas

using LinearAlgebra: norm

# Import Makie's texture atlas system
import Makie: TextureAtlas, get_texture_atlas, glyph_uv_width!

"""
    GlyphInstance

A single glyph to render, with pre-computed screen position and UV coordinates.
"""
struct GlyphInstance
    # Screen-space position (top-left of glyph quad)
    screen_pos::Vec2f
    # Screen-space size of glyph quad
    screen_size::Vec2f
    # View-space depth
    depth::Float32
    # UV bounds in atlas (u_min, v_min, u_max, v_max)
    uv_bounds::Vec4f
    # Color
    color::RGBA{Float32}
end

"""
    rasterize_text!(overlay, depth_buffer, ctx, glyphs, atlas)

Rasterize pre-computed glyph instances using the SDF atlas.

# Arguments
- `overlay`: RGBA output buffer (modified in place)
- `depth_buffer`: Ray-traced depth buffer for depth testing
- `ctx`: RasterContext (used for resolution info)
- `glyphs`: Vector of GlyphInstance structs
- `atlas`: Makie TextureAtlas containing glyph SDFs
"""
function rasterize_text!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    ctx::RasterContext,
    glyphs::AbstractVector{GlyphInstance},
    atlas::TextureAtlas,
)
    n_glyphs = length(glyphs)
    n_glyphs == 0 && return

    atlas_data = atlas.data
    atlas_size = Vec2f(size(atlas_data, 2), size(atlas_data, 1))  # (width, height)

    for glyph in glyphs
        rasterize_glyph!(overlay, depth_buffer, glyph, atlas_data, atlas_size)
    end
end

"""
    rasterize_glyph!(overlay, depth_buffer, glyph, atlas_data, atlas_size)

Rasterize a single glyph using SDF lookup from atlas.
"""
function rasterize_glyph!(
    overlay::AbstractMatrix{RGBA{Float32}},
    depth_buffer::AbstractMatrix{Float32},
    glyph::GlyphInstance,
    atlas_data::AbstractMatrix,
    atlas_size::Vec2f,
)
    h, w = size(overlay)

    # Glyph bounding box in screen space
    min_x = max(1, floor(Int, glyph.screen_pos[1]))
    max_x = min(w, ceil(Int, glyph.screen_pos[1] + glyph.screen_size[1]))
    min_y = max(1, floor(Int, glyph.screen_pos[2]))
    max_y = min(h, ceil(Int, glyph.screen_pos[2] + glyph.screen_size[2]))

    # Early exit if completely outside screen
    (max_x < min_x || max_y < min_y) && return

    # UV bounds in atlas
    u_min, v_min, u_max, v_max = glyph.uv_bounds[1], glyph.uv_bounds[2], glyph.uv_bounds[3], glyph.uv_bounds[4]

    # Rasterize glyph quad
    for py in min_y:max_y
        for px in min_x:max_x
            # Compute UV within glyph [0, 1]
            local_u = (Float32(px) - glyph.screen_pos[1]) / glyph.screen_size[1]
            local_v = (Float32(py) - glyph.screen_pos[2]) / glyph.screen_size[2]

            # Skip if outside glyph bounds
            (local_u < 0f0 || local_u > 1f0 || local_v < 0f0 || local_v > 1f0) && continue

            # Map to atlas UV coordinates
            # Flip both U and V to match Makie's UV convention
            atlas_u = u_max - local_u * (u_max - u_min)
            atlas_v = v_max - local_v * (v_max - v_min)

            # Sample SDF from atlas (bilinear interpolation)
            sdf = sample_atlas_bilinear(atlas_data, atlas_size, atlas_u, atlas_v)

            # The atlas stores distance values where positive = inside glyph
            # (This is the opposite of our other SDFs, so we negate for consistency)
            # Actually, looking at Makie's code, the SDF is stored such that
            # higher values are further from the edge, with ~0 at the edge
            # Let's use it directly: positive inside, negative outside

            # Depth test
            rt_depth = depth_buffer[py, px]
            depth_bias = 0.001f0 * glyph.depth
            glyph.depth > rt_depth + depth_bias && continue

            # The atlas SDF: edge is at glyph_padding (12), inside < 12, outside > 12
            # SDF values are in atlas pixel units
            edge_threshold = 12f0  # atlas.glyph_padding
            aa_width = 1.5f0
            coverage = clamp((edge_threshold - sdf + aa_width) / (2f0 * aa_width), 0f0, 1f0)
            coverage < 0.001f0 && continue

            # Apply alpha and blend
            alpha = glyph.color.alpha * coverage
            overlay[py, px] = alpha_blend(
                RGBA{Float32}(glyph.color.r, glyph.color.g, glyph.color.b, alpha),
                overlay[py, px]
            )
        end
    end
end

"""
    sample_atlas_bilinear(atlas_data, atlas_size, u, v)

Sample the atlas with bilinear interpolation.
u, v are in [0, 1] normalized coordinates.
"""
@inline function sample_atlas_bilinear(
    atlas_data::AbstractMatrix,
    atlas_size::Vec2f,
    u::Float32,
    v::Float32,
)
    # Convert normalized UV to pixel coordinates
    # Atlas is stored as (rows, cols) = (v, u) in Julia
    px = u * atlas_size[1]
    py = v * atlas_size[2]

    # Get integer and fractional parts
    x0 = floor(Int, px)
    y0 = floor(Int, py)
    x1 = x0 + 1
    y1 = y0 + 1
    fx = px - Float32(x0)
    fy = py - Float32(y0)

    # Clamp to valid range
    h, w = size(atlas_data)
    x0 = clamp(x0, 1, w)
    x1 = clamp(x1, 1, w)
    y0 = clamp(y0, 1, h)
    y1 = clamp(y1, 1, h)

    # Sample four corners (atlas is [row, col] = [y, x])
    v00 = Float32(atlas_data[y0, x0])
    v10 = Float32(atlas_data[y0, x1])
    v01 = Float32(atlas_data[y1, x0])
    v11 = Float32(atlas_data[y1, x1])

    # Bilinear interpolation
    v0 = v00 * (1f0 - fx) + v10 * fx
    v1 = v01 * (1f0 - fx) + v11 * fx
    return v0 * (1f0 - fy) + v1 * fy
end

"""
    prepare_text_glyphs(ctx, positions, strings, fonts, fontsizes, colors, atlas)

Convert text data into GlyphInstance vector for rendering.

This is a helper function that takes high-level text parameters and produces
the low-level glyph instances needed for rasterization.
"""
function prepare_text_glyphs(
    ctx::RasterContext,
    positions::AbstractVector{<:Point3f},
    strings::AbstractVector{<:AbstractString},
    fonts::AbstractVector,  # Vector of NativeFont
    fontsizes::Union{Float32, AbstractVector{Float32}},
    colors::Union{RGBA{Float32}, AbstractVector{<:RGBA{Float32}}},
    atlas::TextureAtlas,
)
    glyphs = GlyphInstance[]

    for (i, (pos, str, font)) in enumerate(zip(positions, strings, fonts))
        fontsize = fontsizes isa AbstractVector ? fontsizes[i] : fontsizes
        color = colors isa AbstractVector ? colors[i] : colors

        # Project anchor position
        screen_anchor, depth, visible = project(ctx, pos)
        !visible && continue

        # Render each character
        cursor_x = screen_anchor[1]
        cursor_y = screen_anchor[2]

        for char in str
            # Get glyph UV from atlas
            uv_rect = glyph_uv_width!(atlas, char, font)

            # Compute glyph size in screen pixels
            # The UV rect gives us the glyph's aspect ratio
            u_min, v_min, u_max, v_max = uv_rect[1], uv_rect[2], uv_rect[3], uv_rect[4]
            atlas_width = (u_max - u_min) * size(atlas.data, 2)
            atlas_height = (v_max - v_min) * size(atlas.data, 1)

            # Scale based on fontsize (rough approximation)
            scale = fontsize / atlas.pix_per_glyph
            glyph_width = atlas_width * scale
            glyph_height = atlas_height * scale

            push!(glyphs, GlyphInstance(
                Vec2f(cursor_x, cursor_y),
                Vec2f(glyph_width, glyph_height),
                depth,
                uv_rect,
                color
            ))

            # Advance cursor (simple monospace-like advance for now)
            # TODO: Use proper font metrics for advance width
            cursor_x += glyph_width * 0.9f0
        end
    end

    return glyphs
end

# ============================================================================
# GPU Kernel Version
# ============================================================================

"""
    rasterize_text_pixel!

Inner function for text rasterization at a single pixel.
Separated from kernel to allow normal control flow.
"""
@inline function rasterize_text_pixel!(
    overlay,
    depth_buffer,
    screen_positions,
    screen_sizes,
    depths,
    uv_bounds,
    colors,
    atlas_data,
    atlas_width::Int32,
    atlas_height::Int32,
    n_glyphs::Int32,
    px::Int,
    py::Int,
)
    h, w = size(overlay)

    # Bounds check
    (px < 1 || px > w || py < 1 || py > h) && return

    p = Vec2f(Float32(px), Float32(py))
    result_color = RGBA{Float32}(0f0, 0f0, 0f0, 0f0)
    rt_depth = depth_buffer[py, px]

    atlas_size = Vec2f(Float32(atlas_width), Float32(atlas_height))

    # Check each glyph
    @inbounds for i in 1:n_glyphs
        glyph_pos = screen_positions[i]
        glyph_size = screen_sizes[i]
        depth = depths[i]
        uv = uv_bounds[i]
        color = colors[i]

        # Quick bounding box rejection
        (p[1] < glyph_pos[1] || p[1] > glyph_pos[1] + glyph_size[1]) && continue
        (p[2] < glyph_pos[2] || p[2] > glyph_pos[2] + glyph_size[2]) && continue

        # Compute local UV within glyph
        local_u = (p[1] - glyph_pos[1]) / glyph_size[1]
        local_v = (p[2] - glyph_pos[2]) / glyph_size[2]

        # Map to atlas coordinates
        # Flip both U and V to match Makie's UV convention
        atlas_u = uv[3] - local_u * (uv[3] - uv[1])
        atlas_v = uv[4] - local_v * (uv[4] - uv[2])

        # Sample SDF
        sdf = sample_atlas_bilinear(atlas_data, atlas_size, atlas_u, atlas_v)

        # Depth test
        depth_bias = 0.001f0 * depth
        depth > rt_depth + depth_bias && continue

        # The atlas SDF: edge is at glyph_padding (12), inside < 12, outside > 12
        edge_threshold = 12f0
        aa_width = 1.5f0
        coverage = clamp((edge_threshold - sdf + aa_width) / (2f0 * aa_width), 0f0, 1f0)
        coverage < 0.001f0 && continue

        # Blend
        alpha = color.alpha * coverage
        result_color = alpha_blend(
            RGBA{Float32}(color.r, color.g, color.b, alpha),
            result_color
        )
    end

    # Write result
    @inbounds if result_color.alpha > 0.001f0
        overlay[py, px] = alpha_blend(result_color, overlay[py, px])
    end
    return
end

"""
    rasterize_text_kernel!

GPU kernel for parallel text rasterization.
"""
@kernel function rasterize_text_kernel!(
    overlay,
    @Const(depth_buffer),
    @Const(screen_positions),
    @Const(screen_sizes),
    @Const(depths),
    @Const(uv_bounds),
    @Const(colors),
    @Const(atlas_data),
    atlas_width::Int32,
    atlas_height::Int32,
    n_glyphs::Int32,
)
    px, py = @index(Global, NTuple)
    rasterize_text_pixel!(
        overlay, depth_buffer, screen_positions, screen_sizes,
        depths, uv_bounds, colors, atlas_data,
        atlas_width, atlas_height, n_glyphs, px, py
    )
end
