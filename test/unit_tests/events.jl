using AbstractPlotting: PriorityObservable

@testset "PriorityObservable" begin
    po = PriorityObservable(0)

    first = Node(0.0)
    second = Node(0.0)
    third = Node(0.0)

    on(po, priority=1) do x
        first[] = time()
        return false
    end
    on(po, priority=0) do x
        second[] = time()
        return isodd(x)
    end
    on(po, priority=-1) do x
        third[] = time()
        return false
    end

    x = setindex!(po, 1)
    @test x == true
    @test first[] < second[]
    @test third[] == 0.0

    x = setindex!(po, 2)
    @test x == false
    @test first[] < second[] < third[]

    msg = "Observer functions of PriorityObservables must return a Bool to specify whether the update is consumed (true) or should propagate (false) to other observer functions. The given function has been wrapped to always return false."
    @test_logs (:warn, msg) on(identity, po)
end


@testset "Events" begin
    @testset "Mouse and Keyboard state" begin
        events = AbstractPlotting.Events()
        @test isempty(events.mousebuttonstate[])
        @test isempty(events.keyboardstate[])

        events.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.left, Mouse.press)
        events.keyboardbutton[] = AbstractPlotting.KeyEvent(Keyboard.a, Keyboard.press)
        @test events.mousebuttonstate[] == Set([Mouse.left])
        @test events.keyboardstate[] == Set([Keyboard.a])

        events.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.right, Mouse.press)
        events.keyboardbutton[] = AbstractPlotting.KeyEvent(Keyboard.b, Keyboard.press)
        @test events.mousebuttonstate[] == Set([Mouse.left, Mouse.right])
        @test events.keyboardstate[] == Set([Keyboard.a, Keyboard.b])

        events.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.left, Mouse.release)
        events.keyboardbutton[] = AbstractPlotting.KeyEvent(Keyboard.a, Keyboard.release)
        @test events.mousebuttonstate[] == Set([Mouse.right])
        @test events.keyboardstate[] == Set([Keyboard.b])

        events.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.right, Mouse.release)
        events.keyboardbutton[] = AbstractPlotting.KeyEvent(Keyboard.b, Keyboard.release)
        @test isempty(events.mousebuttonstate[])
        @test isempty(events.keyboardstate[])
    end

    # This testset is based on the results the current camera system has. If 
    # cam3d! is updated this is likely to break. 
    @testset "cam3d!" begin
        scene = Scene();
        e = events(scene)
        cam3d!(scene)
        cc = cameracontrols(scene)

        # Verify initial camera state
        @test cc.lookat[]       == Vec3f0(0)
        @test cc.eyeposition[]  == Vec3f0(3)
        @test cc.upvector[]     == Vec3f0(0, 0, 1)

        # Rotation
        # 1) In scene, in drag
        e.mouseposition[] = (400, 250)
        e.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.left, Mouse.press)
        e.mouseposition[] = (600, 250)
        @test cc.lookat[]       ≈ Vec3f0(0)
        @test cc.eyeposition[]  ≈ Vec3f0(4.14532, -0.9035063, 3.0)
        @test cc.upvector[]     ≈ Vec3f0(-0.5641066, 0.12295161, 0.81649655)

        # 2) Outside scene, in drag
        e.mouseposition[] = (1000, 450)
        @test cc.lookat[]       ≈ Vec3f0(0)
        @test cc.eyeposition[]  ≈ Vec3f0(-2.8912058, -3.8524969, -1.9491522)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)

        # 3) not in drag
        e.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.left, Mouse.release)
        e.mouseposition[] = (400, 250)
        @test cc.lookat[]       ≈ Vec3f0(0)
        @test cc.eyeposition[]  ≈ Vec3f0(-2.8912058, -3.8524969, -1.9491522)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)


        # Pan
        # 1) In scene, in drag
        e.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.right, Mouse.press)
        e.mouseposition[] = (600, 250)
        @test cc.lookat[]       ≈ Vec3f0(-1.662389, 1.2475829, -6.194297f-8)
        @test cc.eyeposition[]  ≈ Vec3f0(-4.5535946, -2.604914, -1.9491524)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)

        # 2) Outside scene, in drag
        e.mouseposition[] = (1000, 450)
        @test cc.lookat[]       ≈ Vec3f0(-4.5191803, 4.3663344, -1.9266889)
        @test cc.eyeposition[]  ≈ Vec3f0(-7.410386, 0.5138376, -3.8758411)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)

        # 3) not in drag
        e.mousebutton[] = AbstractPlotting.MouseButtonEvent(Mouse.right, Mouse.release)
        e.mouseposition[] = (400, 250)
        @test cc.lookat[]       ≈ Vec3f0(-4.5191803, 4.3663344, -1.9266889)
        @test cc.eyeposition[]  ≈ Vec3f0(-7.410386, 0.5138376, -3.8758411)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)


        # Zoom
        e.scroll[] = (0.0, 4.0)
        @test cc.lookat[]       ≈ Vec3f0(-4.10603, 4.056275, -1.9266889)
        @test cc.eyeposition[]  ≈ Vec3f0(-5.8407536, 1.7447768, -3.0961802)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)

        # should not work outside the scene
        e.mouseposition[] = (1000, 450)
        e.scroll[] = (0.0, 4.0)
        @test cc.lookat[]       ≈ Vec3f0(-4.10603, 4.056275, -1.9266889)
        @test cc.eyeposition[]  ≈ Vec3f0(-5.8407536, 1.7447768, -3.0961802)
        @test cc.upvector[]     ≈ Vec3f0(-0.22516009, -0.30002305, 0.92697847)
    end
end