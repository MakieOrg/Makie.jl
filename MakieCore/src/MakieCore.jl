module MakieCore

using Observables
using Observables: to_value
using Base: RefValue, setindex!, getindex

import Observables: to_value, observe, listeners, on, off, AbstractObservable, ObserverFunction

struct ChangeObservable{T} <: AbstractObservable{T}
    obs::Observable{T}
    change::Observable{T}
    function ChangeObservable{T}(x) where {T}
        obs = Observable{T}(x)
        change = observe_changes(obs)
        return new{T}(obs, change)
    end
end
ChangeObservable(val::T) where {T} = ChangeObservable{T}(val)

# Functions that use the value observable
Base.setindex!(co::ChangeObservable, val) = Base.setindex!(co.obs, val)
Base.getindex(co::ChangeObservable) = Base.getindex(co.obs)
to_value(co::ChangeObservable) = to_value(co.obs)

# Functions that use the change observable
observe(co::ChangeObservable) = observe(co.change)
listeners(co::ChangeObservable) = listeners(co.change)
on(@nospecialize(f), co::ChangeObservable; kwargs...) = on(f, co.change; kwargs...)
off(co::ChangeObservable, @nospecialize(f)) = off(co.change, f)
off(co::ChangeObservable, f::ObserverFunction) = off(co.change, f)

export ChangeObservable


include("types.jl")
include("attributes.jl")
include("recipes.jl")
include("basic_plots.jl")
include("conversion.jl")

end
