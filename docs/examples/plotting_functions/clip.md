# clip

{{doc clip}}

### Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

fig, ax, plt = heatmap(rand(10, 10))

clip!(ax, Circle(Point2f(5), 3))

fig
```
\end{examplefigure}
