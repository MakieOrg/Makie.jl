const lift = map

# TODO remove?
Base.close(obs::Observable) = empty!(obs.listeners)

"""
Observables.off but without throwing an error
"""
function safe_off(o::Observables.AbstractObservable, f)
    l = listeners(o)
    for i in 1:length(l)
        if f === l[i][2]
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
