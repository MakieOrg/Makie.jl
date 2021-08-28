# series

{{doc series}}

## Examples

### Matrix

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

data = cumsum(randn(4, 101), dims = 2)

fig, ax, sp = series(data, labels=["label $i" for i in 1:4])
axislegend(ax)
fig
```
\end{examplefigure}

### Vector of vectors

\begin{examplefigure}{}
```julia
pointvectors = [Point2f.(1:100, cumsum(randn(100))) for i in 1:4]

series(pointvectors, markersize=5, color=:Set1)
```
\end{examplefigure}

### Vector and matrix

\begin{examplefigure}{}
```julia
data = cumsum(randn(4, 101), dims = 2)

series(0:0.1:10, data, solid_color=:black)
```
\end{examplefigure}
