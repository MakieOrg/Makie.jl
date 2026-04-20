# pathtext

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

### `text`

```@figure
bp = BezierPath([
    MoveTo(Point2(0, 0)),
    CurveTo(Point2(1, 2), Point2(3, 2), Point2(4, 0)),
])
fig = Figure()
ax = Axis(fig[1, 1], aspect = DataAspect())
lines!(ax, bp, color = (:gray, 0.4))
pathtext!(ax, bp, text = "plain string", fontsize = 20, align = (:left, :bottom))
pathtext!(ax, bp, text = rich("Rich", rich("Text"; color = :red, font = :bold)),
    fontsize = 20, align = (:right, :bottom))
fig
```

### `align`

```@figure
bp = BezierPath([
    MoveTo(Point2(0, 0)),
    CurveTo(Point2(1, 3), Point2(3, 3), Point2(4, 0)),
])
fig = Figure(size = (800, 600))
for (i, va) in enumerate((:top, :center, :baseline, :bottom))
    r, c = fldmod1(i, 2)
    ax = Axis(fig[r, c], aspect = DataAspect(), title = "valign = $(repr(va))",
        limits = (nothing, (-0.5, 3)))
    lines!(ax, bp, color = (:steelblue, 0.5), linewidth = 2)
    pathtext!(ax, bp, text = "Text along a path", fontsize = 22,
        align = (:center, va))
end
fig
```

### `offset`

```@figure
bp = BezierPath([
    MoveTo(Point2(0, 0)),
    CurveTo(Point2(1, 3), Point2(3, 3), Point2(4, 0)),
])
fig = Figure()
ax = Axis(fig[1, 1], aspect = DataAspect(), limits = (nothing, (-0.5, 3)))
lines!(ax, bp, color = (:gray, 0.4), linewidth = 2)
for (off, col) in zip((-15, 0, 15), (:red, :black, :blue))
    pathtext!(ax, bp, text = "offset = $off", fontsize = 14,
        align = (:center, :baseline), offset = off, color = col)
end
fig
```
