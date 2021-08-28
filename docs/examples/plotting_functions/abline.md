# abline!

{{doc abline!}}

The function `abline!` draws a linear function given slope and intercept values through the given `Axis`. The line always spans across the whole axis and doesn't affect the limits.

This function is not a plot type / recipe and only works with `Axis`.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide

fig, ax, pl = scatter(1:4)
abline!(ax, 0, 1)
abline!(ax, 0, 1.5, color = :red, linestyle=:dash, linewidth=2)
fig
```
\end{examplefigure}