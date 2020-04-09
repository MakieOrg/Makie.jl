using MakieRecipes
using Literate, AbstractPlotting, CairoMakie
using Test

@testset "Examples" begin
    literatedir = joinpath(@__DIR__, "..", "docs", "src", "literate")
    @test_nowarn include(joinpath(literatedir, "examples.jl")) # execute the source file directly
end
