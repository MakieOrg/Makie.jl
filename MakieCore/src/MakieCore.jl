module MakieCore

using Observables
using Observables: to_value
using Base: RefValue
using GeometryBasics
using Colors
using Parameters

include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots/abstractplot.jl")
include("basic_plots/scatter.jl")
include("basic_plots/others.jl")
include("conversion.jl")

end
