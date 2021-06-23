abstract type AbstractCamera end

# placeholder if no camera is present
struct EmptyCamera <: AbstractCamera end

@enum RaymarchAlgorithm begin
    IsoValue # 0
    Absorption # 1
    MaximumIntensityProjection # 2
    AbsorptionRGBA # 3
    AdditiveRGBA # 4
    IndexedAbsorptionRGBA # 5
end

include("interaction/iodevices.jl")


"""
This struct provides accessible `PriorityObservable`s to monitor the events
associated with a Scene.

Functions that act on a `PriorityObservable` must return `Consume()` if the function
consumes an event. When an event is consumed it does
not trigger other observer functions. The order in which functions are exectued
can be controlled via the `priority` keyword (default 0) in `on`.

Example:
```
on(events(scene).mousebutton, priority = Int8(20)) do event
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
    The area of the window in pixels, as a `Rect2D`.
    """
    window_area::PriorityObservable{IRect2D}
    """
    The DPI resolution of the window, as a `Float64`.
    """
    window_dpi::PriorityObservable{Float64}
    """
    The state of the window (open => true, closed => false).
    """
    window_open::PriorityObservable{Bool}

    """
    Most recently triggered `MouseButtonEvent`. Contains the relevant
    `event.button` and `event.action` (press/release)

    See also [`ispressed`](@ref).
    """
    mousebutton::PriorityObservable{MouseButtonEvent}
    """
    A Set of all currently pressed mousebuttons.
    """
    mousebuttonstate::Set{Mouse.Button}
    """
    The position of the mouse as a `NTuple{2, Float64}`.
    Updates once per event poll/frame.
    """
    mouseposition::PriorityObservable{NTuple{2, Float64}} # why no Vec2?
    """
    The direction of scroll
    """
    scroll::PriorityObservable{NTuple{2, Float64}} # why no Vec2?

    """
    Most recently triggered `KeyEvent`. Contains the relevant `event.key` and
    `event.action` (press/repeat/release)

    See also [`ispressed`](@ref).
    """
    keyboardbutton::PriorityObservable{KeyEvent}
    """
    Contains all currently pressed keys.
    """
    keyboardstate::Set{Keyboard.Button}

    """
    Contains the last typed character.
    """
    unicode_input::PriorityObservable{Char}
    """
    Contains a list of filepaths to files dragged into the scene.
    """
    dropped_files::PriorityObservable{Vector{String}}
    """
    Whether the Scene window is in focus or not.
    """
    hasfocus::PriorityObservable{Bool}
    """
    Whether the mouse is inside the window or not.
    """
    entered_window::PriorityObservable{Bool}
end

function Events()
    mousebutton = PriorityObservable(MouseButtonEvent(Mouse.none, Mouse.release))
    mousebuttonstate = Set{Mouse.Button}()
    on(mousebutton, priority = typemax(Int8)) do event
        set = mousebuttonstate
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

    keyboardbutton = PriorityObservable(KeyEvent(Keyboard.unknown, Keyboard.release))
    keyboardstate = Set{Keyboard.Button}()
    on(keyboardbutton, priority = typemax(Int8)) do event
        set = keyboardstate
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

    return Events(
        PriorityObservable(IRect(0, 0, 0, 0)),
        PriorityObservable(100.0),
        PriorityObservable(false),

        mousebutton, mousebuttonstate,
        PriorityObservable((0.0, 0.0)),
        PriorityObservable((0.0, 0.0)),

        keyboardbutton, keyboardstate,

        PriorityObservable('\0'),
        PriorityObservable(String[]),
        PriorityObservable(false),
        PriorityObservable(false),
    )
end

# Compat only
function Base.getproperty(e::Events, field::Symbol)
    if field == :mousebuttons
        try
            error()
        catch ex
            bt = catch_backtrace()
            @warn(
                "`events.mousebuttons` is deprecated. Use `events.mousebutton` to " *
                "react to `MouseButtonEvent`s instead and ``."
            )
            Base.show_backtrace(stderr, bt)
            println(stderr)
        end
        mousebuttons = Node(Set{Mouse.Button}())
        on(getfield(e, :mousebutton), priority=typemax(Int8)-1) do event
            mousebuttons[] = getfield(e, :mousebuttonstate)
            return Consume(false)
        end
        return mousebuttons
    elseif field == :keyboardbuttons
        try
            error()
        catch ex
            bt = catch_backtrace()
            @warn(
                "`events.keyboardbuttons` is deprecated. Use " *
                "`events.keyboardbutton` to react to `KeyEvent`s instead."
            )
            Base.show_backtrace(stderr, bt)
            println(stderr)
        end
        keyboardbuttons = Node(Set{Keyboard.Button}())
        on(getfield(e, :keyboardbutton), priority=typemax(Int8)-1) do event
            keyboardbuttons[] = getfield(e, :keyboardstate)
            return Consume(false)
        end
        return keyboardbuttons
    elseif field == :mousedrag
        try
            error()
        catch ex
            bt = catch_backtrace()
            @warn(
                "`events.mousedrag` is deprecated. Use `events.mousebutton` or a " *
                "mouse state machine (`addmouseevents!`) instead."
            )
            Base.show_backtrace(stderr, bt)
            println(stderr)
        end
        mousedrag = Node(Mouse.notpressed)
        on(getfield(e, :mousebutton), priority=typemax(Int8)-1) do event
            if (event.action == Mouse.press) && (length(e.mousebuttonstate) == 1)
                mousedrag[] = Mouse.down
            elseif mousedrag[] in (Mouse.down, Mouse.pressed)
                mousedrag[] = Mouse.up
            end
            return Consume(false)
        end
        on(getfield(e, :mouseposition), priority=typemax(Int8)-1) do pos
            if mousedrag[] in (Mouse.down, Mouse.pressed)
                mousedrag[] = Mouse.pressed
            elseif mousedrag[] == Mouse.up
                mousedrag[] = Mouse.notpressed
            end
            return Consume(false)
        end
        return mousedrag
    else
        getfield(e, field)
    end
end

mutable struct Camera
    pixel_space::Node{Mat4f0}
    view::Node{Mat4f0}
    projection::Node{Mat4f0}
    projectionview::Node{Mat4f0}
    resolution::Node{Vec2f0}
    eyeposition::Node{Vec3f0}
    steering_nodes::Vector{ObserverFunction}
end

"""
Holds the transformations for Scenes.
## Fields
$(TYPEDFIELDS)
"""
struct Transformation <: Transformable
    parent::RefValue{Transformable}
    translation::Node{Vec3f0}
    scale::Node{Vec3f0}
    rotation::Node{Quaternionf0}
    model::Node{Mat4f0}
    flip::Node{NTuple{3, Bool}}
    align::Node{Vec2f0}
    # data conversion node, for e.g. log / log10 etc
    transform_func::Node{Any}
    function Transformation(translation, scale, rotation, model, flip, align, transform_func)
        return new(
            RefValue{Transformable}(),
            translation, scale, rotation, model, flip, align, transform_func
        )
    end
end

"""
`PlotSpec{P<:AbstractPlot}(args...; kwargs...)`

Object encoding positional arguments (`args`), a `NamedTuple` of attributes (`kwargs`)
as well as plot type `P` of a basic plot.
"""
struct PlotSpec{P<:AbstractPlot}
    args::Tuple
    kwargs::NamedTuple
    PlotSpec{P}(args...; kwargs...) where {P<:AbstractPlot} = new{P}(args, values(kwargs))
end

PlotSpec(args...; kwargs...) = PlotSpec{Combined{Any}}(args...; kwargs...)

Base.getindex(p::PlotSpec, i::Int) = getindex(p.args, i)
Base.getindex(p::PlotSpec, i::Symbol) = getproperty(p.kwargs, i)

to_plotspec(::Type{P}, args; kwargs...) where {P} =
    PlotSpec{P}(args...; kwargs...)

to_plotspec(::Type{P}, p::PlotSpec{S}; kwargs...) where {P, S} =
    PlotSpec{plottype(P, S)}(p.args...; p.kwargs..., kwargs...)

plottype(::PlotSpec{P}) where {P} = P
