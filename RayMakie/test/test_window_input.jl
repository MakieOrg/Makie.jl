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
    sleep(1.0)

    t0, f0, k0 = time(), scr.frames_presented[], ticks[]
    sleep(3.0)
    seconds, frames, n = time() - t0, scr.frames_presented[] - f0, ticks[] - k0

    @test RayMakie.renderloop_running(scr)
    @test frames > 0
    @test n > 1.5 * frames
    @test n / seconds > 60

    scr.stop_renderloop[] = true
    RayMakie.wait_viewer(scr)
end
