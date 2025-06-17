using Makie: MouseButtonEvent, KeyEvent, Figure, Textbox
using Makie: Not, And, Or
using InteractiveUtils

# rudimentary equality for tests
Base.:(==)(l::Exclusively, r::Exclusively) = l.x == r.x
Base.:(==)(l::Not, r::Not) = l.x == r.x
Base.:(==)(l::And, r::And) = l.left == r.left && l.right == r.right
Base.:(==)(l::Or, r::Or) = l.left == r.left && l.right == r.right

function Base.isapprox(a::Rect{N, T}, b::Rect{N, T}; kwargs...) where {N, T}
    return isapprox(minimum(a), minimum(b); kwargs...) &&
        isapprox(widths(a), widths(b); kwargs...)
end

@testset "Mouse and Keyboard state" begin
    events = Makie.Events()
    @test isempty(events.mousebuttonstate)
    @test isempty(events.keyboardstate)

    events.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.press)
    @test events.mousebuttonstate == Set([Mouse.left])
    @test events.keyboardstate == Set([Keyboard.a])

    events.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    events.keyboardbutton[] = KeyEvent(Keyboard.b, Keyboard.press)
    @test events.mousebuttonstate == Set([Mouse.left, Mouse.right])
    @test events.keyboardstate == Set([Keyboard.a, Keyboard.b])

    events.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.release)
    @test events.mousebuttonstate == Set([Mouse.right])
    @test events.keyboardstate == Set([Keyboard.b])

    events.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    events.keyboardbutton[] = KeyEvent(Keyboard.b, Keyboard.release)
    @test isempty(events.mousebuttonstate)
    @test isempty(events.keyboardstate)
end

@testset "ispressed" begin
    events = Makie.Events()
    @test isempty(events.mousebuttonstate)
    @test isempty(events.keyboardstate)

    events.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.press)

    # Buttons
    @test ispressed(events, Keyboard.a)
    @test !ispressed(events, Keyboard.b)
    @test ispressed(events, Mouse.left)
    @test !ispressed(events, Mouse.right)

    # Collections
    @test ispressed(events, (Keyboard.a,))
    @test ispressed(events, [Keyboard.a])
    @test ispressed(events, Set((Keyboard.a,)))

    @test !ispressed(events, (Keyboard.a, Keyboard.b))
    @test !ispressed(events, [Keyboard.a, Keyboard.b])
    @test !ispressed(events, Set((Keyboard.a, Keyboard.b)))

    @test ispressed(events, (Keyboard.a, Mouse.left))
    @test ispressed(events, [Keyboard.a, Mouse.left])
    @test ispressed(events, Set((Keyboard.a, Mouse.left)))

    # Boolean
    @test ispressed(events, Keyboard.a & Mouse.left)
    @test !ispressed(events, Keyboard.a & Mouse.right)
    @test ispressed(events, Keyboard.a & !Mouse.right)
    @test !ispressed(events, !Keyboard.a & Mouse.left)

    @test ispressed(events, Keyboard.a | Mouse.left)
    @test ispressed(events, Keyboard.a | Mouse.right)
    @test !ispressed(events, Keyboard.b | Mouse.right)
    @test ispressed(events, Keyboard.b | !Mouse.right)

    # Exclusively
    @test !ispressed(events, Exclusively(Keyboard.a))
    @test !ispressed(events, Exclusively(Mouse.left))

    @test ispressed(events, Exclusively((Keyboard.a, Mouse.left)))
    @test ispressed(events, Exclusively([Keyboard.a, Mouse.left]))
    @test ispressed(events, Exclusively(Set((Keyboard.a, Mouse.left))))

    @test Exclusively(Keyboard.a & Mouse.left) == Exclusively((Keyboard.a, Mouse.left))
    @test ispressed(events, Exclusively(Keyboard.a & Mouse.left))
    @test Exclusively(Keyboard.a | Mouse.left) == Makie.Or(Exclusively(Keyboard.a), Exclusively(Mouse.left))
    @test !ispressed(events, Exclusively(Keyboard.a | Mouse.left))

    expr = Mouse.left & (Keyboard.a | (Keyboard.a & Keyboard.b))
    lowered = Or(
        Exclusively((Mouse.left, Keyboard.a)),
        Exclusively((Mouse.left, Keyboard.a, Keyboard.b))
    )
    @test ispressed(events, expr)
    @test Exclusively(expr) == lowered
    @test ispressed(events, Exclusively(expr))

    events.keyboardbutton[] = KeyEvent(Keyboard.b, Keyboard.press)
    @test ispressed(events, expr)
    @test ispressed(events, Exclusively(expr))

    events.keyboardbutton[] = KeyEvent(Keyboard.c, Keyboard.press)
    @test ispressed(events, expr)
    @test !ispressed(events, Exclusively(expr))

    events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.release)
    @test !ispressed(events, expr)
    @test !ispressed(events, Exclusively(expr))

    # Bools
    @test ispressed(events, true)
    @test !ispressed(events, false)

    @test Exclusively(true) == true
    @test Exclusively(false) == false

    for x in (Keyboard.a, Mouse.left)
        @test true & x == x
        @test x & true == x
        @test false & x == false
        @test x & false == false

        @test true | x == true
        @test x | true == true
        @test false | x == x
        @test x | false == x
    end
end

@testset "copy_paste" begin
    # Hack to get clipboard() working without much setup
    @eval InteractiveUtils begin
        const CLIP = Ref{String}()
        clipboard(str::String) = (CLIP[] = str)
        clipboard() = CLIP[]
    end

    f = Figure(size = (640, 480))
    tb = Textbox(f[1, 1], placeholder = "Copy/paste into me")
    e = events(f.scene)

    # Initial state
    @test !tb.focused[]
    @test tb.stored_string[] === nothing

    # Select textbox
    e.mouseposition[] = (320, 240)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test tb.focused[]

    # Fill clipboard with a string
    clipboard("test string")

    # Trigger left ctrl+v
    e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.v, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.v, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.enter, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.enter, Keyboard.release)

    @test tb.stored_string[] == "test string"


    # Refresh figure to test right control + v combination
    empty!(f)

    f = Figure(size = (640, 480))
    tb = Textbox(f[1, 1], placeholder = "Copy/paste into me")
    e = events(f.scene)

    # Initial state
    @test !tb.focused[]
    @test tb.stored_string[] === nothing

    # Re-select textbox
    e.mouseposition[] = (320, 240)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test tb.focused[]

    clipboard("test string2")

    # Trigger right ctrl+v
    e.keyboardbutton[] = KeyEvent(Keyboard.right_control, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.v, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.v, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.right_control, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.enter, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.enter, Keyboard.release)

    @test tb.stored_string[] == "test string2"
end

@testset "Builtin interaction helpers" begin
    f = Figure(size = (400, 400))
    a = Axis(f[1, 1])
    e = events(f)

    @testset "select_point()" begin
        point = select_point(a)
        initial_pos = point[]

        # Initialize the position in the axis
        e.mouseposition[] = (200, 200)

        # The point should only be updated when the user releases the mouse
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
        e.mouseposition[] = (100, 100)
        @test point[] == initial_pos
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
        @test point[] != initial_pos
    end

    @testset "select_rectangle()" begin
        rect = select_rectangle(a)
        initial_rect = rect[]

        # Similarly to the select_point() test, we initialize the mouse position
        # and check that the rect isn't updated until the mouse is released.
        e.mouseposition[] = (200, 200)
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
        e.mouseposition[] = (100, 100)
        @test rect[] == initial_rect
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
        @test rect[] != initial_rect
    end
end
