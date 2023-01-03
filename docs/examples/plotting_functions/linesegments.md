# linesegments

{{doc linesegments}}

## Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = sin.(xs)

linesegments!(xs, ys)
linesegments!(xs, ys .- 1, linewidth = 5)
linesegments!(xs, ys .- 2, linewidth = 5, color = LinRange(1, 5, length(xs)))

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
    linesegments!(ax, xs, ys .+ i, linecap = cap, linewidth = 50)
    linesegments!(ax, xs, ys .+ i, color = :black)
end

fig
```
\end{examplefigure}
