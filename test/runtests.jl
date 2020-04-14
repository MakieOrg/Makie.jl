using AbstractPlotting
using MakieGallery
using Test
using GLMakie
using StaticArrays, GeometryBasics

@testset "Minimal AbstractPlotting tests" begin

    include("conversions.jl")
    include("quaternions.jl")
    include("projection_math.jl")
    include("shorthands.jl")

    @testset "basic functionality" begin
        scene = scatter(rand(4))
        @test scene[Axis].ticks.title_gap[] == 3
        scene[Axis].ticks.title_gap = 4
        @test scene[Axis].ticks.title_gap[] == 4
        @test scene[Axis].tickmarks.length[] == (1, 1)
    end
end

if GLMakie.WORKING_OPENGL
    # full MakieGallery comparisons here
    include("glmakie_tests.jl")
else
    # run software only tests...
    include("no_backend_tests.jl")
end
