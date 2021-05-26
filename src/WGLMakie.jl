module WGLMakie

using Hyperscript
using JSServe
using Observables
using Makie
using Colors
using ShaderAbstractions
using LinearAlgebra
using GeometryBasics
using ImageMagick
using FreeTypeAbstraction
using StaticArrays

using JSServe: Session
using JSServe: @js_str, onjs, Dependency, App
using JSServe.DOM

using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram

import Makie.FileIO
using Makie: get_texture_atlas, glyph_uv_width!, SceneSpace, Pixel
using Makie: attribute_per_char, glyph_uv_width!, layout_text
using Makie: MouseButtonEvent, KeyEvent
using Makie: apply_transform, transform_func_obs
using Makie: inline!

struct WebGL <: ShaderAbstractions.AbstractContext end
struct WGLBackend <: Makie.AbstractBackend end
#["https://unpkg.com/three@0.123.0/build/three.min.js"
const THREE = Dependency(:THREE,
                                 ["https://cdn.jsdelivr.net/gh/mrdoob/three.js/build/three.js"])

const WGL = Dependency(:WGLMakie, [joinpath(@__DIR__, "wglmakie.js")])
const WEBGL = Dependency(:WEBGL, [joinpath(@__DIR__, "WEBGL.js")])

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
    Makie.register_backend!(b)
    Makie.current_backend[] = b
    Makie.set_glyph_resolution!(Makie.Low)
    return
end

const TEXTURE_ATLAS_CHANGED = Ref(false)

function __init__()
    # Activate WGLMakie as backend!
    activate!()
    browser_display = JSServe.BrowserDisplay() in Base.Multimedia.displays
    Makie.inline!(!browser_display)
    # We need to update the texture atlas whenever it changes!
    # We do this in three_plot!
    Makie.font_render_callback!() do sd, uv
        TEXTURE_ATLAS_CHANGED[] = true
    end
end

for name in names(Makie)
    if name !== :Button && name !== :Slider
        @eval import Makie: $(name)
        @eval export $(name)
    end
end
export inline!

end # module
