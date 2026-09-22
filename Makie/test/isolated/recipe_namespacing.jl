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

    @testset "theming" begin
        @test Makie.qualified_name(A) === Symbol("Main.RecipeNamespaceA.SamePlot")
        @test Makie.qualified_name(Scatter) === Symbol("Makie.Scatter")
        @test Makie.qualified_name(Axis) === Symbol("Makie.Axis")

        unique_name = Scene(theme = Theme(Scatter = (markersize = 33,)))
        @test to_value(Makie.lookup_default(Scatter, unique_name, :markersize)) == 33

        bare = Scene(theme = Theme(SamePlot = (color = :green,)))
        @test_throws "Theme entry `SamePlot` is ambiguous" RecipeNamespaceA.sameplot!(bare, 1:3)
        @test_throws "Main.RecipeNamespaceA.SamePlot" RecipeNamespaceA.sameplot!(bare, 1:3)

        qualified = Scene(theme = Theme(A => (color = :green,)))
        @test RecipeNamespaceA.sameplot!(qualified, 1:3; cycle = []).color[] === :green
        @test RecipeNamespaceB.sameplot!(qualified, 1:3; cycle = []).color[] === :blue
        @test Makie.default_theme(qualified, A).color[] === :green
        @test Makie.default_theme(qualified, B).color[] === :blue
        @test to_value(Makie.lookup_default(A, qualified, :color)) === :green

        theme = Theme()
        theme[B] = (color = :black,)
        @test haskey(theme, B)
        @test !haskey(theme, A)
        @test theme[B].color[] === :black
        @test collect(keys(theme)) == [Symbol("Main.RecipeNamespaceB.SamePlot")]
    end

    @testset "cycle counters are per plot type" begin
        scene = Scene()
        a1 = RecipeNamespaceA.sameplot!(scene, 1:3)
        a2 = RecipeNamespaceA.sameplot!(scene, 1:3)
        b1 = RecipeNamespaceB.sameplot!(scene, 1:3)
        @test (a1.cycle_index[], a2.cycle_index[], b1.cycle_index[]) == (1, 2, 1)
    end
end
