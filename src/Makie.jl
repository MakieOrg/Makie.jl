module Makie


using AbstractPlotting, ImageCore, LinearAlgebra, Statistics, Base64
using GeometryTypes, Colors, ColorVectorSpace, StaticArrays, FixedPointNumbers
import IntervalSets, FileIO
using IntervalSets: ClosedInterval, (..)
using Primes
using Base.Iterators: repeated, drop
using FreeType, FreeTypeAbstraction, UnicodeFun
using PlotUtils, Showoff
using Base: RefValue
import Base: push!, isopen, show

for name in names(AbstractPlotting)
    @eval import AbstractPlotting: $(name)
    @eval export $(name)
end
# Unexported names
using AbstractPlotting: @info, @log_performance, @warn, NativeFont, Key, @key_str

export (..), GLNormalUVMesh
# conflicting identifiers
using AbstractPlotting: Text, volume, VecTypes
using GeometryTypes: widths
export widths, decompose

module ContoursHygiene
    import Contour
end
using .ContoursHygiene
const Contours = ContoursHygiene.Contour



function logo()
    FileIO.load(joinpath(@__DIR__, "..", "assets", "logo.png"))
end

include("makie_recipes.jl")
include("utils.jl")

using GLMakie
using GLMakie: assetpath, loadasset

end
