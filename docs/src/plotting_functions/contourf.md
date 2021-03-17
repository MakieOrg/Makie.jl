# contourf

```@docs
contourf
```

```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

co = contourf!(xs, ys, zs, levels = 10)

Colorbar(f[1, 2], co, width = 20)

f
save("example_contourf_1.svg", f); nothing # hide
```

![example_contourf_1](example_contourf_1.svg)


```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

co = contourf!(xs, ys, zs, levels = -0.75:0.25:0.5,
    extendlow = :cyan, extendhigh = :magenta)

Colorbar(f[1, 2], co, width = 20)

f
save("example_contourf_2.svg", f); nothing # hide
```

![example_contourf_2](example_contourf_2.svg)


```@example
using CairoMakie
CairoMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

xs = LinRange(0, 10, 100)
ys = LinRange(0, 10, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

co = contourf!(xs, ys, zs,
    levels = -0.75:0.25:0.5,
    extendlow = :auto, extendhigh = :auto)

Colorbar(f[1, 2], co, width = 20)

f
save("example_contourf_3.svg", f); nothing # hide
```

![example_contourf_3](example_contourf_3.svg)

