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
# No `using Lava`: none of this file names one, and loading it drags in the
# Vulkan loader — which is not there on every machine this suite runs on, so
# the whole file errored before its first test rather than running on the
# backend `runtests.jl` already found and activated.
using Test, Makie, RayMakie, Hikari, GeometryBasics
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
    for _ in 1:5
        RayMakie.render!(screen; finalize_framebuffer = false)
    end
    # Drain the finalizers of everything the compile and the earlier test files
    # dropped, OUTSIDE the measured calls. A GC that fires inside a sample runs
    # them there, and a finalizer that hands a GPU buffer back allocates —
    # measured 2026-09-08: 1184 B in 8 of 60 samples with 400 dropped arrays
    # and no forced GC, 0 of 30 after one, 0 of 30 after another. The claim
    # under test is the STEADY state of a still scene, which that is not.
    GC.gc(true); GC.gc(true)
    # …and then render again, because the collection above only QUEUED the work.
    # A finalizer that hands a GPU region back puts it on the pool's retire list,
    # and `reclaim!` — which every `run!` calls — is what walks and coalesces it.
    # With the samples measured immediately after a GC, that walk landed INSIDE
    # one of them: 41 KB in a suite that had dropped a few hundred regions in the
    # files before this one, against a few hundred bytes for the same scene
    # measured alone. The steady state is what this file is about, and the frame
    # after a collection is not it.
    for _ in 1:3
        RayMakie.render!(screen; finalize_framebuffer = false)
    end
    # And with the collector OFF for the measurement itself. Draining first is not
    # enough in a suite that has run a dozen files before this one: a GC firing
    # inside one of the twenty samples runs whatever finalizers are pending THERE,
    # and a finalizer handing a GPU region back allocates — 41 KB in one sample of
    # twenty, against a few hundred bytes for every other and for the same scene
    # measured alone. What this file claims is what a still sample costs, and a
    # collection that happens to land in it is not that.
    GC.enable(false)
    bytes = try
        [(@allocated RayMakie.render!(screen; finalize_framebuffer = false)) for _ in 1:n]
    finally
        GC.enable(true)
    end
    return bytes
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
