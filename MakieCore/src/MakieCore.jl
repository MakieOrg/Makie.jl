module MakieCore

if isdefined(Base, :Experimental) && isdefined(Base.Experimental, Symbol("@max_methods"))
    @eval Base.Experimental.@max_methods 1
    @eval Base.Experimental.@optlevel 0
end

using Observables
using Observables: to_value
using Base: RefValue
# Needing REPL for Base.Docs.doc on julia
# https://github.com/MakieOrg/Makie.jl/issues/3276
using REPL


include("LazyObservable.jl")
include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")

end
