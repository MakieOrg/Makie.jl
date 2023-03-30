@reference_test "Figure and Subplots" begin
    fig, _ = scatter(RNG.randn(100, 2), color = :red)
    scatter(fig[1, 2], RNG.randn(100, 2), color = :blue)
    scatter(fig[2, 1:2], RNG.randn(100, 2), color = :green)
    scatter(fig[1:2, 3][1:2, 1], RNG.randn(100, 2), color = :black)
    scatter(fig[1:2, 3][3, 1], RNG.randn(100, 2), color = :gray)
    fig
end

@reference_test "Figure with Blocks" begin
    fig = Figure(resolution = (900, 900))
    ax, sc = scatter(fig[1, 1][1, 1], RNG.randn(100, 2), axis = (;title = "Random Dots", xlabel = "Time"))
    sc2 = scatter!(ax, RNG.randn(100, 2) .+ 2, color = :red)
    ll = fig[1, 1][1, 2] = Legend(fig, [sc, sc2], ["Scatter", "Other"])
    lines(fig[2, 1:2][1, 3][1, 1], 0..3, sin ∘ exp, axis = (;title = "Exponential Sine"))
    heatmap(fig[2, 1:2][1, 1], RNG.randn(30, 30))
    heatmap(fig[2, 1:2][1, 2], RNG.randn(30, 30), colormap = :grays)
    lines!(fig[2, 1:2][1, 2], cumsum(RNG.rand(30)), color = :red, linewidth = 10)
    surface(fig[1, 2], collect(1.0:40), collect(1.0:40), (x, y) -> 10 * cos(x) * sin(y))
    fig[2, 1:2][2, :] = Colorbar(fig, vertical = false,
        height = 20, ticklabelalign = (:center, :top), flipaxis = false)
    fig[3, :] = Menu(fig, options = ["A", "B", "C"])
    lt = fig[0, :] = Label(fig, "Figure Demo")
    fig[5, :] = Textbox(fig)
    fig
end

@reference_test "menus" begin
    fig = Figure()
    funcs = [sqrt, x->x^2, sin, cos]
    options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs)

    menu1 = Menu(fig, options = ["viridis", "heat", "blues"], default = 1)
    menu2 = Menu(fig, options = options, default = "Square")
    menu3 = Menu(fig, options = options, default = nothing)
    menu4 = Menu(fig, options = options, default = nothing)

    fig[1, 1] = grid!(
        [
            Label(fig, "A", width = nothing) Label(fig, "C", width = nothing);
            menu1                            menu3;
            Label(fig, "B", width = nothing) Label(fig, "D", width = nothing);
            menu2                            menu4;
        ]
    )
    menu2.is_open = true
    menu4.is_open = true
    fig
end

@reference_test "Label with text wrapping" begin
    lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    fig = Figure(resolution = (1000, 660))
    m!(fig, lbl) = mesh!(fig.scene, lbl.layoutobservables.computedbbox, color = (:red, 0.5), shading=false)
    lbl1 = Label(fig[1, 1:2], "HEADER "^10, fontsize = 40, word_wrap = true)
    m!(fig, lbl1)

    lbl2 = Label(fig[2, 1], lorem_ipsum, word_wrap = true, justification = :left)
    m!(fig, lbl2)
    lbl3 = Label(fig[2, 2], "Smaller label\n <$('-'^12) pad $('-'^12)>")
    m!(fig, lbl3)

    lbl4 = Label(fig[3, 1], "test", word_wrap = true)
    m!(fig, lbl4)
    lbl5 = Label(fig[3, 2], lorem_ipsum, word_wrap = true)
    m!(fig, lbl5)
    fig
end

@reference_test "Axis titles and subtitles" begin
    f = Figure()

    Axis(
        f[1, 1],
        title = "First Title",
        subtitle = "This is a longer subtitle"
    )
    Axis(
        f[1, 2],
        title = "Second Title",
        subtitle = "This is a longer subtitle",
        titlealign = :left,
        subtitlecolor = :gray50,
        titlegap = 10,
        titlesize = 20,
        subtitlesize = 15,
    )
    Axis(
        f[2, 1],
        title = "Third Title",
        titlecolor = :gray50,
        titlefont = "TeX Gyre Heros Bold Italic Makie",
        titlealign = :right,
        titlesize = 25,
    )
    Axis(
        f[2, 2],
        title = "Fourth Title\nWith Line Break",
        subtitle = "This is an even longer subtitle,\nthat also has a line break.",
        titlealign = :left,
        subtitlegap = 2,
        titlegap = 5,
        subtitlefont = "TeX Gyre Heros Italic Makie",
        subtitlelineheight = 0.9,
        titlelineheight = 0.9,
    )

    f
end

@reference_test "Legend draw order" begin
    with_theme(Lines = (linewidth = 10,)) do
        f = Figure()
        ax = Axis(f[1, 1], backgroundcolor = :gray80)
        for i in 1:3
            lines!(ax,( 1:10) .* i, label = "$i")
        end
        # To verify that RGB values differ across entries
        axislegend(ax, position = :lt, patchcolor = :red, patchsize = (100, 100), bgcolor = :gray50);
        Legend(f[1, 2], ax, patchcolor = :gray80, patchsize = (100, 100), bgcolor = :gray50);
        f
    end
end

@reference_test "LaTeXStrings in Axis3 plots" begin
    xs = LinRange(-10, 10, 100)
    ys = LinRange(0, 15, 100)
    zs = [cos(x) * sin(y) for x in xs, y in ys]


    fig = Figure()
    ax = Axis3(fig[1, 1]; xtickformat = xs -> [L"%$x" for x in xs])

    surface!(ax, xs, ys, zs)
    fig
end
