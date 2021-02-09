using Observables
using Observables: AbstractObservable, ObserverFunction, notify!, InternalFunction, OnUpdate
import Observables: observe, listeners, on, off, onany

mutable struct PriorityObservable{T} <: AbstractObservable{T}
    listeners::Vector{Pair{Int8, Vector{Any}}}
    val::T

    PriorityObservable{T}() where {T} = new{T}(Pair{Int8, Vector{Any}}[])
    PriorityObservable{T}(val) where {T} = new{T}(Pair{Int8, Vector{Any}}[], val)
    # Construct an Observable{Any} without runtime dispatch
    PriorityObservable{Any}(@nospecialize(val)) = new{Any}(Pair{Int8, Vector{Any}}[], val)
end

PriorityObservable(val::T) where {T} = PriorityObservable{T}(val)

Base.getindex(observable::PriorityObservable) = observable.val
function Base.setindex!(observable::PriorityObservable, val; notify=(x)->true)
    observable.val = val
    for f in listeners(observable)
        if notify(f)
            output = if f isa InternalFunction
                f(val)
            else
                Base.invokelatest(f, val)
            end
            output && return true
        end
    end
    return false
end

# reverse order so that the highest priority is notified first
listeners(o::PriorityObservable) = (f for p in reverse(o.listeners) for f in p[2])

function on(@nospecialize(f), observable::PriorityObservable; weak::Bool = false, priority = Int8(0))
    if Core.Compiler.return_type(f, (typeof(observable.val),)) !== Bool
        sanitized_func = x -> begin f(x); false end
        @warn(
            "Observer functions of PriorityObservables must return a Bool to " *
            "specify whether the update is consumed (true) or should " *
            "propagate (false) to other observer functions. The given " *
            "function has been wrapped to always return false."
        )
    else
        sanitized_func = f
    end
    
    priority = Int8(priority)
    # Create or insert into correct priority
    idx = findfirst(p -> p[1] >= priority, observable.listeners)
    if idx === nothing
        push!(observable.listeners, priority => Any[sanitized_func])
    elseif observable.listeners[idx][1] == priority
        push!(observable.listeners[idx][2], sanitized_func)
    else
        insert!(observable.listeners, idx, priority => Any[sanitized_func])
    end

    # same as Observable?
    for g in Observables.addhandler_callbacks
        g(f, observable)
    end
    return ObserverFunction(sanitized_func, observable, weak)
end

function off(observable::PriorityObservable, @nospecialize(f))
    for (i, pairs) in enumerate(observable.listeners)
        fs = pairs[2]
        for (j, f2) in enumerate(fs)
            if f === f2
                deleteat!(fs, j)
                # cleanup priority if it has no listeners
                isempty(fs) && deleteat!(observable.listeners, i)
                for g in Observables.removehandler_callbacks
                    g(observable, f)
                end
                return true
            end
        end
    end
    return false
end
function off(observable::PriorityObservable, obsfunc::ObserverFunction)
    f = obsfunc.f
    off(observable, f)
end

# function onany(f, args...; priority::Int8 = Int8(0), weak::Bool = false)
#     callback = OnUpdate(f, args)

#     # store all returned ObserverFunctions
#     obsfuncs = ObserverFunction[]
#     for observable in args
#         if observable isa PriorityObservable
#             obsfunc = on(callback, observable, priority = priority, weak = weak)
#             push!(obsfuncs, obsfunc)
#         elseif observable isa AbstractObservable
#             obsfunc = on(callback, observable, weak = weak)
#             push!(obsfuncs, obsfunc)
#         end
#     end

#     # same principle as with `on`, this collection needs to be
#     # stored by the caller or the connections made will be cut
#     obsfuncs
# end

# No map. map is evil
# To be specific - map forwards the output of the function to a new observable
# this means we can't exit early true/false