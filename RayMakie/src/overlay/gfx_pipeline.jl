# Graphics pipeline infrastructure for overlay rendering via Lava.jl
# Cached pipelines, atlas texture management, framebuffer utilities.

# ── Overlay framebuffer (per-screen, accessed via screen fields) ──

function get_overlay_framebuffer(screen, w::Int, h::Int)
    if screen.overlay_fb === nothing || screen.overlay_fb_size != (w, h)
        screen.overlay_fb = LavaFramebuffer(w, h;
            depth=false,
            color_format=Vulkan.FORMAT_R32G32B32A32_SFLOAT)
        screen.overlay_fb_size = (w, h)
    end
    return screen.overlay_fb
end

# ── Atlas texture (per-screen, accessed via screen fields) ──

function get_atlas_bindings(screen)
    atlas = Makie.get_texture_atlas()
    atlas_data = atlas.data
    atlas_len = length(atlas_data)

    if screen.gfx_atlas_size == atlas_len && screen.gfx_atlas_bindings !== nothing
        return screen.gfx_atlas_bindings
    end

    atlas_f32 = Float32.(atlas_data)
    tex = LavaTexture2D(atlas_f32)
    sampler = LavaSampler(; filter=:linear, wrap=:clamp)
    bindings = bind_textures([SampledTexture(tex, sampler)])

    screen.gfx_atlas_tex = tex
    screen.gfx_atlas_sampler = sampler
    screen.gfx_atlas_bindings = bindings
    screen.gfx_atlas_size = atlas_len
    return bindings
end

# ── Screen-to-NDC conversion (shared by vertex shaders) ──
#
# Y FLIP RATIONALE (DO NOT CHANGE — confirmed correct 2026-03-24):
#   Makie screen space: y=0 at bottom, y=h at top.
#   With negative viewport (0, h, w, -h), NDC y=-1 maps to fb bottom, y=+1 to fb top.
#   But Makie y=0 (bottom) should map to NDC y=+1 (top of viewport), so we NEGATE.
#   Formula: ndc_y = -(pos_y/res*2 - 1). Verified: screen_y=0 → ndc_y=+1, screen_y=h → ndc_y=-1.
#
# WRONG APPROACHES TRIED AND REVERTED:
#   - Adding +0.5px offset to pos (pixel center alignment) → worsened scores
#   - Using frag_coord_y instead of interpolated pos → wrong Y mapping
#   - Negating only Y without the full formula → inverted image
#   The Y mapping is ALREADY correct. Don't add pixel center offsets here.
@inline function screen_to_ndc(pos::Vec2f, res_x::Float32, res_y::Float32)
    ndc_x = pos[1] / res_x * 2f0 - 1f0
    ndc_y = -(pos[2] / res_y * 2f0 - 1f0)
    return Vec2f(ndc_x, ndc_y)
end

# Quad vertex positions for instanced rendering (2 triangles, 6 vertices)
# Returns offsets: c[1] = along-line direction (-1=p1, +1=p2), c[2] = perpendicular (-1 or +1)
#
# CRITICAL: The triangle split diagonal MUST go along the line direction (p1→p2),
# NOT perpendicular to it. The old split (BL,BR,TL + BR,TR,TL) had the diagonal
# from BR to TL which crossed perpendicular to the line. For elongated horizontal
# quads (axis spines: 440px wide, 2.6px tall), this diagonal crossed through the
# line center at every X position, leaving fragments on one side uncovered.
# The fix (2026-03-24) changed scores from ~0.049/panel to ~0.003/panel.
#
# DO NOT revert to the old BL,BR,TL + BR,TR,TL split.
@inline function quad_corner(vid::Int32)
    # T1: (p1,+n), (p2,+n), (p2,-n)  →  covers +n side of line
    # T2: (p1,+n), (p2,-n), (p1,-n)  →  covers -n side of line
    # Diagonal: (p1,+n)→(p2,-n) runs ALONG the line, not across it.
    if vid == Int32(1) || vid == Int32(4)
        return Vec2f(-1f0, 1f0)   # p1, +n side
    elseif vid == Int32(2)
        return Vec2f(1f0, 1f0)    # p2, +n side
    elseif vid == Int32(3) || vid == Int32(5)
        return Vec2f(1f0, -1f0)   # p2, -n side
    else  # vid == 6
        return Vec2f(-1f0, -1f0)  # p1, -n side
    end
end
