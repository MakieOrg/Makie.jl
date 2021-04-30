module MakieCore

using Observables
using Colors
using Random
using LinearAlgebra
using FixedPointNumbers
import Base: *, +, -, /

abstract type AbstractScreen end
abstract type AbstractPlot end

include("geometry/geometry_implementation.jl")
include("utils.jl")
include("types.jl")
include("conversion.jl")
include("scene.jl")
include("scatter.jl")
include("cairomakie/backend.jl")
# include("precompile.jl")

end
