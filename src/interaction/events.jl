function disconnect!(window::AbstractScreen, signal)
    disconnect!(to_native(window), signal)
end
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

function register_callbacks(scene::Scene, native_window)

    window_area(scene, native_window)
    window_open(scene, native_window)
    mouse_buttons(scene, native_window)
    mouse_position(scene, native_window)
    scroll(scene, native_window)
    keyboard_buttons(scene, native_window)
    unicode_input(scene, native_window)
    dropped_files(scene, native_window)
    hasfocus(scene, native_window)
    entered_window(scene, native_window)

end

"""
Picks a mouse position.  Implemented by the backend.
"""
function pick end

"""
    onpick(func, plot)
Calls `func` if one clicks on `plot`.  Implemented by the backend.
"""
function onpick end


# ispressed logic

abstract type BooleanOperator end

struct And{L, R} <: BooleanOperator
    l::L
    r::R
end

struct Or{L, R} <: BooleanOperator
    l::L
    r::R
end

struct Not{T} <: BooleanOperator
    x::T
end


function Base.show(io::IO, op::And)
    print(io, "(")
    show(io, op.l)
    print(io, " && ")
    show(io, op.r) 
    print(io, ")")
end
function Base.show(io::IO, op::Or)
    print(io, "(")
    show(io, op.l)
    print(io, " || ")
    show(io, op.r) 
    print(io, ")")
end
function Base.show(io::IO, op::Not)
    print(io, "!")
    show(io, op.x)
end


And(l, r, rest...) = And(And(l, r), rest...)
Or(l, r, rest...) = Or(Or(l, r), rest...)


function Base.:(&)(
        l::Union{BooleanOperator, Keyboard.Button, Mouse.Button}, 
        r::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    And(l, r)
end
function Base.:(|)(
        l::Union{BooleanOperator, Keyboard.Button, Mouse.Button}, 
        r::Union{BooleanOperator, Keyboard.Button, Mouse.Button}
    )
    Or(l, r)
end
Base.:(!)(x::Union{BooleanOperator, Keyboard.Button, Mouse.Button}) = Not(x)


# Direct methods
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

For more complicated combinations of buttons the `BooleanOperator` method can be 
used. Buttons can be combined into boolean expression with `&`, `|` and `!`
which can be passed to ispressed for evaluation. For example, you may have one 
action `ispressed(scene, !Keyboard.left_control & Keyboard.c))` and another
`ispressed(scene, Keyboard.left_control & Keyboard.c)`.
"""
ispressed(scene, mb::Mouse.Button) = mb in scene.events.mousebuttonstate
ispressed(scene, key::Keyboard.Button) = key in scene.events.keyboardstate
ispressed(scene, result::Bool) = result
@deprecate ispressed(scene, ::Nothing) ispressed(scene, true)

# Boolean Operator evaluation
ispressed(scene, op::And) = ispressed(scene, op.l) && ispressed(scene, op.r)
ispressed(scene, op::Or)  = ispressed(scene, op.l) || ispressed(scene, op.r)
ispressed(scene, op::Not) = !ispressed(scene, op.x)

# collections
ispressed(scene, set::Set) = all(x -> ispressed(scene, x), set)
ispressed(scene, set::Vector) = all(x -> ispressed(scene, x), set)
ispressed(scene, set::Tuple) = all(x -> ispressed(scene, x), set)
