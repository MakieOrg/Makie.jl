
function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M <: GeometryBasics.Mesh
    return @gen_defaults! data begin
        shading = true
        backlight = 0f0
        main = mesh
        vertex_color = Vec4f0(0)
        texturecoordinates = Vec2f0(0)
        image = nothing => Texture
        matcap = nothing => Texture
        color_map = nothing => Texture
        color_norm = nothing
        fetch_pixel = false
        uv_scale = Vec2f0(1)
        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "standard.vert", "standard.frag",
            view = Dict("light_calc" => light_calc(shading))
        )
    end
end
