using ComputePipeline
using Test
using Random

using ComputePipeline: InputFunctionWrapper, isdirty, ResolveException
using ComputePipeline.Observables

@testset "ComputePipeline.jl" begin
    # Sanity check for CI
    @test ComputePipeline.ENABLE_COMPUTE_CHECKS

    include("unit_tests.jl")
    include("system_tests.jl")
end
