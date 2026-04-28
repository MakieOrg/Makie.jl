using Test
using Lava: LavaArray
using GeometryBasics: Point3f, Point2f, Point
import Makie
import GPUArraysCore

# Load lava_arrays.jl overloads directly (avoids needing a full RayMakie graphical context)
include(joinpath(@__DIR__, "..", "src", "lava_arrays.jl"))

# Helper: run body with scalar indexing strictly disallowed.
# Errors if any scalar GPU indexing occurs.
function with_scalar_disallowed(f)
    task_local_storage(f, :ScalarIndexing, GPUArraysCore.ScalarDisallowed)
end

@testset "LavaArray Makie conversion overloads" begin
    positions = LavaArray([Point3f(0, 0, 0), Point3f(1, 2, 3), Point3f(-2, -1, -3)])

    # convert_single_argument is identity (no scalar iteration)
    out = Makie.convert_single_argument(positions)
    @test out === positions

    # convert_arguments(::PointBased, ...) returns a 1-tuple wrapping the same array
    out = Makie.convert_arguments(Makie.PointBased(), positions)
    @test length(out) == 1
    @test out[1] === positions

    # float_convert / el32convert are identity for canonical Point3f
    @test Makie.float_convert(positions) === positions
    @test Makie.el32convert(positions) === positions

    # All of the above must not trigger scalar iteration
    with_scalar_disallowed() do
        @test Makie.convert_single_argument(positions) === positions
        @test Makie.convert_arguments(Makie.PointBased(), positions)[1] === positions
        @test Makie.float_convert(positions) === positions
        @test Makie.el32convert(positions) === positions
    end
end

@testset "LavaArray non-canonical eltype errors loudly" begin
    # convert_single_argument must error for non-Float32 Point types.
    # We verify by constructing a LavaArray{Point3d} (if the constructor accepts it)
    # or by calling the overload with a manually constructed type.
    #
    # The method signature is LavaArray{<:Point{N,T},1} where T !== Float32.
    # LavaArray{Point{3,Float64}} is isbits and valid.
    positions_f64 = LavaArray([Point{3,Float64}(0.0, 0.0, 0.0)])
    @test_throws ErrorException Makie.convert_single_argument(positions_f64)
end

@testset "extrema_nan over LavaArray returns correct bounds" begin
    positions = LavaArray([Point3f(0, 0, 0), Point3f(1, 2, 3), Point3f(-2, -1, -3)])
    lo, hi = Makie.extrema_nan(positions)
    @test lo == Point3f(-2, -1, -3)
    @test hi == Point3f(1, 2, 3)
end

@testset "extrema_nan handles NaN points" begin
    positions = LavaArray([Point3f(0, 0, 0), Point3f(NaN, NaN, NaN), Point3f(2, 3, 4)])
    lo, hi = Makie.extrema_nan(positions)
    @test lo == Point3f(0, 0, 0)
    @test hi == Point3f(2, 3, 4)
end

@testset "extrema_nan handles empty array" begin
    positions = LavaArray(Point3f[])
    lo, hi = Makie.extrema_nan(positions)
    @test all(isnan, lo)
    @test all(isnan, hi)
end

@testset "extrema_nan 2D points" begin
    positions = LavaArray([Point2f(1, 2), Point2f(-1, 3)])
    lo, hi = Makie.extrema_nan(positions)
    @test lo == Point2f(-1, 2)
    @test hi == Point2f(1, 3)
end

@testset "extrema_nan does not scalar iterate" begin
    positions = LavaArray([Point3f(0, 0, 0), Point3f(1, 2, 3), Point3f(-2, -1, -3)])
    with_scalar_disallowed() do
        lo, hi = Makie.extrema_nan(positions)
        @test lo == Point3f(-2, -1, -3)
        @test hi == Point3f(1, 2, 3)
    end
end

@testset "iterate_transformed no clip planes does not scalar iterate" begin
    # Build a minimal scene + plot so we have a plot object with clip_planes
    scene = Makie.Scene()
    cpu_positions = [Point3f(0, 0, 0), Point3f(1, 2, 3)]
    p = Makie.scatter!(scene, cpu_positions)

    positions = LavaArray([Point3f(0, 0, 0), Point3f(1, 2, 3)])

    # With no clip planes (default), iterate_transformed must not scalar iterate
    with_scalar_disallowed() do
        result = Makie.iterate_transformed(p, positions)
        # Result is a GPU array (transform was applied via broadcast)
        @test result isa LavaArray || result isa AbstractArray
        @test length(result) == 2
    end
end
