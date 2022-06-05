# hlines and vlines

{{doc hlines}}
{{doc vlines}}

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f[1, 1], title = "vlines")

lines!(ax1, 0..4pi, sin)
vlines!(ax1, [pi, 2pi, 3pi], color = :red)

ax2 = Axis(f[1, 2], title = "hlines")
hlines!(ax2, [1, 2, 3, 4], xmax = [0.25, 0.5, 0.75, 1], color = :blue)

f
```
\end{examplefigure}