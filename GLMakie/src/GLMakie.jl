module GLMakie

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    # GLMakie doesn't do much work, besides assembling shaders.
    # If it does, code should be 100% inferable, so hopefully shouldn't be influenced by this
    @eval Base.Experimental.@max_methods 1
end

using ModernGL, FixedPointNumbers, Colors, GeometryBasics
using Makie, FileIO

using Makie: @key_str, Key, broadcast_foreach, to_ndim, NativeFont
using Makie: Scene, Lines, Text, Image, Heatmap, Scatter
using Makie: convert_attribute, @extractvalue, LineSegments
using Makie: @get_attribute, to_value, to_colormap, extrema_nan
using Makie: ClosedInterval, (..)
using Makie: inline!, to_native
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
import Makie: to_font, glyph_uv_width!, el32convert, Shape, CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE
import Makie: RelocatableFolders

using ShaderAbstractions
using FreeTypeAbstraction
using GeometryBasics: StaticVector

using Base: RefValue
import Base: push!, isopen, show
using Base.Iterators: repeated, drop

using LinearAlgebra

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        @eval using Makie: $(name)
        @eval export $(name)
    end
end

export inline!
import ShaderAbstractions: Sampler, Buffer
export Sampler, Buffer

struct GLBackend <: Makie.AbstractBackend
end

const GL_ASSET_DIR = RelocatableFolders.@path joinpath(@__DIR__, "..", "assets")
const SHADER_DIR = RelocatableFolders.@path joinpath(GL_ASSET_DIR, "shader")
loadshader(name) = joinpath(SHADER_DIR, name)

# don't put this into try catch, to not mess with normal errors
include("gl_backend.jl")

function activate!(use_display=true)
    b = GLBackend()
    Makie.register_backend!(b)
    Makie.set_glyph_resolution!(Makie.High)
    Makie.current_backend[] = b
    Makie.inline!(!use_display)
end

function __init__()
    activate!()
end

export set_window_config!

include("precompiles.jl")

end
