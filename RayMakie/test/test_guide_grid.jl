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
    @test traced.guide_grid == -1
    @test all(iszero, Array(traced.film.normal))
    # The background is composited by depth, which needs only the centre ray.
    @test count(!=(picture[1, 1]), picture) > 0
    RayMakie.fillauxbuffers!(scr, traced; guides = true)
    @test traced.guide_grid == 9
    @test any(n -> n != Vec3f(0), Array(traced.film.normal))
end

@testset "camera input between color and depth passes" begin
    scr, traced = guidedscreen(; accumulate = true)
    try
        Makie.colorbuffer(scr; samples = 2)
        previous_depth = Array(traced.film.depth)
        previous_color = Array(traced.film.framebuffer)
        RayMakie.render!(scr)
        @test traced.film.iteration_index[] == 3

        # A camera event can arrive after a sample is submitted and before its
        # depth pass is launched. The depth mask still belongs to that sample.
        camera = cameracontrols(scr.scene)
        camera.lookat[] += Vec3f(0.4, 0.2, 0)
        Makie.update_cam!(scr.scene, camera)
        traced.guide_grid = 0
        RayMakie.fillauxbuffers!(scr, traced)
        @test Array(traced.film.depth) == previous_depth

        RayMakie.render!(scr)
        @test traced.film.iteration_index[] == 1
        RayMakie.fillauxbuffers!(scr, traced)
        @test Array(traced.film.depth) != previous_depth
        moved_color = Array(traced.film.framebuffer)
        @test moved_color != previous_color

        # A fresh plan uploads this view at construction. Matching it also
        # checks that replay uploaded the changed camera to the old plan.
        fresh, fresh_state = guidedscreen()
        try
            fresh_camera = cameracontrols(fresh.scene)
            fresh_camera.lookat[] = camera.lookat[]
            Makie.update_cam!(fresh.scene, fresh_camera)
            Makie.colorbuffer(fresh; samples = 1)
            @test moved_color ≈ Array(fresh_state.film.framebuffer)
        finally
            close(fresh)
        end

        RayMakie.render!(scr)
        @test traced.film.iteration_index[] == 2
    finally
        close(scr)
    end
end
