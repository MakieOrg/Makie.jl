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

@testset "a hidden ancestor makes the subtree inert" begin
    # Routing has to consider the whole ancestor chain, not just a scene's own
    # `visible[]`. A scene created while its parent was visible keeps its own
    # flag, and `unhide!` force-shows a Block's scene — so a subtree can be
    # invisible on screen while every flag inside it still says `true`.
    root = Scene(size = (400, 400))
    container = Scene(root; viewport = Observable(Makie.Recti(0, 0, 400, 400)), visible = true)
    child = Scene(container; viewport = Observable(Makie.Recti(100, 100, 200, 200)), visible = Observable(true))
    root.events.mouseposition[] = (200.0, 200.0)
    @test receives_events(child) == true

    container.visible[] = false
    @test child.visible[] == true                 # own flag untouched
    @test Makie.scene_visible(child) == false     # but hidden through its parent
    @test receives_events(child) == false
    @test Makie.is_mouseinside(child) == false

    container.visible[] = true
    @test receives_events(child) == true
end

@testset "an inactive tab's Axis does not consume scroll" begin
    f = Figure(size = (600, 400))
    t = Tabs(f[1, 1], ["A", "B"])
    ax = Axis(t[1][1, 1])
    for i in 1:20
        Label(t[2][i, 1], "row $i")
        Makie.GridLayoutBase.rowsize!(t[2].layout, i, Makie.GridLayoutBase.Fixed(30))
    end
    Makie.update_state_before_display!(f)

    t.active[] = 2
    e = events(f.scene)
    e.mouseposition[] = Tuple(Float64.(minimum(ax.scene.viewport[]) .+ widths(ax.scene.viewport[]) ./ 2))
    @test receives_events(ax.scene) == false

    limits_before = ax.finallimits[]
    scroll_before = t[2].scroll[]
    e.scroll[] = (0.0, -3.0)
    @test ax.finallimits[] == limits_before        # hidden axis does not zoom
    @test t[2].scroll[] != scroll_before           # and does not swallow the event

    t.active[] = 1
    e.scroll[] = (0.0, -3.0)
    @test ax.finallimits[] != limits_before        # visible axis still zooms
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
