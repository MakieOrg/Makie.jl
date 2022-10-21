

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

function connect_screen(scene::Scene, screen)
    while !isempty(scene.current_screens)
        old_screen = pop!(scene.current_screens)
        disconnect_screen(scene, old_screen)
        old_screen !== screen && close(old_screen)
    end

    push_screen!(scene, screen)

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

    return
end

to_native(window::AbstractScreen) = error("to_native(window) not implemented for $(typeof(window)).")
disconnect!(window::AbstractScreen, signal) = disconnect!(to_native(window), signal)

function disconnect_screen(scene::Scene, screen)
    delete_screen!(scene, screen)
    e = events(scene)

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

    return
end

"""
Picks a mouse position.  Implemented by the backend.
"""
function pick end

function pick(::Scene, ::Screen, xy) where Screen
    @warn "Picking not supported yet by $(parentmodule(Screen))" maxlog=1
    return nothing, 0
end

"""
    onpick(func, plot)
Calls `func` if one clicks on `plot`.  Implemented by the backend.
"""
function onpick end


################################################################################
### ispressed logic
################################################################################


abstract type BooleanOperator end

"""
    And(left, right[, rest...])

Creates an `And` struct with the left and right argument for later evaluation.
If more than two arguments are given a tree of `And` structs is created.

See also: [`Or`](@ref), [`Not`](@ref), [`ispressed`](@ref), [`&`](@ref)
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

See also: [`And`](@ref), [`Not`](@ref), [`ispressed`](@ref), [`|`](@ref)
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

See also: [`And`](@ref), [`Or`](@ref), [`ispressed`](@ref), [`!`](@ref)
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
[`&`](@ref), [`|`](@ref), [`!`](@ref)
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
    print(io, ")")
end
function Base.show(io::IO, op::Or)
    print(io, "(")
    show(io, op.left)
    print(io, " | ")
    show(io, op.right)
    print(io, ")")
end
function Base.show(io::IO, op::Not)
    print(io, "!")
    show(io, op.x)
end
function Base.show(io::IO, op::Exclusively)
    print(io, "exclusively(")
    join(io, op.x, " & ")
    print(io, ")")
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
    And(left, right)
end
function Base.:(&)(
        left::Bool,
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    And(left, right)
end
function Base.:(|)(
        left::Union{BooleanOperator, Keyboard.Button, Mouse.Button},
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button, Bool}
    )
    Or(left, right)
end
function Base.:(|)(
        left::Bool,
        right::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    Or(left, right)
end
Base.:(!)(x::Union{BooleanOperator, Keyboard.Button, Mouse.Button}) = Not(x)


Exclusively(x::Union{Vector, Tuple}) = Exclusively(Set(x))
Exclusively(x::Union{Keyboard.Button, Mouse.Button}) = Exclusively(Set((x,)))
Exclusively(x::Bool) = x
Exclusively(x::Or) = Or(Exclusively(x.left), Exclusively(x.right))
Exclusively(x::And) = Or(Exclusively.(unique(create_sets(x)))...)


# Sets represent `And`, arrays represent `Or`
function create_sets(x::And)
    [union(left, right) for left in create_sets(x.left)
                        for right in create_sets(x.right)]
end
create_sets(x::Or) = vcat(create_sets(x.left), create_sets(x.right))
create_sets(::Not) = Set{Union{Keyboard.Button, Mouse.Button}}()
function create_sets(b::Union{Keyboard.Button, Mouse.Button})
    [Set{Union{Keyboard.Button, Mouse.Button}}((b,))]
end
create_sets(s::Set) = [Set{Union{Keyboard.Button, Mouse.Button}}(s)]


# ispressed and logic evaluation

"""
    ispressed(scene, result::Bool)
    ispressed(scene, button::Union{Mouse.Button, Keyboard.Button)
    ispressed(scene, collection::Union{Set, Vector, Tuple})
    ispressed(scene, op::BooleanOperator)

This function checks if a button or combination of buttons is pressed.

If given a true or false, `ispressed` will return true or false respectively.
This provides a way to turn an interaction "always on" or "always off" from the
outside.

Passing a button or collection of buttons such as `Keyboard.enter` or
`Mouse.left` will return true if all of the given buttons are pressed.

For more complicated combinations of buttons they can be combined into boolean
expression with `&`, `|` and `!`. For example, you can have
`ispressed(scene, !Keyboard.left_control & Keyboard.c))` and
`ispressed(scene, Keyboard.left_control & Keyboard.c)` to avoid triggering both
cases at the same time.

Furthermore you can also make any button, button collection or boolean
expression exclusive by wrapping it in `Exclusively(...)`. With that `ispressed`
will only return true if the currently pressed buttons match the request exactly.

See also: [`And`](@ref), [`Or`](@ref), [`Not`](@ref), [`Exclusively`](@ref),
[`&`](@ref), [`|`](@ref), [`!`](@ref)
"""
ispressed(events::Events, mb::Mouse.Button) = mb in events.mousebuttonstate
ispressed(events::Events, key::Keyboard.Button) = key in events.keyboardstate
ispressed(scene, result::Bool) = result

ispressed(scene, mb::Mouse.Button) = ispressed(events(scene), mb)
ispressed(scene, key::Keyboard.Button) = ispressed(events(scene), key)
@deprecate ispressed(scene, ::Nothing) ispressed(scene, true)

# Boolean Operator evaluation
ispressed(scene, op::And) = ispressed(scene, op.left) && ispressed(scene, op.right)
ispressed(scene, op::Or)  = ispressed(scene, op.left) || ispressed(scene, op.right)
ispressed(scene, op::Not) = !ispressed(scene, op.x)
ispressed(scene::Scene, op::Exclusively) = ispressed(events(scene), op)
ispressed(e::Events, op::Exclusively) = op.x == union(e.keyboardstate, e.mousebuttonstate)

# collections
ispressed(scene, set::Set) = all(x -> ispressed(scene, x), set)
ispressed(scene, set::Vector) = all(x -> ispressed(scene, x), set)
ispressed(scene, set::Tuple) = all(x -> ispressed(scene, x), set)
