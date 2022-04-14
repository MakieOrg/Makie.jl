@cell "Figure and Subplots" begin
    fig, _ = scatter(randn(100, 2), color = :red)
    scatter(fig[1, 2], randn(100, 2), color = :blue)
    scatter(fig[2, 1:2], randn(100, 2), color = :green)
    scatter(fig[1:2, 3][1:2, 1], randn(100, 2), color = :black)
    scatter(fig[1:2, 3][3, 1], randn(100, 2), color = :gray)
    fig
end

@cell "Figure with Blocks" begin
    fig = Figure(resolution = (900, 900))
    ax, sc = scatter(fig[1, 1][1, 1], randn(100, 2), axis = (;title = "Random Dots", xlabel = "Time"))
    sc2 = scatter!(ax, randn(100, 2) .+ 2, color = :red)
    ll = fig[1, 1][1, 2] = Legend(fig, [sc, sc2], ["Scatter", "Other"])
    lines(fig[2, 1:2][1, 3][1, 1], 0..3, sin ∘ exp, axis = (;title = "Exponential Sine"))
    heatmap(fig[2, 1:2][1, 1], randn(30, 30))
    heatmap(fig[2, 1:2][1, 2], randn(30, 30), colormap = :grays)
    lines!(fig[2, 1:2][1, 2], cumsum(rand(30)), color = :red, linewidth = 10)
    surface(fig[1, 2], collect(1.0:40), collect(1.0:40), (x, y) -> 10 * cos(x) * sin(y))
    fig[2, 1:2][2, :] = Colorbar(fig, vertical = false,
        height = 20, ticklabelalign = (:center, :top), flipaxis = false)
    fig[3, :] = Menu(fig, options = ["A", "B", "C"])
    lt = fig[0, :] = Label(fig, "Figure Demo")
    fig[5, :] = Textbox(fig)
    fig
end
