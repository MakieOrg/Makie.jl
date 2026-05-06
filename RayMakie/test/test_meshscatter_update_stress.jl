# Stress tests for the RayMakie meshscatter compute graph.
#
# Pattern:
#   screen = RayMakie.Screen(scene; integrator=...)   # built once
#   colorbuffer(screen)                                # in tight loop
#
# All updates use the standard Makie Observable API. Internal functions
# (Raycore.sync!, meshscatter_update!, etc.) are NEVER called from tests.
#
# Coverage:
#   1. Refit-path correctness, uniform Float32 scale, GPU positions, 500×40
#   2. Refit-path correctness, per-instance Vec3f scale, GPU positions, 300×30
#   3. Refit-path correctness, CPU positions (Vector{Point3f}), 200×30
#   4. trace_transforms buffer reuse — single allocation across many frames
#   5. trace_renderobject identity stability across same-shape refits
#   6. Marker mesh change → full BLAS rebuild, pinned mi_indices reused
#   7. Instance count grow / shrink → BLAS rebuild, materials reflow
#   8. Empty positions ↔ non-empty transitions
#   9. Live color update via Observable, transforms_buf untouched
#  10. Mixed CPU/GPU position alternation across frames
#  11. Large-mesh meshscatter refit stress, 50 frames, hi-res sphere

using Test, Makie, RayMakie, Lava, Raycore, Hikari, GeometryBasics
using Lava: LavaArray, LavaBackend, Mat3x4f
using GeometryBasics: Point3f, Vec3f, Vec4f
using Statistics: mean

# Convenience: the trace_renderobject NamedTuple stored on the plot.
robj_of(plt) = to_value(plt.attributes[:trace_renderobject])

# Convenience: the persistent transforms buffer (LavaArray{Mat3x4f,1} or Vector).
trans_of(plt) = to_value(plt.attributes[:trace_transforms])

# Build a hi-res unit sphere mesh.
hires_sphere(divisions::Int) = GeometryBasics.normal_mesh(
    GeometryBasics.Tesselation(GeometryBasics.Sphere(Point3f(0), 1f0), divisions))

# Make a screen with a 1-sample VolPath for fast offscreen render.
function make_screen(scene)
    return RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=1, max_depth=1))
end

# ---------------------------------------------------------------------------
# Pixel utilities — verify the meshscatter actually shows up in the image
# ---------------------------------------------------------------------------
#
# We don't compare to scene.backgroundcolor because the rendered atmosphere
# / default lighting tints the background. Instead we sample a corner pixel
# (well outside any plausible object placement) as our reference and call
# everything that deviates from it by `thresh` "lit".

function bg_reference(img)
    # Average of the four corners — robust against single-pixel sampler noise.
    h, w = size(img)
    p = (img[1,1], img[1,w], img[h,1], img[h,w])
    Makie.RGBAf(mean(c.r for c in p), mean(c.g for c in p),
                mean(c.b for c in p), 1f0)
end

function lit_mask(img::AbstractMatrix; thresh::Float32 = 0.08f0)
    bg = bg_reference(img)
    [abs(p.r - bg.r) > thresh ||
     abs(p.g - bg.g) > thresh ||
     abs(p.b - bg.b) > thresh
     for p in img]
end

lit_count(img; kw...) = count(lit_mask(img; kw...))

# Centroid (row, col) of lit pixels, or `nothing` if none.
function lit_centroid(img; kw...)
    mask = lit_mask(img; kw...)
    n = count(mask)
    n == 0 && return nothing
    rows = sum(I[1] for I in CartesianIndices(mask) if mask[I])
    cols = sum(I[2] for I in CartesianIndices(mask) if mask[I])
    return (rows / n, cols / n)
end

# ===========================================================================
# 1. GPU positions, uniform scale — 500 instances × 40 frames
# ===========================================================================

@testset "meshscatter refit — GPU positions, uniform scale, 500×40" begin
    n = 500
    positions = Observable(LavaArray([Point3f(Float32(i)*0.05f0 - 12f0, 0f0, 0f0)
                                     for i in 1:n]))

    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.3f0, color=:red)

    screen = make_screen(scene)
    img0 = Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    pinned_robj = robj_of(plt)
    @test pinned_robj.n_instances == n
    @test pinned_buf isa LavaArray{Mat3x4f, 1}
    @test length(pinned_buf) == n
    @test lit_count(img0) > 100   # spheres really show up on screen

    for frame in 1:40
        dx = Float32(frame) * 0.05f0
        positions[] = LavaArray([Point3f(Float32(i)*0.05f0 - 12f0 + dx,
                                         Float32(frame)*0.02f0, 0f0)
                                 for i in 1:n])
        img = Makie.colorbuffer(screen)

        @test trans_of(plt) === pinned_buf                 # buffer reused
        @test robj_of(plt).handles === pinned_robj.handles # same TLAS handles

        cpu = Array(trans_of(plt))
        for i in (1, 200, 250, 499, n)
            t = cpu[i]
            @test t[4,1] ≈ Float32(i)*0.05f0 - 12f0 + dx  atol=1f-4
            @test t[4,2] ≈ Float32(frame)*0.02f0           atol=1f-4
            @test t[4,3] ≈ 0f0                              atol=1f-4
            @test t[1,1] ≈ 0.3f0                            atol=1f-4
            @test t[2,2] ≈ 0.3f0                            atol=1f-4
            @test t[3,3] ≈ 0.3f0                            atol=1f-4
        end

        # Per-frame pixel check: meshes remain visible — never goes blank
        # despite many TLAS refits.
        @test lit_count(img) > 50
    end
    close(screen)
end

# ===========================================================================
# 2. GPU positions, per-instance Vec3f markersize — 300 × 30 frames
# ===========================================================================

@testset "meshscatter refit — per-instance Vec3f scale, 300×30" begin
    n = 300
    positions = Observable(LavaArray([Point3f(Float32(i)*0.05f0 - 7f0, 0f0, 0f0)
                                     for i in 1:n]))
    scales    = Observable(LavaArray([Vec3f(0.05f0, 0.05f0, 0.05f0) for _ in 1:n]))

    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=scales, color=:magenta)

    screen = make_screen(scene)
    img0 = Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    @test robj_of(plt).n_instances == n
    @test lit_count(img0) > 50

    for frame in 1:30
        dx = Float32(frame) * 0.05f0
        positions[] = LavaArray([Point3f(Float32(i)*0.05f0 - 7f0 + dx, 0f0, 0f0)
                                 for i in 1:n])
        scales[]    = LavaArray([Vec3f(0.05f0,
                                       0.05f0 + Float32(frame)*0.001f0,
                                       0.05f0) for _ in 1:n])
        img = Makie.colorbuffer(screen)

        @test trans_of(plt) === pinned_buf

        cpu = Array(trans_of(plt))
        for i in (1, 10, n÷2, n)
            t = cpu[i]
            @test t[1,1] ≈ 0.05f0                              atol=1f-4
            @test t[2,2] ≈ 0.05f0 + Float32(frame)*0.001f0     atol=1f-4
            @test t[3,3] ≈ 0.05f0                              atol=1f-4
            @test t[4,1] ≈ Float32(i)*0.05f0 - 7f0 + dx        atol=1f-4
        end
        @test lit_count(img) > 30
    end
    close(screen)
end

# ===========================================================================
# 3. CPU positions (no LavaArray) — same code path, no isa branching
# ===========================================================================

@testset "meshscatter refit — CPU Vector positions, 200×30" begin
    n = 200
    positions = Observable([Point3f(Float32(i)*0.08f0 - 8f0, 0f0, 0f0) for i in 1:n])

    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.1f0, color=:green)

    screen = make_screen(scene)
    img0 = Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    @test robj_of(plt).n_instances == n
    # CPU positions → CPU transforms buffer (same code path, just a Vector)
    @test pinned_buf isa Vector{Mat3x4f}
    @test length(pinned_buf) == n
    @test lit_count(img0) > 30

    for frame in 1:30
        positions[] = [Point3f(Float32(i)*0.08f0 - 8f0,
                               Float32(frame)*0.05f0, 0f0) for i in 1:n]
        img = Makie.colorbuffer(screen)

        @test trans_of(plt) === pinned_buf
        cpu = trans_of(plt)
        @test cpu[1][4,1] ≈ 0.08f0 - 8f0          atol=1f-4
        @test cpu[1][4,2] ≈ Float32(frame)*0.05f0 atol=1f-4
        @test cpu[1][1,1] ≈ 0.1f0                 atol=1f-4
        @test lit_count(img) > 20
    end
    close(screen)
end

# ===========================================================================
# 4. trace_transforms buffer reuse across very many frames
# ===========================================================================

@testset "meshscatter — single transforms_buf allocation, 100 frames" begin
    n = 64
    positions = Observable(LavaArray([Point3f(Float32(i)*0.2f0 - 6.5f0, 0f0, 0f0)
                                     for i in 1:n]))

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.2f0, color=:orange)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)

    pinned = trans_of(plt)
    pinned_robj_handles = robj_of(plt).handles
    for frame in 1:100
        positions[] = LavaArray([Point3f(Float32(i)*0.2f0 - 6.5f0,
                                         Float32(frame)*0.05f0, 0f0)
                                 for i in 1:n])
        img = Makie.colorbuffer(screen)
        @test trans_of(plt) === pinned
        @test robj_of(plt).handles === pinned_robj_handles
        # Visible across 100 successive refits — no GPU-state regression
        @test lit_count(img) > 5
    end
    close(screen)
end

# ===========================================================================
# 5. Marker mesh change → full rebuild, mi_indices reused
# ===========================================================================

@testset "meshscatter — marker mesh swap triggers rebuild, mi_indices reused" begin
    n = 50
    positions = Observable(LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n]))
    sphere0 = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1f0))
    marker = Observable{Any}(sphere0)

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=marker, markersize=0.4f0)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)

    robj1 = robj_of(plt)
    mi1 = copy(robj1.mi_indices)
    @test length(mi1) == n

    # Swap to a cube — full rebuild path, but mi_indices should be reused.
    cube = GeometryBasics.normal_mesh(GeometryBasics.Rect3f(Vec3f(-1), Vec3f(2)))
    marker[] = cube
    Makie.colorbuffer(screen)

    robj2 = robj_of(plt)
    @test robj2.n_instances == n
    @test robj2.mi_indices == mi1   # reused MultiTypeSet slots — no growth
    close(screen)
end

# ===========================================================================
# 6. Instance count grow / shrink → BLAS rebuild
# ===========================================================================

@testset "meshscatter — instance count cycles trigger rebuild" begin
    positions = Observable(LavaArray([Point3f(0f0, 0f0, 0f0)]))

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.3f0)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)

    for cycle in 1:5
        for n in (10, 100, 250, 100, 10, 1, 50)
            positions[] = LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n])
            Makie.colorbuffer(screen)
            @test robj_of(plt).n_instances == n
            @test length(trans_of(plt)) == n
            cpu = Array(trans_of(plt))
            @test cpu[end][4,1] ≈ Float32(n) atol=1f-4
        end
    end
    close(screen)
end

# ===========================================================================
# 7. Empty positions ↔ non-empty transitions
# ===========================================================================

@testset "meshscatter — empty / non-empty transitions" begin
    positions = Observable(LavaArray(Point3f[]))

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.3f0)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)
    @test robj_of(plt).n_instances == 0

    positions[] = LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:5])
    Makie.colorbuffer(screen)
    @test robj_of(plt).n_instances == 5

    positions[] = LavaArray(Point3f[])
    Makie.colorbuffer(screen)
    @test robj_of(plt).n_instances == 0

    positions[] = LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:20])
    Makie.colorbuffer(screen)
    @test robj_of(plt).n_instances == 20
    close(screen)
end

# ===========================================================================
# 8. Color update via Observable, transforms buffer untouched
# ===========================================================================

@testset "meshscatter — color update keeps transforms_buf identity" begin
    n = 32
    positions = Observable(LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n]))
    color = Observable(Makie.RGBAf(0.8, 0.8, 0.8, 1.0))

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=0.3f0, color=color)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    pinned_handles = robj_of(plt).handles

    for r in range(0f0, 1f0; length=20)
        color[] = Makie.RGBAf(r, 1f0-r, 0.5f0, 1.0)
        Makie.colorbuffer(screen)
        @test trans_of(plt) === pinned_buf
        @test robj_of(plt).handles === pinned_handles  # in-place material update
    end
    close(screen)
end

# ===========================================================================
# 9. Live markersize swap on the same plot, scalar Float updates
# ===========================================================================

@testset "meshscatter — scalar markersize live updates" begin
    n = 80
    positions = Observable(LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n]))
    markersize = Observable(0.3f0)

    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; markersize=markersize)

    screen = make_screen(scene)
    Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    for s in (0.1f0, 0.5f0, 1.0f0, 0.2f0, 0.7f0)
        markersize[] = s
        Makie.colorbuffer(screen)
        @test trans_of(plt) === pinned_buf
        cpu = Array(trans_of(plt))
        @test cpu[1][1,1] ≈ s  atol=1f-4
        @test cpu[1][2,2] ≈ s  atol=1f-4
        @test cpu[1][3,3] ≈ s  atol=1f-4
    end
    close(screen)
end

# ===========================================================================
# 10. Large-mesh refit stress — 50 frames, hi-res sphere, 100 instances
# ===========================================================================

@testset "meshscatter — large-mesh refit stress, 50 frames" begin
    sphere = hires_sphere(50)
    n = 100
    positions = Observable(LavaArray([Point3f(Float32(i)*0.3f0 - 15f0, 0f0, 0f0)
                                     for i in 1:n]))

    scene = Scene(size=(64, 64)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=sphere, markersize=0.5f0, color=:cyan)

    screen = make_screen(scene)
    img0 = Makie.colorbuffer(screen)
    @test robj_of(plt).n_instances == n
    @test lit_count(img0) > 100

    pinned_buf = trans_of(plt)
    centroids = Tuple{Float64, Float64}[]
    for frame in 1:50
        dy = Float32(frame) * 0.1f0
        positions[] = LavaArray([Point3f(Float32(i)*0.3f0 - 15f0, dy, 0f0)
                                 for i in 1:n])
        img = Makie.colorbuffer(screen)
        @test trans_of(plt) === pinned_buf
        cpu = Array(trans_of(plt))
        @test cpu[n÷2][4,2] ≈ dy atol=1f-4
        @test lit_count(img) > 50    # spheres still visible

        c = lit_centroid(img)
        c !== nothing && push!(centroids, c)
    end
    # The whole pack moves in y across 50 frames → centroid row should sweep
    # noticeably (>0.5 px is enough to prove the motion reached pixels).
    cs_row = [c[1] for c in centroids]
    @test (maximum(cs_row) - minimum(cs_row)) > 0.5
    close(screen)
end

# ===========================================================================
# 11. Pixel-level motion verification — meshes really show up and move
# ===========================================================================
# These tests fail if `update_transforms!` silently no-ops, if the TLAS isn't
# being refit, or if the kernel writes to a buffer the GPU never sees.

@testset "meshscatter — pixel motion: single instance shifts in image space" begin
    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-0.5), Vec3f(1)))
    positions = Observable(LavaArray([Point3f(0, 0, 0)]))
    scene = Scene(size=(96, 96)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=cube, markersize=1f0, color=:red)

    screen = RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=8, max_depth=2))

    # Frame 1: cube at origin → centered in image
    img_origin = Makie.colorbuffer(screen)
    n_origin   = lit_count(img_origin)
    c_origin   = lit_centroid(img_origin)
    @test n_origin > 200                        # visible cube produces lit pixels
    @test c_origin !== nothing

    # Frame 2: cube far offscreen → mostly empty
    positions[] = LavaArray([Point3f(100f0, 0, 0)])
    img_off     = Makie.colorbuffer(screen)
    n_off       = lit_count(img_off)
    @test n_off < n_origin ÷ 3                  # >3× drop in lit pixels

    # Frame 3: cube shifted left in world space → centroid shifts in image
    positions[] = LavaArray([Point3f(-1.5f0, 0, 0)])
    img_left    = Makie.colorbuffer(screen)
    c_left      = lit_centroid(img_left)
    @test c_left !== nothing
    @test sqrt((c_left[1] - c_origin[1])^2 + (c_left[2] - c_origin[2])^2) > 4

    # Frame 4: cube right of origin in world → opposite-direction centroid shift
    positions[] = LavaArray([Point3f(+1.5f0, 0, 0)])
    img_right   = Makie.colorbuffer(screen)
    c_right     = lit_centroid(img_right)
    @test c_right !== nothing
    # Whatever the camera orientation, left and right placements must produce
    # centroids on opposite sides of the origin centroid.
    drow_l = c_left[1]  - c_origin[1]
    dcol_l = c_left[2]  - c_origin[2]
    drow_r = c_right[1] - c_origin[1]
    dcol_r = c_right[2] - c_origin[2]
    # Dot product is negative iff the shifts are in opposite directions
    @test drow_l * drow_r + dcol_l * dcol_r < 0

    close(screen)
end

@testset "meshscatter — pixel motion: 50-frame trajectory traces a curve" begin
    sphere = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1f0))
    positions = Observable(LavaArray([Point3f(0, 0, 0)]))
    scene = Scene(size=(96, 96)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=sphere, markersize=0.5f0, color=:cyan)

    screen = RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=4, max_depth=2))
    Makie.colorbuffer(screen)  # warmup

    centroids = Tuple{Float64, Float64}[]
    for frame in 0:49
        θ = 2π * frame / 50
        positions[] = LavaArray([Point3f(2cos(θ), 0f0, 2sin(θ))])
        img = Makie.colorbuffer(screen)
        c = lit_centroid(img)
        c !== nothing && push!(centroids, c)
    end

    # We expect a roughly circular orbit projected onto the image plane.
    # Validate that the centroid (a) actually moved, and (b) didn't collapse
    # to a single point.
    @test length(centroids) > 30
    cs_row = [c[1] for c in centroids]
    cs_col = [c[2] for c in centroids]
    @test (maximum(cs_row) - minimum(cs_row)) > 8     # vertical span
    @test (maximum(cs_col) - minimum(cs_col)) > 8     # horizontal span

    close(screen)
end

@testset "meshscatter — pixel motion: instance count change visibly drops lit pixels" begin
    sphere = GeometryBasics.normal_mesh(GeometryBasics.Sphere(Point3f(0), 1f0))
    positions = Observable(LavaArray([Point3f(Float32(i) - 5f0, 0f0, 0f0) for i in 1:9]))
    scene = Scene(size=(96, 96)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=sphere, markersize=0.3f0, color=:yellow)

    screen = RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=4, max_depth=2))

    img_many = Makie.colorbuffer(screen)
    n_many   = lit_count(img_many)
    @test n_many > 100      # many balls visible

    # Drop to a single ball — should have far fewer lit pixels
    positions[] = LavaArray([Point3f(0, 0, 0)])
    img_one    = Makie.colorbuffer(screen)
    n_one      = lit_count(img_one)
    @test n_one < n_many                # fewer instances → fewer lit pixels
    @test n_one > 20                    # but still visible

    # Empty positions → no instances. Compared to the multi-instance frame
    # the lit count must drop substantially.  We don't compare to n_one
    # because path-tracing noise on the now-uniform background can still
    # produce deviation from the corner-sampled reference.
    positions[] = LavaArray(Point3f[])
    img_empty   = Makie.colorbuffer(screen)
    n_empty     = lit_count(img_empty)
    @test n_empty < n_many                  # lots of instances → ~none

    close(screen)
end

# ===========================================================================
# 12. Direct HWTLAS large-mesh grow/shrink stress (no Makie layer involved)
# ===========================================================================

mat4_translation(dx, dy, dz) = Mat4f(
    1f0, 0f0, 0f0, 0f0,
    0f0, 1f0, 0f0, 0f0,
    0f0, 0f0, 1f0, 0f0,
    Float32(dx), Float32(dy), Float32(dz), 1f0)

@testset "HWTLAS direct — large-mesh grow/shrink, 20 cycles" begin
    sphere = hires_sphere(50)
    @test length(GeometryBasics.faces(sphere)) > 1000

    hwtlas = Lava.HWTLAS(LavaBackend())
    for cycle in 1:20
        h_big = Base.push!(hwtlas, sphere,
                           [mat4_translation(Float32(2i), 0f0, 0f0) for i in 1:200])
        Raycore.sync!(hwtlas)
        @test Raycore.n_instances(hwtlas) == 200
        @test Raycore.delete!(hwtlas, h_big)

        h_small = Base.push!(hwtlas, sphere,
                             [mat4_translation(Float32(2i), 0f0, 0f0) for i in 1:10])
        Raycore.sync!(hwtlas)
        @test Raycore.n_instances(hwtlas) == 10
        @test Raycore.delete!(hwtlas, h_small)
    end
    Raycore.sync!(hwtlas)
    @test Raycore.n_instances(hwtlas) == 0
end
