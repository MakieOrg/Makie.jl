# TODO: test more
@testset "Axis Interactions - Axis3" begin

    Makie.PICK_TRACKING[] = true
    init = Makie._PICK_COUNTER[]

    f = Figure(size = (400, 400))
    a = Axis3(f[1, 1])
    p = scatter!(a, Rect3f(Point3f(1, 2, 3), Vec3f(1, 2, 3)))
    Makie.update_state_before_display!(f)
    e = events(f)

    names = (:dragrotate, :translation, :limitreset, :scrollzoom)
    types = (Makie.DragRotate, Makie.DragPan, Makie.LimitReset, Makie.ScrollZoom)
    for (name, type) in zip(names, types)
        @test haskey(a.interactions, name)
        @test a.interactions[name][1] == true
        @test a.interactions[name][2] isa type
    end

    # Test a series of user interactions with the Axis3
    @test a.targetlimits[] ≈ Rect3f(Point3f(0.95, 1.9, 2.85), Vec3f(1.1, 2.2, 3.3))

    # translations
    e.mouseposition[] = (200, 200)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mouseposition[] = (150, 250)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(1.0789851, 1.4260418, 1.802376), Vec3f(1.1, 2.2, 3.3))

    e.keyboardbutton[] = KeyEvent(Keyboard.x, Keyboard.press)
    e.mouseposition[] = (150, 250)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mouseposition[] = (200, 200)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(0.95, 1.4260418, 1.802376), Vec3f(1.1, 2.2, 3.3))

    e.keyboardbutton[] = KeyEvent(Keyboard.x, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.y, Keyboard.press)
    e.keyboardbutton[] = KeyEvent(Keyboard.z, Keyboard.press)
    e.mouseposition[] = (150, 250)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mouseposition[] = (200, 200)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(0.95, 1.9, 2.85), Vec3f(1.1, 2.2, 3.3))

    e.keyboardbutton[] = KeyEvent(Keyboard.y, Keyboard.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.z, Keyboard.release)

    # reset
    e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    e.keyboardbutton[] = KeyEvent(Keyboard.left_control, Keyboard.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(0.95, 1.9, 2.85), Vec3f(1.1, 2.2, 3.3))

    # zooming
    e.keyboardbutton[] = KeyEvent(Keyboard.x, Keyboard.press)
    e.scroll[] = (0.0, 4.0)
    e.keyboardbutton[] = KeyEvent(Keyboard.x, Keyboard.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(1.0520215, 1.9, 2.85), Vec3f(0.8959568, 2.2, 3.3))
    e.keyboardbutton[] = KeyEvent(Keyboard.y, Keyboard.press)
    e.scroll[] = (0.0, 4.0)
    e.keyboardbutton[] = KeyEvent(Keyboard.y, Keyboard.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(1.0520215, 2.104043, 2.85), Vec3f(0.8959568, 1.7919136, 3.3))
    e.keyboardbutton[] = KeyEvent(Keyboard.z, Keyboard.press)
    e.scroll[] = (0.0, 4.0)
    e.keyboardbutton[] = KeyEvent(Keyboard.z, Keyboard.release)
    @test a.targetlimits[] ≈ Rect3f(Point3f(1.0520215, 2.104043, 3.1560647), Vec3f(0.8959568, 1.7919136, 2.6878703))
    e.mouseposition[] = (200, 200)
    e.scroll[] = (0.0, -4.0)
    @test a.targetlimits[] ≈ Rect3f(Point3f(0.95, 1.9, 2.85), Vec3f(1.1, 2.2, 3.3))

    @test init == Makie._PICK_COUNTER[]
end
