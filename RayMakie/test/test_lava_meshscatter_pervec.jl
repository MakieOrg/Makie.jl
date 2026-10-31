# Per-instance Vec3f markersize on the meshscatter recipe path.
# Tests via Makie API only — no internal function calls.

using Test
using Makie, RayMakie, Lava, Hikari
using Mantle: LavaArray, Mat3x4f
using GeometryBasics
using GeometryBasics: Point3f, Vec3f, Vec4f, Rect3f

robj_of(plt) = to_value(plt.attributes[:trace_renderobject])
trans_of(plt) = to_value(plt.attributes[:trace_transforms])

@testset "normalize_markersize multiple dispatch" begin
    nm = RayMakie.normalize_markersize
    @test nm(0.5f0) === 0.5f0
    @test nm(2)     === 2f0
    @test nm(Vec3f(1,2,3)) === Vec3f(1,2,3)            # scalar Vec3f as-is
    arr = [Vec3f(1, 2, 3), Vec3f(4, 5, 6)]
    @test nm(arr) === arr                              # CPU per-instance
    larr = LavaArray([Vec3f(1, 2, 3), Vec3f(4, 5, 6)])
    @test nm(larr) === larr                            # GPU per-instance
    @test_throws ErrorException nm([1f0, 2f0])         # wrong eltype
    @test_throws ErrorException nm("not a size")
end

@testset "normalize_rotation multiple dispatch" begin
    nr = RayMakie.normalize_rotation
    @test nr(Vec4f(0,0,0,1)) === Vec4f(0,0,0,1)
    @test nr(Quaternionf(0.1, 0.2, 0.3, 0.4)) === Vec4f(0.1f0, 0.2f0, 0.3f0, 0.4f0)
    v4_arr = [Vec4f(0,0,0,1), Vec4f(1,0,0,0)]
    @test nr(v4_arr) === v4_arr
    q_arr = [Quaternionf(0.1, 0.2, 0.3, 0.4)]
    converted = nr(q_arr)
    @test converted isa AbstractVector{Vec4f}
    @test converted[1] === Vec4f(0.1f0, 0.2f0, 0.3f0, 0.4f0)
    @test nr(0) isa Vec4f
end

@testset "per-vec meshscatter — Makie API + persistent screen, 200×20" begin
    n = 200
    positions = Observable(LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n]))
    scales    = Observable(LavaArray([Vec3f(Float32(i), Float32(i)*0.5f0, Float32(i)*0.25f0)
                                      for i in 1:n]))

    cube = GeometryBasics.normal_mesh(Rect3f(Vec3f(-1), Vec3f(2)))
    scene = Scene(size=(32, 32)); cam3d!(scene)
    plt = meshscatter!(scene, positions; marker=cube, markersize=scales)

    screen = RayMakie.Screen(scene; integrator=Hikari.VolPath(samples=1, max_depth=1))
    Makie.colorbuffer(screen)

    pinned_buf = trans_of(plt)
    @test robj_of(plt).n_instances == n
    @test pinned_buf isa LavaArray{Mat3x4f, 1}

    # Verify initial transforms (identity rotation, per-axis scale, position on x-axis)
    cpu = Array(trans_of(plt))
    for i in 1:n
        t = cpu[i]
        @test t[1,1] ≈ Float32(i)         atol=1f-4
        @test t[2,2] ≈ Float32(i)*0.5f0   atol=1f-4
        @test t[3,3] ≈ Float32(i)*0.25f0  atol=1f-4
        @test t[4,1] ≈ Float32(i)         atol=1f-4
    end

    # Refit many times via Observable
    for frame in 1:20
        positions[] = LavaArray([Point3f(Float32(i)+Float32(frame)*0.5f0, 0f0, 0f0)
                                 for i in 1:n])
        scales[] = LavaArray([Vec3f(Float32(frame)*0.1f0, Float32(i)*0.2f0, 0.5f0)
                              for i in 1:n])
        Makie.colorbuffer(screen)

        @test trans_of(plt) === pinned_buf

        cpu = Array(trans_of(plt))
        for i in (1, 50, 100, 150, n)
            t = cpu[i]
            @test t[1,1] ≈ Float32(frame)*0.1f0           atol=1f-4
            @test t[2,2] ≈ Float32(i)*0.2f0               atol=1f-4
            @test t[3,3] ≈ 0.5f0                           atol=1f-4
            @test t[4,1] ≈ Float32(i) + Float32(frame)*0.5f0 atol=1f-4
        end
    end
    close(screen)
end
