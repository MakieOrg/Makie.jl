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
    @testset "#659 Volume errors if data is not a cube" begin
        fig, ax, vplot = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
        lims = Makie.data_limits(vplot)
        lo, hi = extrema(lims)
        @test all(lo .<= 1)
        @test all(hi .>= (8,8,10))
    end

    include("conversions.jl")
    include("quaternions.jl")
    include("projection_math.jl")
    include("liftmacro.jl")
    include("makielayout.jl")
    include("figures.jl")
    include("transformations.jl")
    include("stack.jl")
    include("events.jl")
    include("text.jl")
    include("boundingboxes.jl")
    include("record.jl")
end
