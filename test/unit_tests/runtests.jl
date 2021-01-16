@testset "Unit tests" begin
    @testset "#659 Volume errors if data is not a cube" begin
        fig, ax, vplot = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
        lims = AbstractPlotting.data_limits(vplot)
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
end
