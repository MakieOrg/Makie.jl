module WGLMakie

using Hyperscript
using JSServe
using Observables
using AbstractPlotting
using Colors
using ShaderAbstractions
using LinearAlgebra
using GeometryBasics
using ImageMagick
using FreeTypeAbstraction
using StaticArrays

using JSServe: Session, evaljs, linkjs, onload
using JSServe: @js_str, onjs, Dependency, with_session
using JSServe.DOM

using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram

import AbstractPlotting.FileIO
using AbstractPlotting: get_texture_atlas, glyph_uv_width!, SceneSpace, Pixel
using AbstractPlotting: attribute_per_char, glyph_uv_width!, layout_text

struct WebGL <: ShaderAbstractions.AbstractContext end
struct WGLBackend <: AbstractPlotting.AbstractBackend end
#["https://unpkg.com/three@0.123.0/build/three.min.js"
const THREE = Dependency(:THREE,
                                 ["https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js"])
const WGL = Dependency(:WGLMakie, [joinpath(@__DIR__, "wglmakie.js")])

include("three_plot.jl")
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
    AbstractPlotting.current_backend[] = b
    AbstractPlotting.set_glyph_resolution!(AbstractPlotting.Low)
    return
end

function __init__()
    # Activate WGLMakie as backend!
    activate!()
    display_in_browser = JSServe.BrowserDisplay() in Base.Multimedia.displays
    AbstractPlotting.inline!(!display_in_browser)
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
