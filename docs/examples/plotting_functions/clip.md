# clip

{{doc clip}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

fig = Figure()
ax = Axis(fig[1, 1])
clip!(ax, Circle(Point2f(5), 3))

plt = heatmap(rand(10, 10))

fig
```
\end{examplefigure}
