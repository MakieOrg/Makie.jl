using Test, Makie, RayMakie, GeometryBasics, Colors
using GeometryBasics: Point3f, Vec3f, Sphere

@testset "the window ticks at its own rate, not once a frame" begin
    sc = Scene(size = (640, 480), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0, 0, 0), 0.8f0); color = :orange)
    scr = RayMakie.Screen(sc; samples = 1, max_depth = 8, hw_accel = true, visible = true)
    display(scr, sc)
    ticks = Ref(0)
    on(_ -> ticks[] += 1, events(sc).tick)
    # Measured once the loop is warm: its first frames compile, and compiling holds
    # the thread. A second after `display`, a cold session had presented one frame
    # and ticked twice a second.
    t = time()
    while scr.frames_presented[] < 3 && time() - t < 120
        sleep(0.1)
    end

    t0, f0, k0 = time(), scr.frames_presented[], ticks[]
    sleep(3.0)
    seconds, frames, n = time() - t0, scr.frames_presented[] - f0, ticks[] - k0

    @test RayMakie.renderloop_running(scr)
    @test frames > 0
    # At the input rate, however fast the frames: once a frame, a GPU slower than
    # 60 frames a second falls below this. A faster one cannot tell the two loops
    # apart here; Mantle's `test_hostwait.jl` and `test_window_portable.jl` pin the
    # waits that make this hold, on every device.
    @test n / seconds > 60

    scr.stop_renderloop[] = true
    RayMakie.wait_viewer(scr)
end
