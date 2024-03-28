# pie

{{doc pie}}

## Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


data   = [36, 12, 68, 5, 42, 27]
colors = [:yellow, :orange, :red, :blue, :purple, :green]

f, ax, plt = pie(data,
                 color = colors,
                 radius = 4,
                 inner_radius = 2,
                 strokecolor = :white,
                 strokewidth = 5,
                 axis = (autolimitaspect = 1, )
                )

f
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f, ax, plt = pie([π/2, 2π/3, π/4],
                normalize=false,
                offset = π/2,
                color = [:orange, :purple, :green],
                axis = (autolimitaspect = 1,)
                )

f
```
\end{examplefigure}
