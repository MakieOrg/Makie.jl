# How many samples one `colorbuffer` read renders.
#
# A path tracer's frame is a running average, so "how many samples" is a property
# of the READ, not of the renderer: an interactive preview wants one sample per
# read and lets them accumulate while nothing moves, and a finished frame — a
# bake, an export — wants the whole budget in one call. Both come off the same
# screen with the same integrator.
#
# So there are three sources, narrowest first: `colorbuffer`'s `samples`, then the
# screen's own `samples`, then the integrator's `samples_per_pixel`. The middle
# one is what a settings form can offer — an integrator is a Julia object, and
# "how expensive is one finished frame" should be a number in a box.

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

@testset "the sample budget of one read" begin
    @testset "with nothing said, the integrator's own" begin
        screen = RayMakie.Screen(budget_scene(); integrator = Hikari.VolPath(samples = 5))
        Makie.colorbuffer(screen)
        @test rendered(screen) == 5
    end

    @testset "the screen's `samples` overrides the integrator's" begin
        # What the editor's rendering dialog writes: the integrator keeps its own
        # count, and the number in the box is what one finished frame costs.
        screen = RayMakie.Screen(budget_scene();
                                 integrator = Hikari.VolPath(samples = 8), samples = 3)
        Makie.colorbuffer(screen)
        @test screen.config.integrator.samples_per_pixel == 8
        @test rendered(screen) == 3
    end

    @testset "the read's `samples` overrides both" begin
        screen = RayMakie.Screen(budget_scene();
                                 integrator = Hikari.VolPath(samples = 8), samples = 3)
        Makie.colorbuffer(screen; samples = 1)
        @test rendered(screen) == 1
    end

    @testset "`clear = false` keeps adding to the film that is there" begin
        # This is what makes a live preview converge: a playhead move costs one
        # sample, and standing still adds one at a time to the same frame.
        screen = RayMakie.Screen(budget_scene(); integrator = Hikari.VolPath(samples = 5))
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
        screen = RayMakie.Screen(budget_scene();
                                 integrator = Hikari.VolPath(samples = 2), samples = 8.0)
        @test screen.config.samples === 8
    end
end
