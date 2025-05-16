# textlabel

```@shortdocs; canonical=false
textlabel
```


## Examples

```@figure
using CairoMakie
using FileIO

f, a, p = image(rotr90(load(assetpath("cow.png"))))
textlabel!(a, Point2f(200, 150), text = "Cow", fontsize = 20)
f
```

```@figure
using CairoMakie
using DelimitedFiles
loc = readdlm(assetpath("airportlocations.csv"))

f, a, p = scatter(
    loc[1:5004:end, :], marker = '✈', markersize = 20, color = :black
)
textlabel!(
    a, loc[1:5004:end, :], text = ["A$i" for i in axes(loc[1:5004:end, :], 1)],
    offset = (0, -20), text_align = (:center, :top)
)

xlims!(a, -140, 150)
ylims!(a, -5, 65)

f
```

### Custom Background Shapes

The background shape can be adjusted with the `shape` attribute.
It can be anything that converts to a vector of points through `convert_arguments`, e.g. a GeometryPrimitive, a BezierPath, a vector of points, etc.
These points are then transformed to fit the text bounding box of the label.
More specifically, they are transformed such that `shape_limits` gets scaled up to the text bounding box plus padding.

Let's consider using a `Circle(Point2f(0), 1f0)` as our background shape.
We want the text to fit inside the circle, so we want the text boundingbox to relate to an inner bounding box of the circle.
We can choose this to be a square from `-sqrt(0.5) .. sqrt(0.5)` resulting in `shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2))`:

```@figure
using CairoMakie

ps = Point2f[
    (0, 0),
    (-1, -1), (1, -1),
    (-1.5, -2), (-0.5, -2), (0.5, -2), (1.5, -2)
]
f,a,p = textlabel(
    ps,
    ["A", "B", "C", "D",  "E", "F", "G"],
    fontsize = 20, padding = 0,
    shape = Circle(Point2f(0), 1f0),
    shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
    keep_aspect = true
)
linesegments!(a, [
    ps[1], ps[2], ps[1], ps[3],
    ps[2], ps[4], ps[2], ps[5], ps[3], ps[6], ps[3], ps[7]
], linewidth = 4)

xlims!(a, -2, 2)
ylims!(a, -2.5, 0.5)
f
```

Another option for `shape` is to pass a function that constructs an already transformed vector of points from a translation and scale.
If `shape_limits = Rect2f(0,0,1,1)` those are the origin and size of text boundingbox plus padding.
This can be used, for example, to construct a circle that more tightly fits the text bounding box:

```@figure
using CairoMakie
using GeometryBasics
using LinearAlgebra

function build_shape(origin, size)
    radius = norm(0.5 * size)
    center = Point2f(origin + 0.5 * size)
    return coordinates(Circle(center, radius))
end

f, a, p = textlabel(
    [-1, 0, 1], [1, 1, 1], ["long label", "A", "t\na\nl\nl"],
    shape = build_shape, fontsize = 20, padding = 0
)
textlabel!(
    a, [-1, 0, 1], [-1, -1, -1], ["long label", "A", "t\na\nl\nl"],
    shape = Circle(Point2f(0), 1f0), fontsize = 20, padding = 0,
    shape_limits = Rect2f(-sqrt(0.5), -sqrt(0.5), sqrt(2), sqrt(2)),
    keep_aspect = true
)
xlims!(a, -1.5, 1.5)
ylims!(a, -1.75, 1.75)
f
```

## Attributes

```@attrdocs
TextLabel
```
