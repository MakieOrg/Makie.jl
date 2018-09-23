struct PlotDisplay <: AbstractDisplay
end

"""
Currently available displays by backend
"""
const backend_displays = AbstractDisplay[]

function register_backend!(display::AbstractDisplay)
    push!(backend_displays, display)
end

# Hacky workaround, for the difficulty of removing closed screens from the display stack
# So we just leave the makiedisplay on stack, and then just get the singleton gl display for now!
function Base.display(::PlotDisplay, scene::Scene)
    if isempty(backend_displays)
        error("No backend display available. Make sure you're using a Plotting backend")
    end
    scene.updated[] = true
    force_update!()
    yield()
    # TODO integrate with mime system to select best available backend!
    display(first(backend_displays), scene)
end

function __init__()
    pushdisplay(PlotDisplay())
end

Base.showable(::MIME"text/plain", scene::Scene) = true

function Base.show(io::IO, m::MIME"text/plain", scene::Scene)
    println(io, "Scene ($(size(scene, 1))px, $(size(scene, 2))px):")
    println(io, "events:")
    for field in fieldnames(Events)
        println(io, "    ", field, ": ", to_value(getfield(scene.events, field)))
    end
    println(io, "plots:")
    for plot in scene.plots
        println(io, "   *", typeof(plot))
    end
    println(io, "subscenes:")
    for subscene in scene.children
        println(io, "   *scene($(size(subscene, 1))px, $(size(subscene, 2))px)")
    end
end

function Base.show(io::IO, m::MIME"text/plain", plot::Combined)
    println(io, typeof(plot))
    println(io, "plots:")
    for p in plot.plots
        println(io, "   *", typeof(p))
    end
    println(io, "attributes:")
    for (k, v) in theme(plot)
        println(io, "  $k : $(typeof(v))")
    end
end



function Base.show(io::IO, m::MIME"text/plain", plot::Atomic)
    println(io, typeof(plot))
    println(io, "attributes:")
    for (k, v) in theme(plot)
        println(io, "  $k : $(typeof(to_value(v)))")
    end
end
