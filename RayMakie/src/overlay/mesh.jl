# =============================================================================
# Mesh rendering for overlay — simple flat-colored triangle mesh
# =============================================================================
# Vertex shader projects positions via projectionview * model.
# Fragment shader outputs a flat color (no lighting for 2D overlay).

function get_mesh_pipeline!(screen)
    get!(screen.gfx_pipelines, :mesh) do
        GraphicsPipeline(; vertex = VertexShader(mesh_overlay_vertex;
                                                outputs = (colour = Vec4f,)),
                           fragment = FragmentShader(mesh_overlay_fragment),
                           blend = Premultiplied(),
                           topology = TriangleList(),
                           cull = NoCull(),
                           depth = DepthLessEq())
    end
end

function mesh_overlay_vertex(
    positions::AbstractVector{Vec3f},
    colors::AbstractVector{Vec4f},
    projectionview::Mat4f,
    model::Mat4f,
)
    vid = vertex_index()
    pos = positions[vid]
    clip = projectionview * model * Vec4f(pos[1], pos[2], pos[3], 1f0)
    return (position = gl_to_clip_depth(clip),
            colour = colors[vid])
end

function mesh_overlay_fragment(
    inputs,
    positions::AbstractVector{Vec3f},
    colors::AbstractVector{Vec4f},
    projectionview::Mat4f,
    model::Mat4f,
)
    c = inputs.colour
    a = c[4]
    # A transparent fragment must not claim DEPTH: with writes on, an
    # alpha-zero corner of a glyph or marker quad occludes whatever should
    # have shown through it. Discarding is what lets a BLENDED pass use a
    # depth buffer, which is how a scene's z translation gets honoured.
    a < 1f-3 && discard()
    return Vec4f(c[1] * a, c[2] * a, c[3] * a, a)
end
