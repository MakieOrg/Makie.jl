# pathtext

```@shortdocs; canonical=false
pathtext
```

## Examples

### Along a BezierPath

```@figure
bp = BezierPath([
    MoveTo(Point2(0, 0)),
    CurveTo(Point2(1, 3), Point2(3, 3), Point2(4, 0)),
])

f = Figure()
ax = Axis(f[1, 1], aspect = DataAspect(), limits = (nothing, (-0.5, 3)))
lines!(ax, bp, color = (:steelblue, 0.4), linewidth = 2)
pathtext!(ax, bp, text = "text along a Bezier curve", fontsize = 20, align = (:center, :bottom))
f
```

### Along a polyline

```@figure
path = Point2f[(0, 0), (1, 0), (2, 1), (3, 1), (4, 0)]

f = Figure()
ax = Axis(f[1, 1])
lines!(ax, path, color = :gray70)
pathtext!(ax, path, text = "polyline path", fontsize = 18, align = (:center, :baseline))
f
```

### RichText with sub/superscripts

```@figure
bp = BezierPath([
    MoveTo(Point2(0, 0)),
    CurveTo(Point2(2, 4), Point2(6, 4), Point2(8, 0)),
])

f = Figure()
ax = Axis(f[1, 1], aspect = DataAspect(), limits = (nothing, (-0.5, 4)))
lines!(ax, bp, color = (:gray, 0.4), linewidth = 2)
pathtext!(ax, bp,
    text = rich("H", subscript("2"), "O → H", superscript("+"), " + OH", superscript("−")),
    fontsize = 24, align = (:center, :bottom))
f
```

## Attributes

```@attrdocs
PathText
```
