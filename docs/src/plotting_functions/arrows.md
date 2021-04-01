# arrows

```@docs
arrows
```

### Examples

```@example
using GLMakie
GLMakie.activate!() # hide
AbstractPlotting.inline!(true) # hide

f = Figure(resolution = (800, 600))
Axis(f[1, 1])

xs = LinRange(1, 10, 20)
ys = LinRange(1, 15, 20)
us = [cos(x) for x in xs, y in ys]
vs = [sin(y) for x in xs, y in ys]

arrows!(xs, ys, us, vs, arrowsize = 0.2, lengthscale = 0.3)

f
```

