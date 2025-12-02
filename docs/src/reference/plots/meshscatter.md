# meshscatter

```@shortdocs; canonical=false
meshscatter
```


## Examples

```@figure backend=GLMakie
xs = cos.(1:0.5:20)
ys = sin.(1:0.5:20)
zs = LinRange(0, 3, length(xs))

meshscatter(xs, ys, zs, markersize = 0.1, color = zs)
```

```@figure backend=GLMakie
using FileIO, GeometryBasics
cow = Makie.loadasset("cow.png")

N = 8; M = 10
f = Figure(size = (500, 400))
a, p = meshscatter(
    f[1, 1],
    [Point2f(x, y) for x in 1:M for y in 1:N],
    color = cow,
    uv_transform = [
        # 1. undo y flip of uvs relative to pos
        # 2. grab relevant section from image
        # 3. rotate to match view
        (:rotl90, (Vec2f(x, y), Vec2f(1/M, 1/N)), :flip_y)
        for x in range(0, 1, length = M+1)[1:M]
        for y in range(0, 1, length = N+1)[1:N]
    ],
    markersize = Vec3f(0.9, 0.9, 1),
    marker = uv_normal_mesh(Rect2f(-0.5, -0.5, 1, 1))
)
hidedecorations!(a)
xlims!(a, 0.4, M+0.6)
ylims!(a, 0.4, N+0.6)
f
```


## Attributes

```@attrdocs
MeshScatter
```
