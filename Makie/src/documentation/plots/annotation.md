# annotation

## Examples

### Automatic label placement

If only target points are specified, text label offsets are automatically optimized for less overlap with their data points, each other and the axis boundary.

In this example, you can see how the `text` recipe results in an unreadable overlap for some labels, while `annotation` pushes labels apart.

```@figure
f = Figure()

points = [(-2.15, -0.19), (-1.66, 0.78), (-1.56, 0.87), (-0.97, -1.91), (-0.96, -0.25), (-0.79, 2.6), (-0.74, 1.68), (-0.56, -0.44), (-0.36, -0.63), (-0.32, 0.67), (-0.15, -1.11), (-0.07, 1.23), (0.3, 0.73), (0.72, -1.48), (0.8, 1.12)]

fruit = ["Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew",
          "Indian Fig", "Jackfruit", "Kiwi", "Lychee", "Mango", "Nectarine", "Orange"]

limits = (-3, 1.5, -3, 3)

ax1 = Axis(f[1, 1]; limits, title = "text")

scatter!(ax1, points)
text!(ax1, points, text = fruit)

ax2 = Axis(f[1, 2]; limits, title = "annotation")

scatter!(ax2, points)
annotation!(ax2, points, text = fruit)

hidedecorations!.([ax1, ax2])

f
```

## Attributes

### `shrink`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], xgridvisible = false, ygridvisible = false)
shrinks = [(0, 0), (5, 5), (10, 10), (20, 20), (5, 20), (20, 5)]
for (i, shrink) in enumerate(shrinks)
    annotation!(ax, -200, 0, 0, i; text = "shrink = $shrink", shrink, style = Ann.Styles.LineArrow())
    scatter!(ax, 0, i)
end
fig
```

### `style`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.3, 0.3), xgridvisible = false, ygridvisible = false)
annotation!(-200, 0, 0, 0, style = Ann.Styles.Line())
annotation!(-200, 0, 0, -1, style = Ann.Styles.LineArrow())
annotation!(-200, 0, 0, -2, style = Ann.Styles.LineArrow(head = Ann.Arrows.Head()))
annotation!(-200, 0, 0, -3, style = Ann.Styles.LineArrow(tail = Ann.Arrows.Line(length = 20)))
fig
```

### `path`

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.3, 0.3), xgridvisible = false, ygridvisible = false)
scatter!(ax, fill(0, 4), 0:-1:-3)
annotation!(-200, 0, 0, 0, path = Ann.Paths.Line(), text = "Line()")
annotation!(-200, 0, 0, -1, path = Ann.Paths.Arc(height = 0.1), text = "Arc(height = 0.1)")
annotation!(-200, 0, 0, -2, path = Ann.Paths.Arc(height = 0.3), text = "Arc(height = 0.3)")
annotation!(-200, 30, 0, -3, path = Ann.Paths.Corner(), text = "Corner()")
fig
```

### `labelspace`

```@figure
g(x) = cos(6x) * exp(x)
xs = 0:0.01:4
ys = g.(xs)

f, ax, _ = lines(xs, ys; axis = (; xgridvisible = false, ygridvisible = false))

annotation!(ax, 1, 20, 2.1, g(2.1),
    text = "(1, 20)\nlabelspace = :data",
    path = Ann.Paths.Arc(0.3),
    style = Ann.Styles.LineArrow(),
    labelspace = :data
)

annotation!(ax, -100, -100, 2.65, g(2.65),
    text = "(-100, -100)\nlabelspace = :relative_pixel",
    path = Ann.Paths.Arc(-0.3),
    style = Ann.Styles.LineArrow()
)

f
```
