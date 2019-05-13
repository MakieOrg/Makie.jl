using Test, Tables, Observables
using AbstractPlotting
using WGLMakie
import GeometryTypes
using WGLMakie: WebGL, lasset, JSInstanceBuffer, JSBuffer, to_js_uniforms
using Tables: columns
using JSCall

Scene(resolution = (300, 300))
scene = scatter!(
    rand(Point3f0, 10),
    color = rand(RGBAf0, 10),
)
a,b, jsscene = WGLMakie.js_display(scene)
#
#
# x = rand(Float32, 4096, 4096)
#
# data = WGLMakie.to_js_buffer(x)
#
# tex = WGLMakie.THREE.new.DataTexture(
#     data, size(x, 1), size(x, 2),
#     WGLMakie.THREE.AlphaFormat, WGLMakie.THREE.FloatType
# )
# tex.needsUpdate = true
