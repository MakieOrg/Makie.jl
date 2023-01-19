include("interaction/iodevices.jl")


"""
    Events

This struct provides accessible `Observable`s to monitor the events
associated with a Scene.

Functions that act on a `Observable` must return `Consume()` if the function
consumes an event. When an event is consumed it does
not trigger other observer functions. The order in which functions are exectued
can be controlled via the `priority` keyword (default 0) in `on`.

Example:
```
on(events(scene).mousebutton, priority = 20) do event
    if is_correct_event(event)
        do_something()
        return Consume()
    end
    return
end
```

## Fields
$(TYPEDFIELDS)
"""
struct Events
    """
    The area of the window in pixels, as a `Rect2`.
    """
    window_area::Observable{Rect2i}
    """
    The DPI resolution of the window, as a `Float64`.
    """
    window_dpi::Observable{Float64}
    """
    The state of the window (open => true, closed => false).
    """
    window_open::Observable{Bool}

    """
    Most recently triggered `MouseButtonEvent`. Contains the relevant
    `event.button` and `event.action` (press/release)

    See also [`ispressed`](@ref).
    """
    mousebutton::Observable{MouseButtonEvent}
    """
    A Set of all currently pressed mousebuttons.
    """
    mousebuttonstate::Set{Mouse.Button}
    """
    The position of the mouse as a `NTuple{2, Float64}`.
    Updates once per event poll/frame.
    """
    mouseposition::Observable{NTuple{2, Float64}} # why no Vec2?
    """
    The direction of scroll
    """
    scroll::Observable{NTuple{2, Float64}} # why no Vec2?

    """
    Most recently triggered `KeyEvent`. Contains the relevant `event.key` and
    `event.action` (press/repeat/release)

    See also [`ispressed`](@ref).
    """
    keyboardbutton::Observable{KeyEvent}
    """
    Contains all currently pressed keys.
    """
    keyboardstate::Set{Keyboard.Button}

    """
    Contains the last typed character.
    """
    unicode_input::Observable{Char}
    """
    Contains a list of filepaths to files dragged into the scene.
    """
    dropped_files::Observable{Vector{String}}
    """
    Whether the Scene window is in focus or not.
    """
    hasfocus::Observable{Bool}
    """
    Whether the mouse is inside the window or not.
    """
    entered_window::Observable{Bool}
end

function Base.show(io::IO, events::Events)
    println(io, "Events:")
    fields = propertynames(events)
    maxlen = maximum(length ∘ string, fields)
    for field in propertynames(events)
        pad = maxlen - length(string(field)) + 1
        println(io, "  $field:", " "^pad, to_value(getproperty(events, field)))
    end
end

function Events()
    events = Events(
        Observable(Recti(0, 0, 0, 0)),
        Observable(100.0),
        Observable(false),

        Observable(MouseButtonEvent(Mouse.none, Mouse.release)),
        Set{Mouse.Button}(),
        Observable((0.0, 0.0)),
        Observable((0.0, 0.0)),

        Observable(KeyEvent(Keyboard.unknown, Keyboard.release)),
        Set{Keyboard.Button}(),
        Observable('\0'),
        Observable(String[]),
        Observable(false),
        Observable(false),
    )

    connect_states!(events)
    return events
end

function connect_states!(e::Events)
    on(e.mousebutton, priority = typemax(Int)) do event
        set = e.mousebuttonstate
        if event.action == Mouse.press
            push!(set, event.button)
        elseif event.action == Mouse.release
            delete!(set, event.button)
        else
            error("Unrecognized Keyboard action $(event.action)")
        end
        # This never consumes because it just keeps track of the state
        return Consume(false)
    end

    on(e.keyboardbutton, priority = typemax(Int)) do event
        set = e.keyboardstate
        if event.key != Keyboard.unknown
            if event.action == Keyboard.press
                push!(set, event.key)
            elseif event.action == Keyboard.release
                delete!(set, event.key)
            elseif event.action == Keyboard.repeat
                # set should already have the key
            else
                error("Unrecognized Keyboard action $(event.action)")
            end
        end
        # This never consumes because it just keeps track of the state
        return Consume(false)
    end
    return
end

# # Compat only
# function Base.getproperty(e::Events, field::Symbol)
#     if field === :mousebuttons
#         error("`events.mousebuttons` is deprecated. Use `events.mousebutton` to react to `MouseButtonEvent`s instead.")
#     elseif field === :keyboardbuttons
#         error("`events.keyboardbuttons` is deprecated. Use `events.keyboardbutton` to react to `KeyEvent`s instead.")
#     elseif field === :mousedrag
#         error("`events.mousedrag` is deprecated. Use `events.mousebutton` or a mouse state machine (`addmouseevents!`) instead.")
#     else
#         return getfield(e, field)
#     end
# end

function Base.empty!(events::Events)
    for field in fieldnames(Events)
        field in (:mousebuttonstate, :keyboardstate) && continue
        obs = getfield(events, field)
        for (prio, f) in obs.listeners
            prio == typemax(Int) && continue
            off(obs, f)
        end
    end
    return
end



struct TrackedObservable{T} <: AbstractObservable{T}
    observable::Observable{T}
    callbacks::Vector{Any} # or have CameraLift inherit from Function?
end

# Observable interface
for func in (:listeners, :observe, :obsid)
    @eval Observables.$(func)(to::TrackedObservable) = Observables.$(func)(to.observable)
end
# Is it ok to pretend this is the same as Observable?
Base.show(io::IO, to::TrackedObservable) = show(io, to.observable)
Base.show(io::IO, mime, to::TrackedObservable) = show(io, mime, to.observable)

# This should catch all cleanup
function Observables.off(@nospecialize(to::TrackedObservable), @nospecialize(f))
    x = off(to.observable, f)
    for i in eachindex(to.callbacks)
        if to.callbacks[i] === f
            deleteat!(to.callbacks, i)
        end
    end
    return x
end

# This should catch all connections
function Observables.register_callback(to::TrackedObservable, priority::Int, @nospecialize(f))
    Observables.register_callback(to.observable, priority, f)
    push!(to.callbacks, f)
    return 
end

# This is our specialized cleanup
function Base.empty!(to::TrackedObservable)
    for f in to.callbacks
        off(to, f)
    end
    empty!(to.callbacks)
    return
end



"""
    TrackedEvents

TrackedEvents is a wrapper around `Events` which tracks connected oberservables
for potential cleanup. It's usage matches the Events struct.
"""
struct TrackedEvents
    window_area::TrackedObservable{Rect2i}
    window_dpi::TrackedObservable{Float64}
    window_open::TrackedObservable{Bool}

    mousebutton::TrackedObservable{MouseButtonEvent}
    mousebuttonstate::Set{Mouse.Button}
    mouseposition::TrackedObservable{NTuple{2, Float64}} # why no Vec2?
    scroll::TrackedObservable{NTuple{2, Float64}} # why no Vec2?

    keyboardbutton::TrackedObservable{KeyEvent}
    keyboardstate::Set{Keyboard.Button}

    unicode_input::TrackedObservable{Char}
    dropped_files::TrackedObservable{Vector{String}}
    hasfocus::TrackedObservable{Bool}
    entered_window::TrackedObservable{Bool}
end

function TrackedEvents(parent::Events)
    TrackedEvents(
        TrackedObservable(parent.window_area, Any[]),
        TrackedObservable(parent.window_dpi, Any[]),
        TrackedObservable(parent.window_open, Any[]),

        TrackedObservable(parent.mousebutton, Any[]),
        parent.mousebuttonstate,
        TrackedObservable(parent.mouseposition, Any[]),
        TrackedObservable(parent.scroll, Any[]),

        TrackedObservable(parent.keyboardbutton, Any[]),
        parent.keyboardstate,

        TrackedObservable(parent.unicode_input, Any[]),
        TrackedObservable(parent.dropped_files, Any[]),
        TrackedObservable(parent.hasfocus, Any[]),
        TrackedObservable(parent.entered_window, Any[]),
    )
end

function TrackedEvents(parent::TrackedEvents)
    TrackedEvents(
        TrackedObservable(parent.window_area.observable, Any[]),
        TrackedObservable(parent.window_dpi.observable, Any[]),
        TrackedObservable(parent.window_open.observable, Any[]),

        TrackedObservable(parent.mousebutton.observable, Any[]),
        parent.mousebuttonstate,
        TrackedObservable(parent.mouseposition.observable, Any[]),
        TrackedObservable(parent.scroll.observable, Any[]),

        TrackedObservable(parent.keyboardbutton.observable, Any[]),
        parent.keyboardstate,

        TrackedObservable(parent.unicode_input.observable, Any[]),
        TrackedObservable(parent.dropped_files.observable, Any[]),
        TrackedObservable(parent.hasfocus.observable, Any[]),
        TrackedObservable(parent.entered_window.observable, Any[]),
    )
end

function Base.empty!(e::TrackedEvents)
    for field in fieldnames(TrackedEvents)
        (field === :mousebuttonstate || field === :keyboardstate) && continue
        empty!(getfield(e, field))
    end
    return
end
