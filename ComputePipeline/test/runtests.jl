using ComputePipeline
using Test

using ComputePipeline: InputFunctionWrapper, isdirty, ResolveException

@testset "ComputePipeline.jl" begin
    include("unit_tests.jl")
    include("system_tests.jl")
end
