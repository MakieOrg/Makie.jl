# scatter

{{doc scatter}}

## Examples

### Using x and y vectors

Scatters can be constructed by passing a list of x and y coordinates.

\begin{examplefigure}{name = "basic_scatter", svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


xs = range(0, 10, length = 30)
ys = 0.5 .* sin.(xs)

scatter(xs, ys)
```
\end{examplefigure}

### Using points

It is also possible to pass coordinates as a vector of points, which is preferred if the coordinates should be updated later, to avoid different lengths of x and y.

Attributes like `color` and `markersize` can be set in scalar or vector form.
If you pass a vector of numbers for `color`, the attribute `colorrange` which is by default automatically equal to the extrema of the color values, decides how colors are looked up in the `colormap`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


xs = range(0, 10, length = 30)
ys = 0.5 .* sin.(xs)
points = Point2f.(xs, ys)

scatter(points, color = 1:30, markersize = range(5, 30, length = 30),
    colormap = :thermal)
```
\end{examplefigure}

### Markers

There are a couple different categories of markers you can use with `scatter`:

- `Char`s like `'x'` or `'α'`. The glyphs are taken from Makie's default font `TeX Gyre Heros Makie`.
- `BezierPath` objects which can be used to create custom marker shapes. Most default markers which are accessed by symbol such as `:circle` or `:rect` convert to `BezierPath`s internally.
- `Polygon`s, which are equivalent to constructing `BezierPath`s exclusively out of `LineTo` commands.
- `Matrix{<:Colorant}` objects which are plotted as image scatters.
- Special markers like `Circle` and `Rect` which have their own backend implementations and can be faster to display.

#### Default markers

Here is an example plot showing different shapes that are accessible by `Symbol`s, as well as a few characters.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


markers_labels = [
    (:circle, ":circle"),
    (:rect, ":rect"),
    (:diamond, ":diamond"),
    (:hexagon, ":hexagon"),
    (:cross, ":cross"),
    (:xcross, ":xcross"),
    (:utriangle, ":utriangle"),
    (:dtriangle, ":dtriangle"),
    (:ltriangle, ":ltriangle"),
    (:rtriangle, ":rtriangle"),
    (:pentagon, ":pentagon"),
    (:star4, ":star4"),
    (:star5, ":star5"),
    (:star6, ":star6"),
    (:star8, ":star8"),
    (:vline, ":vline"),
    (:hline, ":hline"),
    ('a', "'a'"),
    ('B', "'B'"),
    ('↑', "'\\uparrow'"),
    ('😄', "'\\:smile:'"),
    ('✈', "'\\:airplane:'"),
]

f = Figure()
ax = Axis(f[1, 1], yreversed = true,
    xautolimitmargin = (0.15, 0.15),
    yautolimitmargin = (0.15, 0.15)
)
hidedecorations!(ax)

for (i, (marker, label)) in enumerate(markers_labels)
    p = Point2f(fldmod1(i, 6)...)

    scatter!(p, marker = marker, markersize = 20, color = :black)
    text!(p, text = label, color = :gray70, offset = (0, 20),
        align = (:center, :bottom))
end

f
```
\end{examplefigure}

#### Markersize

The `markersize` attribute scales the scatter size relative to the scatter marker's base size.
Therefore, `markersize` cannot be directly understood in terms of a unit like `px`, it depends on _what_ is scaled.

For `Char` markers, `markersize` is equivalent to the font size when displaying the same characters using `text`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f, ax, sc = scatter(1, 1, marker = 'A', markersize = 50)
text!(2, 1, text = "A", fontsize = 50, align = (:center, :center))
xlims!(ax, -1, 4)
f
```
\end{examplefigure}

The default `BezierPath` markers like `:circle`, `:rect`, `:utriangle`, etc. have been chosen such that they approximately match `Char` markers of the same markersize.
This makes it easier to switch out markers without the overall look changing too much.
However, both `Char` and `BezierPath` markers are not exactly `markersize` high or wide.
We can visualize this by plotting some `Char`s, `BezierPath`s, `Circle` and `Rect` in front of a line of width `50`.
You can see that only the special markers `Circle` and `Rect` match the line width because their base size is 1 x 1, however they don't match the `Char`s or `BezierPath`s very well.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f, ax, l = lines([0, 1], [1, 1], linewidth = 50, color = :gray80)
for (marker, x) in zip(['X', 'x', :circle, :rect, :utriangle, Circle, Rect], range(0.1, 0.9, length = 7))
    scatter!(ax, x, 1, marker = marker, markersize = 50, color = :black)
end
f
```
\end{examplefigure}

If you need a marker that has some exact base size, so that you can match it with lines or other plot objects of known size, or because you want to use the marker in data space, you can construct it yourself using `BezierPath` or `Polygon`.
A marker with a base size of 1 x 1, e.g., will be scaled like `lines` when `markersize` and `linewidth` are the same, just like `Circle` and `Rect` markers.

Here, we construct a hexagon polygon with radius `1`, which we can then use to tile a surface in data coordinates by setting `markerspace = :data`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


hexagon = Makie.Polygon([Point2f(cos(a), sin(a)) for a in range(1/6 * pi, 13/6 * pi, length = 7)])

points = Point2f[(0, 0), (sqrt(3), 0), (sqrt(3)/2, 1.5)]

scatter(points,
    marker = hexagon,
    markersize = 1,
    markerspace = :data,
    color = 1:3,
    axis = (; aspect = 1, limits = (-2, 4, -2, 4)))
```
\end{examplefigure}

### Bezier path markers

Bezier paths are the basis for vector graphic formats such as svg and pdf and consist of a couple different operations that can define complex shapes.

A `BezierPath` contains a vector of path commands, these are `MoveTo`, `LineTo`, `CurveTo`, `EllipticalArc` and `ClosePath`.
A filled shape should start with `MoveTo` and end with `ClosePath`.

!!! note
    Unfilled markers (like a single line or curve) are possible in CairoMakie but not in GLMakie and WGLMakie, because these backends have to render the marker as a filled shape to a texture first.
    If no filling can be rendered, the marker will be invisible.
    CairoMakie, on the other hand can stroke such markers without problem.

Here is an example with a simple arrow that is centered on its tip, built from path elements.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


arrow_path = BezierPath([
    MoveTo(Point(0, 0)),
    LineTo(Point(0.3, -0.3)),
    LineTo(Point(0.15, -0.3)),
    LineTo(Point(0.3, -1)),
    LineTo(Point(0, -0.9)),
    LineTo(Point(-0.3, -1)),
    LineTo(Point(-0.15, -0.3)),
    LineTo(Point(-0.3, -0.3)),
    ClosePath()
])

scatter(1:5,
    marker = arrow_path,
    markersize = range(20, 50, length = 5),
    rotations = range(0, 2pi, length = 6)[1:end-1],
)
```
\end{examplefigure}

#### Holes

Paths can have holes, just start a new subpath with `MoveTo` that is inside the main path.
The holes have to be in clockwise direction if the outside is in anti-clockwise direction, or vice versa.
For example, a circle with a square cut out can be made by one `EllipticalArc` that goes anticlockwise, and a square inside which goes clockwise:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


circle_with_hole = BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
    MoveTo(Point(0.5, 0.5)),
    LineTo(Point(0.5, -0.5)),
    LineTo(Point(-0.5, -0.5)),
    LineTo(Point(-0.5, 0.5)),
    ClosePath(),
])

scatter(1:5,
    marker = circle_with_hole,
    markersize = 30,
)
```
\end{examplefigure}

#### Construction from svg path strings

You can also create a bezier path from an [svg path specification string](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands).
You can automatically resize the path and flip the y-axis (svgs usually have a coordinate system where y increases downwards) with the keywords `fit` and `yflip`.
By default, the bounding box for the fitted path is a square of width 1 centered on zero.
You can pass a different bounding `Rect` with the `bbox` keyword argument.
By default, the aspect of the path is left intact, and if it's not matching the new bounding box, the path is centered so it fits inside.
Set `keep_aspect = false` to squeeze the path into the bounding box, disregarding its original aspect ratio.

Here's an example with an svg string that contains the bat symbol:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


batsymbol_string = "M96.84 141.998c-4.947-23.457-20.359-32.211-25.862-13.887-11.822-22.963-37.961-16.135-22.041 6.289-3.005-1.295-5.872-2.682-8.538-4.191-8.646-5.318-15.259-11.314-19.774-17.586-3.237-5.07-4.994-10.541-4.994-16.229 0-19.774 21.115-36.758 50.861-43.694.446-.078.909-.154 1.372-.231-22.657 30.039 9.386 50.985 15.258 24.645l2.528-24.367 5.086 6.52H103.205l5.07-6.52 2.543 24.367c5.842 26.278 37.746 5.502 15.414-24.429 29.777 6.951 50.891 23.936 50.891 43.709 0 15.136-12.406 28.651-31.609 37.267 14.842-21.822-10.867-28.266-22.549-5.549-5.502-18.325-21.147-9.341-26.125 13.886z"

batsymbol = BezierPath(batsymbol_string, fit = true, flipy = true)

scatter(1:10, marker = batsymbol, markersize = 50, color = :black)
```
\end{examplefigure}

### Polygon markers

One can also use `GeometryBasics.Polgyon` as a marker.
A polygon always needs one vector of points which forms the outline.
It can also take an optional vector of vectors of points, each of which forms a hole in the outlined shape.

In this example, a small circle is cut out of a larger circle:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie, GeometryBasics
CairoMakie.activate!() # hide


p_big = decompose(Point2f, Circle(Point2f(0), 1))
p_small = decompose(Point2f, Circle(Point2f(0), 0.5))
scatter(1:4, fill(0, 4), marker=Polygon(p_big, [p_small]), markersize=100, color=1:4, axis=(limits=(0, 5, -1, 1),))
```
\end{examplefigure}

### Marker rotation

Markers can be rotated using the `rotations` attribute, which also allows to pass a vector.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


points = [Point2f(x, y) for y in 1:10 for x in 1:10]
rotations = range(0, 2pi, length = length(points))

scatter(points, rotations = rotations, markersize = 20, marker = '↑')
```
\end{examplefigure}

### Vec markersize

You can scale x and y dimension of markers separately by passing a `Vec`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
ax = Axis(f[1, 1])

scales = range(0.5, 1.5, length = 10)

for (i, sx) in enumerate(scales)
    for (j, sy) in enumerate(scales)
        scatter!(ax, Point2f(i, j),
            marker = '✈',
            markersize = 30 .* Vec2f(sx, sy),
            color = :black)
    end
end

f
```
\end{examplefigure}

### Marker space

By default marker sizes are given in pixel units. You can change this by adjusting `markerspace`. For example, you can have a marker scaled in data units by setting `markerspace = :data`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
ax = Axis(f[1, 1])
limits!(ax, -10, 10, -10, 10)

scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = :data,
    marker = '✈', label = "markerspace = :data")
scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = :pixel,
    marker = '✈', label = "markerspace = :pixel")

axislegend(ax)

f
```
\end{examplefigure}

### Airport locations example

\begin{examplefigure}{}
```julia
using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide


a = readdlm(assetpath("airportlocations.csv"))

scatter(a[1:50:end, :], marker = '✈',
    markersize = 20, color = :black)
```
\end{examplefigure}
