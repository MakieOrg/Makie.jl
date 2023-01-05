if get(ENV, "MAKIE_PRECOMPILE", "true") == "false"
    __precompile__(false)
end

module MakieCore

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
    @eval Base.Experimental.@optlevel 0
end

using Observables
using Observables: to_value
using Base: RefValue


include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")

end
