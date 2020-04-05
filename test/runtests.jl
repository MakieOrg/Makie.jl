using MakieRecipes
using Literate, AbstractPlotting, CairoMakie
using Test

@testset "Examples" begin
    literatedir = joinpath(@__DIR__, "..", "docs", "src", "literate")
    Literate.markdown(joinpath(literatedir, "examples.jl"), literatedir)
    @test true
end
