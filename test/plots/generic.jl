@testset "plot!() to scene" begin
    scene = Scene()
    for PlotType in ALL_PLOT_TYPES
        @testset "$PlotType" begin
            testplot!(scene, PlotType)
            @test true
        end
    end
end