module GLMakie

using ModernGL, FixedPointNumbers, Colors, GeometryBasics, StaticArrays
using AbstractPlotting, FileIO

using AbstractPlotting: @key_str, Key, broadcast_foreach, to_ndim, NativeFont
using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments
using AbstractPlotting: @get_attribute, to_value, to_colormap, extrema_nan
using AbstractPlotting: ClosedInterval, (..)
using ShaderAbstractions
using FreeTypeAbstraction

using Base: RefValue
import Base: push!, isopen, show
using Base.Iterators: repeated, drop

using LinearAlgebra

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end

struct GLBackend <: AbstractPlotting.AbstractBackend
end

loadshader(name) = normpath(joinpath(@__DIR__, "..", "assets", "shader", name))

# don't put this into try catch, to not mess with normal errors
include("gl_backend.jl")

function activate!(use_display=true)
    b = GLBackend()
    AbstractPlotting.register_backend!(b)
    AbstractPlotting.set_glyph_resolution!(AbstractPlotting.High)
    AbstractPlotting.current_backend[] = b
    AbstractPlotting.inline!(!use_display)
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
