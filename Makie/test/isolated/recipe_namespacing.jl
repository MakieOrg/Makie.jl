module RecipeNamespaceA
    using Makie
    @recipe SamePlot (x,) begin
        color = :red
        cycle = [:color]
    end
    function Makie.plot!(p::SamePlot)
        scatter!(p, p.x; color = p.color)
        return p
    end
end

module RecipeNamespaceB
    using Makie
    @recipe SamePlot (x,) begin
        color = :blue
        cycle = [:color]
    end
    function Makie.plot!(p::SamePlot)
        lines!(p, p.x; color = p.color)
        return p
    end
end

@testset "Recipes with the same name in different modules" begin
    A = RecipeNamespaceA.SamePlot
    B = RecipeNamespaceB.SamePlot
    @test A !== B
    @test Makie.plotsym(A) === :SamePlot
    @test Makie.plotsym(B) === :SamePlot

    @testset "symbol lookup" begin
        @test Makie.symbol_to_plot(:Scatter) === Scatter
        @test Makie.symbol_to_plot(:NotARecipe) === nothing
        @test_throws "SamePlot is ambiguous" Makie.symbol_to_plot(:SamePlot)
        @test_throws "RecipeNamespaceA.SamePlot" Makie.symbol_to_plot(:SamePlot)
        @test_throws "RecipeNamespaceB.SamePlot" Makie.symbol_to_plot(:SamePlot)
        @test_throws "SamePlot is ambiguous" Makie.SpecApi.SamePlot(1:3)
    end

    @testset "PlotSpec keeps the type" begin
        spec_a = Makie.PlotSpec(A, 1:3)
        spec_b = Makie.PlotSpec(B, 1:3)
        @test Makie.plottype(spec_a) === A
        @test Makie.plottype(spec_b) === B
        @test Makie.plottype(Makie.PlotSpec(:Scatter, 1:3)) === Scatter
        @test sprint(show, spec_a) == "S.SamePlot(::UnitRange{Int64}; )"

        scene = Scene()
        plots = plotlist!(scene, [spec_a, spec_b])
        @test typeof(plots.plots[1]) <: A
        @test typeof(plots.plots[2]) <: B
    end
end
