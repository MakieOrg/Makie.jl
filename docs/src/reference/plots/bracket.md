# bracket

```
f, ax, pl = bracket(args...; kw...) # return a new figure, axis, and plot
   ax, pl = bracket(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = bracket!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Bracket(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Examples

#### Scalar arguments

```@figure
f, ax, l = lines(0..9, sin; axis = (; xgridvisible = false, ygridvisible = false))
ylims!(ax, -1.5, 1.5)

bracket!(pi/2, 1, 5pi/2, 1, offset = 5, text = "Period length", style = :square)

bracket!(pi/2, 1, pi/2, -1, text = "Amplitude", orientation = :down,
    linestyle = :dash, rotation = 0, align = (:right, :center), textoffset = 4, linewidth = 2, color = :red, textcolor = :red)

bracket!(2.3, sin(2.3), 4.0, sin(4.0),
    text = "Falling", offset = 10, orientation = :up, color = :purple, textcolor = :purple)

bracket!(Point(5.5, sin(5.5)), Point(7.0, sin(7.0)),
    text = "Rising", offset = 10, orientation = :down, color = :orange, textcolor = :orange, 
    fontsize = 30, textoffset = 30, width = 50)
f
```

#### Vector arguments

```@figure
f = Figure()
ax = Axis(f[1, 1])

bracket!(ax,
    1:5,
    2:6,
    3:7,
    2:6,
    text = ["A", "B", "C", "D", "E"],
    orientation = :down,
)

bracket!(ax,
    [(Point2f(i, i-0.7), Point2f(i+2, i-0.7)) for i in 1:5],
    text = ["F", "G", "H", "I", "J"],
    color = [:red, :blue, :green, :orange, :brown],
    linestyle = [:dash, :dot, :dash, :dot, :dash],
    orientation = [:up, :down, :up, :down, :up],
    textcolor = [:red, :blue, :green, :orange, :brown],
    fontsize = range(12, 24, length = 5),
)

f
```

#### Styles

```@figure
f = Figure()
ax = Axis(f[1, 1], xgridvisible = false, ygridvisible = false)
ylims!(ax, -1, 2)
bracket!(ax, 1, 0, 3, 0, text = "Curly", style = :curly)
bracket!(ax, 2, 1, 4, 1, text = "Square", style = :square)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/bracket) for rendered examples.

## Attributes

### `space`

**Default:** `:data`

Sets the space for the start and end points of brackets.

### `text`

**Default:** `""`

The text(s) displayed at the center of the bracket(s).

### `textoffset`

**Default:** `automatic`

Undirected offset between text and the center of the bracket. By default this is set to 75% of the fontsize. The direction of the offset is always perpendicular to the line from the start to the end point.

### `orientation`

**Default:** `:up`

Which way the bracket extends relative to the line from start to end point. Can be `:up` or `:down`.

### `linestyle`

**Default:** `nothing`

Sets the line pattern of the bracket line. See `?lines` for more information.

### `justification`

**Default:** `automatic`

Sets the justification of multi-line text.

### `font`

**Default:** `@inherit font`

The font used for text.

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering at line corners. Options are `:miter` for sharp corners, `:bevel` for cut-off corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `align`

**Default:** `(:center, :center)`

The alignment of text.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used for bracket lines. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

### `rotation`

**Default:** `automatic`

Sets the rotation of text. By default text is rotated to be parallel to the line from the start to end point of the bracket, and never upside-down.

### `textcolor`

**Default:** `@inherit textcolor`

Sets the color of the text.

### `miter_limit`

**Default:** `@inherit miter_limit`

" Sets the minimum inner line join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

### `style`

**Default:** `:curly`

Sets the style of drawn bracket. The current options are `:curly` for curly braces `}` and `:square` for brackets `]`. More bracket types can be implemented by providing a method of `Makie.bracket_bezierpath(...)`, see `?Makie.bracket_bezierpath`.

### `offset`

**Default:** `0`

The offset of the bracket perpendicular to the line from start to end point in screen units. The direction depends on the `orientation` attribute.

### `color`

**Default:** `@inherit linecolor`

Sets the color of the bracket line.

### `fontsize`

**Default:** `@inherit fontsize`

Sets the fontsize of text

### `linewidth`

**Default:** `@inherit linewidth`

Sets the width of the bracket line.

### `width`

**Default:** `15`

The width of the bracket (perpendicularly away from the line from start to end point) in screen units.
