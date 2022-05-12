using ReferenceTests
using ReferenceTests: RNG, loadasset
using GeometryBasics
using Statistics
using ReferenceTests.CategoricalArrays: categorical, levelcode
using LinearAlgebra
using FileIO, Colors
using Makie: Record, volume
using LaTeXStrings

@testset "primitives" begin
    include("primitives.jl")
end
@testset "text.jl" begin
    include("text.jl")
end
@testset "attributes.jl" begin
    include("attributes.jl")
end
@testset "examples2d.jl" begin
    include("examples2d.jl")
end
@testset "examples3d.jl" begin
    include("examples3d.jl")
end
@testset "short_tests.jl" begin
    include("short_tests.jl")
end
