"""
    record_events(f, scene::Scene, path::String)

Records all window events that happen while executing function `f`
for `scene` and serializes them to `path`.
"""
function record_events(f, scene::Scene, path::String)
    display(scene)
    result = Vector{Pair{Float64, Pair{Symbol, Any}}}()
    for field in fieldnames(Events)
        # These are not Observables
        (field === :mousebuttonstate || field === :keyboardstate) && continue
        on(getfield(scene.events, field); priority = typemax(Int)) do value
            value = isa(value, Set) ? copy(value) : value
            push!(result, time() => (field => value))
            return Consume(false)
        end
    end
    f()
    return open(path, "w") do io
        return serialize(io, result)
    end
end

"""
    replay_events(f, scene::Scene, path::String)
    replay_events(scene::Scene, path::String)

Replays the serialized events recorded with `record_events` in `path` in `scene`.
"""
replay_events(scene::Scene, path::String) = replay_events(() -> nothing, scene, path)
function replay_events(f, scene::Scene, path::String)
    events = open(io -> deserialize(io), path)
    sort!(events; by = first)
    for i in 1:length(events)
        t1, (field, value) = events[i]
        (field === :mousebuttonstate || field === :keyboardstate) && continue
        Base.invokelatest() do
            return getfield(scene.events, field)[] = value
        end
        f()
        if i < length(events)
            t2, (field, value) = events[i + 1]
            # min sleep time 0.001
            if (t2 - t1 > 0.001)
                sleep(t2 - t1)
            else
                yield()
            end
        end
    end
    return
end

struct RecordEvents
    scene::Scene
    path::String
end

Base.display(re::RecordEvents) = display(re.scene)
