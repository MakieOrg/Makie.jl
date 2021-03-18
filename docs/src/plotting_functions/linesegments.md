# linesegments

```@docs
linesegments
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = 1:0.2:10
ys = sin.(xs)

linesegments!(xs, ys)
linesegments!(xs, ys .- 1, linewidth = 5)
linesegments!(xs, ys .- 2, linewidth = 5, color = LinRange(1, 5, length(xs)))

f
```
