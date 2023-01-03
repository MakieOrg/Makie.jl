# lines

{{doc lines}}

## Examples

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

lines!(xs, ys)
lines!(xs, ys .- 1, linewidth = 5)
lines!(xs, ys .- 2, linewidth = 5, color = ys)
lines!(xs, ys .- 3, linestyle = :dash)

f
```
\end{examplefigure}

### Linestyles

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 0:0.01:10
ys = 0.5 .* sin.(xs)

for (i, lw) in enumerate([1, 2, 3])
    lines!(xs, ys .- i/6, linestyle = nothing, linewidth = lw)
    lines!(xs, ys .- i/6 .- 1, linestyle = :dash, linewidth = lw)
    lines!(xs, ys .- i/6 .- 2, linestyle = :dot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 3, linestyle = :dashdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 4, linestyle = :dashdotdot, linewidth = lw)
    lines!(xs, ys .- i/6 .- 5, linestyle = [0.5, 1.0, 1.5, 2.5], linewidth = lw)
end

f
```
\end{examplefigure}

### Linecaps

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


fig = Figure()
ax = Axis(fig[1, 1])
xlims!(ax, 0.75, 3.25)
ylims!(ax, 1, 4.5)

caps = (nothing, :square, :round)
xs = [1, 2, 3, 2]
ys = [0.5, 1, 0.75, 0.5]

for (i, cap) in enumerate(caps)
    lines!(ax, xs, ys .+ i, linecap = cap, linewidth = 50)
    lines!(ax, xs, ys .+ i, color = :black)
end

fig
```
\end{examplefigure}
