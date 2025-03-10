# These tests are relevant for general Makie performance but only tested here
# because Bonito makes it easy to test. If the tests fail it is likely not
# WGLMakies fault.
# A lower number of messages maybe caused by optimizations or broken interactions.
# A higher number could come from added functionality or performance regressions.


@testset "TextBox with Menu" begin
    f = Figure()
    t1 = Textbox(f[1, 1])
    m = Menu(f[2, 1], options = string.(1:1000))
    display(edisplay, App(() -> f))

    # trigger select
    all_messages, summary_str = Bonito.collect_messages() do
        events(f).mouseposition[] = (300, 250)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end
    @test length(all_messages) == 44

    # type text
    for (char, expected) in zip(collect("test"), [18, 39, 39, 39])
        _key = getproperty(Makie.Keyboard, Symbol(char))
        all_messages, summary_str = Bonito.collect_messages() do
            events(f).keyboardbutton[] = Makie.KeyEvent(_key, Keyboard.press)
            events(f).unicode_input[] = char
            events(f).keyboardbutton[] = Makie.KeyEvent(_key, Keyboard.release)
        end
        @test length(all_messages) == expected
    end
end

@testset "Menu" begin
    f = Figure()
    m = Menu(f[1,1], options = string.(1:10))
    display(edisplay, App(() -> f))

    # open menu
    all_messages, summary_str = Bonito.collect_messages() do
        events(f).mouseposition[] = (300, 230)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end
    @test length(all_messages) == 102

    # scroll items
    all_messages, summary_str = Bonito.collect_messages() do
        events(f).mouseposition[] = (300, 200)
        events(f).scroll[] = (0.0, -1.0)
    end
    @test length(all_messages) == 16

    # select item
    all_messages, summary_str = Bonito.collect_messages() do
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end
    @test length(all_messages) == 29
end

@testset "Textbox" begin
    f = Figure()
    t1 = Textbox(f[1, 1], tellwidth = false)
    display(edisplay, App(() -> f))

    all_messages, summary_str = Bonito.collect_messages() do
        events(f).mouseposition[] = (300, 225)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.press)
        events(f).mousebutton[] = Makie.MouseButtonEvent(Mouse.left, Mouse.release)
    end
    @test length(all_messages) == 34

    all_messages, summary_str = Bonito.collect_messages() do
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.press)
        events(f).unicode_input[] = 't'
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.release)
    end
    @test length(all_messages) == 18

    all_messages, summary_str = Bonito.collect_messages() do
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.e, Keyboard.press)
        events(f).unicode_input[] = 'e'
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.e, Keyboard.release)
    end
    @test length(all_messages) == 30

    all_messages, summary_str = Bonito.collect_messages() do
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.s, Keyboard.press)
        events(f).unicode_input[] = 's'
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.s, Keyboard.release)
    end
    @test length(all_messages) == 30

    all_messages, summary_str = Bonito.collect_messages() do
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.press)
        events(f).unicode_input[] = 't'
        events(f).keyboardbutton[] = Makie.KeyEvent(Keyboard.t, Keyboard.release)
    end
    @test length(all_messages) == 30

end
