# contour3d

```@shortdocs; canonical=false
contour3d
```


## Examples

3D contour plots exist in two variants.
[contour](@ref) implements a variant showing multiple isosurfaces, i.e. surfaces that sample the same value from a 3D array.
`contour3d` computes the same isolines as a 2D `contour` plot but renders them in 3D at z values equal to their level.

```@figure backend=GLMakie
r = range(-pi, pi, length = 21)
data2d = [cos(x) + cos(y) for x in r, y in r]
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 400))
a1 = Axis3(f[1, 1], title = "3D contour()")
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d)

a2 = Axis3(f[1, 2], title = "contour3d()")
contour3d!(a2, r, r, data2d, linewidth = 3, levels = 10)
f
```

```@figure backend=GLMakie
f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

xs = ys = LinRange(-0.5, 0.5, 100)
zs = [sqrt(x^2+y^2) for x in xs, y in ys]

contour3d!(xs, ys, -zs, linewidth=2, color=:blue2)
contour3d!(xs, ys, +zs, linewidth=2, color=:red2)

f
```

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`:

```@figure
f = Figure()
Axis3(f[1, 1], aspect=(0.5,0.5,1), perspectiveness=0.75)

xs = ys = LinRange(-0.5, 0.5, 100)
zs = [sqrt(x^2+y^2) for x in xs, y in ys]

contour3d!(-zs, levels=-(.025:0.05:.475), linewidth=2, color=:blue2)
contour3d!(+zs, levels=  .025:0.05:.475,  linewidth=2, color=:red2)

f
```

## Attributes

```@attrdocs
Contour3d
```
