using CairoMakie
CairoMakie.activate!(type = "png")

##

fig, ax, bars = errorbars(1:10, 1:10, 1:10, color = 1:10, colormap = :viridis)
ax.backgroundcolor = :gray95

scatter!(ax, 1:10, 1:10)

ax, scat = scatter(fig[1, 2], 1:10, 1:10)
scatter(fig[2, :], 1:10, 1:10)

heatmap(fig[:, 3], randn(10, 10))
lines!(fig[1, 1], randn(100))
lines!(fig[1, 1], randn(100))


# fig[0, :] = LText(fig.scene, "hello")

fig

##


fig, _ = scatter(randn(100))

lines(fig[1, 2], randn(100))
lines(fig[2, :], randn(100))

fig
