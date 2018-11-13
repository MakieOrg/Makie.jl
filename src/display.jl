struct PlotDisplay <: AbstractDisplay end

abstract type AbstractBackend end
function backend_display end

"""
Currently available displays by backend
"""
const available_backends = AbstractBackend[]
const current_backend = Ref{Union{Missing,AbstractBackend}}(missing)
const use_display = Ref{Bool}(true)

function inline!(inline = true)
    use_display[] = !inline
end

function register_backend!(backend::AbstractBackend)
    push!(available_backends, backend)
    if(length(available_backends) == 1)
        current_backend[] = backend
    end
    nothing
end

function __init__()
    pushdisplay(PlotDisplay())
end

function Base.display(d::PlotDisplay, scene::Scene)
    use_display[] || throw(MethodError(display, (d, scene)))
    try
        backend_display(current_backend[], scene)
    catch ex
        if ex isa MethodError && ex.f in (backend_display, backend_show)
            throw(MethodError(display, (d, scene)))
        else
            rethrow()
        end
    end
end

Base.showable(mime::MIME, scene::Scene) = backend_showable(current_backend[], mime, scene)

# have to be explicit with mimetypes to avoid ambiguity

function backend_show end
for M in (MIME"text/plain", MIME)
    @eval function Base.show(io::IO, m::$M, scene::Scene)
        res = get(io, :juno_plotsize, size(scene))
        resize!(scene, res...)
        update!(scene)
        AbstractPlotting.backend_show(current_backend[], io, m, scene)
    end
end

function backend_showable(backend, m::MIME, scene::Scene)
    hasmethod(backend_show, Tuple{typeof(backend), IO, typeof(m), typeof(scene)})
end

# fallback show when no backend is selected
function backend_show(backend, io::IO, ::MIME"text/plain", scene::Scene)
    println(io, "Scene ($(size(scene, 1))px, $(size(scene, 2))px):")
    println(io, "events:")
    for field in fieldnames(Events)
        println(io, "    ", field, ": ", to_value(getfield(scene.events, field)))
    end
    println(io, "plots:")
    for plot in scene.plots
        println(io, "   *", typeof(plot))
    end
    print(io, "subscenes:")
    for subscene in scene.children
        print(io, "\n   *scene($(size(subscene, 1))px, $(size(subscene, 2))px)")
    end
    return
end

function backend_show(backend, io::IO, ::MIME"text/plain", plot::Combined)
    println(io, typeof(plot))
    println(io, "plots:")
    for p in plot.plots
        println(io, "   *", typeof(p))
    end
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(v))")
    end
end

function Base.show(io::IO, ::MIME"text/plain", plot::Atomic)
    println(io, typeof(plot))
    print(io, "attributes:")
    for (k, v) in theme(plot)
        print(io, "\n  $k : $(typeof(to_value(v)))")
    end
end




# Stepper for generating progressive plot examples
mutable struct Stepper
    scene::Scene
    folder::String
    step::Int
end

function Stepper(scene, path)
    ispath(path) || mkpath(path)
    Stepper(scene, path, 1)
end

function FileIO.save(filename::String, scene::Scene)
    open(filename, "w") do s
        show(IOContext(s, :full_fidelity => true), MIME"image/png"(), scene)
    end
end
"""
    step!(s::Stepper)
steps through a `Makie.Stepper` and outputs a file with filename `filename-step.jpg`.
This is useful for generating progressive plot examples.
"""
function step!(s::Stepper)
    FileIO.save(joinpath(s.folder, basename(s.folder) * "-$(s.step).jpg"), s.scene)
    s.step += 1
    return s
end


"""
Record all window events that happen while executing function `f`
for `scene` and serializes them to `path`.
"""
function record_events(f, scene::Scene, path::String)
    display(scene)
    result = Vector{Pair{Float64, Pair{Symbol, Any}}}()
    for field in fieldnames(Events)
        on(getfield(scene.events, field)) do value
            value = isa(value, Set) ? copy(value) : value
            push!(result, time() => (field => value))
        end
    end
    f()
    open(path, "w") do io
        serialize(io, result)
    end
end


"""
Replays the serialized events recorded with `record_events` in `path` in `scene`.
"""
replay_events(scene::Scene, path::String) = replay_events(()-> nothing, scene, path)
function replay_events(f, scene::Scene, path::String)
    display(scene)
    events = open(io-> deserialize(io), path)
    sort!(events, by = first)
    for i in 1:length(events)
        t1, (field, value) = events[i]
        field == :mousedrag && continue
        if field == :mousebuttons
            Base.invokelatest() do
                getfield(scene.events, field)[] = value
            end
        else
            Base.invokelatest() do
                getfield(scene.events, field)[] = value
            end
        end
        f()
        yield()
        if i < length(events)
            t2, (field, value) = events[i + 1]
            # min sleep time 0.001
            (t2 - t1 > 0.001) && sleep(t2 - t1)
        end
    end
end


struct RecordEvents
    scene::Scene
    path::String
end

function Base.display(d::PlotDisplay, re::RecordEvents)
    display(d, re.scene)
end


export Stepper, step!, replay_events, record_events, RecordEvents
