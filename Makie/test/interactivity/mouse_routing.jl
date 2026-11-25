using Makie: MouseButtonEvent, Mouse

function click!(scene, pos)
    e = events(scene)
    e.mouseposition[] = Float64.(Tuple(pos))
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    return
end

@testset "is_mouseinside respects ancestors" begin
    root = Scene(size = (400, 400))
    container = Scene(root; viewport = Recti(0, 0, 200, 200), visible = true)
    child = Scene(container; viewport = Recti(100, 100, 200, 200), visible = true)
    e = events(root)

    e.mouseposition[] = (150.0, 150.0)
    @test is_mouseinside(child)
    container.visible[] = false
    @test child.visible[] # own flag is untouched
    @test !is_mouseinside(child)
    container.visible[] = true

    # inside the child's viewport, but clipped away by its parent
    e.mouseposition[] = (250.0, 250.0)
    @test !is_mouseinside(child)
end

@testset "captures_mouse" begin
    root = Scene(size = (400, 400))
    below = Scene(root; viewport = Recti(0, 0, 400, 400))
    overlay = Scene(root; viewport = Recti(100, 100, 200, 200), visible = true)
    overlay.captures_mouse = true
    inside = Scene(overlay; viewport = Recti(150, 150, 50, 50))
    e = events(root)

    e.mouseposition[] = (160.0, 160.0)
    @test !is_mouseinside(below)
    @test is_mouseinside(overlay)
    @test is_mouseinside(inside)
    @test is_mouseinside(root) # ancestors of the capturing scene still receive input

    e.mouseposition[] = (50.0, 50.0) # outside the capturing scene
    @test is_mouseinside(below)

    e.mouseposition[] = (160.0, 160.0)
    overlay.visible[] = false
    @test is_mouseinside(below)
    overlay.visible[] = true

    # Blocks underneath the capturing scene don't receive clicks
    f = Figure(size = (400, 400))
    b = Button(f[1, 1], width = 400, height = 400)
    overlay = Scene(f.scene; viewport = Recti(100, 100, 200, 200), camera = campixel!)
    overlay.captures_mouse = true
    b_inside = Button(overlay; bbox = BBox(150, 250, 150, 250))
    Makie.update_state_before_display!(f)
    click!(f.scene, (50, 50))
    @test b.clicks[] == 1
    click!(f.scene, (200, 200))
    @test b.clicks[] == 1
    @test b_inside.clicks[] == 1
end

@testset "Blocks in an offset scene" begin
    f = Figure(size = (800, 300))
    sub = Scene(f.scene; viewport = Recti(400, 0, 300, 300), camera = campixel!)
    # Block layouts are in window coordinates, also inside offset scenes
    sl = Slider(sub; bbox = BBox(450, 650, 100, 120), range = 0:100, startvalue = 0)
    b = Button(sub; bbox = BBox(600, 800, 200, 240), width = 200, height = 40) # partially outside `sub`
    Makie.update_state_before_display!(f)
    @test viewport(sl.blockscene)[] == viewport(f.scene)[]
    @test Makie.effective_clip(sl.blockscene) == Recti(400, 0, 300, 300)

    e = events(f.scene)
    e.mouseposition[] = (460.0, 110.0)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mouseposition[] = (550.0, 110.0)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    @test sl.value[] == 50

    click!(f.scene, (650, 220)) # visible part
    @test b.clicks[] == 1
    click!(f.scene, (750, 220)) # clipped part
    @test b.clicks[] == 1

    sub.visible[] = false
    click!(f.scene, (650, 220))
    @test b.clicks[] == 1
end
