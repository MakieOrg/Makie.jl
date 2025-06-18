module WGLMakie

using Hyperscript
using Bonito
using Observables
using Makie
using Colors
using ShaderAbstractions
using LinearAlgebra
using GeometryBasics
using PNGFiles
using FreeTypeAbstraction

using Bonito: Session
using Bonito: @js_str, onjs, App, ES6Module
using Bonito.DOM

using RelocatableFolders: @path

using ShaderAbstractions: VertexArray, Buffer, Sampler, AbstractSampler
using ShaderAbstractions: InstancedProgram
using GeometryBasics: StaticVector

import Makie.FileIO
using Makie: get_texture_atlas, SceneSpace, Pixel, Automatic
using Makie: attribute_per_char, layout_text
using Makie: MouseButtonEvent, KeyEvent
using Makie: apply_transform, transform_func_obs
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
using Makie: f32_conversion_obs, f32_convert

struct WebGL <: ShaderAbstractions.AbstractContext end

const WGL = ES6Module(joinpath(@__DIR__, "javascript", "WGLMakie.js"))
# using as THREE version: "https://cdn.esm.sh/v66/three@0.173/es2021/three.js"

include("shader-abstractions.jl")
include("display.jl")
include("three_plot.jl")
include("serialization.jl")
include("events.jl")
include("plot-primitives.jl")
include("picking.jl")
include("voxel.jl")

const LAST_INLINE = Base.RefValue{Union{Automatic, Bool}}(Makie.automatic)

"""
    WGLMakie.activate!(; screen_config...)

Sets WGLMakie as the currently active backend and also allows to quickly set the `screen_config`.
Note, that the `screen_config` can also be set permanently via `Makie.set_theme!(WGLMakie=(screen_config...,))`.

# Arguments one can pass via `screen_config`:

$(Base.doc(ScreenConfig))
"""
function activate!(; inline::Union{Automatic, Bool} = LAST_INLINE[], screen_config...)
    Makie.inline!(inline)
    LAST_INLINE[] = inline
    Makie.set_active_backend!(WGLMakie)
    Makie.set_screen_config!(WGLMakie, screen_config)
    if !Bonito.has_html_display()
        Bonito.browser_display()
    end
    return
end

function __init__()
    # Activate WGLMakie as backend!
    activate!()
    return
end

# re-export Makie, including deprecated names
for name in names(Makie, all = true)
    if Base.isexported(Makie, name) && name !== :Button && name !== :Slider
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

include("precompiles.jl")

end # module
