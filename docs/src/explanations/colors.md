# Colors

There are multiple ways to specify colors in Makie.
Most plot objects allow passing an array as the `color` attribute, where there must be as many color elements as there are visual elements (scatter markers, line segments, polygons, etc.).
Alternatively, one can pass a single color element which is applied to all visual elements at once.

When passing an array of numbers or a single number, the values are converted to colors using the `colormap` and `colorrange` attributes.
By default, the `colorrange` spans the range of the color values, but it can be fixed manually as well.
For example, this can be useful for picking categorical colors.
The number `1` will pick the first and the number `2` the second color from the 10-color categorical map `:tab10`, for example, if the `colorrange` is set to `(1, 10)`.

`NaN` values are usually displayed with `:transparent` color, so they are invisible.
This can be changed with the attribute `nan_color`.

If values exceed the `colorrange` at the low or high end, by default the start or end color of the map is picked, unless the `lowclip` and `highclip` attributes are set to some other color.

## Alpha or Opacity

You can use `alpha` keyword in most Makie Plots.

Alternatively, one can make partially transparent colors or colormaps by passing a tuple `(color, alpha)` to the color/colormap attribute.

## Textures, Patterns and MatCaps

Some plot types (e.g. mesh, surface, ...) allow you to sample colors from an image.
The sampling can happen based on texture coordinates (uv coordinates), pixel coordinates or normals.

The first case is used when an image `Matrix` is passed directly as the `color` attribute.
Note that texture coordinates need to be available to get a well defined result.

The second case is used when a `Makie.AbstractPattern` is passed as the `color`.
This is typically used for hatching.
For example a hatching pattern with diagonal lines can be set with `color = Pattern('/')`.
More generally, you can define a line pattern with `Makie.LinePattern()` or use an image as a pattern with `Pattern(image)`.

The last case is used when an image is passed with the `matcap` attribute.
The image is then interpreted as going from (-1, 1) to (1, 1) so that normals can be mapped to it.
The (0,0,1) direction of the normal is facing the camera/viewer.

```@figure backend=GLMakie
using GLMakie, FileIO

f = Figure()

mesh(f[1, 1], Rect2f(0,0,1,1), color = load(Makie.assetpath("cow.png")), shading = NoShading, axis=(title ="texture",))
mesh(f[2, 1], Rect2f(0,0,1,1), color = Pattern('/'), shading = NoShading, axis=(title ="Pattern",))

hidedecorations!.(f.content)

catmesh = FileIO.load(assetpath("cat.obj"))
texture = FileIO.load(assetpath("diffusemap.png"))
matcap = FileIO.load(Base.download("https://raw.githubusercontent.com/nidorx/matcaps/master/1024/E6BF3C_5A4719_977726_FCFC82.png"))

Label(f[1, 2][1, 1], "texture 3D", tellwidth = false)
a, p = mesh(f[1, 2][2, 1], catmesh, color = texture, axis = (show_axis = false, ))
Label(f[2, 2][1, 1], "matcap", tellwidth = false)
mesh(f[2, 2][2, 1], catmesh, matcap = matcap, shading = NoShading, axis = (show_axis = false, ))

f
```

## Cheat Sheet

Here's a little cheat sheet showing common color specifications:

```@figure
using Makie.Colors

theme = Attributes(
    Scatter = (; markersize = 40),
    Text = (; align = (:center, :bottom), offset = (0, 30))
)

with_theme(theme) do

    f = Figure(size = (800, 1200))
    ax = Axis(f[1, 1], xautolimitmargin = (0.2, 0.2), yautolimitmargin = (0.1, 0.1))
    hidedecorations!(ax)
    hidespines!(ax)

    scatter!(ax, 1, 1, color = :red)
    text!(ax, 1, 1, text = ":red")

    scatter!(ax, 2, 1, color = (:red, 0.5))
    text!(ax, 2, 1, text = "(:red, 0.5)")

    scatter!(ax, 3, 1, color = RGBf(0.5, 0.2, 0.8))
    text!(ax, 3, 1, text = "RGBf(0.5, 0.2, 0.8)")

    scatter!(ax, 4, 1, color = RGBAf(0.5, 0.2, 0.8, 0.5))
    text!(ax, 4, 1, text = "RGBAf(0.5, 0.2, 0.8, 0.5)")

    scatter!(ax, 1, 0, color = Colors.HSV(40, 30, 60))
    text!(ax, 1, 0, text = "Colors.HSV(40, 30, 60)")

    scatter!(ax, 2, 0, color = 1, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 2, 0, text = "color = 1\ncolormap = :tab10\ncolorrange = (1, 10)")

    scatter!(ax, 3, 0, color = 2, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 3, 0, text = "color = 2\ncolormap = :tab10\ncolorrange = (1, 10)")

    scatter!(ax, 4, 0, color = 3, colormap = :tab10, colorrange = (1, 10))
    text!(ax, 4, 0, text = "color = 3\ncolormap = :tab10\ncolorrange = (1, 10)")

    text!(ax, 2.5, -1, text = "color = 1:10\ncolormap = :viridis\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-1, 10), color = 1:10, colormap = :viridis)

    text!(ax, 2.5, -2, text = "color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10]\ncolormap = :viridis\ncolorrange = (2, 9)")
    scatter!(ax, range(1, 4, length = 10), fill(-2, 10), color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10], colormap = :viridis, colorrange = (2, 9))

    text!(ax, 2.5, -3, text = "color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10]\ncolormap = :viridis\ncolorrange = (2, 9)\nnan_color = :red, highclip = :magenta, lowclip = :cyan")
    scatter!(ax, range(1, 4, length = 10), fill(-3, 10), color = [1, 2, 3, 4, NaN, 6, 7, 8, 9, 10], colormap = :viridis, colorrange = (2, 9), nan_color = :red, highclip = :magenta, lowclip = :cyan)

    text!(ax, 2.5, -4, text = "color = HSV.(range(0, 360, 10), 50, 50)")
    scatter!(ax, range(1, 4, length = 10), fill(-4, 10), color = HSV.(range(0, 360, 10), 50, 50))

    text!(ax, 2.5, -5, text = "color = 1:10\ncolormap = (:viridis, 0.5)\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-5, 10), color = 1:10, colormap = (:viridis, 0.5))

    text!(ax, 2.5, -6, text = "color = 1:10\ncolormap = [:red, :orange, :brown]\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-6, 10), color = 1:10, colormap = [:red, :orange, :brown])

    text!(ax, 2.5, -7, text = "color = 1:10\ncolormap = Reverse(:viridis)\ncolorrange = automatic")
    scatter!(ax, range(1, 4, length = 10), fill(-7, 10), color = 1:10, colormap = Reverse(:viridis))

    f
end
```

## Named colors
Named colors in Makie.jl (e.g., `:blue`) are parsed using [Colors.jl](https://juliagraphics.github.io/Colors.jl/stable/constructionandconversion/#Color-Parsing) and thus have a large array of possibilities under CSS specifications. You can find a plotted table of all possible names [in this page](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/).

## Colormaps

Makie's default categorical color palette used for cycling is a reordered version of the one presented in [Wong (2011)](https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106).

Makie's default continuous color map is `:viridis` which is a perceptually uniform colormap originally developed for matplotlib.

```@figure
f, ax, sc = scatter(1:7, fill(1, 7), color = Makie.wong_colors(), markersize = 50)
hidedecorations!(ax)
hidespines!(ax)
text!(ax, 4, 1, text = "Makie.wong_colors()",
    align = (:center, :bottom), offset = (0, 30))
scatter!(range(1, 7, 20), fill(0, 20), color = 1:20, markersize = 50)
text!(ax, 4, 0, text = ":viridis",
    align = (:center, :bottom), offset = (0, 30))
ylims!(ax, -1, 2)
f
```

The following is a list of all the colormaps accessible via a `Symbol` in Makie which are defined in ColorSchemes.jl:

### misc

These colorschemes are not defined or provide different colors in ColorSchemes.jl
They are kept for compatibility with the old behaviour of Makie, before v0.10.

```@example colors
using Markdown # hide
using Makie.PlotUtils # hide
Core.include(@__MODULE__, "colormap_generation.jl") # hide
ColorTable([:default; sort(collect(keys(PlotUtils.MISC_COLORSCHEMES)))]) # hide
```

### cmocean

```@example colors
getkeys(colorscheme) = sort([k for (k, v) in PlotUtils.ColorSchemes.colorschemes if occursin(colorscheme, v.category)]) # hide
ColorTable(getkeys("cmocean")) # hide
```

### scientific

```@example colors
ColorTable(getkeys("scientific")) # hide
```

### matplotlib

```@example colors
ColorTable(getkeys("matplotlib")) # hide
```

### colorbrewer

```@example colors
ColorTable(getkeys("colorbrewer")) # hide
```

### gnuplot

```@example colors
ColorTable(getkeys("gnuplot")) # hide
```

### colorcet

```@example colors
ColorTable(getkeys("colorcet")) # hide
```

### seaborn

```@example colors
ColorTable(getkeys("seaborn")) # hide
```

### general

```@example colors
ColorTable(getkeys("general")) # hide
```

