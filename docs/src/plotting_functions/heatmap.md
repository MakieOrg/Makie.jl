# heatmap

```@docs
heatmap
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide


f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

heatmap!(xs, ys, zs)

f
save("example_heatmap_1.svg", f); nothing # hide
```

![example_heatmap_1](example_heatmap_1.svg)


