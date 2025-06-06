ENV["ENABLE_COMPUTE_CHECKS"] = "true"
using ComputePipeline
using Test
using Random

using ComputePipeline: InputFunctionWrapper, isdirty, ResolveException
using ComputePipeline.Observables

@testset "ComputePipeline.jl" begin
    include("unit_tests.jl")
    include("system_tests.jl")
end
