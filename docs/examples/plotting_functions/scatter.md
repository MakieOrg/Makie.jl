# scatter

{{doc scatter}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti-aliasing). Note that scatter plots already include a different form of anti-aliasing when plotting non-image markers.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw). 
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color::Union{Symbol, <:Colorant, Tuple{Symbol, <:AbstractFloat}, Tuple{<:Colorant, <:AbstractFloat}, Real}` sets the color of the plot. Usually the color can also be given per plot element (e.g. scattered marker, point in line, vertex in mesh, etc) by passing a `Vector` of colors. If the color is numeric it will be used to sample the `colormap`. In some cases a `Matrix{<: Colorant}` can be passed to be used as a texture.
- `colormap::Union{Symbol, Vector{<:Colorant}} = :viridis` sets the colormap that is sampled for numeric `color`s.
- `colorrange::Tuple{<:Real, <:Real}` sets the values representing the start and end points of `colormap`.
- `nan_color::Union{Symbol, <:Colorant} = RGBAf(0,0,0,0)` sets a replacement color for `color = NaN`.

### Other

- `cycle::Vector{Symbol} = [:color]` sets which attributes to cycle when creating multiple plots.
- `marker::Union{Symbol, Char, Matrix{<:Colorant}}` sets the scatter marker.
- `markersize::Union{<:Real, Vec2f} = 9` sets the size of the marker.
- `markerspace::Union{Type{Pixel}, Type{SceneSpace}} = Pixel` sets the space in which `markersize` is given. (I.e. `Pixel` units or `SceneSpace` (data) units)
- `strokewidth::Real = 0` sets the width of the outline around a marker.
- `strokecolor::Union{Symbol, <:Colorant} = :black` sets the color of the outline around a marker.
- `glowwidth::Real = 0` sets the size of a glow effect around the marker.
- `glowcolor::Union{Symbol, <:Colorant} = (:black, 0)` sets the color of the glow effect.
- `rotations::Union{Real, Billboard, Quaternion} = Billboard(0f0)` sets the rotation of the marker. A `Billboard` rotation is always around the depth axis.

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