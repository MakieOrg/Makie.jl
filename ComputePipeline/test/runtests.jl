using ComputePipeline
using Test
using Random

using ComputePipeline: InputFunctionWrapper, isdirty, ResolveException, map_latest!
using ComputePipeline.Observables

@testset "ComputePipeline.jl" begin
    # Sanity check for CI
    @test ComputePipeline.ENABLE_COMPUTE_CHECKS

    # Use failfast to prevent deadlocks from keeping these tests running
    ts = @testset "Concurrency tests" failfast = true begin
        include("concurrency.jl")
    end

    # And skip remaining tests if we fine any errors (possible deadlocks)
    tc = Test.get_test_counts(ts)
    if tc.errors == 0
        include("unit_tests.jl")
        include("system_tests.jl")
    else
        error("Skipped further tests due to errors in concurrency tests.")
    end
end
