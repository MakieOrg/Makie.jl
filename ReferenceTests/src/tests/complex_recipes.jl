
@recipe complex AllBlocks (x, y) begin
    "Color for scatter plot"
    scatter_color = :blue
    "Color for line plot"
    line_color = :red
    linewidth = @inherit linewidth
    linestyle = @inherit linestyle
    markersize = 2
end

function Makie.plot!(cr::AllBlocks)
    ax, p1 = heatmap(cr[2:3, 1], rand(10, 10))
    lines!(ax, Rect2f(1, 1, 9, 9), color = :cyan, linewidth = cr.linewidth, linestyle = cr.linestyle)

    ax3 = Axis3(cr[2, 2])
    p2 = scatter!(ax3, cr.x, cr.y; color=cr.scatter_color, markersize = cr.markersize)
    po = PolarAxis(cr[3, 2])
    hidedecorations!(po, grid = false)
    p3 = lines!(po, cr.x, cr.y; color=cr.line_color, linewidth = cr.linewidth, linestyle = cr.linestyle)
    Legend(cr[1, 1:2], [p1, p2, p3], ["heatmap", "scatter", "lines"], nbanks = 5, tellheight = true)
    Colorbar(cr[2:3, 3], p1)

    gl = GridLayout(cr[0, 1:3])
    Menu(gl[1, 1], options = ["one", "two", "three"])
    Button(gl[1, 2], label = "Button")
    Checkbox(gl[1, 3])
    Toggle(gl[1, 4])
    Textbox(gl[1, 5])
    Box(gl[2, :], height = 20)

    sl = Slider(gl[3, 1])
    Label(gl[3, 2], map(v -> "$v", sl.value))
    IntervalSlider(gl[3, 3:5])

    return cr
end

@reference_test "Complex Recipes" begin
    my_theme = Theme(linewidth = 6)
    fig, ax, cr = with_theme(my_theme, linestyle = :dash) do
        fig, ax, cr = allblocks(1:0.5:10, sin, markersize = 20)
    end
    lines!(cr[2:3, 1], Rect2f(2, 2, 7, 7), color = :white)
    cr.scatter_color = :green
    fig
end
