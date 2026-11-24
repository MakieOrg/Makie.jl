using Test, RayMakie, Makie, Hikari, GeometryBasics
const C = Makie.Colors

channel_sum(img) = sum(p -> C.red(p) + C.green(p) + C.blue(p), img)

@testset "ray_visibility reaches the tracer and follows updates" begin
    sc = Scene(; size = (64, 64), backgroundcolor = RGBf(0, 0, 0), lights = [AmbientLight(RGBf(0, 0, 0))])
    cam3d!(sc)
    panel = mesh!(sc, Rect3f(Point3f(-1, -1, 0), Vec3f(2, 2, 0.01));
                  material = Hikari.Emission(color = (1, 1, 1), strength = 1, two_sided = true),
                  ray_visibility = Hikari.Visibility(camera = false))
    update_cam!(sc, Vec3f(0, -0.01, 4), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    screen = RayMakie.Screen(sc; visible = false, rasterize = false, samples = 4, max_depth = 2)

    @test channel_sum(Makie.colorbuffer(screen)) == 0
    panel.ray_visibility = nothing
    @test channel_sum(Makie.colorbuffer(screen)) > 0
    panel.ray_visibility = Hikari.Visibility(camera = false)
    @test channel_sum(Makie.colorbuffer(screen)) == 0
    close(screen)
end
