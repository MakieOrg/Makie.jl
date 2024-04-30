# COV_EXCL_START
using Test
using Makie
using Makie.Observables
using Makie.GeometryBasics
using Makie.PlotUtils
using Makie.FileIO
using Makie.IntervalSets
using GeometryBasics: Pyramid

using Makie: volume
# COV_EXCL_STOP

@testset "Unit tests" begin
    @testset "#659 Volume errors if data is not a cube" begin
        fig, ax, vplot = volume(1..8, 1..8, 1..10, rand(8, 8, 10))
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
    include("quaternions.jl")
    include("projection_math.jl")
    include("observables.jl")
    include("makielayout.jl")
    include("figures.jl")
    include("transformations.jl")
    include("events.jl")
    include("text.jl")
    include("boundingboxes.jl")
    include("ray_casting.jl")
    include("PolarAxis.jl")
    include("barplot.jl")
    include("bezier.jl")
    include("hist.jl")

    # TODO: move some things in here
    include("convert_arguments.jl")
    # from here
    include("conversions.jl")

    include("float32convert.jl")
    include("dim-converts.jl")
end
