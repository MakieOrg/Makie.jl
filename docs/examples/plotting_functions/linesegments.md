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
