module GLMakie

using ModernGL, FixedPointNumbers, Colors, GeometryBasics
using Makie, FileIO

using Makie: @key_str, Key, broadcast_foreach, to_ndim, NativeFont
using Makie: Scene, Lines, Text, Image, Heatmap, Scatter
using Makie: convert_attribute, @extractvalue, LineSegments
using Makie: @get_attribute, to_value, to_colormap, extrema_nan
using Makie: ClosedInterval, (..)
using Makie: inline!
using Makie: spaces, is_data_space, is_pixel_space, is_relative_space, is_clip_space
import Makie: to_font, glyph_uv_width!, el32convert

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

loadshader(name) = normpath(joinpath(@__DIR__, "..", "assets", "shader", name))

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

if Base.VERSION >= v"1.4.2"
    include("precompile.jl")
    _precompile_()
end

end
