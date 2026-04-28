using Test
using Lava
using Lava: LavaArray, LavaInstanceRecord
using GeometryBasics
using GeometryBasics: Point3f, Vec3f, Vec4f, Rect3f
import RayMakie
import Hikari

# P3-fu3: per-instance Vec3f markersize on the GPU meshscatter recipe path.

@testset "gpu_scale dispatch" begin
    @test RayMakie.gpu_scale(0.5f0) === 0.5f0
    @test RayMakie.gpu_scale(2) === 2f0
    @test RayMakie.gpu_scale(Vec3f(0.3, 0.3, 0.3)) === 0.3f0
    @test_throws ErrorException RayMakie.gpu_scale(Vec3f(1, 2, 3))   # non-uniform
    arr = LavaArray([Vec3f(1, 2, 3), Vec3f(4, 5, 6)])
    @test RayMakie.gpu_scale(arr) === arr
    arr_bad = LavaArray([Vec4f(1, 2, 3, 4)])
    @test_throws ErrorException RayMakie.gpu_scale(arr_bad)
    @test_throws ErrorException RayMakie.gpu_scale([Vec3f(1, 1, 1), Vec3f(2, 2, 2)])
end

@testset "per-vec meshscatter_create_gpu! + refit" begin
    n = 4
    positions = LavaArray([Point3f(Float32(i), 0, 0) for i in 1:n])
    rotations = LavaArray([Vec4f(0, 0, 0, 1) for _ in 1:n])
    scales    = LavaArray([Vec3f(Float32(i), Float32(i) * 0.5, Float32(i) * 0.25) for i in 1:n])

    backend = Lava.LavaBackend()
    hikari_scene = Hikari.Scene(; backend=backend, hw_accel=true)
    cube = GeometryBasics.normal_mesh(GeometryBasics.Rect3f(Vec3f(-1), Vec3f(2)))

    robj = RayMakie.meshscatter_create_gpu!(hikari_scene, nothing, cube,
                                             positions, rotations, scales, UInt8(0x04))
    @test robj.gpu_path == true
    @test robj.n_instances == n
    @test robj.scale === scales

    cpu = Array(robj.instance_buf)
    for i in 1:n
        rec = cpu[i]
        sx = Float32(i)
        sy = Float32(i) * 0.5f0
        sz = Float32(i) * 0.25f0
        @test rec.transform == (sx,  0f0, 0f0, Float32(i),
                                 0f0, sy,  0f0, 0f0,
                                 0f0, 0f0, sz,  0f0)
    end

    # Refit with new per-instance scales.
    Lava.copyto!(scales, [Vec3f(10f0, 20f0, 30f0) for _ in 1:n])
    RayMakie.meshscatter_refit_gpu!(hikari_scene, nothing, positions, rotations, scales, robj)

    cpu2 = Array(robj.instance_buf)
    for i in 1:n
        rec = cpu2[i]
        @test rec.transform == (10f0, 0f0,  0f0,  Float32(i),
                                 0f0,  20f0, 0f0,  0f0,
                                 0f0,  0f0,  30f0, 0f0)
    end
end
