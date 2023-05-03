# lift makes it easier to search + replace observable code, while `map` is really hard to differentiate from `map(f, array)`
const lift = map

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

function on_latest(f, observable; update=false, spawn=false)
    # How does one create a finished task??
    last_task = @async nothing
    yield()
    function run_f(new_value)
        try
            f(new_value)
        catch e
            @warn "Error in f" exception=e
        end
        # Since we skip updates completely while executing the above `f`
        # We need to check after finishing, if the value has changed!
        # If != is too expensive or ill defined, we could use a flag `has_changed`
        # But `!=` is more correct, considering, that one could arrive at an old value.
        # For async_latest, `f` is considered to be side effect free anyways
        if new_value != observable[]
            run_f(observable[]) # needs to recursive
        end
    end
    return on(observable; update=update) do new_value
        if istaskdone(last_task)
            if spawn
                last_task = Threads.@spawn run_f(new_value)
            else
                last_task = Threads.@async run_f(new_value)
            end
        else
            return # Do nothing if working
        end
    end
end

function onany_latest(f, observables...; update=false, spawn=false)
    result = Observable{Any}(map(to_value, observables))
    onany((args...)-> (result[] = args), observables...)
    on_latest((args)-> f(args...), result; update=update, spawn=spawn)
end
