module MakieCore

using Observables
using Observables: to_value
using Base: RefValue

function convert_arguments end
function convert_attribute end

include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")

end
