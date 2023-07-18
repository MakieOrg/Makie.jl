using ReferenceTests
using ReferenceTests: RNG, loadasset, @reference_test
using ReferenceTests.GeometryBasics
using ReferenceTests.Statistics
using ReferenceTests.CategoricalArrays: categorical, levelcode
using ReferenceTests.LinearAlgebra
using ReferenceTests.FileIO
using ReferenceTests.Colors
using ReferenceTests.LaTeXStrings
using ReferenceTests.DelimitedFiles
using ReferenceTests.Test
using ReferenceTests.Colors: RGB, N0f8
using ReferenceTests.DelaunayTriangulation
using Makie: Record, volume

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
@testset "figures_and_makielayout.jl" begin
    include("figures_and_makielayout.jl")
end
@testset "updating_plots" begin
    include("updating.jl")
end
