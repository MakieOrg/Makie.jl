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
using Makie: to_native
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
import Makie: to_font, glyph_uv_width!, el32convert, Shape, CIRCLE, RECTANGLE, ROUNDED_RECTANGLE, DISTANCEFIELD, TRIANGLE
import Makie: RelocatableFolders

using ShaderAbstractions
using FreeTypeAbstraction
using GeometryBasics: StaticVector
using Observables

using Base: RefValue
import Base: push!, isopen, show
using Base.Iterators: repeated, drop

using LinearAlgebra

# re-export Makie, including deprecated names
for name in names(Makie, all=true)
    if Base.isexported(Makie, name)
        try
            @eval using Makie: $(name)
            @eval export $(name)
        catch e
        end
    end
end

import ShaderAbstractions: Sampler, Buffer
export Sampler, Buffer

const GL_ASSET_DIR = RelocatableFolders.@path joinpath(@__DIR__, "..", "assets")
const SHADER_DIR = RelocatableFolders.@path joinpath(GL_ASSET_DIR, "shader")
loadshader(name) = joinpath(SHADER_DIR, name)

# don't put this into try catch, to not mess with normal errors
include("gl_backend.jl")

function __init__()
    activate!()
end

Base.@deprecate set_window_config!(; screen_config...) GLMakie.activate!(; screen_config...)

include("precompiles.jl")

end
