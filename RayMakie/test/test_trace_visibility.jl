# What a plot's `visible` and `delete!` do to the TRACED scene.
#
# The tracer read no `visible` at all: a mesh hidden before or after the screen
# existed was path traced anyway, while the raster preview hid it. And deleting
# a glowing mesh took out only its geometry, so its face lights stayed in the
# scene's light set and a deleted lamp went on lighting the floor.
#
# A floor lit only by a lamp panel above it, seen at a pixel of floor, and a
# sphere filling the centre of the frame; both on the hardware and the software
# acceleration structure.

using Test, Makie, RayMakie, Hikari, GeometryBasics, Mantle

lum(c) = 0.2126f0 * c.r + 0.7152f0 * c.g + 0.0722f0 * c.b

function lamp_scene()
    sc = Scene(; size = (64, 64), backgroundcolor = RGBf(0, 0, 0), lights = [AmbientLight(RGBf(0, 0, 0))])
    cam3d!(sc; center = false)
    mesh!(sc, Rect3f(Vec3f(-3, -3, -0.01), Vec3f(6, 6, 0.01)); material = Hikari.Diffuse(Kd = (0.8, 0.8, 0.8)))
    lamp = mesh!(sc, Rect3f(Vec3f(-0.5, -0.5, 2), Vec3f(1, 1, 0.01));
                 material = Hikari.Emissive(Le = (10, 10, 10), two_sided = true))
    update_cam!(sc, cameracontrols(sc), Vec3f(0, -5, 1.5), Vec3f(0, 0, 0), Vec3f(0, 0, 1))
    return sc, lamp
end

function sphere_scene(; visible)
    sc = Scene(; size = (64, 64), backgroundcolor = RGBf(0, 0, 0),
               lights = [DirectionalLight(RGBf(3, 3, 3), Vec3f(0, 1, 0))])
    cam3d!(sc; center = false)
    p = mesh!(sc, Sphere(Point3f(0), 1f0); material = Hikari.Diffuse(Kd = (0.8, 0.8, 0.8)), visible)
    update_cam!(sc, cameracontrols(sc), Vec3f(0, -4, 0), Vec3f(0), Vec3f(0, 0, 1))
    return sc, p
end

traced(sc; hw_accel, samples = 16) =
    RayMakie.Screen(sc; visible = false, rasterize = false, samples, max_depth = 4, hw_accel)

@testset "visible and delete! in the traced scene (hw_accel = $hw_accel)" for hw_accel in (true, false)
    @testset "a mesh hidden before the screen exists" begin
        sc, p = sphere_scene(; visible = false)
        screen = traced(sc; hw_accel, samples = 4)
        @test lum(Makie.colorbuffer(screen)[32, 32]) < 0.01
        p.visible[] = true
        @test lum(Makie.colorbuffer(screen)[32, 32]) > 0.5
        p.visible[] = false
        @test lum(Makie.colorbuffer(screen)[32, 32]) < 0.01
        close(screen)
    end

    @testset "a hidden lamp lights nothing, and a deleted one is gone" begin
        sc, lamp = lamp_scene()
        screen = traced(sc; hw_accel)
        lit = lum(Makie.colorbuffer(screen)[40, 32])
        @test lit > 0.3
        lamp.visible[] = false
        @test lum(Makie.colorbuffer(screen)[40, 32]) < 0.01
        # Shown again, from the slots it kept: the same light as before.
        lamp.visible[] = true
        @test lum(Makie.colorbuffer(screen)[40, 32]) ≈ lit atol = 0.05
        delete!(sc, lamp)
        @test lum(Makie.colorbuffer(screen)[40, 32]) < 0.01
        close(screen)
    end
end
