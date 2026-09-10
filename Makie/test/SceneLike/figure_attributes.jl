module FigureAttributeTestRecipes
    using Makie
    using Makie: make_block_docstring

    @recipe(FigureThemePlot, values) do scene
        Attributes(
            color = Makie.inherit(scene, :figure_old_plot_color, :red),
            theme_color = theme(scene, :figure_old_plot_theme_color; default = :red),
        )
    end

    @recipe FigureInheritedPlot (values,) begin
        color = @inherit figure_plot_color :red
    end

    abstract type NestedFigureBlock <: Makie.Block end

    Makie.@Block FigureThemeBlock <: NestedFigureBlock begin
        @attributes begin
            color = @inherit(:figure_block_color, :red)
            legacy_color = Makie.inherit(scene, :figure_old_block_color, :red)
            nested_color = Makie.inherit(scene, (:FigureNestedTheme, :color), :red)
            theme_color = theme(scene, :figure_direct_theme_color)
            keyword_theme_color = theme(scene, :figure_block_theme_color; default = :red)
        end
    end

    module CustomFigureBackend
        import Makie
        abstract type AbstractScreen <: Makie.MakieScreen end
        struct Screen <: AbstractScreen end
    end
end

@testset "Figure keyword validation" begin
    for kwargs in ((noproblem = false,), (backgrouncolor = :red,), (title = "invalid",))
        @test_throws Makie.InvalidAttributeError Figure(; kwargs...)
    end
    @test_throws Makie.InvalidAttributeError scatter(1:3; figure = (noproblem = false,))

    error = try
        Figure(backgrouncolor = :red)
    catch e
        e
    end
    @test error isa Makie.InvalidAttributeError
    @test occursin("backgroundcolor", sprint(showerror, error; context = :color => false))

    f = Figure(size = (120, 100), backgroundcolor = :white, figure_padding = 0, visible = Observable(false))
    @test f isa Figure
    @test f.scene.visible[] == false

    f = Figure(
        FigureThemePlot = (color = :blue,),
        FigureInheritedPlot = (color = :green,),
        FigureThemeBlock = (color = :orange,),
        figure_plot_color = :purple,
        figure_block_color = :yellow,
        figure_old_plot_color = :pink,
        figure_old_block_color = :brown,
        FigureNestedTheme = (color = :cyan,),
        figure_direct_theme_color = :orange,
        CustomFigureBackend = (antialias = true,),
        Axis = (xgridvisible = false,),
    )
    @test f.scene.theme[:FigureThemePlot][:color][] === :blue
    @test f.scene.theme[:figure_plot_color][] === :purple
    @test f.scene.theme[:figure_block_color][] === :yellow
    @test f.scene.theme[:CustomFigureBackend][:antialias][] === true
    @test Makie.default_attribute_values(FigureAttributeTestRecipes.FigureThemeBlock, f.scene)[:color] === :yellow
    @test Makie.to_value(Makie.default_attribute_values(FigureAttributeTestRecipes.FigureThemeBlock, f.scene)[:legacy_color]) === :brown
    @test Makie.to_value(Makie.default_attribute_values(FigureAttributeTestRecipes.FigureThemeBlock, f.scene)[:nested_color]) === :cyan
    @test Makie.to_value(Makie.default_attribute_values(FigureAttributeTestRecipes.FigureThemeBlock, f.scene)[:theme_color]) === :orange
    @test Makie.default_theme(f.scene, FigureAttributeTestRecipes.FigureThemePlot)[:color][] === :pink
    @test Makie.lookup_default(FigureAttributeTestRecipes.FigureInheritedPlot, f.scene, :color) === :green
    inherited = Figure(figure_plot_color = :purple)
    @test Makie.lookup_default(FigureAttributeTestRecipes.FigureInheritedPlot, inherited.scene, :color) === :purple
    @test Axis(f[1, 1]).xgridvisible[] === false

    f = Figure(figure_old_plot_theme_color = :blue, figure_block_theme_color = :green)
    @test Makie.default_theme(f.scene, FigureAttributeTestRecipes.FigureThemePlot)[:theme_color][] === :blue
    @test Makie.to_value(Makie.default_attribute_values(FigureAttributeTestRecipes.FigureThemeBlock, f.scene)[:keyword_theme_color]) === :green

    with_theme(; custom_figure_setting = :red) do
        f = Figure(custom_figure_setting = :blue)
        @test f.scene.theme[:custom_figure_setting][] === :blue
    end
    @test_throws Makie.InvalidAttributeError Figure(custom_figure_setting = :blue)
    f = Figure(theme = Attributes(custom_figure_setting = :red), custom_figure_setting = :blue)
    @test f.scene.theme[:custom_figure_setting][] === :blue

    # Validation must not silently accept unrelated attributes of child blocks.
    @test_throws Makie.InvalidAttributeError Figure(xlabel = "not a figure keyword")
    @test_throws Makie.InvalidAttributeError Figure(UnknownFigureBackend = (antialias = true,))
    @test Figure(CairoMakie = (antialias = :best,)) isa Figure

    f = Figure()
    ax = Axis(f[1, 1])
    p = scatter!(ax, 1:3; label = "points")
    @test_throws Makie.InvalidAttributeError Legend(f[2, 1], ax; thisshoulderror = true)
    @test_throws Makie.InvalidAttributeError Legend(f[2, 1], [[p]], [["points"]], ["group"]; thisshoulderror = true)
    @test Legend(f[2, 1], [[p]], [["points"]], ["group"]; titleposition = :left) isa Legend
    @test_throws Makie.InvalidAttributeError Axis(f[3, 1]; thisshoulderror = true)
end
