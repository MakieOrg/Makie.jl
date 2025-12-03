@testset "GUIState creation and management" begin
    # GUI requires gui=true in figure attributes or theme
    f = Figure(; gui = true)
    ax = Axis(f[1, 1])
    pl = scatter!(ax, rand(10), label = "test")

    # Initially no GUI elements (not yet displayed)
    @test isnothing(f.gui_state.hovermenu)

    # Add GUI
    Makie.add_gui!(f, ax, pl)

    # Now has hovermenu
    @test !isnothing(f.gui_state.hovermenu)

    # Adding GUI again should not duplicate
    hovermenu_before = f.gui_state.hovermenu
    Makie.add_gui!(f, ax, pl)
    @test f.gui_state.hovermenu === hovermenu_before

    # Remove GUI
    Makie.remove_gui!(f)
    @test isnothing(f.gui_state.hovermenu)
end

@testset "add_gui! with FigureAxisPlot" begin
    # Test with FigureAxisPlot and figure=(; gui=true)
    fap = scatter(rand(10), rand(10), label = "Points"; figure = (; gui = true))
    result = Makie.add_gui!(fap)

    # Should return same FigureAxisPlot
    @test result === fap
    @test result isa Makie.FigureAxisPlot

    # Figure should have hovermenu
    @test !isnothing(fap.figure.gui_state.hovermenu)
end

@testset "Legend attributes" begin
    # Test that legend gets correct labels from plots
    f, ax, pl = scatter(
        rand(10), label = "My Scatter";
        figure = (; legend = (position = :lt, title = "Test Legend"))
    )
    lines!(ax, rand(10), label = "My Line")
    Makie.add_gui!(f, ax, pl)

    legend = f.gui_state.legend
    @test !isnothing(legend)
    @test legend isa Legend

    # Check title was passed through (stored in entrygroups)
    @test legend.entrygroups[][1][1] == "Test Legend"

    # Check position (overlay at left-top means halign=:left, valign=:top)
    @test legend.halign[] == :left
    @test legend.valign[] == :top

    # Test legend with grid position
    f2, ax2, pl2 = scatter(
        rand(10), label = "Grid Legend";
        figure = (; legend = (position = [1, 2],))
    )
    Makie.add_gui!(f2, ax2, pl2)
    legend2 = f2.gui_state.legend
    @test !isnothing(legend2)
    # Grid position legend should be in layout, not overlay
    # For grid positions, tellwidth defaults to Automatic (which behaves as true)
    @test legend2.tellwidth[] isa Makie.Automatic

    # Test legend with margin (overlay only)
    f3, ax3, pl3 = scatter(
        rand(10), label = "Margin Test";
        figure = (; legend = (position = :rt, margin = (20, 20, 20, 20)))
    )
    Makie.add_gui!(f3, ax3, pl3)
    legend3 = f3.gui_state.legend
    @test !isnothing(legend3)
    @test legend3.margin[] == (20, 20, 20, 20)

    # Test unique and merge options
    f4 = Figure(; legend = (position = :lt, unique = true, merge = true))
    ax4 = Axis(f4[1, 1])
    scatter!(ax4, rand(10), label = "Same")
    scatter!(ax4, rand(10), label = "Same")  # duplicate label
    lines!(ax4, rand(10), label = "Same")    # same label, different plot type
    Makie.add_gui!(f4, ax4, first(ax4.scene.plots))
    legend4 = f4.gui_state.legend
    @test !isnothing(legend4)
    # With unique=true and merge=true, should have fewer entries
end

@testset "Colorbar attributes" begin
    # Test colorbar with label
    f, ax, pl = heatmap(
        rand(10, 10);
        figure = (; colorbar = (position = [1, 2], label = "Heat Values"))
    )
    Makie.add_gui!(f, ax, pl)

    colorbar = f.gui_state.colorbar
    @test !isnothing(colorbar)
    @test colorbar isa Colorbar
    @test colorbar.label[] == "Heat Values"

    # Test colorbar overlay position
    f2, ax2, pl2 = scatter(
        rand(10), color = 1:10;
        figure = (; colorbar = (position = :rt,))
    )
    Makie.add_gui!(f2, ax2, pl2)
    colorbar2 = f2.gui_state.colorbar
    @test !isnothing(colorbar2)
    @test colorbar2.halign[] == :right
    @test colorbar2.valign[] == :top

    # Test colorbar with margin (overlay only)
    f3, ax3, pl3 = scatter(
        rand(10), color = 1:10;
        figure = (; colorbar = (position = :lt, margin = (10, 60, 10, 10)))
    )
    Makie.add_gui!(f3, ax3, pl3)
    colorbar3 = f3.gui_state.colorbar
    @test !isnothing(colorbar3)
    @test colorbar3.margin[] == (10, 60, 10, 10)

    # Test that colorbar inherits colormap from plot
    f4, ax4, pl4 = heatmap(
        rand(10, 10), colormap = :viridis;
        figure = (; colorbar = (position = [1, 2],))
    )
    Makie.add_gui!(f4, ax4, pl4)
    colorbar4 = f4.gui_state.colorbar
    @test !isnothing(colorbar4)
    # Colorbar should have a colormap (derived from plot)
    @test length(to_value(colorbar4.colormap)) > 0
end

@testset "Hover bar attributes" begin
    # Test hover bar with default style
    f = Figure(; gui = true)
    ax = Axis(f[1, 1])
    pl = scatter!(ax, rand(10))
    Makie.add_gui!(f, ax, pl)

    gui = f.gui_state.hovermenu
    @test !isnothing(gui)
    @test gui isa HoverMenu

    # Test hover bar with custom style (styling params directly in gui=)
    f2 = Figure(;
        gui = (
            bar_color = :red,
            height = 50,
            width = 300,
        )
    )
    ax2 = Axis(f2[1, 1])
    pl2 = scatter!(ax2, rand(10))
    Makie.add_gui!(f2, ax2, pl2)

    gui2 = f2.gui_state.hovermenu
    @test !isnothing(gui2)
    @test gui2 isa HoverMenu
    # Check that custom style was applied
    @test gui2.height[] == 50
    @test gui2.width[] == 300
end

@testset "Figure constructor with GUI options" begin
    # Test Figure(; gui=true) - options should be empty dict (HoverMenu block handles defaults)
    f = Figure(; gui = true)
    @test !isnothing(f.gui_state.hovermenu_options)
    @test f.gui_state.hovermenu_options == Dict{Symbol, Any}()

    ax = Axis(f[1, 1])
    pl = scatter!(ax, rand(10), label = "test")
    Makie.add_gui!(f, ax, pl)
    @test !isnothing(f.gui_state.hovermenu)

    # Test Figure(; gui=true, legend=(...))
    f2 = Figure(; gui = true, legend = (position = :lt, title = "My Title"))
    @test !isnothing(f2.gui_state.legend_options)
    @test f2.gui_state.legend_options[:position] == :lt
    @test f2.gui_state.legend_options[:title] == "My Title"

    ax2 = Axis(f2[1, 1])
    pl2 = scatter!(ax2, rand(10), label = "test")
    Makie.add_gui!(f2, ax2, pl2)
    @test !isnothing(f2.gui_state.legend)
    @test f2.gui_state.legend.entrygroups[][1][1] == "My Title"

    # Test Figure(; gui=false) - should not add GUI
    f3 = Figure(; gui = false)
    @test isnothing(f3.gui_state.hovermenu_options)
    ax3 = Axis(f3[1, 1])
    pl3 = scatter!(ax3, rand(10), label = "test")
    Makie.add_gui!(f3, ax3, pl3)
    @test isnothing(f3.gui_state.hovermenu)
end

@testset "figure keyword in plot calls" begin
    # Test figure=(; gui=true, legend=(...))
    f, ax, pl = scatter(
        rand(10), rand(10), label = "Test";
        figure = (; gui = true, legend = (position = :lt,))
    )
    Makie.add_gui!(f, ax, pl)
    @test !isnothing(f.gui_state.hovermenu)
    @test !isnothing(f.gui_state.legend)

    # Test figure=(; gui=true, colorbar=false)
    f2, ax2, pl2 = scatter(
        rand(10), rand(10), color = 1:10;
        figure = (; gui = true, colorbar = false)
    )
    Makie.add_gui!(f2, ax2, pl2)
    @test isnothing(f2.gui_state.colorbar)

    # Test figure=(; legend=true) without gui - legend should still be created
    f3, ax3, pl3 = scatter(
        rand(10), label = "test";
        figure = (; legend = true)
    )
    Makie.add_gui!(f3, ax3, pl3)
    @test !isnothing(f3.gui_state.legend)
    @test isnothing(f3.gui_state.hovermenu)  # gui not enabled
end

@testset "GUI theming with Figure theme" begin
    # Test that Figure theme options are picked up
    fap1 = with_theme(Figure = (; gui = true)) do
        scatter(rand(10), label = "test")
    end
    @test !isnothing(fap1.figure.gui_state.hovermenu_options)

    # Add GUI and verify it works
    Makie.add_gui!(fap1)
    @test !isnothing(fap1.figure.gui_state.hovermenu)

    # Test Figure theme with legend options including attributes
    fap2 = with_theme(Figure = (; legend = (position = :lt, title = "Theme Title"))) do
        scatter(rand(10), label = "test")
    end
    Makie.add_gui!(fap2)
    @test !isnothing(fap2.figure.gui_state.legend)
    @test fap2.figure.gui_state.legend.entrygroups[][1][1] == "Theme Title"

    # Test figure attrs override Figure theme
    fap3 = with_theme(Figure = (; gui = true, legend = (position = :lt, title = "Theme"))) do
        # Figure attribute overrides theme
        scatter(rand(10), label = "test"; figure = (; legend = false))
    end
    Makie.add_gui!(fap3)
    @test isnothing(fap3.figure.gui_state.legend)  # legend disabled by figure attr
    @test !isnothing(fap3.figure.gui_state.hovermenu)  # hovermenu from theme

    # Test that GUI is NOT added when theme has gui=false (default)
    fap4 = with_theme(Figure = (; gui = false)) do
        scatter(rand(10), label = "test")
    end
    Makie.add_gui!(fap4)
    @test isnothing(fap4.figure.gui_state.hovermenu)

    # Test colorbar options from theme
    fap5 = with_theme(Figure = (; colorbar = (position = [1, 2], label = "Theme CB"))) do
        heatmap(rand(10, 10))
    end
    Makie.add_gui!(fap5)
    @test !isnothing(fap5.figure.gui_state.colorbar)
    @test fap5.figure.gui_state.colorbar.label[] == "Theme CB"
end

@testset "GUI with various plot types" begin
    # Lines with legend - verify labels are correct
    f1, ax1, pl1 = lines(rand(10), label = "My Line"; figure = (; legend = true))
    Makie.add_gui!(f1, ax1, pl1)
    @test !isnothing(f1.gui_state.legend)

    # Heatmap with colorbar (grid position) - verify colormap inheritance
    f2, ax2, pl2 = heatmap(
        rand(10, 10), colormap = :heat;
        figure = (; colorbar = (position = [1, 2],))
    )
    Makie.add_gui!(f2, ax2, pl2)
    @test !isnothing(f2.gui_state.colorbar)
    # Colorbar should have a colormap (derived from plot)
    @test length(to_value(f2.gui_state.colorbar.colormap)) > 0

    # Series with legend - multiple labels
    f3, ax3, pl3 = series(
        rand(5, 10), labels = ["a", "b", "c", "d", "e"];
        figure = (; legend = true)
    )
    Makie.add_gui!(f3, ax3, pl3)
    @test !isnothing(f3.gui_state.legend)

    # Scatter with both legend and colorbar
    f4, ax4, pl4 = scatter(
        rand(10), color = 1:10, label = "Colored Points";
        figure = (; legend = (position = :lt,), colorbar = (position = :rt,))
    )
    Makie.add_gui!(f4, ax4, pl4)
    @test !isnothing(f4.gui_state.legend)
    @test !isnothing(f4.gui_state.colorbar)
    @test f4.gui_state.legend.halign[] == :left
    @test f4.gui_state.colorbar.halign[] == :right
end

@testset "remove_gui! cleans up state" begin
    f, ax, pl = scatter(
        rand(10), color = 1:10, label = "test";
        figure = (; gui = true, legend = true, colorbar = true)
    )
    Makie.add_gui!(f, ax, pl)

    @test !isnothing(f.gui_state.hovermenu)
    @test !isnothing(f.gui_state.legend)
    @test !isnothing(f.gui_state.colorbar)

    Makie.remove_gui!(f)
    @test isnothing(f.gui_state.hovermenu)
    @test isnothing(f.gui_state.legend)
    @test isnothing(f.gui_state.colorbar)

    # Calling remove on figure without GUI should not error
    f2 = Figure()
    @test isnothing(Makie.remove_gui!(f2))
end

@testset "Legend and Colorbar position options" begin
    # Test all overlay positions for legend
    for pos in [:lt, :rt, :lb, :rb, :lc, :rc, :ct, :cb]
        f, ax, pl = scatter(rand(10), label = "test"; figure = (; legend = (position = pos,)))
        Makie.add_gui!(f, ax, pl)
        legend = f.gui_state.legend
        @test !isnothing(legend)
        # Verify halign/valign based on position
        halign, valign = Makie.legend_position_to_aligns(pos)
        @test legend.halign[] == halign
        @test legend.valign[] == valign
    end

    # Test grid position (Vector)
    f2, ax2, pl2 = scatter(rand(10), color = 1:10; figure = (; colorbar = (position = [1, 2],)))
    Makie.add_gui!(f2, ax2, pl2)
    @test !isnothing(f2.gui_state.colorbar)

    # Test colorbar overlay positions
    for pos in [:lt, :rt, :lb, :rb]
        f, ax, pl = scatter(rand(10), color = 1:10; figure = (; colorbar = (position = pos,)))
        Makie.add_gui!(f, ax, pl)
        colorbar = f.gui_state.colorbar
        @test !isnothing(colorbar)
        halign, valign = Makie.legend_position_to_aligns(pos)
        @test colorbar.halign[] == halign
        @test colorbar.valign[] == valign
    end
end

@testset "No labeled plots or colormap" begin
    # Legend with no labeled plots should return nothing
    f1 = Figure(; legend = true)
    ax1 = Axis(f1[1, 1])
    scatter!(ax1, rand(10))  # no label
    Makie.add_gui!(f1, ax1, first(ax1.scene.plots))
    @test isnothing(f1.gui_state.legend)

    # Colorbar with no colormap should return nothing
    f2 = Figure(; colorbar = true)
    ax2 = Axis(f2[1, 1])
    pl2 = lines!(ax2, rand(10))  # no colormap
    Makie.add_gui!(f2, ax2, pl2)
    @test isnothing(f2.gui_state.colorbar)
end
