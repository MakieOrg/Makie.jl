using Test, Makie, RayMakie, Mantle, GeometryBasics, Colors
using GeometryBasics: Point3f, Vec3f, Sphere

# The window's frame drawn into an image instead of the window, so it can be read back.
function window_path_frame(scr)
    h, w = size(scr.output_buffer)
    plan, out = RayMakie.frame_plan!(scr, :window, g -> Mantle.Transient.Image(g, RayMakie.COMPOSITE_FORMAT, (w, h)),
                                     Mantle.Keep, scr.output_buffer, RayMakie.overlay_robjs(scr), w, h;
                                     finish = function (g, img)
                                         buf = Mantle.Transient.Buffer(g, RayMakie.COMPOSITE_FORMAT, w * h)
                                         Mantle.copy!(g, "read", buf, img)
                                         buf
                                     end)
    Mantle.run!(plan)
    return RayMakie.unswizzle(reshape(Array(Mantle.storage(out.result)), w, h), w, h)
end

@testset "the window shows the composited frame pixel for pixel" begin
    sc = Scene(size = (96, 64), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0.7, 0.4, 0), 0.5f0); color = :orange)
    update_cam!(sc, Vec3f(0, 0, 4), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    scr = RayMakie.Screen(sc; samples = 1, max_depth = 3, visible = false)
    display(scr, sc)
    Makie.colorbuffer(scr)
    @test window_path_frame(scr) == RayMakie.composited_frame(scr)
end
