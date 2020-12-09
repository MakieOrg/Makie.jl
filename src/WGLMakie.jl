module WGLMakie

using Hyperscript
using JSServe, Observables, AbstractPlotting
using Colors, GeometryBasics
using ShaderAbstractions, LinearAlgebra
using GeometryBasics: GeometryBasics

using JSServe: Application, Session, evaljs, linkjs
using JSServe: @js_str, onjs, Button, TextField, Slider, JSString, Dependency, with_session
using JSServe: JSObject, onload, uuidstr
using JSServe.DOM
using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
import AbstractPlotting.FileIO
using StaticArrays
using GeometryBasics: decompose_uv
using ImageMagick: ImageMagick

using FreeTypeAbstraction
using AbstractPlotting: get_texture_atlas, glyph_uv_width!, SceneSpace, Pixel
using AbstractPlotting: attribute_per_char, glyph_uv_width!, layout_text

struct WebGL <: ShaderAbstractions.AbstractContext end
struct WGLBackend <: AbstractPlotting.AbstractBackend end

const THREE = JSServe.Dependency(:THREE,
                                 ["https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js"])
const WGL = JSServe.Dependency(:WGLMakie, [joinpath(@__DIR__, "wglmakie.js")])

struct ThreeDisplay <: AbstractPlotting.AbstractScreen
    context::JSObject
end
JSServe.session(td::ThreeDisplay) = JSServe.session(td.context)

function Base.insert!(td::ThreeDisplay, scene::Scene, plot::AbstractPlot)
    js_scene = serialize_three(scene, plot)
    td.context.add_plot(js_scene)
    return
end

"""
    get_plot(td::ThreeDisplay, plot::AbstractPlot)

Gets the ThreeJS object representing the plot object.
"""
function get_plot(td::ThreeDisplay, plot::AbstractPlot)
    return td.context.get_plot(string(objectid(plot)))
end

include("serialization.jl")
include("events.jl")

include("particles.jl")
include("lines.jl")
include("meshes.jl")
include("imagelike.jl")
include("display.jl")

function activate!()
    b = WGLBackend()
    AbstractPlotting.register_backend!(b)
    AbstractPlotting.set_glyph_resolution!(AbstractPlotting.Low)
    AbstractPlotting.current_backend[] = b
    display_in_browser = JSServe.BrowserDisplay() in Base.Multimedia.displays
    AbstractPlotting.inline!(!display_in_browser)
    return
end

function __init__()
    # Activate WGLMakie as backend!
    activate!()
    # The reasonable_solution is a terrible default for the web!
    if AbstractPlotting.minimal_default.resolution[] == AbstractPlotting.reasonable_resolution()
        AbstractPlotting.minimal_default.resolution[] = (600, 400)
    end
end

for name in names(AbstractPlotting)
    if name !== :Button && name !== :Slider
        @eval import AbstractPlotting: $(name)
        @eval export $(name)
    end
end

end # module
