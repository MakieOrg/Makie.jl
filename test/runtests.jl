using Test, Tables, Observables
using AbstractPlotting
using WGLMakie
import GeometryTypes
using WGLMakie: WebGL, lasset, JSInstanceBuffer, JSBuffer, to_js_uniforms
using Tables: columns
using JSCall, Random
Random.seed!(42)
set_theme!(resolution = (1000, 1000))
scene = linesegments(rand(Point2f0, 10), linewidth = 10, color = rand(RGBAf0, 10))
document, window, jsscene = WGLMakie.js_display(scene)
