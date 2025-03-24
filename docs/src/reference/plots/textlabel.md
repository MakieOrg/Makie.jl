# textlabel

```@shortdocs; canonical=false
textlabel
```


## Examples

```@figure
using CairoMakie
using FileIO

f, a, p = image(rotr90(load(assetpath("cow.png"))))
textlabel!(a, Point2f(200, 100), text = "cow", fontsize = 16)
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
    offset = (0, -20), align = (:center, :top)
)

xlims!(a, -140, 150)
ylims!(a, -5, 65)

f
```

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
    fontsize = 20, pad = 10,
    shape = Circle(Point2f(0), 1f0),
    shape_limits = Rect2f(-1, -1, 2, 2),
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


## Attributes

```@attrdocs
textlabel
```
