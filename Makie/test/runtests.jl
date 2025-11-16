# COV_EXCL_START
ENV["ENABLE_COMPUTE_CHECKS"] = "true"
using Test
using LinearAlgebra

using Makie
using Makie.Observables
using Makie.GeometryBasics
using Makie.PlotUtils
using Makie.FileIO
using Makie.IntervalSets
using GeometryBasics: Pyramid
using Makie.ComputePipeline: ResolveException
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
        include("isolated/texture_atlas.jl")
        include("isolated/datetime_ticks.jl")
    end

    @testset "Plots" begin
        include("plots/primitives.jl")
        include("plots/generic_attributes.jl")
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
    end

    @testset "Conversion & Projection Pipeline" begin
        # TODO: move some things in here
        include("conversions/convert_arguments.jl")
        # from here
        include("conversions/conversions.jl")
        include("conversions/convert_attributes.jl")

        include("conversions/dim-converts.jl")
        include("conversions/transformations.jl")
        include("conversions/float32convert.jl")
        include("conversions/cameras.jl")
        include("conversions/projection_math.jl")

        include("conversions/recipe_projections.jl")
    end

    @testset "Interactivity" begin
        include("interactivity/events.jl")
        include("interactivity/MouseStateMachine.jl")
        include("interactivity/camera_controls.jl")
        include("interactivity/Axis.jl")
        include("interactivity/Axis3.jl")
        include("interactivity/DataInspector.jl")
    end

    include("boundingboxes.jl")
    include("updating.jl")
    include("deprecated.jl")
    include("specapi.jl")
    include("pipeline.jl")
    include("record.jl")
    include("ray_casting.jl")

    # for short tests of resolved issues
    include("issues.jl")
end
