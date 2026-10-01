# A traced scene follows its lights.
#
# The tracer used to be handed the scene's lights once, when its state was
# built, and never again: a light moved with `set_light!` stayed where it
# started and a dimmed one never dimmed, while the raster path followed both.
# `sync_lights!` now replaces a changed light in place before every trace.

using Test, RayMakie, Makie
const C = Makie.Colors

brightness(img) = sum(p -> C.red(p) + C.green(p) + C.blue(p), img) / length(img)

@testset "set_light! reaches the tracer" begin
    sc = Scene(; size = (96, 96), backgroundcolor = RGBf(0, 0, 0),
               lights = [PointLight(RGBf(3, 3, 3), Point3f(0, 0, 2))])
    cam3d!(sc)
    mesh!(sc, Rect3f(Point3f(-2, -2, -0.1), Vec3f(4, 4, 0.1)); color = RGBf(0.8, 0.8, 0.8))
    update_cam!(sc, Vec3f(0, -0.01, 5), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    screen = RayMakie.Screen(sc; visible = false, rasterize = false, samples = 8, max_depth = 2)
    trace() = Makie.colorbuffer(screen)

    near = brightness(trace())
    Makie.set_light!(sc, 1; position = Point3f(0, 0, 6))      # three times as far: a ninth of the light
    far = brightness(trace())
    Makie.set_light!(sc, 1; position = Point3f(0, 0, 2))
    back = brightness(trace())
    Makie.set_light!(sc, 1; color = RGBf(0, 0, 0))
    dark = brightness(trace())
    close(screen)

    @test near > 0.1
    @test far < 0.5 * near
    @test isapprox(back, near; rtol = 0.05)
    @test dark < 0.01
end
