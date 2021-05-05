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

xs = rand(1:3, 1000)
ys = map(xs) do x
    return x == 1 ? randn() : x == 2 ? 0.5 * randn() : 5 * rand()
end

violin(xs, ys, datalimits = extrema)
```


```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

N = 1000
xs = rand(1:3, N)
dodge = rand(1:2, N)
side = rand([:left, :right], N)
colors = map(side) do s
    return s == :left ? "orange" : "teal"
end
ys = map(side) do s
    return s == :left ? randn() : rand()
end

violin(xs, ys, dodge = dodge, side = side, color = colors)
```
