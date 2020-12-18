using CairoMakie
CairoMakie.activate!(type = "png")

##
using GLMakie
GLMakie.activate!()
set_window_config!(float = true)

##

fig, ax, bars = errorbars(1:10, 1:10, 1:10, color = 1:10, colormap = :viridis,
    figure = (resolution = (800, 600), font = "Helvetica Light"))
ax.backgroundcolor = :gray95

ax, scat = scatter(fig[1, 2], 1:10, 1:10, axis = (title = "hello", xlabel = "green"))

lpos = fig[2, :]
lines(lpos, cumsum(randn(10000)))
lines!(lpos, cumsum(randn(10000)), color = "green")
lines!(lpos, cumsum(randn(10000)), color = "red")

fig

##

fig, _ = scatter(randn(100))

lines(fig[1, 2], randn(100))
lines!(fig[1, 2], randn(100) .+ 1, color = :red)
lines(fig[2, :], randn(100))

fig

##

fig = Figure()

##
fig = Figure(resolution = (900, 900))
ax, sc = scatter(fig[1, 1][1, 1], randn(100, 2), axis = (;title = "Random Dots", xlabel = "Time"))
sc2 = scatter!(ax, randn(100, 2) .+ 2, color = :red)
ll = fig[1, 1][1, 2] = LLegend(fig, [sc, sc2], ["Scatter", "Other"])
lines(fig[2, 1:2][1, 3][1, 1], 0..3, sin ∘ exp, axis = (;title = "Exponential Sine"))
heatmap(fig[2, 1:2][1, 1], randn(30, 30))
heatmap(fig[2, 1:2][1, 2], randn(30, 30), colormap = :grays)
lines!(fig[2, 1:2][1, 2], cumsum(rand(30)), color = :red, linewidth = 10)
ls = fig[1, 2] = LScene(fig, scenekw = (camera = cam3d!, raw = false, show_axis = true, clear = true))
surface!(ls, collect(1.0:40), collect(1.0:40), (x, y) -> cos(x) * sin(y))
fig[2, 1:2][2, :] = LColorbar(fig, vertical = false,
    height = 20, ticklabelalign = (:center, :top), flipaxisposition = false)
fig[3, :] = LMenu(fig, options = ["A", "B", "C"], direction = :up)
lt = fig[0, :] = Label(fig, "Figure Demo")
fig[5, :] = Textbox(fig)
fig


##


scatter(randn(100, 3))


##

let 
    xs = LinRange(1, 10, 20)
    ys = LinRange(1, 15, 20)
    us = [cos(x) for x in xs, y in ys]
    vs = [sin(y) for x in xs, y in ys]

    scene = arrows(xs, ys, us, vs, arrowsize = 0.2, lengthscale = 0.3, axis = (; aspect = DataAspect()))
end

