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

co = contourf!(xs, ys, zs, levels = -0.75:0.25:0.5,
    extendlow = :cyan, extendhigh = :magenta)

Colorbar(f[1, 2], co, width = 20)

f
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

co = contourf!(xs, ys, zs,
    levels = -0.75:0.25:0.5,
    extendlow = :auto, extendhigh = :auto)

Colorbar(f[1, 2], co, width = 20)

f
```

