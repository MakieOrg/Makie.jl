# scatter

```@docs
scatter
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(0, 10, 20)
ys = 0.5 .* sin.(xs)

scatter!(xs, ys, color = :red)
scatter!(xs, ys .- 1, color = xs)
scatter!(xs, ys .- 2, markersize = LinRange(5, 30, 20))
scatter!(xs, ys .- 3, marker = 'a':'t', strokewidth = 0, color = :black)

f
save("example_scatter_1.svg", f); nothing # hide
```

![example_scatter_1](example_scatter_1.svg)

