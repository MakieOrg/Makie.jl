# test_dolphin_update_stress.jl
#
# Mirrors the smallest viable shape of the moving-dolphin renderer
# (`RayDemo/Waterlily/render_dolphin_rainbow_glow.jl`): one frame's worth of
# work per loop iter mutates BOTH the dolphin mesh (`Makie.update!(plt;
# arg1=new_mesh)`) and the surrounding emissive volumetric medium
# (`Makie.update!(plt; material=new_MediumInterface)`).  Repeats for many
# frames at minimal resolution + samples to surface:
#
#   * leaks (live_buffer_count / gpu_live_bytes growth across frames)
#   * use-after-free assertions
#   * batch.bq desync
#   * SPIR-V emit failures triggered by dynamic mesh/material updates
#
# Runs both lava_sw (SW BVH) and lava_hw (AdaptedAccel inline ray query),
# proving the polymorphic `Raycore.closest_hit(accel, ray)` path is leak-free
# across mesh + medium swaps.

using Test, Makie, RayMakie, Lava, Hikari, Raycore
using GeometryBasics
using GeometryBasics: Point3f, Vec3f, Rect3f, Sphere

ctx = MVE.vk_context()
const HW_AVAILABLE = ctx.ray_query_available

# Two interchangeable mesh shapes — same mesh-recipe schema, different
# topology, so each `update!(plt; arg1=other_mesh)` exercises the resize-or-
# rebuild branch in draw_atomic.
const SPHERE = GeometryBasics.normal_mesh(GeometryBasics.Tesselation(Sphere(Point3f(0), 1f0), 16))
const CUBE   = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))

"""
Build a small RGBGridMedium mimicking the rainbow_glow medium in
render_dolphin_rainbow_glow.jl.  Per-frame call returns a fresh medium so
the `material=` update path actually flips the underlying GPU arrays.
"""
function fresh_medium(; nx::Int=8, scale::Float32=1.0f0)
    σ_a = fill(Hikari.RGBSpectrum(0.05f0, 0.05f0, 0.05f0), nx, nx, nx)
    σ_s = fill(Hikari.RGBSpectrum(scale * 0.3f0, scale * 0.3f0, scale * 0.3f0), nx, nx, nx)
    Le  = fill(Hikari.RGBSpectrum(scale * 1.0f0, scale * 0.6f0, scale * 0.2f0), nx, nx, nx)
    bounds = Raycore.Bounds3(Point3f(-2, -2, -2), Point3f(2, 2, 2))
    Hikari.RGBGridMedium(σ_a_grid=σ_a, σ_s_grid=σ_s, Le_grid=Le,
        sigma_scale=0.05f0, Le_scale=0.5f0, g=0.6f0,
        bounds=bounds, majorant_res=Vec{3, Int64}(4, 4, 4))
end

fresh_glass_with_medium(scale::Float32) = Hikari.MediumInterface(
    Hikari.Dielectric(index=1.0f0, roughness=0.0f0); inside=fresh_medium(; scale))

"""
Run `n_frames` of (mesh-swap + medium-swap), measuring buffer delta + GPU
bytes after each frame.  Returns a NamedTuple with the raw counts so the
caller can assert against drift.
"""
function dolphin_like_loop(; hw_accel::Bool, n_frames::Int=10, samples::Int=1)
    GC.gc(true); sleep(0.1); GC.gc(true)
    base_bufs  = MVE.live_buffer_count(ctx)
    base_bytes = MVE.gpu_live_bytes(ctx)

    scene = Scene(size=(96, 64); lights=Makie.AbstractLight[
        Makie.DirectionalLight(Makie.RGBf(2, 2, 2), Vec3f(-0.4, -0.5, -0.7))],
        ambient=Makie.RGBf(0,0,0), backgroundcolor=Makie.RGBf(0,0,0))
    cam3d!(scene)
    update_cam!(scene, Vec3f(6, -6, 4), Vec3f(0,0,0), Vec3f(0,0,1))

    dolphin_plt = mesh!(scene, SPHERE; material=Hikari.CoatedDiffuse(
        reflectance=(0.30f0, 0.32f0, 0.38f0), roughness=0.05f0, eta=1.5f0))
    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-2), Vec3f(4)))
    medium_plt = mesh!(scene, cube; material=fresh_glass_with_medium(1f0))

    integrator = Hikari.VolPath(samples=samples, max_depth=4, hw_accel=hw_accel)
    screen = RayMakie.Screen(scene; integrator)

    bufs_after = Int[]
    bytes_after = Int[]
    img_sample = nothing
    for f in 1:n_frames
        # Mesh swap — alternates SPHERE ↔ CUBE so the recipe sees both topologies
        Makie.update!(dolphin_plt; arg1=isodd(f) ? CUBE : SPHERE)
        # Medium swap — fresh MediumInterface every frame (new GPU arrays,
        # mat slot reused per the no-rebuild invariant in mesh_update_stress).
        Makie.update!(medium_plt; material=fresh_glass_with_medium(Float32(0.5 + 0.5 * sin(f))))
        img_sample = Makie.colorbuffer(screen)
        push!(bufs_after, MVE.live_buffer_count(ctx))
        push!(bytes_after, MVE.gpu_live_bytes(ctx))
    end
    close(screen)

    GC.gc(true); sleep(0.2); GC.gc(true)
    final_bufs = MVE.live_buffer_count(ctx)
    final_bytes = MVE.gpu_live_bytes(ctx)

    return (; base_bufs, base_bytes, bufs_after, bytes_after,
              final_bufs, final_bytes, img_sample)
end

@testset "dolphin update stress — SW BVH (10 frames mesh+medium swap)" begin
    r = dolphin_like_loop(; hw_accel=false, n_frames=10)
    # The strict invariant is "after GC, no per-frame growth" — i.e. buffer
    # count returns to a small constant cache regardless of n_frames.  During
    # the loop itself buffers can pile up while GC waits for the next pause
    # (small per-frame allocations don't trigger collection); that lag is not
    # a bug.  But final Δ MUST stay bounded — if it scaled with n_frames we'd
    # have a real leak.
    Δ = r.final_bufs - r.base_bufs
    Δ_bytes = (r.final_bytes - r.base_bytes) / 1e6
    @test Δ < 30
    @test Δ_bytes < 800   # MB; real leaks scale with n_frames * frame size
    println("  SW: bufs $(r.bufs_after), final Δ=$Δ bufs, GPU Δ=$(round(Δ_bytes, digits=1))MB")
end

if HW_AVAILABLE
    @testset "dolphin update stress — HW ray query (10 frames mesh+medium swap)" begin
        r = dolphin_like_loop(; hw_accel=true, n_frames=10)
        Δ = r.final_bufs - r.base_bufs
        Δ_bytes = (r.final_bytes - r.base_bytes) / 1e6
        @test Δ < 40   # HW path keeps a few extra: hwtlas BLAS+TLAS caches
        @test Δ_bytes < 800
        println("  HW: bufs $(r.bufs_after), final Δ=$Δ bufs, GPU Δ=$(round(Δ_bytes, digits=1))MB")
    end

    @testset "dolphin update stress — HW vs SW polymorphism: same mesh, same scene → both render" begin
        # Locks down the contract from step-2 of the inline-ray-query
        # migration: the SAME high-level scene + animation loop, swapped only
        # by `hw_accel=true|false`, must both succeed.  Production canary for
        # the multiple-dispatch closest_hit path on a mesh+medium update sequence.
        r_sw = dolphin_like_loop(; hw_accel=false, n_frames=3)
        r_hw = dolphin_like_loop(; hw_accel=true, n_frames=3)
        @test r_sw.img_sample !== nothing
        @test r_hw.img_sample !== nothing
        @test size(r_sw.img_sample) == size(r_hw.img_sample)
    end
end
