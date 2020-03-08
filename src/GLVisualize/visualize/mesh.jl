# function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M
#     @gen_defaults! data begin
#         main = mesh
#         shading = true
#         color = nothing
#         shader = GLVisualizeShader(
#             "fragment_output.frag", "util.vert", "attribute_mesh.vert", "standard.frag",
#             view = Dict("light_calc" => light_calc(shading))
#         )
#     end
# end

function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M <: GLNormalMesh
    @gen_defaults! data begin
        shading = true
        main = mesh
        color = default(RGBA{Float32}, s)
        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "standard.vert", "standard.frag",
            view = Dict("light_calc" => light_calc(shading))
        )
    end
end
function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M <: GLNormalUVMesh
    @gen_defaults! data begin
        shading = true
        main = mesh
        color = default(RGBA{Float32}, s) => Texture

        shader = GLVisualizeShader(
            "fragment_output.frag", "util.vert", "uv_normal.vert", "standard.frag",
            view = Dict("light_calc" => light_calc(shading))
        )
    end
end
# function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M
#     @gen_defaults! data begin
#         shading = true
#         main = mesh
#         color = nothing
#         shader = GLVisualizeShader(
#             "fragment_output.frag", "util.vert", "vertexcolor.vert", "standard.frag",
#             view = Dict("light_calc" => light_calc(shading))
#         )
#     end
# end

# function _default(mesh::GLNormalColorMesh, s::Style, data::Dict)
#     data[:color] = decompose(RGBA{Float32}, mesh)
#     _default(GLNormalMesh(mesh), s, data)
# end

function _default(mesh::TOrSignal{M}, s::Style, data::Dict) where M <: GLPlainMesh
    @gen_defaults! data begin
        primitive::GLPlainMesh = mesh
        color = default(RGBA, s, 1)
        shader = GLVisualizeShader("fragment_output.frag", "plain.vert", "plain.frag")
    end
end
