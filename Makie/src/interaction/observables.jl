# lift makes it easier to search + replace observable code, while `map` is really hard to differentiate from `map(f, array)`
const lift, lift! = map, map!

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
    return
end

function on_latest(f, observable::Observable; update = false, spawn = false, throttle = 0.0)
    return on_latest(f, nothing, observable; update = update, spawn = spawn, throttle = throttle)
end


function on_latest(f, to_track, observable::Observable; update = false, spawn = false, throttle = 0.0)
    task_lock = Threads.ReentrantLock()
    last_task = nothing
    has_changed = Threads.Atomic{Bool}(false)
    function run_f(new_value)
        t1 = time()
        try
            f(new_value)
            tdiff = time() - t1
            if throttle > 0.0 && tdiff < throttle
                sleep(throttle - tdiff)
            end
        catch e
            @warn "Error in f" exception = (e, Base.catch_backtrace())
        end
        # Since we skip updates completely while executing the above `f`
        # We need to check after finishing, if the value has changed!
        # `==` can be pretty expensive or ill defined, so we use a flag `has_changed`
        # But `==` would be better, considering, that one could arrive at an old value.
        # This should be configurable, but since async_latest is needed for working on big data as input
        # we assume for now that `==` is prohibitive as the default
        return if has_changed[]
            has_changed[] = false
            run_f(observable[]) # needs to be recursive
        end
    end

    function on_callback(new_value)
        return lock(task_lock) do
            if isnothing(last_task) || istaskdone(last_task)
                if spawn
                    last_task = Threads.@spawn run_f(new_value)
                else
                    last_task = Threads.@async run_f(new_value)
                end
            else
                has_changed[] = true
                return nothing # Do nothing if working
            end
        end
    end

    update && f(observable[])

    if isnothing(to_track)
        return on(on_callback, observable)
    else
        return on(on_callback, to_track, observable)
    end
end

function onany_latest(f, observables...; update = false, spawn = false, throttle = 0.0)
    result = Observable{Any}(map(to_value, observables))
    onany((args...) -> (result[] = args), observables...)
    return on_latest((args) -> f(args...), result; update = update, spawn = spawn, throttle = throttle)
end

function map_latest!(f, result::Observable, observables...; update = false, spawn = false, throttle = 0.0)
    callback = Observables.MapCallback(f, result, observables)
    return onany_latest(callback, observables...; update = update, spawn = spawn, throttle = throttle)
end

function map_latest(f, observables...; spawn = false, ignore_equal_values = false, throttle = 0.0)
    first_value = f(map(to_value, observables)...)
    result = Observable(first_value; ignore_equal_values = ignore_equal_values)
    map_latest!(f, result, observables..., spawn = spawn, throttle = throttle)
    return result
end
