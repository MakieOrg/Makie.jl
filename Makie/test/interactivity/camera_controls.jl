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

@testset "stage_cam!" begin
    function ndc(scene, p)
        q = scene.camera.projectionview[] * Point4d(p[1], p[2], p[3], 1)
        return Point3d(q[1], q[2], q[3]) ./ q[4]
    end

    @testset "framing" begin
        for (size, right_ndc, top_ndc) in [
                ((400, 400), 1.0, 1.0),
                ((200, 400), 1.0, 0.5),
                ((400, 200), 0.5, 1.0),
            ]
            scene = Scene(; size)
            cam = stage_cam!(scene, stage_size = 2.0, fov = 90.0)

            @test scene.camera.eyeposition[] ≈ Vec3f(1, 0, 0)
            @test ndc(scene, Point3d(0, 1, 0))[1] ≈ right_ndc
            @test ndc(scene, Point3d(0, 0, 1))[2] ≈ top_ndc
        end
    end

    @testset "crop_factor crops without moving the camera" begin
        scene = Scene(size = (400, 400))
        cam = stage_cam!(scene, stage_size = 2.0, fov = 90.0)
        cam.crop_factor[] = 2.0

        @test scene.camera.eyeposition[] ≈ Vec3f(1, 0, 0)
        @test ndc(scene, Point3d(0, 1, 0))[1] ≈ 2.0
    end

    @testset "relative offset" begin
        for (size, mm) in [((400, 400), 50.0), ((400, 200), 24.0), ((200, 400), 100.0)]
            scene = Scene(; size)
            cam = stage_cam!(scene; stage_size = 2.0, mm)
            eyeposition = scene.camera.eyeposition[]

            cam.relative_offset[] = (1 / 3, 0)
            @test ndc(scene, cam.lookat[])[1] ≈ -1 / 3
            @test ndc(scene, cam.lookat[])[2] ≈ 0.0
            @test scene.camera.eyeposition[] ≈ eyeposition

            cam.relative_offset[] = (0, -0.5)
            @test ndc(scene, cam.lookat[])[1] ≈ 0.0
            @test ndc(scene, cam.lookat[])[2] ≈ 0.5
            @test scene.camera.eyeposition[] ≈ eyeposition
        end
    end

    @testset "focal length" begin
        scene = Scene(size = (400, 400))
        cam = stage_cam!(scene, stage_size = 2.0, mm = 50.0)

        @test Makie.fov_degrees(cam) ≈ 2 * atand(36, 100)
        @test scene.camera.eyeposition[] ≈ Vec3f(1 / 0.36, 0, 0)

        @test_throws "Cannot set both mm and fov" stage_cam!(scene, mm = 50.0, fov = 45.0)
        @test_throws "Either mm or fov must be set" stage_cam!(scene, mm = nothing)
    end

    @testset "reposition keeps the camera in place" begin
        scene = Scene(size = (400, 400))
        cam = stage_cam!(scene, stage_size = 2.0, fov = 90.0, azimuth = 30.0, elevation = 20.0)
        eyeposition = Makie.stage_eyeposition(cam)

        Makie.reposition_cam!(cam, Point3d(0.2, -0.1, 0.3))

        @test Makie.stage_eyeposition(cam) ≈ eyeposition
        @test cam.lookat[] ≈ Vec3d(0.2, -0.1, 0.3)
        @test ndc(scene, cam.lookat[])[1] ≈ 0 atol = 1.0e-12
        @test ndc(scene, cam.lookat[])[2] ≈ 0 atol = 1.0e-12
        @test cam.stage_size[] ≈ 2 * norm(eyeposition - cam.lookat[])
    end

    @testset "clip planes" begin
        scene = Scene(size = (400, 400))
        cam = stage_cam!(scene, stage_size = 2.0, fov = 90.0)
        @test Makie.clip_planes(cam, Makie.stage_eyeposition(cam), 1.0) == (0.01, 10.0)

        update_cam!(scene, cam, Rect3d(-40, -40, -40, 80, 80, 80))
        far = norm(Makie.stage_eyeposition(cam)) + 0.5 * norm(Vec3d(80))
        @test Makie.clip_planes(cam, Makie.stage_eyeposition(cam), 1.0)[2] ≈ 1.05 * far

        cam.nearclip[] = 0.5
        cam.farclip[] = 7.0
        @test Makie.clip_planes(cam, Makie.stage_eyeposition(cam), 1.0) == (0.5, 7.0)

        f = Figure()
        lscene = LScene(f[1, 1], show_axis = false, scenekw = (; camera = stage_cam!))
        mesh!(lscene, Rect3d(-40, -40, -40, 80, 80, 80))
        Makie.update_state_before_display!(f)
        @test radius(cameracontrols(lscene.scene).bounding_sphere[]) ≈ 0.5 * norm(Vec3d(80)) rtol = 0.05
    end

    @testset "elevation limit" begin
        scene = Scene(size = (400, 400))
        cam = stage_cam!(scene, stage_size = 2.0, fov = 90.0, elevation = 90.0)

        @test all(isfinite, scene.camera.projectionview[])
        @test scene.camera.upvector[] ≈ Vec3f(-1, 0, 0) atol = 1.0f-2
    end

    @testset "mouse controls" begin
        scene = Scene(size = (400, 400))
        e = events(scene)
        cam = stage_cam!(scene, stage_size = 2.0, mm = 50.0)
        e.mouseposition[] = (200, 200)

        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
        e.mouseposition[] = (240, 180)
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
        @test cam.azimuth[] ≈ -20.0
        @test cam.elevation[] ≈ 10.0

        e.keyboardbutton[] = KeyEvent(Keyboard.left_shift, Keyboard.press)
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.press)
        e.mouseposition[] = (140, 280)
        e.mousebutton[] = MouseButtonEvent(Mouse.left, Mouse.release)
        e.keyboardbutton[] = KeyEvent(Keyboard.left_shift, Keyboard.release)
        @test cam.relative_offset[] ≈ Vec2d(0.5, -0.5)
        @test ndc(scene, cam.lookat[])[1] ≈ -0.5
        @test ndc(scene, cam.lookat[])[2] ≈ 0.5
        @test cam.azimuth[] ≈ -20.0
        @test cam.elevation[] ≈ 10.0

        e.keyboardbutton[] = KeyEvent(Keyboard.left_shift, Keyboard.press)
        e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.press)
        e.mousebutton[] = MouseButtonEvent(Mouse.right, Mouse.release)
        e.keyboardbutton[] = KeyEvent(Keyboard.left_shift, Keyboard.release)
        @test cam.relative_offset[] == Vec2d(0, 0)

        e.mouseposition[] = (200, 200)

        e.scroll[] = (0.0, 1.0)
        @test cam.stage_size[] ≈ 2 / 1.1
        @test cam.mm[] == 50.0

        cam.stage_size[] = 2.0
        distance = norm(scene.camera.eyeposition[] - cam.lookat[])
        e.keyboardbutton[] = KeyEvent(Keyboard.left_shift, Keyboard.press)
        e.scroll[] = (0.0, 1.0)
        @test cam.mm[] ≈ 55.0
        @test cam.stage_size[] ≈ 2.0
        @test norm(scene.camera.eyeposition[] - cam.lookat[]) > distance

        cam.mm[] = 50.0
        distance = norm(scene.camera.eyeposition[] - cam.lookat[])
        e.keyboardbutton[] = KeyEvent(Keyboard.left_alt, Keyboard.press)
        e.scroll[] = (0.0, 1.0)
        @test cam.mm[] ≈ 55.0
        @test cam.stage_size[] ≈ 2 * (36 / 110) / 0.36
        @test norm(scene.camera.eyeposition[] - cam.lookat[]) ≈ distance
    end
end
