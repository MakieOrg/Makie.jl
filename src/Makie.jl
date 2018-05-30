__precompile__(true)
module Makie

using AbstractPlotting
importall AbstractPlotting
using AbstractPlotting: @info, @log_performance, @warn, jl_finalizer, NativeFont, Key, @key_str

using Reactive, GeometryTypes, Colors, StaticArrays

using Colors, GeometryTypes, ColorVectorSpace
using Contour
import Quaternions
using Primes

using Base.Iterators: repeated, drop
using Fontconfig, FreeType, FreeTypeAbstraction, UnicodeFun
using IntervalSets
using PlotUtils, Showoff

using Base: RefValue

import Base: push!, isopen

# functions we overload

include("scene.jl")
include("makie_recipes.jl")
include("argument_conversion.jl")
include("tickranges.jl")
include("glbackend/glbackend.jl")
include("cairo/cairo.jl")
include("output.jl")

export Scene

end
