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

There are no `alpha` or `opacity` keywords in Makie.
Instead, one can make partially transparent colors or colormaps by using a tuple `(color, alpha)`.

## Cheat Sheet

Here's a little cheat sheet showing common color specifications:

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide
using Makie.Colors

theme = Attributes(
    Scatter = (; markersize = 40),
    Text = (; align = (:center, :bottom), offset = (0, 30))
)

with_theme(theme) do

    f = Figure(resolution = (800, 1200))
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
\end{examplefigure}

## Named colors
Named colors in Makie.jl (e.g., `:blue`) are parsed using [Colors.jl](https://juliagraphics.github.io/Colors.jl/stable/constructionandconversion/#Color-Parsing) and thus have a large array of possibilities under CSS specifications. You can find a plotted table of all possible names [in this page](https://juliagraphics.github.io/Colors.jl/stable/namedcolors/).

## Colormaps

Makie's default categorical color palette used for cycling is a reordered version of the one presented in [Wong (2011)](https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106).

Makie's default continuous color map is `:viridis` which is a perceptually uniform colormap originally developed for matplotlib.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

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
\end{examplefigure}

The following is a list of all the colormaps accessible via a `Symbol` in Makie which are defined in ColorSchemes.jl:

{{colorschemes}}
