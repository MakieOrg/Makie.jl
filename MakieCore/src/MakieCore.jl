module MakieCore

using Observables
using Observables: to_value
using Base: RefValue

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
end

include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")

end
