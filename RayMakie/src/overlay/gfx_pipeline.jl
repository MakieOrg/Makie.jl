# Graphics pipeline infrastructure for overlay rendering via Lava.jl
# Cached pipelines, atlas texture management, framebuffer utilities.

# ── Overlay framebuffer (per-screen, accessed via screen fields) ──

function get_overlay_framebuffer(screen, w::Int, h::Int)
    if screen.overlay_fb === nothing || screen.overlay_fb_size != (w, h)
        screen.overlay_fb = Framebuffer(screen.config.device, w, h;
            depth=false,
            color_format=RGBA{Float32})
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
    tex = Texture2D(screen.config.device, atlas_f32)
    sampler = Sampler(screen.config.device; filter=:linear, wrap=:clamp)
    bindings = bind_textures([SampledTexture(tex, sampler)])

    screen.gfx_atlas_tex = tex
    screen.gfx_atlas_sampler = sampler
    screen.gfx_atlas_bindings = bindings
    screen.gfx_atlas_size = atlas_len
    return bindings
end

# ── Depth: OpenGL's clip range to this one ──────────────────────────────────
#
# Makie's cameras build OpenGL-convention projections, where a visible point has
# clip z in `[-w, w]`. Vulkan and Metal both keep `[0, w]` and clip everything
# below it, so a GL matrix has to be remapped or half its range is thrown away.
#
# What that cost was an `Axis` with no frame and no tick marks. Makie stacks its
# decorations in z — the ticks at 10 and the spines at 20 — and with the pixel
# camera's `-0.0001` z scale those became clip z of -0.001 and -0.002: inside GL's
# range, just outside this one, and clipped away by the near plane while the
# background at z = -100 (clip z +0.01) came through. Nothing reported it, because
# a clipped primitive is not an error.
#
# `0.5 * (z + w)`, which is the standard GL-to-Vulkan depth remap and leaves the
# ordering it encodes untouched.
@inline gl_to_clip_depth(clip::Vec4f) =
    Vec4f(clip[1], clip[2], 0.5f0 * (clip[3] + clip[4]), clip[4])

# ── Screen-to-NDC conversion (shared by vertex shaders) ──
#
# Y FLIP RATIONALE:
#   Makie screen space: y=0 at bottom, y=h at top.
#   With negative viewport (0, h, w, -h), NDC y=-1 maps to fb bottom, y=+1 to fb top.
#   But Makie y=0 (bottom) should map to NDC y=+1 (top of viewport), so we NEGATE.
#   Formula: ndc_y = -(pos_y/res*2 - 1). Verified: screen_y=0 → ndc_y=+1, screen_y=h → ndc_y=-1.
#
# That negation is the ONLY one a shader here writes. `KernelInterface.clip_y` is
# NOT for this and used to be called on the `position` these stages return: it
# answers "this backend's clip y given the portable one", and the backend ALREADY
# applies it to every position a stage writes. Calling it here applied the mirror
# a second time, which on Vulkan is invisible (there it is the identity) and on
# Metal drew every sprite and every glyph upside down — text at the bottom of a
# figure came out at the top, mirrored. The lines stages called it twice, in the
# vertex and again in the geometry, which cancelled and hid the same mistake.
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
