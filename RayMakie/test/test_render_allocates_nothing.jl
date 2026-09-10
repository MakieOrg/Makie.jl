# A sample of a still scene allocates nothing on the host.
#
# `RayMakie.render!(screen)` is what every sample of a `colorbuffer` and every
# frame of the render loop goes through, and on the RayDemo materials scene it
# allocated 11 KB a sample for a scene where nothing had changed. Three things,
# each pinned here by the same number:
#   * `poll_all_plots` read `p[:trace_renderobject][]` on every plot to trigger
#     resolution, and the read boxed the render object (a NamedTuple holding a
#     large isbits material) — 7 KB for 21 plots. It asks
#     `ComputePipeline.isdirty` first and reads only what is dirty.
#   * `render!` read `state.camera[]` through a `Union{Observable, Nothing}`
#     field and made a dynamic call with the 684-byte camera among its
#     arguments and a keyword in a NamedTuple — boxed, all of it. The call goes
#     through `tracesample!`, one dynamic dispatch on heap objects only.
#   * Hikari's own per-sample compare and Mantle's per-buffer stamp, pinned in
#     their own suites (`test_sample_is_one_run.jl`, `test_run_allocates_nothing.jl`).
# The second testset is the other half of the first fix: a plot that DID change
# is still resolved by the poll, or the dirty check would have made every edit
# invisible.
#
# Everything measured lives inside a function — locals, not globals — because a
# non-const global read boxes its way into the count.
using Test, Makie, RayMakie, Lava, Hikari, GeometryBasics
using GeometryBasics: Point3f, Vec3f, Rect3f, Sphere

function allocfree_scene()
    scene = Scene(size = (64, 48), lights = [PointLight(RGBf(30, 30, 30), Vec3f(4, 5, 6))])
    cam3d!(scene)
    mesh!(scene, Rect3f(Vec3f(-4, -4, -0.01), Vec3f(8, 8, 0.01)); material = Hikari.Diffuse(Kd = (0.7, 0.7, 0.7)))
    plt = mesh!(scene, Sphere(Point3f(0, 0, 0.5), 0.5f0); color = :red)
    mesh!(scene, Sphere(Point3f(1.2, 0, 0.4), 0.4f0); material = Hikari.Dielectric(index = 1.5))
    mesh!(scene, Sphere(Point3f(-1.2, 0, 0.4), 0.4f0); material = Hikari.Conductor())
    return scene, plt
end

function sample_bytes(screen, n)
    for _ in 1:n
        RayMakie.render!(screen; finalize_framebuffer = false)
    end
    # Drain the finalizers of everything the compile and the earlier test files
    # dropped, OUTSIDE the measured calls. A GC that fires inside a sample runs
    # them there, and a finalizer that hands a GPU buffer back allocates —
    # measured 2026-09-08: 1184 B in 8 of 60 samples with 400 dropped arrays
    # and no forced GC, 0 of 30 after one, 0 of 30 after another. The claim
    # under test is the STEADY state of a still scene, which that is not.
    GC.gc(true); GC.gc(true)
    # TWO windows, and the first is thrown away — the same rule
    # `Mantle/test/vulkan/test_dispatch_allocation.jl` states, for the same
    # reason. A render SUBMITS and does not wait, so the queue's in-flight list
    # grows until the device catches up and its Vector reallocates on the way:
    # measured 3488 B in the FIRST sample of a window and 0 in all nineteen
    # after it, then 0 in every sample of the next window. The claim under test
    # is the steady state of a still scene, and a list still reaching its
    # working depth is not it.
    [(@allocated RayMakie.render!(screen; finalize_framebuffer = false)) for _ in 1:n]
    return [(@allocated RayMakie.render!(screen; finalize_framebuffer = false)) for _ in 1:n]
end

@testset "a sample of a still scene allocates nothing" begin
    scene, plt = allocfree_scene()
    screen = RayMakie.Screen(scene; integrator = Hikari.VolPath(samples = 1, max_depth = 4, hw_accel = true),
                             visible = false)
    img = colorbuffer(screen)       # compiles, records, renders one sample
    @test size(img) == (48, 64)
    bytes = sample_bytes(screen, 20)
    @test maximum(bytes) == 0
    close(screen)
end

@testset "a changed plot is still resolved by the poll" begin
    scene, plt = allocfree_scene()
    screen = RayMakie.Screen(scene; integrator = Hikari.VolPath(samples = 1, max_depth = 4, hw_accel = true),
                             visible = false)
    colorbuffer(screen)
    node = plt[:trace_renderobject]
    @test !Makie.ComputePipeline.isdirty(node)
    plt.color = :blue
    @test Makie.ComputePipeline.isdirty(node)
    RayMakie.render!(screen; finalize_framebuffer = false)
    @test !Makie.ComputePipeline.isdirty(node)      # the sample's poll resolved it
    close(screen)
end
