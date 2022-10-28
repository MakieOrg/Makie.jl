# text

{{doc text}}

## Pixel space text

By default, text is drawn in pixel space (`space = :pixel`).
The text anchor is given in data coordinates, but the size of the glyphs is independent of data scaling.
The boundingbox of the text will include every data point or every text anchor point.
This also means that `autolimits!` might cut off your text, because the glyphs don't have a meaningful size in data coordinates (the size is independent of zoom level), and you have to take some care to manually place the text or set data limits such that it is fully visible.

You can either plot one string with one position, or a vector of strings with a vector of positions.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

Axis(f[1, 1], aspect = DataAspect(), backgroundcolor = :gray50)

scatter!(Point2f(0, 0))
text!(0, 0, text = "center", align = (:center, :center))

circlepoints = [(cos(a), sin(a)) for a in LinRange(0, 2pi, 16)[1:end-1]]
scatter!(circlepoints)
text!(
    circlepoints,
    text = "this is point " .* string.(1:15),
    rotation = LinRange(0, 2pi, 16)[1:end-1],
    align = (:right, :baseline),
    color = cgrad(:Spectral)[LinRange(0, 1, 15)]
)

f
```
\end{examplefigure}

## Data space text

For text whose dimensions are meaningful in data space, set `markerspace = :data`.
This means that the boundingbox of the text in data coordinates will include every glyph.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
LScene(f[1, 1])

text!(
    [Point3f(0, 0, i/2) for i in 1:7],
    text = fill("Makie", 7),
    rotation = [i / 7 * 1.5pi for i in 1:7],
    color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
    align = (:left, :baseline),
    textsize = 1,
    markerspace = :data
)

f
```
\end{examplefigure}

## Alignment

Text can be aligned with the horizontal alignments `:left`, `:center`, `:right` and the vertical alignments `:bottom`, `:baseline`, `:center`, `:top`.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


aligns = [(h, v) for v in [:bottom, :baseline, :center, :top]
                 for h in [:left, :center, :right]]
x = repeat(1:3, 4)
y = repeat(1:4, inner = 3)
scatter(x, y)
text!(x, y, text = string.(aligns), align = aligns)
current_figure()
```
\end{examplefigure}

## Justification

By default, justification of multiline text follows alignment.
Text that is left aligned is also left justified.
You can override this with the `justification` attribute.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


scene = Scene(camera = campixel!, resolution = (800, 800))

points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3]
scatter!(scene, points, marker = :circle, markersize = 10px)

symbols = (:left, :center, :right)

for ((justification, halign), point) in zip(Iterators.product(symbols, symbols), points)

    t = text!(scene,
        point,
        text = "a\nshort\nparagraph",
        color = (:black, 0.5),
        align = (halign, :center),
        justification = justification)

    bb = boundingbox(t)
    wireframe!(scene, bb, color = (:red, 0.2))
end

for (p, al) in zip(points[3:3:end], (:left, :center, :right))
    text!(scene, p .+ (0, 80), text = "align :" * string(al),
        align = (:center, :baseline))
end

for (p, al) in zip(points[7:9], (:left, :center, :right))
    text!(scene, p .+ (80, 0), text = "justification\n:" * string(al),
        align = (:center, :top), rotation = pi/2)
end

scene
```
\end{examplefigure}

## Offset

The offset attribute can be used to shift text away from its position.
This is especially useful with `space = :pixel`, for example to place text together with barplots.
You can specify the end of the barplots in data coordinates, and then offset the text a little bit to the left.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


f = Figure()

horsepower = [52, 78, 80, 112, 140]
cars = ["Kia", "Mini", "Honda", "Mercedes", "Ferrari"]

ax = Axis(f[1, 1], xlabel = "horse power")
tightlimits!(ax, Left())
hideydecorations!(ax)

barplot!(horsepower, direction = :x)
text!(Point.(horsepower, 1:5), text = cars, align = (:right, :center),
    offset = (-20, 0), color = :white)

f
```
\end{examplefigure}

## MathTeX

Makie can render LaTeX strings from the LaTeXStrings.jl package using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl/).

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


lines(0.5..20, x -> sin(x) / sqrt(x), color = :black)
text!(7, 0.38, text = L"\frac{\sin(x)}{\sqrt{x}}", color = :black)
current_figure()
```
\end{examplefigure}


You can also pass L-strings to many objects that use text, for example as labels in the legend.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide


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

## Rich text

With rich text, you can conveniently plot text whose parts have different colors or fonts, and you can position sections as subscripts and superscripts.
You can create such rich text objects using the functions `rich`, `superscript` and `subscript`, all of which create `RichText` objects.

Each of these functions takes a variable number of arguments, each of which can be a `String` or `RichText`.
Each can also take keyword arguments such as `color` or `font`, to set these attributes for the given part.
The top-level settings for font, color, etc. are taken from the `text` attributes as usual.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(fontsize = 30)
Label(
    f[1, 1],
    rich(
        "H", subscript("2"), "O is the formula for ",
        rich("water", color = :cornflowerblue, font = :italic)
    )
)

str = "A beautiful rainbow"
rainbow = cgrad(:rainbow, length(str), categorical = true)
fontsizes = 30 .+ 10 .* sin.(range(0, 3pi, length = length(str)))

rainbow_chars = map(enumerate(str)) do (i, c)
    rich("$c", color = rainbow[i], fontsize = fontsizes[i])
end

Label(f[2, 1], rich(rainbow_chars...), font = :bold)

f
```
\end{examplefigure}

### Tweaking offsets

Sometimes, when using regular and italic fonts next to each other, the gaps between glyphs are too narrow or too wide.
You can use the `offset` value for rich text to shift glyphs by an amount proportional to the fontsize.


\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

f = Figure(fontsize = 30)
Label(
    f[1, 1],
    rich(
        "ITALIC",
        superscript("Regular without x offset", font = :regular),
        font = :italic
    )
)

Label(
    f[2, 1],
    rich(
        "ITALIC",
        superscript("Regular with x offset", font = :regular, offset = (0.15, 0)),
        font = :italic
    )
)

f
```
\end{examplefigure}