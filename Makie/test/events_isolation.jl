using Makie
using Makie: forward_events!, MouseButtonEvent, KeyEvent, Mouse, Keyboard, Events
using Test

@testset "forward_events! isolation" begin
    root = Scene()
    active = Observable(true)
    target = Scene(root; events = Events(), viewport = Rect2i(0, 0, 100, 100))
    @test events(target) !== events(root)
    forward_events!(target, root; active = active)

    @testset "context events always forwarded" begin
        root.events.window_dpi[] = 123.0
        @test target.events.window_dpi[] == 123.0
        active[] = false
        root.events.window_dpi[] = 200.0
        @test target.events.window_dpi[] == 200.0
        active[] = true
    end

    @testset "input gated by active" begin
        root.events.mouseposition[] = (10.0, 10.0)
        @test target.events.mouseposition[] == (10.0, 10.0)

        active[] = false
        root.events.mouseposition[] = (20.0, 20.0)
        @test target.events.mouseposition[] == (10.0, 10.0)

        active[] = true
        root.events.mouseposition[] = (30.0, 30.0)
        @test target.events.mouseposition[] == (30.0, 30.0)
    end

    @testset "keyboard gated by active" begin
        got = Ref(0)
        on(target.events.keyboardbutton) do _
            got[] += 1
            return Consume(false)
        end
        active[] = true
        root.events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.press)
        root.events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.release)
        @test got[] == 2

        active[] = false
        before = got[]
        root.events.keyboardbutton[] = KeyEvent(Keyboard.b, Keyboard.press)
        @test got[] == before
    end

    @testset "Consume propagates back to source" begin
        active[] = true
        on(target.events.mousebutton; priority = 10) do _
            return Consume(true)
        end
        consumed = setindex!(root.events.mousebutton, MouseButtonEvent(Mouse.left, Mouse.press))
        @test consumed == true
    end

    @testset "held inputs released on deactivation" begin
        active[] = true
        empty!(root.events.mousebuttonstate)
        empty!(target.events.mousebuttonstate)
        root.events.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
        @test Mouse.right in target.events.mousebuttonstate
        active[] = false
        @test isempty(target.events.mousebuttonstate)
    end
end

@testset "Tabs event isolation" begin
    f = Figure()
    t = Tabs(f[1, 1], ["A", "B"])
    s1, s2 = content_scene(t, 1), content_scene(t, 2)
    @test events(s1) !== events(f.scene)
    @test events(s2) !== events(s1)

    counts = [0, 0]
    on(_ -> (counts[1] += 1; Consume(false)), events(s1).keyboardbutton)
    on(_ -> (counts[2] += 1; Consume(false)), events(s2).keyboardbutton)

    t.active[] = 1
    f.scene.events.keyboardbutton[] = KeyEvent(Keyboard.a, Keyboard.press)
    @test counts == [1, 0]

    t.active[] = 2
    before = copy(counts)
    f.scene.events.keyboardbutton[] = KeyEvent(Keyboard.b, Keyboard.press)
    @test counts[1] == before[1]
    @test counts[2] == before[2] + 1
end

labels_of(t) = [td.label[] for td in t.tabs]
closable_of(t) = [td.closable[] for td in t.tabs]

@testset "Tabs closable" begin
    f = Figure()
    t = Tabs(f[1, 1], ["A", "B", "C"]; closable = [true, false, true])
    scenes0 = [content_scene(t, i) for i in 1:3]

    # click the center of tab `slot`'s close glyph (the LineSegments plots are
    # the close ×s, in tab order; the separator is a `Lines`, not LineSegments)
    function click_close(slot)
        cps = filter(p -> p isa Makie.LineSegments, t.blockscene.plots)
        seg = cps[slot].positions[]
        cx = sum(p -> p[1], seg) / length(seg)
        cy = sum(p -> p[2], seg) / length(seg)
        e = t.blockscene.events
        e.mouseposition[] = (Float64(cx), Float64(cy))
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
        return e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    end

    click_close(1)   # close "A"
    @test labels_of(t) == ["B", "C"]
    @test closable_of(t) == [false, true]        # per-tab state stays aligned
    # reindex: remaining tabs map to their original content scenes
    @test content_scene(t, 1) === scenes0[2]
    @test content_scene(t, 2) === scenes0[3]
end

@testset "Tabs setter API" begin
    f = Figure()
    t = Tabs(f[1, 1], ["A", "B"])
    @test length(t) == 2
    @test t.active[] == 1

    sf = add_tab!(t, "C"; activate = true)
    @test length(t) == 3
    @test labels_of(t) == ["A", "B", "C"]
    @test t.active[] == 3
    @test content_scene(t, 3) === sf.scene

    set_tab!(t, 3; label = "Z")
    @test labels_of(t) == ["A", "B", "Z"]

    set_tab!(t, 1; closable = false)
    @test closable_of(t) == [false, true, true]

    remove_tab!(t, 3)
    @test length(t) == 2
    @test t.active[] == 2                         # clamped down from removed tab

    remove_tab!(t, 1)
    remove_tab!(t, 1)
    @test length(t) == 0
    @test t.active[] == 0                         # no tabs -> no active tab

    add_tab!(t, "back")
    @test t.active[] == 1                         # first tab on empty becomes active
end
