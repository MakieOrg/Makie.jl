using Test, Tables, Observables
using AbstractPlotting
using WGLMakie
import GeometryTypes
using WGLMakie: WebGL, lasset, JSInstanceBuffer, JSBuffer, to_js_uniforms
using Tables: columns
using JSCall

Scene(resolution = (300, 300))
scene = scatter!(
    rand(Point2f0, 10),
    marker = 'c',
    color = rand(RGBAf0, 10),
)
p = scene[end]
p.uv_offset_width[]
a,b, jsscene = WGLMakie.js_display(scene)
