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
                           depth = DepthOff())
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
    return (position = Vec4f(clip[1], clip_y(clip[2]), clip[3], clip[4]),
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
    return Vec4f(c[1] * a, c[2] * a, c[3] * a, a)
end
