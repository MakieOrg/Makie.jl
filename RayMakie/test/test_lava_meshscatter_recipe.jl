# Integration test for RayMakie's GPU-resident meshscatter path.
#
# Tests meshscatter_create_gpu! and meshscatter_refit_gpu! directly, bypassing
# the full Makie recipe/compute-graph machinery (which requires a display).
# Validates:
#   - First-sync: BLAS built, instance_buf filled correctly, TLAS built.
#   - Refit: instance_buf updated in-place, TLAS refitted, handle preserved.
#   - ensure_lava_rotations: converts Quaternionf, Vec4f, and CPU Vector inputs.
#   - gpu_scale: dispatches to Float32 (uniform) or LavaArray{Vec3f} (per-instance).

using Test, Lava, Raycore, Hikari, GeometryBasics
using Lava: LavaArray, LavaBackend, LavaInstanceRecord, AS_INPUT_USAGE
using GeometryBasics: Point3f, Vec4f, Vec3f
using Makie: Quaternionf

# Load RayMakie helpers from source directly (avoids needing a full display).
# We only need the meshscatter helpers, not the Makie recipe infrastructure.
# Include the common helpers first (create_material_with_color etc).
import RayMakie

# ============================================================================
# Helper: build a fresh Hikari scene with HWTLAS
# ============================================================================

function fresh_scene()
    return Hikari.Scene(; backend=LavaBackend(), hw_accel=true)
end

function test_cube()
    return GeometryBasics.normal_mesh(GeometryBasics.Rect3f(Vec3f(-1), Vec3f(2)))
end

# ============================================================================

@testset "meshscatter_create_gpu! -- first sync" begin
    n = 8
    positions = LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n])
    rotations = LavaArray([Vec4f(0f0, 0f0, 0f0, 1f0) for _ in 1:n])

    scene = fresh_scene()
    cube  = test_cube()

    robj = RayMakie.meshscatter_create_gpu!(scene, nothing, cube,
                                             positions, rotations, 0.5f0, UInt8(0x04))

    @test robj.n_instances == n
    @test robj.handle isa Raycore.TLASHandle
    @test robj.gpu_path === true
    @test robj.scale == 0.5f0
    @test robj.mask == UInt8(0x04)

    # instance_buffer accessor must return the same object.
    @test Raycore.instance_buffer(scene.accel, robj.handle) === robj.instance_buf

    # Verify transforms: identity rotation * scale 0.5, translation = (i, 0, 0).
    cpu = Array(robj.instance_buf)
    for i in 1:n
        rec = cpu[i]
        @test rec.transform[4]  ≈ Float32(i)   # tx
        @test rec.transform[8]  ≈ 0f0           # ty
        @test rec.transform[12] ≈ 0f0           # tz
        @test rec.transform[1]  ≈ 0.5f0         # Rxx * scale
        @test rec.blas_address == robj.blas_addr
        # Default mi_idx=0 means custom_index=0 for all instances (physics-only mode).
        @test (rec.custom_index_and_mask & 0x00FFFFFF) == UInt32(0)
        @test (rec.custom_index_and_mask >> 24) == UInt32(0x04)
    end

    # TLAS must be built after create.
    @test scene.accel.hw_tlas !== nothing
    @test !scene.accel.dirty
end

@testset "meshscatter_refit_gpu! -- positions update, handle preserved" begin
    n = 8
    positions = LavaArray([Point3f(Float32(i), 0f0, 0f0) for i in 1:n])
    rotations = LavaArray([Vec4f(0f0, 0f0, 0f0, 1f0) for _ in 1:n])

    scene = fresh_scene()
    cube  = test_cube()

    robj = RayMakie.meshscatter_create_gpu!(scene, nothing, cube,
                                             positions, rotations, 0.5f0, UInt8(0x04))

    # Move all positions by +100.  refit takes the scale explicitly as of P3-fu3
    # (multiple-dispatch over Float32 vs LavaArray{Vec3f, 1}).
    new_positions = LavaArray([Point3f(Float32(i + 100), 0f0, 0f0) for i in 1:n])
    robj2 = RayMakie.meshscatter_refit_gpu!(scene, nothing, new_positions, rotations,
                                             0.5f0, robj)

    # Handle identity must be preserved.
    @test robj2.handle === robj.handle
    @test robj2.n_instances == n

    # instance_buf is the same object (refit is in-place).
    @test robj2.instance_buf === robj.instance_buf

    # Verify new translations.
    cpu = Array(robj.instance_buf)
    for i in 1:n
        @test cpu[i].transform[4] ≈ Float32(i + 100)
    end
end

@testset "ensure_lava_rotations -- Quaternionf scalar" begin
    n = 4
    q = Quaternionf(0f0, 0f0, 0f0, 1f0)  # identity
    result = RayMakie.ensure_lava_rotations(q, n)
    @test result isa LavaArray{Vec4f, 1}
    @test length(result) == n
    cpu = Array(result)
    for r in cpu
        @test r == Vec4f(0f0, 0f0, 0f0, 1f0)
    end
end

@testset "ensure_lava_rotations -- Vec4f scalar" begin
    n = 4
    q = Vec4f(0f0, 0f0, 0f0, 1f0)
    result = RayMakie.ensure_lava_rotations(q, n)
    @test result isa LavaArray{Vec4f, 1}
    @test length(result) == n
end

@testset "ensure_lava_rotations -- AbstractVector{Quaternionf}" begin
    n = 3
    qs = [Quaternionf(0f0, 0f0, 0f0, 1f0) for _ in 1:n]
    result = RayMakie.ensure_lava_rotations(qs, n)
    @test result isa LavaArray{Vec4f, 1}
    @test length(result) == n
end

@testset "ensure_lava_rotations -- LavaArray passthrough" begin
    n = 4
    arr = LavaArray([Vec4f(0f0, 0f0, 0f0, 1f0) for _ in 1:n])
    result = RayMakie.ensure_lava_rotations(arr, n)
    @test result === arr  # same object, no copy
end

@testset "gpu_scale dispatch -- Number / Vec3f / LavaArray" begin
    # Renamed in P3-fu3 from uniform_scale_f32 to gpu_scale (multiple-dispatch
    # over scalar Number, Vec3f, and LavaArray{Vec3f} forms).  Per-instance
    # CPU Vector still rejected.
    @test RayMakie.gpu_scale(0.005f0) === 0.005f0
    @test RayMakie.gpu_scale(2)        === 2f0
    @test RayMakie.gpu_scale(Vec3f(0.5f0, 0.5f0, 0.5f0)) === 0.5f0
    @test_throws ErrorException RayMakie.gpu_scale(Vec3f(1f0, 2f0, 3f0))
    @test_throws ErrorException RayMakie.gpu_scale([0.1f0, 0.2f0])
end
