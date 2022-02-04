# pie

{{doc pie}}



## Attributes

### Generic

- `normalize = true` sets whether the data will be normalized to the range [0, 2π]. 
- `color` sets the color of the pie segments. It can be given as a single named color or a vector of the same length as the input data
- `strokecolor = :black` sets the color of the outline around the segments.
- `strokewidth = 1` sets the width of the outline around the segments.
- `vertex_per_deg = 1` defines the number of vertices per degree that are used to create the pie plot with polys. Increase if smoother circles are needed.
- `radius = 1` sets the radius for the pie plot.
- `inner_radius = 0` sets the innner radius if the plot. Choose as a value between 0 and `radius` to create a donut chart.
- `offset = 0` rotates the pie plot counterclockwise as given in radians.
- `transparency = false` adjusts how the plot deals with transparency.
In GLMakie `transparency = true` results in using Order Independent Transparency.
- `inspectable = true` sets whether this plot should be seen by `DataInspector`.

### Other

Set the axis property `autolimitaspect = 1` to ensure that a circle and not an elipsoid is plottet. 

## Examples

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

data   = [36, 12, 68, 5, 42, 27]
colors = [:yellow, :orange, :red, :blue, :purple, :green]

f, ax, plt = pie(data, 
                 color = colors,
                 radius = 4, 
                 inner_radius = 2,
                 strokecolor = :white,
                 strokewidth = 5, 
                 figure = (resolution= (800, 600), ), 
                 axis = (autolimitaspect = 1, ) 
    )

f 
```
\end{examplefigure}


\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f, ax, plt = pie([π/2, 2π/3, π/4],
                normalize=false,
                offset = π/2,
                color = [:orange, :purple, :green],
                figure = (resolution= (800, 600), ),
                axis = (autolimitaspect = 1,)
                )

f                
```
\end{examplefigure}
