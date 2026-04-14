using ComputePipeline
using Test
using Random

using ComputePipeline: isdirty, ResolveException, map_latest!
using ComputePipeline.Observables

# Use failfast to prevent deadlocks from keeping these tests running
@testset "ComputePipeline.jl" failfast = true begin
    # Sanity check for CI
    @test ComputePipeline.ENABLE_COMPUTE_CHECKS

    @testset "Concurrency tests"  begin
        include("concurrency.jl")
    end

    @testset "general" failfast = false begin
        include("unit_tests.jl")
        include("system_tests.jl")
    end
end
