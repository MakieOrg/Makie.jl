window_area(scene, native_window) = not_implemented_for(native_window)
window_open(scene, native_window) = not_implemented_for(native_window)
mouse_buttons(scene, native_window) = not_implemented_for(native_window)
mouse_position(scene, native_window) = not_implemented_for(native_window)
scroll(scene, native_window) = not_implemented_for(native_window)
keyboard_buttons(scene, native_window) = not_implemented_for(native_window)
unicode_input(scene, native_window) = not_implemented_for(native_window)
dropped_files(scene, native_window) = not_implemented_for(native_window)
hasfocus(scene, native_window) = not_implemented_for(native_window)
entered_window(scene, native_window) = not_implemented_for(native_window)
frame_tick(scene, native_window) = not_implemented_for(native_window)

function connect_screen(scene::Scene, screen)

    on(scene, screen.window_open) do open
        events(scene).window_open[] = open
    end

    window_area(scene, screen)
    window_open(scene, screen)
    mouse_buttons(scene, screen)
    mouse_position(scene, screen)
    scroll(scene, screen)
    keyboard_buttons(scene, screen)
    unicode_input(scene, screen)
    dropped_files(scene, screen)
    hasfocus(scene, screen)
    entered_window(scene, screen)
    frame_tick(scene, screen)

    return
end

to_native(window::MakieScreen) = error("to_native(window) not implemented for $(typeof(window)).")
disconnect!(window::MakieScreen, signal) = disconnect!(to_native(window), signal)

function disconnect_screen(scene::Scene, screen)
    e = events(scene)
    # the isopen check was never needed, since we didn't seem to disconnect from a closed screen.
    # But due to a bug, it became clear that disconnecting events from a destroyed screen may segfault...
    if isopen(screen)
        disconnect!(screen, window_area)
        disconnect!(screen, window_open)
        disconnect!(screen, mouse_buttons)
        disconnect!(screen, mouse_position)
        disconnect!(screen, scroll)
        disconnect!(screen, keyboard_buttons)
        disconnect!(screen, unicode_input)
        disconnect!(screen, dropped_files)
        disconnect!(screen, hasfocus)
        disconnect!(screen, entered_window)
        disconnect!(screen, frame_tick)
    end
    return
end

"""
Picks a mouse position. Implemented by the backend.
"""
function pick end

function pick(::Scene, ::Screen, xy) where {Screen}
    @warn "Picking not supported yet by $(parentmodule(Screen))" maxlog = 1
    return nothing, 0
end

"""
    onpick(func, plot)
Calls `func` if one clicks on `plot`. Implemented by the backend.
"""
function onpick end


mutable struct TickCallback
    event::Observable{Makie.Tick}
    start_time::UInt64
    last_time::UInt64
    TickCallback(tick::Observable{Makie.Tick}) = new(tick, time_ns(), time_ns())
end
TickCallback(scene::SceneLike) = TickCallback(events(scene).tick)

function (cb::TickCallback)(x::Makie.TickState)
    if x > Makie.UnknownTickState # not backend or Unknown
        cb.last_time = Makie.next_tick!(cb.event, x, cb.start_time, cb.last_time)
    end
    return nothing
end

function next_tick!(tick::Observable{Tick}, state::TickState, start_time::UInt64, last_time::UInt64)
    t = time_ns()
    since_start = 1.0e-9 * (t - start_time)
    delta_time = 1.0e-9 * (t - last_time)
    tick[] = Tick(state, tick[].count + 1, since_start, delta_time)
    return t
end


################################################################################
### ispressed logic
################################################################################


"""
    And(left, right[, rest...])

Creates an `And` struct with the left and right argument for later evaluation.
If more than two arguments are given a tree of `And` structs is created.

See also: [`Or`](@ref), [`Not`](@ref), [`ispressed`](@ref), `&`
"""
struct And{L, R} <: BooleanOperator
    left::L
    right::R
end
And(left::Bool, right) = left ? right : false
And(left, right::Bool) = right ? left : false

"""
    Or(left, right[, rest...])

Creates an `Or` struct with the left and right argument for later evaluation.
If more than two arguments are given a tree of `Or` structs is created.

See also: [`And`](@ref), [`Not`](@ref), [`ispressed`](@ref), `|`
"""
struct Or{L, R} <: BooleanOperator
    left::L
    right::R
end
Or(left::Bool, right) = left ? true : right
Or(left, right::Bool) = right ? true : left

"""
    Not(x)

Creates a `Not` struct with the given argument for later evaluation.

See also: [`And`](@ref), [`Or`](@ref), [`ispressed`](@ref), `!`
"""
struct Not{T} <: BooleanOperator
    x::T
end
Not(x::Bool) = !x

"""
    Exclusively(x)

Marks a button, button collection or logical expression of buttons as the
exclusive subset of buttons that must be pressed for `ispressed` to return true.

For example `Exclusively((Keyboard.left_control, Keyboard.c))` would require
left control and c to be pressed without any other buttons.

Boolean expressions are lowered to multiple `Exclusive` sets in an `Or`. It is
worth noting that `Not` branches are ignored here, i.e. it assumed that every
button under a `Not` must not be pressed and that this follows automatically
from the subset of buttons that must be pressed.

See also: [`And`](@ref), [`Or`](@ref), [`Not`](@ref), [`ispressed`](@ref),
`&`, `|`, `!`
"""
struct Exclusively <: BooleanOperator
    x::Set{Union{Keyboard.Button, Mouse.Button}}
end

# Printing

function Base.show(io::IO, op::And)
    print(io, "(")
    show(io, op.left)
    print(io, " & ")
    show(io, op.right)
    return print(io, ")")
end
function Base.show(io::IO, op::Or)
    print(io, "(")
    show(io, op.left)
    print(io, " | ")
    show(io, op.right)
    return print(io, ")")
end
function Base.show(io::IO, op::Not)
    print(io, "!")
    return show(io, op.x)
end
function Base.show(io::IO, op::Exclusively)
    print(io, "exclusively(")
    join(io, op.x, " & ")
    return print(io, ")")
end

# Constructors

And(left, right, rest...) = And(And(left, right), rest...)
Or(left, right, rest...) = Or(Or(left, right), rest...)
And(x) = x
Or(x) = x


function Base.:(&)(
        left::Union{BooleanOperator, Keyboard.Button, Mouse.Button},
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button, Bool}
    )
    return And(left, right)
end
function Base.:(&)(
        left::Bool,
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    return And(left, right)
end
function Base.:(|)(
        left::Union{BooleanOperator, Keyboard.Button, Mouse.Button},
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button, Bool}
    )
    return Or(left, right)
end
function Base.:(|)(
        left::Bool,
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    return Or(left, right)
end
Base.:(!)(x::Union{BooleanOperator, Keyboard.Button, Mouse.Button}) = Not(x)


Exclusively(x::Union{Vector, Tuple}) = Exclusively(Set(x))
Exclusively(x::Union{Keyboard.Button, Mouse.Button}) = Exclusively(Set((x,)))
Exclusively(x::Bool) = x
Exclusively(x::Or) = Or(Exclusively(x.left), Exclusively(x.right))
Exclusively(x::And) = Or(Exclusively.(unique(create_sets(x)))...)


# Sets represent `And`, arrays represent `Or`
function create_sets(x::And)
    return [
        union(left, right) for left in create_sets(x.left)
            for right in create_sets(x.right)
    ]
end
create_sets(x::Or) = vcat(create_sets(x.left), create_sets(x.right))
create_sets(::Not) = Set{Union{Keyboard.Button, Mouse.Button}}()
function create_sets(b::Union{Keyboard.Button, Mouse.Button})
    return [Set{Union{Keyboard.Button, Mouse.Button}}((b,))]
end
create_sets(s::Set) = [Set{Union{Keyboard.Button, Mouse.Button}}(s)]


# ispressed and logic evaluation

"""
    ispressed(parent, result::Bool[, waspressed = nothing])
    ispressed(parent, button::Union{Mouse.Button, Keyboard.Button[, waspressed = nothing])
    ispressed(parent, collection::Union{Set, Vector, Tuple}[, waspressed = nothing])
    ispressed(parent, op::BooleanOperator[, waspressed = nothing])

This function checks if a button or combination of buttons is pressed.

If given a true or false, `ispressed` will return true or false respectively.
This provides a way to turn an interaction "always on" or "always off" from the
outside.

Passing a button or collection of buttons such as `Keyboard.enter` or
`Mouse.left` will return true if all of the given buttons are pressed.

Parent can be any object that has `get_scene` method implemented, which includes
e.g. Figure, Axis, Axis3, Lscene, FigureAxisPlot, and AxisPlot.

For more complicated combinations of buttons they can be combined into boolean
expression with `&`, `|` and `!`. For example, you can have
`ispressed(parent, !Keyboard.left_control & Keyboard.c))` and
`ispressed(parent, Keyboard.left_control & Keyboard.c)` to avoid triggering both
cases at the same time.

Furthermore you can also make any button, button collection or boolean
expression exclusive by wrapping it in `Exclusively(...)`. With that `ispressed`
will only return true if the currently pressed buttons match the request exactly.

For cases where you want to react to a release event you can optionally add
a key or mousebutton `waspressed` which is then assumed to be pressed regardless
of it's current state. For example, when reacting to a mousebutton event, you can
pass `event.button` so that a key combination including that button still evaluates
as true.

See also: [`And`](@ref), [`Or`](@ref), [`Not`](@ref), [`Exclusively`](@ref),
`&`, `|`, `!`
"""
ispressed(events::Events, mb::Mouse.Button, waspressed = nothing) = mb in events.mousebuttonstate || mb == waspressed
ispressed(events::Events, key::Keyboard.Button, waspressed = nothing) = key in events.keyboardstate || key == waspressed
ispressed(parent, result::Bool, waspressed = nothing) = result

ispressed(parent, mb::Mouse.Button, waspressed = nothing) = ispressed(events(parent), mb, waspressed)
ispressed(parent, key::Keyboard.Button, waspressed = nothing) = ispressed(events(parent), key, waspressed)

# Boolean Operator evaluation
ispressed(parent, op::And, waspressed = nothing) = ispressed(parent, op.left, waspressed) && ispressed(parent, op.right, waspressed)
ispressed(parent, op::Or, waspressed = nothing) = ispressed(parent, op.left, waspressed) || ispressed(parent, op.right, waspressed)
ispressed(parent, op::Not, waspressed = nothing) = !ispressed(parent, op.x, waspressed)
ispressed(parent, op::Exclusively, waspressed = nothing) = ispressed(events(parent), op, waspressed)
ispressed(e::Events, op::Exclusively, waspressed::Union{Mouse.Button, Keyboard.Button}) = op.x == union(e.keyboardstate, e.mousebuttonstate, waspressed)
ispressed(e::Events, op::Exclusively, waspressed = nothing) = op.x == union(e.keyboardstate, e.mousebuttonstate)

# collections
ispressed(parent, set::Set, waspressed = nothing) = all(x -> ispressed(parent, x, waspressed), set)
ispressed(parent, set::Vector, waspressed = nothing) = all(x -> ispressed(parent, x, waspressed), set)
ispressed(parent, set::Tuple, waspressed = nothing) = all(x -> ispressed(parent, x, waspressed), set)
