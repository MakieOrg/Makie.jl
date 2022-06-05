# hspan and vspan

{{doc hspan}}
{{doc vspan}}


\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

lines(0..20, sin)
vspan!([0, 2pi, 4pi], [pi, 3pi, 5pi],
    color = [(c, 0.2) for c in [:red, :orange, :pink]])
hspan!(-1.1, -0.9, color = (:blue, 0.2))
current_figure()
```
\end{examplefigure}
