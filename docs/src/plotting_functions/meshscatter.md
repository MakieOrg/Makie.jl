# meshscatter

```@docs
meshscatter
```

### Examples

```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
```


