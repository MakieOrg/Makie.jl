# scatter

{{doc scatter}}

## Examples

### Using x and y vectors

Scatters can be constructed by passing a list of x and y coordinates.

\begin{examplefigure}{name = "basic_scatter", svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

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
Makie.inline!(true) # hide

xs = range(0, 10, length = 30)
ys = 0.5 .* sin.(xs)
points = Point2f.(xs, ys)

scatter(points, color = 1:30, markersize = range(5, 30, length = 30),
    colormap = :thermal)
```
\end{examplefigure}

### Available markers

As markers, you can use almost any unicode character.
Currently, such glyphs are picked from the `Dejavu Sans` font, because it offers a wide range of symbols.
There is also a number of markers that can be referred to as a symbol, so that it's not necessary to find out the respective unicode character.

The backslash character examples have to be tab-completed in the REPL or editor so they are converted into unicode.

!!! note
    The scatter markers have the same sizes that the glyphs in Dejavu Sans have. This means that they are not matched in size or area. Currently, Makie does not have the option to use area matched markers, and sometimes manual adjustment might be necessary to achieve a good visual result.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

markers_labels = [
    (:rect, ":rect"),
    (:star5, ":star5"),
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
    (:star8, ":star8"),
    (:vline, ":vline"),
    (:hline, ":hline"),
    (:x, ":x"),
    (:+, ":+"),
    (:circle, ":circle"),
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

for (i, (marker, label)) in enumerate(markers_labels)
    p = Point2f(fldmod1(i, 6)...)

    scatter!(p, marker = marker, markersize = 20, color = :black)
    text!(label, position = p, color = :gray70, offset = (0, 20),
        align = (:center, :bottom))
end

f
```
\end{examplefigure}

### Bezier path markers

You can also use bezier paths as markers.
A bezier path marker should fit into the square from -1 to 1 in x and y to be comparable in size to other default markers and to be correctly rendered by GLMakie, because here the path has to be rendered to a bitmap first .
In CairoMakie, paths are drawn as they are without an intermediate bitmap, so every size is possible.

A `BezierPath` contains a vector of path commands, these are `MoveTo`, `LineTo`, `CurveTo`, `EllipticalArc` and `ClosePath`.

Here is an example with a simple arrow that is centered on its tip, built from path elements.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

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

Paths can have holes, just start a new subpath with `MoveTo` that is inside the main path.
The holes have to be in clockwise direction if the outside is in anti-clockwise direction, or vice versa.
For example, a circle with a square cut out can be made by one `EllipticalArc` that goes anticlockwise, and a square inside that goes clockwise:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

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

You can also create a bezier path from an [svg path specification string](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/d#path_commands).
You can automatically resize the path to the -1 to 1 square and flip the y-axis with the keywords `fit` and `yflip`.
Here's an example with an svg string that contains the bat symbol:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

batsymbol_string = "M96.84 141.998c-4.947-23.457-20.359-32.211-25.862-13.887-11.822-22.963-37.961-16.135-22.041 6.289-3.005-1.295-5.872-2.682-8.538-4.191-8.646-5.318-15.259-11.314-19.774-17.586-3.237-5.07-4.994-10.541-4.994-16.229 0-19.774 21.115-36.758 50.861-43.694.446-.078.909-.154 1.372-.231-22.657 30.039 9.386 50.985 15.258 24.645l2.528-24.367 5.086 6.52H103.205l5.07-6.52 2.543 24.367c5.842 26.278 37.746 5.502 15.414-24.429 29.777 6.951 50.891 23.936 50.891 43.709 0 15.136-12.406 28.651-31.609 37.267 14.842-21.822-10.867-28.266-22.549-5.549-5.502-18.325-21.147-9.341-26.125 13.886z"

batsymbol = BezierPath(batsymbol_string, fit = true, flipy = true)

scatter(1:10, marker = batsymbol, markersize = 50, color = :black)
```
\end{examplefigure}

### Marker rotation

Markers can be rotated using the `rotations` attribute, which also allows to pass a vector.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

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
Makie.inline!(true) # hide

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

By default, marker sizes do not scale relative to the data limits.
You can enable this by setting `markerspace = SceneSpace()`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
ax = Axis(f[1, 1])
limits!(ax, -10, 10, -10, 10)

scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = SceneSpace(),
    marker = '✈', label = "markerspace = SceneSpace()")
scatter!(ax, Point2f(0, 0), markersize = 20, markerspace = Pixel,
    marker = '✈', label = "markerspace = Pixel")

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
Makie.inline!(true) # hide

a = readdlm(assetpath("airportlocations.csv"))

scatter(a[1:50:end, :], marker = '✈',
    markersize = 20, color = :black)
```
\end{examplefigure}