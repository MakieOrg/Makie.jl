using Test, Makie, RayMakie, GeometryBasics, Colors
using GeometryBasics: Point3f, Vec3f, Sphere

@testset "a window's guides refine while its camera holds still" begin
    @test [RayMakie.guide_grid(true, samples) for samples in 0:9] == [1, 1, 3, 3, 3, 3, 3, 3, 9, 9]
    @test RayMakie.guide_grid(false, 0) == 9
end

function guidedscreen(; kw...)
    sc = Scene(size = (64, 48), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0, 0, 0), 0.8f0); color = :orange)
    scr = RayMakie.Screen(sc; samples = 2, max_depth = 3, visible = false, kw...)
    display(scr, sc)
    return scr, only(ss for ss in scr.scene_states if !ss.overlay_only)
end

@testset "an offscreen render fills its guides at the finest grid when something reads them" begin
    scr, traced = guidedscreen(; denoise = true)
    Makie.colorbuffer(scr)
    @test traced.guide_grid == 9
end

@testset "a render nothing denoises traces one guide ray a pixel, and the capture asks for all of them" begin
    scr, traced = guidedscreen()
    picture = Makie.colorbuffer(scr)
    @test traced.guide_grid == 1
    # The background is composited by depth, which needs only the centre ray.
    @test count(!=(picture[1, 1]), picture) > 0
    RayMakie.fillauxbuffers!(scr, traced; guides = true)
    @test traced.guide_grid == 9
    @test any(n -> n != Vec3f(0), Array(traced.film.normal))
end
