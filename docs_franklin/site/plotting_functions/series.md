# series

{{doc series}}

## Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

fig, ax, sp = series(rand(4, 10), labels=["label $i" for i in 1:4])
axislegend(ax)
fig
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
series([Point2f0.(1:10, rand(10)) for i in 1:4], markersize=5, color=:Set1)
```
\end{examplefigure}

\begin{examplefigure}{}
```julia
series(LinRange(0, 1, 10), rand(4, 10), solid_color=:black)
```
\end{examplefigure}
