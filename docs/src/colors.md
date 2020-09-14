# Colors

`Makie` has support for you to color your plots however you want to. You can manipulate the color of a plot by using the `color` keyword, and change the colormap by using the `colormap` keyword.

## Colors

For line plots, you can provide a single color or symbol that will color the entire line;
or, you can provide an array of values that map to colors using a colormap.

Any color symbol supported by [Colors.jl](https://github.com/JuliaGraphics/Colors.jl) is supported, check out their page on [named colors](https://juliagraphics.github.io/Colors.jl/latest/namedcolors.html) to see what you can get away with! You can also pass RGB or RGBA values.

## Colormaps

Colormaps are mappings of values to colors. You can supply the coloring values using the `color` keyword argument, and the colormap will automatically be adjusted to fit those values. THe default colormap is `viridis`, which looks like this:

![Viridis colormap](../assets/viridis.png)

You can copy this code and substitute `cmap` with any `Colormap` to show the colormap.

`Makie` supports multiple colormap libraries. Currently, support for colormaps provided by `PlotUtils` is inbuilt, meaning that any colormap symbol that works with Plots will also work with Makie. Colormaps from the `ColorSchemes` package can be used by `colormap = ColorSchemes.<name of colormap>.colors`. Similarly, colormaps from the `PerceptualColourMaps` package (which is a superset of the `colorcet` library) can be used by `colormap = PerceptualColourMaps.cgrad("<name of colormap>")`. In principle, any Array of `RGB` values can be used as a colormap.

### Builtins

Makie relies on [PlotUtils](https://github.com/JuliaPlots/PlotUtils.jl) for colormap support, so all of Plots' colormap features are supported here. There are many ways of specifying a colormap:

- You can pass a `Symbol` or `String` corresponding to a colormap name.
- You can pass a `Vector{Colorant}` (which can be anything that `Colors.jl` can parse to a color).
- You can pass the result of calling the `cgrad(colors, [values]; categorical, scale, rev, alpha)` function. This allows you to customize your colormap in many ways; see the documentation (by `?cgrad`) for more detail on the available options.

Colormaps can be reversed by `Reverse(:<gradient_name>)`. The `colorrange::NTuple{2,Number}` attribute can be used to define the data values that correspond with the ends of the colormap.

See [Colormap reference](@ref) for a table enumerating all available colormaps.

## Color legends

To show the colormap and its scaling, you can use a color legend. Color legends can be automatically produced by the `colorlegend` function, to which a Plot object must be passed. Its range and the colormap it shows can also be manually altered, as can many of its attributes.

To simply produce a color legend and plot it to the left of the original plot, you can produce a colorlegend and `vbox` it.

```@example
using Makie
using ColorSchemes      # colormaps galore

t = range(0, stop=1, length=500) # time steps

θ = (6π) .* t    # angles

x = t .* cos.(θ) # x coords of spiral
y = t .* sin.(θ) # y coords of spiral

p1 = lines(
    x,
    y,
    color = t,
    colormap = ColorSchemes.magma.colors,
    linewidth=8)

cm = colorlegend(
    p1[end],             # access the plot of Scene p1
    raw = true,          # without axes or grid
    camera = campixel!,  # gives a concrete bounding box in pixels
                            # so that the `vbox` gives you the right size
    width = (            # make the colorlegend longer so it looks nicer
        30,              # the width
        540              # the height
    )
    )

scene_final = vbox(p1, cm) # put the colorlegend and the plot together in a `vbox`

```

## Colormap reference
