# barplot

```@docs
barplot
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot!(xs, ys, color = :red, strokecolor = :black, strokewidth = 1)
barplot!(xs, ys .- 1, fillto = -1, color = xs, strokecolor = :black, strokewidth = 1)

f
```

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot(xs, ys, width = step(xs), color = :gray85, strokecolor = :black, strokewidth = 1)
```

```@example bar
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

tbl = (x = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )
```

```@example bar
barplot(tbl.x, tbl.height,
        stack = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        figure = (resolution = (800, 600), )
        )
```

```@example bar
barplot(tbl.x, tbl.height,
        dodge = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        figure = (resolution = (800, 600), )
        )
```

```@example bar
barplot(tbl.x, tbl.height,
        dodge = tbl.grp1,
        stack = tbl.grp2,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged and stacked bars"),
        figure = (resolution = (800, 600), )
        )
```

```@example bar
let
    colors = AbstractPlotting.wong_colors

    # Figure and Axis
    fig = Figure(resolution = (800, 600))
    ax = Axis(fig[1,1], xticks = (1:3, ["left", "middle", "right"]),
              title = "Dodged bars with legend")

    # Plot
    barplot!(ax, tbl.x, tbl.height,
             dodge = tbl.grp,
             color = colors[tbl.grp])

    # Legend
    labels = ["group 1", "group 2", "group 3"]
    elements = [PolyElement(color = colors[i], strokecolor = :transparent) for i in 1:length(labels)]
    title = "Groups"

    Legend(fig[1,2], elements, labels, title)

    fig
end
```