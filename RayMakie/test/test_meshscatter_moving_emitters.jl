# A glowing meshscatter whose instances move every frame (sun spots under glass
# drops, fireflies). Its instances are meshes of their own in world space, so a
# move deletes and pushes them again, and deleting an emitter only switches its
# lights off. Pushed anew, 90 moving spots of a 96-face disc grew the light set
# by ~8000 lights a frame (half a million after 60 frames, every frame slower)
# until a 13 s film failed in `trace_renderobject`. The rebuild takes the old
# emitters' material and light slots instead.

using Test, Makie, RayMakie, Hikari, GeometryBasics

lum(c) = 0.2126f0 * c.r + 0.7152f0 * c.g + 0.0722f0 * c.b
half_lum(img, cols) = sum(lum, img[:, cols]) / length(img[:, cols])

flat_disc(n) = normal_mesh(Tessellation(Cylinder(Point3f(0), Point3f(0, 0, 0.01f0), 1f0), n))

function spot_scene(positions, sizes)
    sc = Scene(; size = (64, 64), backgroundcolor = RGBf(0, 0, 0), lights = [AmbientLight(RGBf(0, 0, 0))])
    cam3d!(sc; center = false)
    mesh!(sc, Rect3f(Vec3f(-3, -3, -0.01), Vec3f(6, 6, 0.01)); material = Hikari.Diffuse(color = (0.8, 0.8, 0.8)))
    p = meshscatter!(sc, positions; marker = flat_disc(24), markersize = sizes,
                     material = Hikari.Emission(color = (20, 20, 20), two_sided = true))
    update_cam!(sc, cameracontrols(sc), Vec3f(0, 0, 6), Vec3f(0, 0, 0), Vec3f(0, 1, 0))
    return sc, p
end

@testset "moving glowing instances" begin
    @testset "the light set stays the size of the instances" begin
        n = 40
        sc, p = spot_scene([Point3f(0, 0, 0.3) for _ in 1:n], fill(Vec3f(0.1, 0.1, 1), n))
        screen = RayMakie.Screen(sc; visible = false, rasterize = false, samples = 1, max_depth = 2)
        Makie.colorbuffer(screen)
        hs = screen.state.hikari_scene
        lights0, interfaces0 = length(hs.lights), length(hs.media_interfaces)
        for k in 1:12
            pos = [Point3f(4rand() - 2, 4rand() - 2, 0.3) for _ in 1:n]
            # some hidden (scaled to nothing): they leave their slots spare for later frames
            sizes = [isodd(i + k) && i % 3 == 0 ? Vec3f(0) : Vec3f(0.1, 0.1, 1) for i in 1:n]
            Makie.update!(p; arg1 = pos, markersize = sizes)
            Makie.colorbuffer(screen)
        end
        @test length(hs.lights) == lights0
        @test length(hs.media_interfaces) == interfaces0
        close(screen)
    end

    @testset "a moved lamp lights where it is now" begin
        sc, p = spot_scene([Point3f(-1.5, 0, 0.5), Point3f(0, 0, -5)], [Vec3f(0.4, 0.4, 1), Vec3f(0)])
        screen = RayMakie.Screen(sc; visible = false, rasterize = false, samples = 16, max_depth = 3)
        img = Makie.colorbuffer(screen)
        @test half_lum(img, 1:24) > 4 * half_lum(img, 41:64)
        # moved right; the hidden one takes the old place, still hidden
        Makie.update!(p; arg1 = [Point3f(1.5, 0, 0.5), Point3f(-1.5, 0, 0.5)], markersize = [Vec3f(0.4, 0.4, 1), Vec3f(0)])
        img = Makie.colorbuffer(screen)
        @test half_lum(img, 41:64) > 4 * half_lum(img, 1:24)
        # both shown
        Makie.update!(p; markersize = [Vec3f(0.4, 0.4, 1), Vec3f(0.4, 0.4, 1)])
        img = Makie.colorbuffer(screen)
        @test half_lum(img, 1:24) ≈ half_lum(img, 41:64) rtol = 0.2
        close(screen)
    end
end
