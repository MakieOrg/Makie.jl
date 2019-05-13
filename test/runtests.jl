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
    color = rand(RGBAf0, 10),
)
document, window, jsscene = WGLMakie.js_display(scene)
# 
# container = document.getElementById("container");
# jlvalue(container)
# container.width() |> jlvalue
# $(container).height());
#
# width, height = size(scene)
# THREE, document, window = JSModule(
#     :THREE,
#     "https://cdnjs.cloudflare.com/ajax/libs/three.js/103/three.js",
# )
# style = Dict(
#     :width => width, :height => height
# )
# display(scope(THREE)(dom"div#container"(style = style)))
# renderer = THREE.new.WebGLRenderer(antialias = true)
# renderer.setSize(width, height)
# document.body.appendChild(renderer.domElement)
