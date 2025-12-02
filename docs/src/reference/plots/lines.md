# lines

```@shortdocs; canonical=false
lines
```

### Dealing with outline artifacts in GLMakie

In GLMakie 3D line plots can generate outline artifacts depending on the order line segments are rendered in.
Currently there are a few ways to mitigate this problem, but they all come at a cost:
- `fxaa = true` will disable the native anti-aliasing of line segments and use fxaa instead. This results in less detailed lines.
- `transparency = true` will disable depth testing to a degree, resulting in all lines being rendered without artifacts. However with this lines will always have some level of transparency.
- `overdraw = true` will disable depth testing entirely (read and write) for the plot, removing artifacts. This will however change the z-order of line segments and allow plots rendered later to show up on top of the lines plot.

```@figure backend=GLMakie
ps = rand(Point3f, 500)
cs = rand(500)
f = Figure(size = (600, 650))
Label(f[1, 1], "base", tellwidth = false)
lines(f[2, 1], ps, color = cs, fxaa = false)
Label(f[1, 2], "fxaa = true", tellwidth = false)
lines(f[2, 2], ps, color = cs, fxaa = true)
Label(f[3, 1], "transparency = true", tellwidth = false)
lines(f[4, 1], ps, color = cs, transparency = true)
Label(f[3, 2], "overdraw = true", tellwidth = false)
lines(f[4, 2], ps, color = cs, overdraw = true)
f
```

## Attributes

```@attrdocs
Lines
```
