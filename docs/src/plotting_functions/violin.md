# violin

```@docs
violin
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = rand(1:3, 1000)
ys = randn(1000)

violin(xs, ys)
```

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs1 = rand(1:3, 1000)
ys1 = randn(1000)
dodge1 = rand(1:2, 1000)

xs2 = rand(1:3, 1000)
ys2 = randn(1000)
dodge2 = rand(1:2, 1000)

fig = Figure()
ax = Axis(fig[1, 1])
violin!(ax, xs1, ys1, dodge = dodge1, side = :left, color = :orange)
violin!(ax, xs2, ys2, dodge = dodge2, side = :right, color = :teal)
fig
```
