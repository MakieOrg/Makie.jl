# COV_EXCL_START
using Test
using LinearAlgebra

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

    # Tests that don't or barely rely on other components. I.e. they don't create
    # scenes, plots etc or only use them to get auxiliary data, e.g. a projection matrix
    @testset "Isolated Tests" begin
        include("isolated/bezier.jl")
        include("isolated/quaternions.jl")
        include("isolated/observables.jl")
        include("isolated/timing.jl")
        include("isolated/Plane.jl")
    end

    @testset "Plots" begin
        include("plots/primitives.jl")
        include("plots/text.jl")
        include("plots/barplot.jl")
        include("plots/hist.jl")
        include("plots/poly.jl")
        include("plots/voronoiplot.jl")
    end

    @testset "Scenes, Blocks & Figures" begin
        include("SceneLike/scenes.jl")
        include("SceneLike/figures.jl")
        include("SceneLike/makielayout.jl")
        include("SceneLike/PolarAxis.jl")
        # include("SceneLike/zoom_pan.jl") # TODO: fix
    end

    @testset "Conversion & Projection Pipeline" begin
        # TODO: move some things in here
        include("convert_arguments.jl")
        # from here
        include("conversions.jl")
        include("convert_attributes.jl")

        include("dim-converts.jl")
        include("transformations.jl")
        include("float32convert.jl")
        include("cameras.jl")
        include("projection_math.jl")
    end

    include("boundingboxes.jl")
    include("updating.jl")
    include("deprecated.jl")
    include("specapi.jl")
    include("pipeline.jl")
    include("record.jl")
    include("events.jl")
    include("ray_casting.jl")

    # for short tests of resolved issues
    include("issues.jl")
end
