# pick() is fairly expensive operation as it requires data to be transferred
# from the GPU to the CPU side. Whenever possible we should prefer boundingbox/
# area checks for performance.
# Note that pick-less code can also run without a backend whereas pick-full
# code requires the backend to correctly resolve actions.

@testset "Widget pick() tracking" begin

    Makie.PICK_TRACKING[] = true

    # sanity check
    init = Makie._PICK_COUNTER[]
    scene = Scene()
    pick(scene, (50, 50))
    pick(scene)
    pick(scene, Rect2i(10, 10, 20, 20))
    pick(scene, 10, 20, 5)
    Makie.pick_sorted(scene, (10, 20), 5)
    @test Makie._PICK_COUNTER[] == init + 5

    init = Makie._PICK_COUNTER[]

    @testset "Menu" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (600, 450))
        m = Menu(f[1, 1], options = string.(1:10))
        Makie.update_state_before_display!(f)

        # open menu
        events(f).mouseposition[] = (300, 230)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        # select option
        events(f).mouseposition[] = (300, 300)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "Button" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (100, 100))
        Makie.Button(f[1, 1])
        Makie.update_state_before_display!(f)

        # click button
        events(f).mouseposition[] = (50, 50)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "Textbox" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (200, 100))
        Textbox(f[1, 1])
        Makie.update_state_before_display!(f)

        # enter text field
        events(f).mouseposition[] = (300, 225)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        # type
        events(f).unicode_input[] = 't'
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.press)
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.release)

        # exit
        events(f).mouseposition[] = (0, 0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "Slider" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (200, 100))
        Makie.Slider(f[1, 1])
        Makie.update_state_before_display!(f)

        # initiate drag
        events(f).mouseposition[] = (21.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)

        # finalize drag
        events(f).mouseposition[] = (105.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "Toggle" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (100, 100))
        Makie.Toggle(f[1, 1])
        Makie.update_state_before_display!(f)

        # click
        events(f).mouseposition[] = (50.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "Checkbox" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (100, 100))
        Makie.Checkbox(f[1, 1])
        Makie.update_state_before_display!(f)

        # click
        events(f).mouseposition[] = (50.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @testset "IntervalSlider" begin
        prev = Makie._PICK_COUNTER[]

        f = Figure(size = (200, 100))
        Makie.IntervalSlider(f[1, 1])
        Makie.update_state_before_display!(f)

        # left end drag
        events(f).mouseposition[] = (20.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mouseposition[] = (70.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        # interval drag
        events(f).mouseposition[] = (120.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mouseposition[] = (90.0, 50.0)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)

        @test Makie._PICK_COUNTER[] == prev
    end

    @test Makie._PICK_COUNTER[] == init
end
