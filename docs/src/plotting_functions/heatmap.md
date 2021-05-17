# heatmap

```@docs
heatmap
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide


f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 25)
ys = LinRange(0, 15, 25)
zs = [cos(x) * sin(y) for x in xs, y in ys]

heatmap!(xs, ys, zs)

f
```
