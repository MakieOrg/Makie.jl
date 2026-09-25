# How many samples one `colorbuffer` read renders.
#
# A path tracer's frame is a running average, so "how many samples" is a property
# of the READ, not of the renderer: an interactive preview wants one sample per
# read and lets them accumulate while nothing moves, and a finished frame — a
# bake, an export — wants the whole budget in one call. Both come off the same
# screen.
#
# So there are three sources, narrowest first: `colorbuffer`'s `samples`, then the
# screen's own `samples`, then `Hikari.VolPath`'s default. `hw_accel = false` is
# what these ran with when the tracer was passed in as a `VolPath`.

using Test
using Makie, RayMakie, Hikari, GeometryBasics, Colors
using Makie: Scene, cam3d!, mesh!, cameracontrols, update_cam!, Point3f, Vec3f,
             Sphere, RGBf, PointLight

function budget_scene()
    sc = Scene(; size = (64, 64), lights = [PointLight(RGBf(60, 60, 60), Vec3f(4, 4, 6))],
               backgroundcolor = :white)
    cam3d!(sc)
    mesh!(sc, Sphere(Point3f(0), 1.0f0); material = Hikari.Diffuse(Kd = (0.8, 0.2, 0.2)))
    cam = cameracontrols(sc)
    cam.eyeposition[] = Vec3f(0, -6, 3)
    cam.lookat[] = Vec3f(0, 0, 0)
    cam.upvector[] = Vec3f(0, 0, 1)
    update_cam!(sc, cam)
    return sc
end

"How many samples the last read actually rendered."
rendered(screen) = Int(screen.state.film.iteration_index[])
tracer(screen) = only(filter(ss -> !ss.overlay_only, screen.scene_states)).integrator

@testset "the sample budget of one read" begin
    @testset "with nothing said, Hikari's default" begin
        screen = RayMakie.Screen(budget_scene(); hw_accel = false)
        Makie.colorbuffer(screen)
        @test rendered(screen) == Hikari.VolPath().samples_per_pixel
    end

    @testset "the screen's `samples`" begin
        # What the editor's rendering dialog writes: the number in the box is what
        # one finished frame costs, and the tracer is built for it.
        screen = RayMakie.Screen(budget_scene(); samples = 3, hw_accel = false)
        Makie.colorbuffer(screen)
        @test rendered(screen) == 3
        @test tracer(screen).samples_per_pixel == 3
    end

    @testset "the read's `samples` overrides both" begin
        screen = RayMakie.Screen(budget_scene(); samples = 3, hw_accel = false)
        Makie.colorbuffer(screen; samples = 1)
        @test rendered(screen) == 1
    end

    @testset "`clear = false` keeps adding to the film that is there" begin
        # This is what makes a live preview converge: a playhead move costs one
        # sample, and standing still adds one at a time to the same frame.
        screen = RayMakie.Screen(budget_scene(); samples = 5, hw_accel = false)
        Makie.colorbuffer(screen; samples = 1)
        @test rendered(screen) == 1
        Makie.colorbuffer(screen; samples = 1, clear = false)
        @test rendered(screen) == 2
        Makie.colorbuffer(screen; samples = 1, clear = false)
        @test rendered(screen) == 3
        Makie.colorbuffer(screen; samples = 1)          # …and clearing starts over
        @test rendered(screen) == 1
    end

    @testset "a settings form's number arrives as a float" begin
        # A text box has no way to know the field wants an `Int`, so the value
        # comes through as `8.0`. The constructor rounds it rather than throwing.
        screen = RayMakie.Screen(budget_scene(); samples = 8.0, hw_accel = false)
        @test screen.config.samples === 8
    end
end
