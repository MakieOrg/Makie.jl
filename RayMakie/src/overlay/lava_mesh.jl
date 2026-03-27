# =============================================================================
# Lava mesh rendering for overlay — simple flat-colored triangle mesh
# =============================================================================
# Vertex shader projects positions via projectionview * model.
# Fragment shader outputs a flat color (no lighting for 2D overlay).

function get_mesh_pipeline!(screen)
    get!(screen.gfx_pipelines, :mesh) do
        GraphicsPipeline(;
            vertex = mesh_overlay_vertex,
            fragment = mesh_overlay_fragment,
            blend = Premultiplied(),
            topology = TriangleList(),
            cull = NoCull(),
            depth = DepthOff(),
        )
    end
end

function mesh_overlay_vertex(
    positions::LavaDeviceArray{Vec3f, 1},
    colors::LavaDeviceArray{Vec4f, 1},
    projectionview::Mat4f,
    model::Mat4f,
)
    vid = vertex_index()
    pos = positions[vid]
    clip = projectionview * model * Vec4f(pos[1], pos[2], pos[3], 1f0)
    set_position!(clip)
    gfx_output(0, colors[vid])
    return nothing
end

function mesh_overlay_fragment(
    positions::LavaDeviceArray{Vec3f, 1},
    colors::LavaDeviceArray{Vec4f, 1},
    projectionview::Mat4f,
    model::Mat4f,
)
    c = gfx_input(Vec4f, 0)
    a = c[4]
    gfx_output(0, Vec4f(c[1] * a, c[2] * a, c[3] * a, a))
    return nothing
end
