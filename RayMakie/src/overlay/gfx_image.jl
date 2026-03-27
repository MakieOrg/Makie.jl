# Graphics pipeline image/heatmap rendering for overlay.
# Renders a textured quad using hardware texture sampling.
# Vertex shader expands screen-space corners to a quad with UV interpolation.
# Fragment shader samples the RGBA texture at interpolated UV.

function get_image_pipeline!(screen)
    get!(screen.gfx_pipelines, :image) do
        GraphicsPipeline(;
            vertex=image_overlay_vertex,
            fragment=image_overlay_fragment,
            blend=Premultiplied(),
            topology=TriangleList(),
            cull=NoCull(),
            depth=DepthOff(),
        )
    end
end

# ── Vertex Shader ──
# 6 vertices (2 triangles) covering the screen-space quad.
# BDA args: screen_bl (Vec2f), screen_tr (Vec2f), res (Vec2f)
# Outputs: UV coordinates for fragment texture sampling.

function image_overlay_vertex(
    screen_bl::Vec2f,
    screen_tr::Vec2f,
    res::Vec2f,
)
    vid = vertex_index()

    # Quad corners in screen space
    # T1: BL, BR, TL  T2: BR, TR, TL
    pos = if vid == Int32(1)
        screen_bl                                    # BL
    elseif vid == Int32(2)
        Vec2f(screen_tr[1], screen_bl[2])            # BR
    elseif vid == Int32(3) || vid == Int32(6)
        Vec2f(screen_bl[1], screen_tr[2])            # TL
    elseif vid == Int32(4)
        Vec2f(screen_tr[1], screen_bl[2])            # BR
    else  # vid == 5
        screen_tr                                    # TR
    end

    uv = if vid == Int32(1)
        Vec2f(0f0, 1f0)   # BL → bottom-left of image
    elseif vid == Int32(2) || vid == Int32(4)
        Vec2f(1f0, 1f0)   # BR
    elseif vid == Int32(3) || vid == Int32(6)
        Vec2f(0f0, 0f0)   # TL
    else  # vid == 5
        Vec2f(1f0, 0f0)   # TR
    end

    ndc = screen_to_ndc(pos, res[1], res[2])
    set_position!(Vec4f(ndc[1], ndc[2], 0f0, 1f0))
    gfx_output(0, uv)
    return nothing
end

# ── Fragment Shader ──
# Samples the RGBA texture at interpolated UV, premultiplies alpha.

function image_overlay_fragment(
    screen_bl::Vec2f,
    screen_tr::Vec2f,
    res::Vec2f,
)
    uv = gfx_input(Vec2f, 0)
    tex = GfxTexture2D(UInt32(0))
    color = tex[uv]

    # Premultiply alpha for Porter-Duff compositing
    a = color[4]
    gfx_output(0, Vec4f(color[1] * a, color[2] * a, color[3] * a, a))
    return nothing
end
