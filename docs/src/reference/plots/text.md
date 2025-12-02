# text

```@shortdocs; canonical=false
text
```


## Marker space pixel

By default, text is drawn with `markerspace = :pixel`, which means that the text size is interpreted in pixel space.
(The space of the text position is determined by the `space` attribute instead.)

The boundingbox of text with `markerspace = :pixel` will include every data point or every text anchor point but not the text itself, because its extent depends on the current projection of the axis it is in.
This also means that `autolimits!` might cut off your text, because the glyphs don't have a meaningful size in data coordinates (the size is independent of zoom level), and you have to take some care to manually place the text or set data limits such that it is fully visible.

You can either plot one string with one position, or a vector of strings with a vector of positions.

```@figure
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

## Marker space data

For text whose dimensions are meaningful in data space, set `markerspace = :data`.
This means that the boundingbox of the text in data coordinates will include every glyph.

```@figure
f = Figure()
LScene(f[1, 1])

text!(
    [Point3f(0, 0, i/2) for i in 1:7],
    text = fill("Makie", 7),
    rotation = [i / 7 * 1.5pi for i in 1:7],
    color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
    align = (:left, :baseline),
    fontsize = 1,
    markerspace = :data
)

f
```

## Alignment

Text can be aligned with the horizontal alignments `:left`, `:center`, `:right` and the vertical alignments `:bottom`, `:baseline`, `:center`, `:top`.

```@figure
aligns = [(h, v) for v in [:bottom, :baseline, :center, :top]
                 for h in [:left, :center, :right]]
x = repeat(1:3, 4)
y = repeat(1:4, inner = 3)
scatter(x, y)
text!(x, y, text = string.(aligns), align = aligns)
current_figure()
```

## Justification

By default, justification of multiline text follows alignment.
Text that is left aligned is also left justified.
You can override this with the `justification` attribute.

```@figure
scene = Scene(camera = campixel!, size = (800, 800))

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

    bb = boundingbox(t, :pixel)
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

## Offset

The offset attribute can be used to shift text away from its position.
This is especially useful with `space = :pixel`, for example to place text together with barplots.
You can specify the end of the barplots in data coordinates, and then offset the text a little bit to the left.

```@figure
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

## Relative space

The default setting of `text` is `space = :data`, which means the final position depends on the axis limits and scaling.
However, it can be useful to place text relative to the axis itself, independent of scaling.
With `space = :relative`, the position `(0, 0)` refers to the lower left corner and `(1, 1)` the upper right of the `Scene` that a plot object is in (for an `Axis` that is equivalent to the plotting area, which is implemented using a `Scene`).

A common scenario is to place labels within axes:

```@figure
f = Figure()

ax1 = Axis(f[1, 1], limits = (1, 2, 3, 4))
ax2 = Axis(f[1, 2], width = 300, limits = (5, 6, 7, 8))
ax3 = Axis(f[2, 1:2], limits = (9, 10, 11, 12))

for (ax, label) in zip([ax1, ax2, ax3], ["A", "B", "C"])
    text!(
        ax, 0, 1,
        text = label,
        font = :bold,
        align = (:left, :top),
        offset = (4, -2),
        space = :relative,
        fontsize = 24
    )
end

f
```

## MathTeX

Makie can render LaTeX strings from the LaTeXStrings.jl package using [MathTeXEngine.jl](https://github.com/Kolaru/MathTeXEngine.jl/).

```@figure
lines(0.5..20, x -> sin(x) / sqrt(x), color = :black)
text!(7, 0.38, text = L"\frac{\sin(x)}{\sqrt{x}}", color = :black)
current_figure()
```


You can also pass L-strings to many objects that use text, for example as labels in the legend.

```@figure
f = Figure()
ax = Axis(f[1, 1])

lines!(0..10, x -> sin(3x) / (cos(x) + 2),
    label = L"\frac{\sin(3x)}{\cos(x) + 2}")
lines!(0..10, x -> sin(x^2) / (cos(sqrt(x)) + 2),
    label = L"\frac{\sin(x^2)}{\cos(\sqrt{x}) + 2}")

Legend(f[1, 2], ax)

f
```

## Rich text

With rich text, you can conveniently plot text whose parts have different colors or fonts, and you can position sections as subscripts and superscripts.
You can create such rich text objects using the functions `rich`, `superscript`, `subscript`, `subsup` and `left_subsup`, all of which create `RichText` objects.

Each of these functions takes a variable number of arguments (except `subsup` and `left_subsup` which take exactly two arguments), each of which can be a `String` or `RichText`.
Each can also take keyword arguments such as `color` or `font`, to set these attributes for the given part.
The top-level settings for font, color, etc. are taken from the `text` attributes as usual.

```@figure
f = Figure(fontsize = 30)
Label(
    f[1, 1],
    rich(
        "H", subscript("2"), "O is the formula for ",
        rich("water", color = :cornflowerblue, font = :italic)
    )
)

str = "A BEAUTIFUL RAINBOW"
rainbow = cgrad(:rainbow, length(str), categorical = true)
fontsizes = 30 .+ 10 .* sin.(range(0, 3pi, length = length(str)))

rainbow_chars = map(enumerate(str)) do (i, c)
    rich("$c", color = rainbow[i], fontsize = fontsizes[i])
end

Label(f[2, 1], rich(rainbow_chars...), font = :bold)

Label(f[3, 1], rich("Chemists use notations like ", left_subsup("92", "238"), "U or PO", subsup("4", "3−")))

f
```

### Tweaking offsets

Sometimes, when using regular and italic fonts next to each other, the gaps between glyphs are too narrow or too wide.
You can use the `offset` value for rich text to shift glyphs by an amount proportional to the fontsize.


```@figure
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

## Attributes

```@attrdocs
Text
```
