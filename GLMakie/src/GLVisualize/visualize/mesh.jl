
function visualize_mesh(@nospecialize(mesh), data::Dict)
    @gen_defaults! data begin
        shading = true
        backlight = 0f0
        main = mesh
        vertex_color = Vec4f(0)
        texturecoordinates = Vec2f(0)
        image = nothing => Texture
        matcap = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        fetch_pixel = false
        uv_scale = Vec2f(1)
        transparency = false
        shader = GLVisualizeShader(
            "util.vert", "mesh.vert", "mesh.frag", "fragment_output.frag",
            view = Dict(
                "light_calc" => light_calc(shading),
                "buffers" => output_buffers(to_value(transparency)),
                "buffer_writes" => output_buffer_writes(to_value(transparency))
            )
        )
    end
    return assemble_shader(data)
end
