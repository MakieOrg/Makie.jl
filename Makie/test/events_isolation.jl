using Makie
using Makie: MouseButtonEvent, Mouse, receives_events
using Test

@testset "Tabs event isolation (shared events + receives_events)" begin
    f = Figure()
    t = Tabs(f[1, 1], ["A", "B"])
    Axis(t[1][1, 1])
    Axis(t[2][1, 1])
    s1, s2 = content_scene(t, 1), content_scene(t, 2)

    # Tabs share the figure's Events (no per-tab Events / event forwarding).
    @test events(s1) === events(f.scene)
    @test events(s2) === events(f.scene)

    # Isolation is by visibility: only the active tab is visible, and a hidden
    # scene is inert to the event router (`receives_events` short-circuits on
    # `visible[] == false`). Handlers that guard on `receives_events` /
    # `is_mouseinside` therefore fire only for the active tab.
    t.active[] = 1
    @test s1.visible[] == true
    @test s2.visible[] == false
    @test receives_events(s1) == true
    @test receives_events(s2) == false

    t.active[] = 2
    @test s1.visible[] == false
    @test s2.visible[] == true
    @test receives_events(s1) == false
    @test receives_events(s2) == true
end

@testset "a hidden Tabs header does not take the click" begin
    # Isolation by visibility only works if the handlers ASK. The header's did
    # not: `tab_at` answers from the tab rects alone, so a `Tabs` whose scene is
    # hidden — a dismissed dialog still sitting in the figure — kept taking
    # clicks. Two modals holding a `Tabs` at the same place: the click switched
    # the invisible one's tab and the visible one stayed on tab 1.
    f = Figure(size = (700, 500))
    a = Modal(f; title = "A"); ta = Tabs(a[1, 1], ["Preview", "Bake"]; closable = false)
    open!(a); close!(a)                         # dismissed, hidden, still there
    b = Modal(f; title = "B"); tb = Tabs(b[1, 1], ["Preview", "Bake"]; closable = false)
    open!(b)
    Makie.update_state_before_display!(f)

    r = tb.tabs[2].rect[]
    @test ta.tabs[2].rect[] == r                # they do sit on top of each other
    e = f.scene.events
    e.mouseposition[] = Tuple(Point2f(r.origin .+ r.widths ./ 2))
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)

    @test tb.active[] == 2                      # the dialog on screen switched…
    @test ta.active[] == 1                      # …and the hidden one did not move
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

    sf = add_tab!(t, "C"; activate = true, closable = false)   # closable forwarded to set_tab!
    @test length(t) == 3
    @test labels_of(t) == ["A", "B", "C"]
    @test t.active[] == 3
    @test content_scene(t, 3) === sf.scene
    @test closable_of(t) == [true, true, false]

    set_tab!(t, 3; label = "Z", closable = true)
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
