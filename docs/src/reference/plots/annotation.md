# annotation

```
f, ax, pl = annotation(args...; kw...) # return a new figure, axis, and plot
   ax, pl = annotation(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = annotation!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Annotation(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

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

See the [online documentation](https://docs.makie.org/stable/reference/plots/annotation) for rendered examples.

## Attributes

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `text`

**Default:** `""`

One object or an array of objects that determine the textual content of the labels.

### `fonts`

**Default:** `@inherit fonts`

Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

### `justification`

**Default:** `automatic`

Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.

### `algorithm`

**Default:** `automatic`

The algorithm used to automatically place labels with reduced overlaps. The positioning of the labels with a given input may change between non-breaking versions.

### `font`

**Default:** `@inherit font`

Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file.

### `labelspace`

**Default:** `:relative_pixel`

The space in which the label positions are given. Can be `:relative_pixel` (the positions are given in screen space relative to the target data positions) or `:data`. If a text label should be positioned somewhere close to the labeled point, `:relative_pixel` is usually easier to get a consistent visual result. If an arrow is supposed to point from one data point to another, `:data` is the appropriate choice.

**Example:**

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

### `align`

**Default:** `(:center, :center)`

The alignment of text relative to the label anchor position.

### `maxiter`

**Default:** `automatic`

The maximum number of iterations that the label placement algorithm is allowed to run.

### `clipstart`

**Default:** `automatic`

Determines which object is used to clip the path at the start. If set to `automatic`, the boundingbox of the text label is used.

### `path`

**Default:** `Ann.Paths.Line()`

One path type or an array of path types that determine how to connect each label to its point. Suitable objects can be found in the module `Makie.Ann.Paths`.

**Example:**

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

### `lineheight`

**Default:** `1.0`

The lineheight multiplier.

### `textcolor`

**Default:** `automatic`

The color of the text labels. If `automatic`, `textcolor` matches `color`.

### `shrink`

**Default:** `(5.0, 7.0)`

One tuple or an array of tuples with two numbers, where each number specifies the radius of a circle in screen space which clips the connection path at the start or end, respectively, to add a little bit of visual space between arrow and label or target.

**Example:**

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

**Default:** `automatic`

One style object or an array of style objects that determine how the path from a label to its point is visualized. Suitable objects can be found in the module `Makie.Ann.Styles`.

**Example:**

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.3, 0.3), xgridvisible = false, ygridvisible = false)
annotation!(-200, 0, 0, 0, style = Ann.Styles.Line())
annotation!(-200, 0, 0, -1, style = Ann.Styles.LineArrow())
annotation!(-200, 0, 0, -2, style = Ann.Styles.LineArrow(head = Ann.Arrows.Head()))
annotation!(-200, 0, 0, -3, style = Ann.Styles.LineArrow(tail = Ann.Arrows.Line(length = 20)))
fig

```

### `color`

**Default:** `@inherit linecolor`

The basic color of the connection object. For more fine-grained adjustments, modify the `style` object directly.

### `fontsize`

**Default:** `@inherit fontsize`

The size of the label font.

### `linewidth`

**Default:** `1.0`

The default line width for connection styles that have lines
