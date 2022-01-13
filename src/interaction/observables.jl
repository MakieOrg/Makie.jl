# I don't want to use map anymore, it's so ambigious, especially to newcomers.
# TODO should this become it's own function?
"""
    lift(f, o1::Observables.AbstractObservable, rest...) -> w

Create a new `w::Observable` by applying `f` to the _values_ of all observables 
in `o1` and `rest...`. The initial value of `w` is determined by the first function
evaluation. The observable `w` is updated by calling `f` each time any of the
observables `o1, rest...` are updated.

## Examples
```julia
julia> x = Observable(2)
Observable{Int64} with 0 listeners. Value:
2

julia> y = lift(a -> a^2, x)
Observable{Int64} with 0 listeners. Value:
4

julia> z = lift((a,b) -> a+b, x, y)
Observable{Int64} with 0 listeners. Value:
6
```
"""
function lift(f, o1::Observables.AbstractObservable, rest...; kw...)
    if !isempty(kw)
        error("lift(f, obs...; init=f.(obs...), typ=typeof(init)) is deprecated. Use lift(typ, f, obs...), or map!(f, Observable(), obs...) for different init.")
    end
    init = f(to_value(o1), to_value.(rest)...)
    typ = typeof(init)
    result = Observable{typ}(init)
    map!(f, result, o1, rest...)
    return result
end

function lift(
        f, ::Type{T}, o1::Observables.AbstractObservable, rest...
    ) where {T}
    init = f(to_value(o1), to_value.(rest)...)
    result = Observable{T}(init)
    map!(f, result, o1, rest...)
    return result
end

Base.close(obs::Observable) = empty!(obs.listeners)

"""
Observables.off but without throwing an error
"""
function safe_off(o::Observables.AbstractObservable, f)
    l = listeners(o)
    for i in 1:length(l)
        if f === l[i]
            deleteat!(l, i)
            for g in Observables.removehandler_callbacks
                g(o, f)
            end
            return
        end
    end
end

"""
    map_once(closure, inputs::Observable....)::Observable

Like Reactive.foreach, in the sense that it will be preserved even if no reference is kept.
The difference is, that you can call map once multiple times with the same closure and it will
close the old result Observable and register a new one instead.

```
function test(s1::Observable)
    s3 = map_once(x-> (println("1 ", x); x), s1)
    s3 = map_once(x-> (println("2 ", x); x), s1)

end
test(Observable(1), Observable(2))
>

"""
function map_once(
        f, input::Observable, inputrest::Observable...
    )
    for arg in (input, inputrest...)
        safe_off(arg, f)
    end
    lift(f, input, inputrest...)
end
