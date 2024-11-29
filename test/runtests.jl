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
    include("updating.jl")
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
    include("poly.jl")
    include("cameras.jl")
    include("voronoiplot.jl")

    # for short tests of resolved issues
    include("issues.jl")

    # TODO: move some things in here
    include("convert_arguments.jl")
    # from here
    include("conversions.jl")
    include("convert_attributes.jl")

    include("float32convert.jl")
    include("dim-converts.jl")
    include("Plane.jl")
end
