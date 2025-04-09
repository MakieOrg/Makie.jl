# poly

```@shortdocs; canonical=false
poly
```


## Examples

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

poly!(Point2f[(0, 0), (2, 0), (3, 1), (1, 1)], color = :red, strokecolor = :black, strokewidth = 1)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# polygon with hole
p = Polygon(
    Point2f[(0, 0), (2, 0), (3, 1), (1, 1)],
    [Point2f[(0.75, 0.25), (1.75, 0.25), (2.25, 0.75), (1.25, 0.75)]]
)

poly!(p, color = :blue)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = 1:15,
    colormap = :heat
)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1], aspect = DataAspect())

# shape decomposition
poly!(Circle(Point2f(0, 0), 15f0), color = :pink)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1]; backgroundcolor = :gray15)

# vector of polygons
ps = [Polygon(rand(Point2f, 3) .+ Point2f(i, j))
    for i in 1:5 for j in 1:10]

poly!(ps, color = rand(RGBf, length(ps)))

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = :white,
    strokewidth = 2,
    strokecolor = 1:15,
    strokecolormap=:plasma,
)

f
```

## Attributes

```@attrdocs
Poly
```
