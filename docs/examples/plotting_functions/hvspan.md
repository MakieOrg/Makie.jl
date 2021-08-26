# hspan! and vspan!

{{doc hspan!}}
{{doc vspan!}}

These functions are not plot types / recipes and only work with `Axis`.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
ax = Axis(f[1, 1])

lines!(ax, 0..20, sin)
vspan!(ax, [0, 2pi, 4pi], [pi, 3pi, 5pi], color = (:red, 0.2))
hspan!(ax, -1.1, -0.9, color = (:blue, 0.2))

f
```
\end{examplefigure}
