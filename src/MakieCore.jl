module MakieCore

using Observables
using Observables: to_value
using Base: RefValue


include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")

end
