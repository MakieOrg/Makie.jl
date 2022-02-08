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

using RelocatableFolders: @path

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

const THREE = Dependency(:THREE, ["https://unpkg.com/three@0.130.0/build/three.js"])
const WGL = Dependency(:WGLMakie, [@path joinpath(@__DIR__, "wglmakie.js")])
const WEBGL = Dependency(:WEBGL, [@path joinpath(@__DIR__, "WEBGL.js")])

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

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name) && name !== :Button && name !== :Slider
        @eval using Makie: $(name)
        @eval export $(name)
    end
end
export inline!

end # module
