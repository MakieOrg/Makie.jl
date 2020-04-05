
function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M <: GeometryBasics.Mesh
    return @gen_defaults! data begin
        shading = true
        main = mesh
        vertex_color = Vec4f0(0)
        texturecoordinates = Vec2f0(0)
        image = nothing => Texture
        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "standard.vert", "standard.frag",
            view = Dict("light_calc" => light_calc(shading))
        )
    end
end
