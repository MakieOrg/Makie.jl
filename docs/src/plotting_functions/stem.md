# stem

```@docs
stem
```

### Examples

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs))

f
save("example_stem_1.svg", f); nothing # hide
```

![example stem_1](example_stem_1.svg)



```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin,
    offset = 0.5, trunkcolor = :blue, marker = :rect,
    stemcolor = :red, color = :orange,
    markersize = 15, strokecolor = :red, strokewidth = 3,
    trunklinestyle = :dash, stemlinestyle = :dashdot)

f
save("example_stem_2.svg", f); nothing # hide
```

![example stem_2](example_stem_2.svg)



```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(0, 4pi, 30)

stem!(xs, sin.(xs),
    offset = LinRange(-0.5, 0.5, 30),
    color = LinRange(0, 1, 30), colorrange = (0, 0.5),
    trunkcolor = LinRange(0, 1, 30), trunkwidth = 5)

f
save("example_stem_3.svg", f); nothing # hide
```

![example stem_3](example_stem_3.svg)



```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))

xs = LinRange(0, 4pi, 30)

stem(f[1, 1], 0.5xs, 2 .* sin.(xs), 2 .* cos.(xs),
    offset = Point3f0.(0.5xs, sin.(xs), cos.(xs)),
    stemcolor = LinRange(0, 1, 30), stemcolormap = :Spectral, stemcolorrange = (0, 0.5))

f
```


