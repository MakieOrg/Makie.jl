module GLMakie

using ModernGL, FixedPointNumbers, Colors, GeometryTypes, StaticArrays
using AbstractPlotting, FreeType, FreeTypeAbstraction, FileIO, IntervalSets
using ImageCore

using AbstractPlotting: @key_str, Key, broadcast_foreach, to_ndim, NativeFont
using AbstractPlotting: Scene, Lines, Text, Image, Heatmap, Scatter
using AbstractPlotting: convert_attribute, @extractvalue, LineSegments
using AbstractPlotting: @get_attribute, to_value, to_colormap, extrema_nan
using IntervalSets: ClosedInterval, (..)

using Base: RefValue
import Base: push!, isopen, show
using Base.Iterators: repeated, drop

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
end

struct GLBackend <: AbstractPlotting.AbstractBackend
end

"""
returns path relative to the assets folder
"""
assetpath(folders...) = joinpath(@__DIR__, "GLVisualize", "assets", folders...)


"""
Loads a file from the asset folder
"""
function loadasset(folders...; kw_args...)
    path = assetpath(folders...)
    isfile(path) || isdir(path) || error("Could not locate file at $path")
    load(path; kw_args...)
end

export assetpath, loadasset

include("../deps/deps.jl")

if WORKING_OPENGL
     # don't put this into try catch, to not mess with normal errors
    include("gl_backend.jl")
end

function __init__()
    if WORKING_OPENGL
        AbstractPlotting.register_backend!(GLBackend())
    end
end

end
