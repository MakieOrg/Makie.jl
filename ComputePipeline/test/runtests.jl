using ComputePipeline
using Test

using ComputePipeline: InputFunctionWrapper, isdirty, ResolveException
using ComputePipeline.Observables

@testset "ComputePipeline.jl" begin
    include("unit_tests.jl")
    include("system_tests.jl")
end
