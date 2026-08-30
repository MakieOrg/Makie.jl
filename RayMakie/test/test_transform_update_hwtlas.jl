using Test
using Makie, RayMakie, Hikari, Lava, GeometryBasics, Raycore
import ColorTypes

# Moving a `mesh!` did nothing under hardware ray tracing, which is the default.
#
# `update_trace_transform!` had two branches: the multi-handle one (meshscatter)
# called `Raycore.update_transform!(accel, handle, transform)`, which both
# `Raycore.TLAS` and `Mantle.VulkanTLAS` implement, while the single-handle one
# (mesh) called the index-based `update_instance_transforms!(tlas, …, idx)`,
# which only `TLAS` has — `VulkanTLAS` is batch/handle-addressed. So the mesh path
# threw a MethodError, `poll_all_plots` logged and swallowed it, and the
# transform never applied. Silent: meshscatter animated, mesh sat still.
#
# Both branches now use the handle API. A single mesh is a batch of one and
# `update_transform!` sets every instance in the batch, so it is the same
# operation minus the per-update `allocate` + `fill!`.
@testset "transform update reaches the accel" begin
    scene = Makie.Scene(size = (48, 48))
    Makie.Camera3D(scene)
    p = mesh!(scene, Rect3f(Vec3f(-0.5), Vec3f(1)), color = :red)
    screen = RayMakie.Screen(scene; device = Mantle.defaultbackend(), visible = false)
    RayMakie.init_scene!(screen, scene)
    state = screen.scene_states[1]

    # Pin the configuration this regressed under; a software TLAS never had the
    # bug, so a test that silently ran on one would prove nothing. `HWTLAS` is
    # the abstract type in Mantle core — `VulkanTLAS` named one backend's
    # concrete and made this assertion unreachable on any other.
    @test state.hikari_scene.accel isa Mantle.HWTLAS

    before = (state.refit_eligible_rebuilds, state.topology_rebuilds)
    for f in 1:5
        Makie.translate!(p, 0.05f0 * f, 0.0f0, 0.0f0)
        RayMakie.poll_all_plots(screen, scene)
    end
    # A transform must take the update path, never a rebuild.
    @test (state.refit_eligible_rebuilds, state.topology_rebuilds) == before
    # And it must actually have been queued for the next refit.
    @test state.hikari_scene.accel.transforms_dirty

    close(screen)
end

# The counters above only say a rebuild was avoided, not that anything moved.
# This renders and compares. The renderer is deterministic at a fixed sample
# index, so two renders of an unchanged scene differ by exactly 0.0 — the
# control is what makes the comparison meaningful rather than a noise contest.
@testset "transform update reaches the image" begin
    scene = Makie.Scene(size = (48, 48))
    Makie.Camera3D(scene)
    p = mesh!(scene, Rect3f(Vec3f(-0.5), Vec3f(1)), color = :red)
    screen = RayMakie.Screen(scene; device = Mantle.defaultbackend(), visible = false)

    red_of(img) = Float32.(ColorTypes.red.(img))
    a = red_of(Makie.colorbuffer(screen))
    b = red_of(Makie.colorbuffer(screen))
    noise = maximum(abs.(a .- b))
    @test noise == 0.0f0            # if this ever fails, the assert below is meaningless

    Makie.translate!(p, 3.0f0, 0.0f0, 0.0f0)
    c = red_of(Makie.colorbuffer(screen))
    @test maximum(abs.(b .- c)) > 0.01f0

    close(screen)
end
