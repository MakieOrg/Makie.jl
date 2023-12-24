using Test
using Makie
using Makie.Observables
using Makie.GeometryBasics
using Makie.PlotUtils
using Makie.FileIO
using Makie.IntervalSets
using GeometryBasics: Pyramid

using Makie: volume

@testset "Unit tests" begin
    @testset "Volume errors if data is not a cube (#659)" begin
        fig, ax, vplot = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
        lims = Makie.data_limits(vplot)
        lo, hi = extrema(lims)
        @test all(lo .<= 1)
        @test all(hi .>= (8,8,10))
    end

    include("deprecated.jl")
    include("specapi.jl")
    include("primitives.jl")
    include("pipeline.jl")
    include("record.jl")
    include("scenes.jl")
    include("conversions.jl")
    include("quaternions.jl")
    include("projection_math.jl")
    include("liftmacro.jl")
    include("makielayout.jl")
    include("figures.jl")
    include("transformations.jl")
    include("events.jl")
    include("text.jl")
    include("boundingboxes.jl")
    # include("statistical_tests.jl")  # FIXME: untested ?
    include("ray_casting.jl")
    include("PolarAxis.jl")
    include("barplot.jl")
    include("bezier.jl")
    include("hist.jl")

    @tetset "Hexbin singleton (#3357)" begin
        # degenerate case with singleton 0
        hexbin([0, 0], [1, 2])
        hexbin([1, 2], [0, 0])

        # degenerate case with singleton 1
        hexbin([1, 1], [1, 2])
        hexbin([1, 2], [1, 1])
    end
end
