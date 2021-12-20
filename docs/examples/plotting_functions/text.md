# text

{{doc text}}

## Attributes

### Generic

- `visible::Bool = true` sets whether the plot will be rendered or not.
- `overdraw::Bool = false` sets whether the plot will draw over other plots. This specifically means ignoring depth checks in GL backends.
- `transparency::Bool = false` adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.
- `fxaa::Bool = false` adjusts whether the plot is rendered with fxaa (anti aliasing). Note that some plots already include anti aliasing through different means.
- `inspectable::Bool = true` sets whether this plot should be seen by `DataInspector`.
- `depth_shift::Float32 = 0f0` adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `0 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw). 
- `model::Makie.Mat4f` sets a model matrix for the plot. This replaces adjustments made with `translate!`, `rotate!` and `scale!`.
- `color::Union{Symbol, <:Colorant, Tuple{Symbol, <:AbstractFloat}, Tuple{<:Colorant, <:AbstractFloat}}` sets the color of the plot. Usually the color can also be given per plot element (e.g. scattered marker, point in line, vertex in mesh, etc) by passing a `Vector` of colors.

### Other

- `align::Tuple{Union{Symbol, Real}, Union{Symbol, Real}} = (:left, :bottom)` sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.
- `font::Union{String, Vector{String}} = "Dejavu Sans"` sets the font for the string or each character.
- `justification::Union{Real, Symbol} = automatic` sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.
- `position::Union{Point2f, Point3f} = Point2f(0)` sets an anchor position for text. Can also be a `Vector` of positions.
- `rotation::Union{Real, Quaternion}` rotates text around the given position.
- `textsize::Union{Real, Vec2f}` sets the size of each character.
- `space::Symbol = :screen` sets the space in which `textsize` acts. Can be `:screen` (pixel space) or `:data` (world space).
- `strokewidth::Real = 0` sets the width of the outline around a marker.
- `strokecolor::Union{Symbol, <:Colorant} = :black` sets the color of the outline around a marker.
- `glowwidth::Real = 0` sets the size of a glow effect around the marker.
- `glowcolor::Union{Symbol, <:Colorant} = (:black, 0)` sets the color of the glow effect.


## Screen space text

By default, text is drawn in screen space (`space = :screen`).
The text anchor is given in data coordinates, but the size of the glyphs is independent of data scaling.
The boundingbox of the text will include every data point or every text anchor point.
This also means that `autolimits!` might cut off your text, because the glyphs don't have a meaningful size in data coordinates (the size is independent of zoom level), and you have to take some care to manually place the text or set data limits such that it is fully visible.

You can either plot one string with one position, or a vector of strings with a vector of positions.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

Axis(f[1, 1], aspect = DataAspect(), backgroundcolor = :gray50)

scatter!(Point2f(0, 0))
text!("center", position = (0, 0), align = (:center, :center))

circlepoints = [(cos(a), sin(a)) for a in LinRange(0, 2pi, 16)[1:end-1]]
scatter!(circlepoints)
text!(
    "this is point " .* string.(1:15),
    position = circlepoints,
    rotation = LinRange(0, 2pi, 16)[1:end-1],
    align = (:right, :baseline),
    color = cgrad(:Spectral)[LinRange(0, 1, 15)]
)

f
```
\end{examplefigure}

## Data space text

For text whose dimensions are meaningful in data space, set `space = :data`.
This means that the boundingbox of the text in data coordinates will include every glyph.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
LScene(f[1, 1])

text!(
    fill("Makie", 7),
    rotation = [i / 7 * 1.5pi for i in 1:7],
    position = [Point3f(0, 0, i/2) for i in 1:7],
    color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
    align = (:left, :baseline),
    textsize = 1,
    space = :data
)

f
```
\end{examplefigure}

## Justification

By default, justification of multiline text follows alignment.
Text that is left aligned is also left justified.
You can override this with the `justification` attribute.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

scene = Scene(camera = campixel!, resolution = (800, 800))

points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3]
scatter!(scene, points, marker = :circle, markersize = 10px)

symbols = (:left, :center, :right)

for ((justification, halign), point) in zip(Iterators.product(symbols, symbols), points)

    t = text!(scene, "a\nshort\nparagraph",
        color = (:black, 0.5),
        position = point,
        align = (halign, :center),
        justification = justification)

    bb = boundingbox(t)
    wireframe!(scene, bb, color = (:red, 0.2))
end

for (p, al) in zip(points[3:3:end], (:left, :center, :right))
    text!(scene, "align :" * string(al), position = p .+ (0, 80),
        align = (:center, :baseline))
end

for (p, al) in zip(points[7:9], (:left, :center, :right))
    text!(scene, "justification\n:" * string(al), position = p .+ (80, 0),
        align = (:center, :top), rotation = pi/2)
end

scene
```
\end{examplefigure}

## Offset

The offset attribute can be used to shift text away from its position.
This is especially useful with `space = :screen`, for example to place text together with barplots.
You can specify the end of the barplots in data coordinates, and then offset the text a little bit to the left.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()

horsepower = [52, 78, 80, 112, 140]
cars = ["Kia", "Mini", "Honda", "Mercedes", "Ferrari"]

ax = Axis(f[1, 1], xlabel = "horse power")
tightlimits!(ax, Left())
hideydecorations!(ax)

barplot!(horsepower, direction = :x)
text!(cars, position = Point.(horsepower, 1:5), align = (:right, :center),
    offset = (-20, 0), color = :white)

f
```
\end{examplefigure}

## MathTeX

Makie can render LaTeX strings from the LaTeXStrings.jl package using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl/).
For example, you can pass L-strings as labels to the legend.

\begin{examplefigure}{}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure()
ax = Axis(f[1, 1])

lines!(0..10, x -> sin(3x) / (cos(x) + 2),
    label = L"\frac{\sin(3x)}{\cos(x) + 2}")
lines!(0..10, x -> sin(x^2) / (cos(sqrt(x)) + 2),
    label = L"\frac{\sin(x^2)}{\cos(\sqrt{x}) + 2}")

Legend(f[1, 2], ax)

f
```
\end{examplefigure}
