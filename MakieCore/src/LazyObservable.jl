"""
    LazyObservable{T}(update::Function)
    LazyObservable(update::Function, init::T)

Creates a lazy observables which updates using the passed `update` Function when
its value is requested by `lazyobs[]`.

Notes:
- `on()`, `map()` etc do not pass the value of the LazyObservable to the
attached function. Instead they pass the LazyObservable itself, so that you
need to explicitly call `lazyobs[]` to trigger an update.

TODO: Should this just update and have something like
`no_update(l::LazyObserbale) = l.up_to_date` for listening without updates?
"""
mutable struct LazyObservable{T}
    updater::Function
    up_to_date::Observable{Bool}
    val::T

    LazyObservable{T}(f::Function) = new{T}(f, Observable{Bool}(false))
    LazyObservable(f::Function, init::T) = new{T}(f, Observable{Bool}(false), init)
end

function update!(l::LazyObservable{T}) where T
    if !l.up_to_date[]
        l.val = l.updater()::T
        l.up_to_date.val = true
    end
    return l.val
end

function notify(l::LazyObservable)
    l.up_to_date[] = false
    return
end

getindex(l::LazyObservable) = update!(l)
listeners(l::LazyObservable) = listeners(l.up_to_date)

function on(@nospecialize(f), l::LazyObservable; kwargs...)
    return on(l.up_to_date; kwargs...) do state
        state || f(l) # TODO: should this update? e.g. use l[]?
        return
    end
end

off(l::LazyObservable, @nospecialize(f)) = off(l.up_to_date, f)