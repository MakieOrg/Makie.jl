using Observables: AbstractObservable, ObserverFunction, notify
import Observables: observe, listeners, on, off, notify

struct PrioCallback
    f::Any
end

struct Consume
    x::Bool
end
Consume() = Consume(true)
Consume(x::Consume) = Consume(x.x) # for safety in selection_point etc
Base.:(==)(a::Consume, b::Consume) = a.x == b.x

function (f::PrioCallback)(val)::Bool
    consume = Base.invokelatest(f.f, val)
    return consume isa Consume && consume.x
end

mutable struct PriorityObservable{T} <: AbstractObservable{T}
    listeners::Vector{Pair{Int8, Vector{PrioCallback}}}
    val::T

    PriorityObservable{T}() where {T} = new{T}(Pair{Int8, Vector{PrioCallback}}[])
    PriorityObservable{T}(val) where {T} = new{T}(Pair{Int8, Vector{PrioCallback}}[], val)
    # Construct an Observable{Any} without runtime dispatch
    PriorityObservable{Any}(@nospecialize(val)) = new{Any}(Pair{Int8, Vector{PrioCallback}}[], val)
end

function Base.precompile(observable::PriorityObservable)
    tf = true
    T = eltype(observable)
    for (_, f) in observable.listeners
        precompile(f, (T,))
    end
    return tf
end

"""
    PriorityObservable(value)

Creates a new `PriorityObservable` holding the given `value`.

A `po = PriorityObservable` differs from a normal `Observable` (or `Observable`) in
two ways:
1. When registering a function to `po` you can also give it a `priority`.
Functions with higher priority will be evaluated first.
2. Each registered function is assumed to return a `Bool`. If `true` is returned
the observable will stop calling the remaining observer functions.

In the following example we have 3 listeners to a `PriorityObservable`. When
triggering the `PriorityObservable` you will first see `"First"` as it is the
callback with the highest priority. After that `"Second"` will be printed and
stop further execution. `"Third"` will therefore not be printed.
```
po = PriorityObservable(1)
on(x -> begin printstyled("First\n", color=:green); false end, po, priority = 1)
on(x -> begin printstyled("Second\n", color=:orange); true end, po, priority = 0)
on(x -> begin printstyled("Third\n", color=:red); false end, po, priority = -1)
po[] = 2
```

Note that `PriorityObservable` does not implement `map`. If you wish to know
whether any observer function returned `true`, you can check the output of
`setindex!(po, val)`.
"""
PriorityObservable(val::T) where {T} = PriorityObservable{T}(val)

function Base.show(io::IO, po::PriorityObservable)
    print(io, "PriorityObservable(")
    print(io, po.val)
    print(io, ")")
end
function Base.show(io::IO, ::MIME"text/plain", po::PriorityObservable{T}) where {T}
    print(io, "PriorityObservable{T}(")
    print(io, po.val)
    N = isempty(po.listeners) ? 0 : mapreduce(x -> length(x[2]), +, po.listeners)
    print(io, ") with $N listeners at priorities [", join(first.(po.listeners), ','), "]")
end



Base.getindex(observable::PriorityObservable) = observable.val

function Base.setindex!(observable::PriorityObservable, val)
    observable.val = val
    return notify(observable)
end

function Base.notify(observable::PriorityObservable)
    val = observable[]
    for f in listeners(observable)
        Base.invokelatest(f, val) && return true
    end
    return false
end

# reverse order so that the highest priority is notified first
listeners(o::PriorityObservable) = (f for p in reverse(o.listeners) for f in p[2])

function on(@nospecialize(f), observable::PriorityObservable; weak::Bool = false, priority = 0)
    sanitized_func = PrioCallback(f)

    # Create or insert into correct priority
    idx = findfirst(p -> p[1] >= priority, observable.listeners)
    if idx === nothing
        push!(observable.listeners, priority => [sanitized_func])
    elseif observable.listeners[idx][1] == priority
        push!(observable.listeners[idx][2], sanitized_func)
    else
        insert!(observable.listeners, idx, priority => [sanitized_func])
    end

    # same as Observable?
    for g in Observables.addhandler_callbacks
        g(sanitized_func, observable)
    end
    # Return a ObserverFunction so that the caller is responsible
    # to keep a reference to it around as long as they want the connection to
    # persist. If the ObserverFunction is garbage collected, f will be released from
    # observable's listeners as well.
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
off(observable::PriorityObservable, obsfunc::ObserverFunction) = off(observable, obsfunc.f)
