

# Box

A simple rectangle poly that is block. This can be useful to make boxes for
facet plots or when a rectangular placeholder is needed.

\begin{examplefigure}{}
```julia
using CairoMakie
using ColorSchemes
CairoMakie.activate!() # hide

fig = Figure()

rects = fig[1:4, 1:6] = [
    Box(fig, color = c)
    for c in get.(Ref(ColorSchemes.rainbow), (0:23) ./ 23)]

fig
```
\end{examplefigure}

## Attributes

\attrdocs{Box}