# This testset is based on the results the current camera system has. If
# cam3d! is updated this is likely to break.
@testset "cam3d!" begin
    Makie.PICK_TRACKING[] = true
    init = Makie._PICK_COUNTER[]

    scene = Scene(size = (800, 600))
    e = events(scene)
    cam3d!(scene, fixed_axis = true, cad = false, zoom_shift_lookat = false)
    cc = cameracontrols(scene)

    # Verify initial camera state
    @test cc.lookat[] == Vec3f(0)
    @test cc.eyeposition[] == Vec3f(3)
    @test cc.upvector[] == Vec3f(0, 0, 1)

    # Rotation
    # 1) In scene, in drag
    e.mouseposition[] = (400, 250)
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
    e.mouseposition[] = (600, 250)
    @test cc.lookat[] ≈ Vec3f(0)
    @test cc.eyeposition[] ≈ Vec3f(4.14532, -0.9035063, 3.0)
    @test cc.upvector[] ≈ Vec3f(0, 0, 1)

    # 2) Outside scene, in drag
    e.mouseposition[] = (1000, 450)
    @test cc.lookat[] ≈ Vec3f(0)
    @test cc.eyeposition[] ≈ Vec3f(-2.8912058, -3.8524969, -1.9491514)
    @test cc.upvector[] ≈ Vec3f(-0.5050875, -0.6730229, 0.5403024)

    # 3) not in drag
    e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
    e.mouseposition[] = (400, 250)
    @test cc.lookat[] ≈ Vec3f(0)
    @test cc.eyeposition[] ≈ Vec3f(-2.8912058, -3.8524969, -1.9491514)
    @test cc.upvector[] ≈ Vec3f(-0.5050875, -0.6730229, 0.5403024)


    # Reset state so this is independent from the last checks
    scene = Scene(size = (800, 600))
    e = events(scene)
    cam3d!(scene, fixed_axis = true, cad = false, zoom_shift_lookat = false)
    cc = cameracontrols(scene)

    # Verify initial camera state
    @test cc.lookat[] == Vec3f(0)
    @test cc.eyeposition[] == Vec3f(3)
    @test cc.upvector[] == Vec3f(0, 0, 1)

    # translation
    # 1) In scene, in drag
    e.mouseposition[] = (400, 250)
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
    e.mouseposition[] = (600, 250)
    @test cc.lookat[] ≈ Vec3f(1.0146117, -1.0146117, 0.0)
    @test cc.eyeposition[] ≈ Vec3f(4.0146117, 1.9853883, 3.0)
    @test cc.upvector[] ≈ Vec3f(0.0, 0.0, 1.0)

    # 2) Outside scene, in drag
    e.mouseposition[] = (1000, 450)
    @test cc.lookat[] ≈ Vec3f(3.6296215, -2.4580488, -1.1715729)
    @test cc.eyeposition[] ≈ Vec3f(6.6296215, 0.5419513, 1.8284271)
    @test cc.upvector[] ≈ Vec3f(0.0, 0.0, 1.0)

    # 3) not in drag
    e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
    e.mouseposition[] = (400, 250)
    @test cc.lookat[] ≈ Vec3f(3.6296215, -2.4580488, -1.1715729)
    @test cc.eyeposition[] ≈ Vec3f(6.6296215, 0.5419513, 1.8284271)
    @test cc.upvector[] ≈ Vec3f(0.0, 0.0, 1.0)


    # Reset state
    scene = Scene(size = (800, 600))
    e = events(scene)
    cam3d!(scene, fixed_axis = true, cad = false, zoom_shift_lookat = false)
    cc = cameracontrols(scene)

    # Verify initial camera state
    @test cc.lookat[] == Vec3f(0)
    @test cc.eyeposition[] == Vec3f(3)
    @test cc.upvector[] == Vec3f(0, 0, 1)

    # Zoom
    e.mouseposition[] = (400, 250) # for debugging
    e.scroll[] = (0.0, 4.0)
    @test cc.lookat[] ≈ Vec3f(0)
    @test cc.eyeposition[] ≈ 0.6830134f0 * Vec3f(3)
    @test cc.upvector[] ≈ Vec3f(0.0, 0.0, 1.0)

    # should not work outside the scene
    e.mouseposition[] = (1000, 450)
    e.scroll[] = (0.0, 4.0)
    @test cc.lookat[] ≈ Vec3f(0)
    @test cc.eyeposition[] ≈ 0.6830134f0 * Vec3f(3)
    @test cc.upvector[] ≈ Vec3f(0.0, 0.0, 1.0)

    @test init == Makie._PICK_COUNTER[]
end
