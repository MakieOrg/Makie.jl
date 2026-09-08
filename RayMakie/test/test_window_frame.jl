# The render loop presents a frame, with the overlays drawn over the blit.
#
# `display` opens a window and starts the loop: each frame is one closed
# command buffer — the blit of the composited output buffer, every scene's
# overlays drawn over it, and the transition to `PRESENT_SRC` — handed to
# `present_frame!` (see `present_composited!`). That path had no test, and it
# had been broken twice over since the queue stopped holding an open batch:
# the loop drew into `bq.active_batch` and presented with the two-argument
# `present_frame!` that took the batch over, and before it got that far the
# window itself failed to open, because `Mantle.Window` was handed the
# portable `BGRA{N0f8}` and the Vulkan constructor took only a `VK.Format`.
# `test_overlay_compositing.jl` covers the offscreen path; this is the window.
using Test, Makie, RayMakie, Lava, Hikari, GeometryBasics
using GeometryBasics: Point3f, Vec3f, Sphere

@testset "the render loop presents frames with overlays" begin
    sc = Scene(size = (320, 240), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0, 0, 0), 0.8f0); color = :orange)
    lines!(sc, [Point3f(-1, -1, 0), Point3f(1, 1, 0), Point3f(1, -1, 0)]; color = :black, linewidth = 3)
    scr = RayMakie.Screen(sc; integrator = Hikari.VolPath(samples = 1, max_depth = 3, hw_accel = true),
                          visible = true)
    display(scr, sc)
    t0 = time()
    while time() - t0 < 15 && scr.last_colorbuffer === nothing
        sleep(0.2)
    end
    @test RayMakie.renderloop_running(scr)
    @test scr.last_colorbuffer !== nothing
    @test size(scr.last_colorbuffer) == (240, 320)
    sleep(1.0)
    @test RayMakie.renderloop_running(scr)      # a second frame did not kill it
    close(scr)
    sleep(0.5)
    @test !RayMakie.renderloop_running(scr)
end
