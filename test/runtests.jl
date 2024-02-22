using Test
using Makie
using Makie.Observables
using Makie.GeometryBasics
using Makie.PlotUtils
using Makie.FileIO
using Makie.IntervalSets
using LinearAlgebra

@testset "Unit tests" begin
    include("barplot.jl")
    include("bezier.jl")
    include("boundingboxes.jl")
    include("conversions.jl")
    include("deprecated.jl")
    include("events.jl")
    include("figures.jl")
    include("hist.jl")
    include("issues.jl")
    include("liftmacro.jl")
    include("makielayout.jl")
    include("pipeline.jl")
    include("polaraxis.jl")
    include("primitives.jl")
    include("projection_math.jl")
    include("quaternions.jl")
    include("ray_casting.jl")
    include("record.jl")
    include("scenes.jl")
    include("specapi.jl")
    # include("statistical_tests.jl")  # FIXME: untested and broken ?
    include("text.jl")
    include("transformations.jl")
    # include("zoom_pan.jl")  # FIXME: untested and broken ?
end
