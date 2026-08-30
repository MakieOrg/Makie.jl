# Switching `hw_accel` on a live scene must switch the acceleration structure.
#
# `create_scene_state` builds the `Hikari.Scene` from the integrator, and
# `hw_accel` picks the accel type THERE — it is baked in at construction. But a
# second `colorbuffer` on the same Makie scene goes through
# `apply_screen_config!`, which used to keep the existing scene states and only
# free the integrator state. So the second render silently kept the first
# render's traversal path.
#
# Nothing errored and both images were right, which is what made it expensive:
# any A/B of the two paths measured the first one twice. Measured on an M5 with
# crown at 1000x1400 / 8 spp, hardware then software in one process: 2.24 s and
# 2.24 s. In separate processes, with the correct structures: 2.76 s and 5.63 s.
#
# The second half of the fix is the one that is easy to miss: `init_scene!`
# skips any plot that still carries a `:trace_renderobject`, so dropping the
# scene states alone rebuilds an EMPTY scene, `n_instances` is 0, and the
# render returns a blank film in milliseconds. Both halves are asserted here —
# the accel TYPE changes, and the rebuilt scene still has its geometry.

using Test, Makie, RayMakie, Hikari, Raycore, GeometryBasics

# The accel a fresh render of `scene` actually ends up with, plus how much
# geometry reached it.
function accel_after_render(scene, hw)
    integrator = Hikari.VolPath(; samples = 1, max_depth = 2, hw_accel = hw)
    Makie.colorbuffer(scene; backend = RayMakie, integrator = integrator, update = false)
    screen = Makie.getscreen(scene)
    @test screen !== nothing
    state = first(screen.scene_states)
    accel = state.hikari_scene.accel
    (accel, Raycore.n_instances(accel))
end

@testset "switching hw_accel rebuilds the acceleration structure" begin
    scene = Makie.Scene(size = (64, 48))
    Makie.cam3d!(scene)
    mesh!(scene, Sphere(Point3f(0), 1.0f0); color = :red)

    hw1, n1 = accel_after_render(scene, true)
    sw,  ns = accel_after_render(scene, false)
    hw2, n2 = accel_after_render(scene, true)

    # The type is the assertion, not a driver name: what matters is that
    # `hw_accel=false` does NOT keep whatever `hw_accel=true` built, and back.
    @test typeof(hw1) !== typeof(sw)
    @test typeof(hw2) === typeof(hw1)

    # …and every rebuild still has the geometry. This is what fails when the
    # plots are not re-registered: the accel type flips and the scene is empty.
    @test n1 > 0
    @test ns > 0
    @test n2 > 0
    @test ns == n1
end

@testset "an unchanged hw_accel does not rebuild" begin
    # The cheap path has to stay cheap: re-rendering with a new integrator that
    # wants the SAME structure must not drop the scene, because rebuilding
    # re-uploads every mesh.
    scene = Makie.Scene(size = (64, 48))
    Makie.cam3d!(scene)
    mesh!(scene, Sphere(Point3f(0), 1.0f0); color = :blue)

    accel_after_render(scene, true)
    first_accel = first(Makie.getscreen(scene).scene_states).hikari_scene.accel
    accel_after_render(scene, true)
    @test first(Makie.getscreen(scene).scene_states).hikari_scene.accel === first_accel
end
