# arrows3d

## Examples

### Basic 3D arrows

```@figure backend=GLMakie
ps = [Point3f(x, y, z) for x in -5:2:5 for y in -5:2:5 for z in -5:2:5]
ns = map(p -> 0.1 * Vec3f(p[2], p[3], p[1]), ps)
arrows3d(
    ps, ns,
    shaftcolor = :gray, tipcolor = :black,
    align = :center, axis=(type=Axis3,)
)
```

### 3D arrows with color mapping

```@figure backend=GLMakie
using LinearAlgebra

ps = [Point3f(x, y, z) for x in -5:2:5 for y in -5:2:5 for z in -5:2:5]
ns = map(p -> 0.1 * Vec3f(p[2], p[3], p[1]), ps)
lengths = norm.(ns)
arrows3d(
    ps, ns, color = lengths, lengthscale = 1.5,
    align = :center, axis=(type=Axis3,)
)
```

### Arrow scaling in 3D

```@figure
ps = Point2f.(1:5, 0)
vs = Vec2f.(0, 2 .^ (1:2:10))

fig = Figure()

ax = Axis(fig[1, 1], title = "Always scale, never elongate")
# x and y coordinates are on different scales, so radius (x) and length (y) are too
arrows3d!(ax, ps, vs, shaftlength = 50,
    tipradius = 0.1, tiplength = 20, shaftradius = 0.02)

ax = Axis(fig[1, 2], title = "Never scale, always elongate")
arrows3d!(ax, ps, vs, minshaftlength = 0,
    markerscale = 1, tiplength = 30)

fig
```
