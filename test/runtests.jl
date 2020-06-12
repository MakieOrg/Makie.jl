using AbstractPlotting
using MakieGallery
using Test
using GLMakie
using StaticArrays, GeometryBasics
using Observables
using GeometryBasics: Pyramid
using PlotUtils
using MeshIO, FileIO, AbstractPlotting.MakieLayout

# Minimal sanity checks for MakieLayout
@testset "Layoutables constructors" begin
    scene, layout = layoutscene()
    ax = layout[1, 1] = LAxis(scene)
    cb = layout[1, 2] = LColorbar(scene)
    gl2 = layout[2, :] = MakieLayout.GridLayout()
    bu = gl2[1, 1] = LButton(scene)
    sl = gl2[1, 2] = LSlider(scene)

    scat = scatter!(ax, rand(10))
    le = gl2[1, 3] = LLegend(scene, [scat], ["scatter"])

    to = gl2[1, 4] = LToggle(scene)
    te = layout[0, :] = LText(scene, "A super title")
    me = layout[end+1, :] = LMenu(scene, options = ["one", "two", "three"])
    @test true
end

@testset "Minimal AbstractPlotting tests" begin

    include("conversions.jl")
    include("quaternions.jl")
    include("projection_math.jl")
    include("shorthands.jl")
    include("liftmacro.jl")

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
