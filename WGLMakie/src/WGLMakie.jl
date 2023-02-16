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

using JSServe: Session
using JSServe: @js_str, onjs, App, ES6Module
using JSServe.DOM

using RelocatableFolders: @path

using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
using GeometryBasics: StaticVector

import Makie.FileIO
using Makie: get_texture_atlas, SceneSpace, Pixel
using Makie: attribute_per_char, layout_text
using Makie: MouseButtonEvent, KeyEvent
using Makie: apply_transform, transform_func_obs
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space

struct WebGL <: ShaderAbstractions.AbstractContext end

const WGL = ES6Module(@path joinpath(@__DIR__, "wglmakie.js"))

include("display.jl")
include("three_plot.jl")
include("serialization.jl")
include("events.jl")
include("particles.jl")
include("lines.jl")
include("meshes.jl")
include("imagelike.jl")
include("picking.jl")

const LAST_INLINE = Ref(true)

"""
    WGLMakie.activate!(; screen_config...)

Sets WGLMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set permanently via `Makie.set_theme!(WGLMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; inline=LAST_INLINE[], screen_config...)
    Makie.inline!(inline)
    LAST_INLINE[] = inline
    Makie.set_active_backend!(WGLMakie)
    Makie.set_screen_config!(WGLMakie, screen_config)
    return
end

const TEXTURE_ATLAS = Observable(Float32[])

wgl_texture_atlas() = Makie.get_texture_atlas(1024, 32)

function __init__()
    # Activate WGLMakie as backend!
    activate!()
    # We need to update the texture atlas whenever it changes!
    # We do this in three_plot!
    atlas = wgl_texture_atlas()
    TEXTURE_ATLAS[] = convert(Vector{Float32}, vec(atlas.data))
    Makie.font_render_callback!(atlas) do sd, uv
        TEXTURE_ATLAS[] = convert(Vector{Float32}, vec(wgl_texture_atlas().data))
    end
end

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name) && name !== :Button && name !== :Slider
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

include("precompiles.jl")

end # module
