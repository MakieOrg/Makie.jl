using AbstractPlotting
using MakieGallery
using Test
using StaticArrays, GeometryBasics
using Observables
using GeometryBasics: Pyramid
using PlotUtils
using MeshIO, FileIO, AbstractPlotting.MakieLayout

@testset "#659 Volume errors if data is not a cube" begin
    vol = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
    lims = AbstractPlotting.data_limits(vol[1])
    lo, hi = extrema(lims)
    @test all(lo .<= 1)
    @test all(hi .>= (8,8,10))
end

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
    me = layout[end + 1, :] = LMenu(scene, options=["one", "two", "three"])
    tb = layout[end + 1, :] = LTextbox(scene)
    @test true
end

include("zoom_pan.jl")

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

        scene = scatter([22.0, 28.0])
        AbstractPlotting.update_limits!(scene)
        lim = scene.data_limits[]
        @test lim.origin[1] <= 1 && lim.widths[1] >= 1 && lim.origin[1]+lim.widths[1] >= 2
        @test lim.origin[2] <= 22 && lim.widths[2] >= 6 && lim.origin[2]+lim.widths[2] >= 28
    end
end

# run software only tests...
include("no_backend_tests.jl")

# test statistical recipes
include("statistical_tests.jl")
