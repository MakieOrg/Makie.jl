# [Colorbar](@id Colorbar_page)

A Colorbar needs a colormap and a tuple of low/high limits.
The colormap's axis will then span from low to high along the visual representation of the colormap.
You can set ticks in a similar way to `Axis`.

Here's how you can create Colorbars manually.

```@figure

fig = Figure()

Axis(fig[1, 1])

# vertical colorbars
Colorbar(fig[1, 2], limits = (0, 10), colormap = :viridis,
    flipaxis = false)
Colorbar(fig[1, 3], limits = (0, 5),
    colormap = cgrad(:Spectral, 5, categorical = true), size = 25)
Colorbar(fig[1, 4], limits = (-1, 1), colormap = :heat,
    highclip = :cyan, lowclip = :red, label = "Temperature")

# horizontal colorbars
Colorbar(fig[2, 1], limits = (0, 10), colormap = :viridis,
    vertical = false)
Colorbar(fig[3, 1], limits = (0, 5), size = 25,
    colormap = cgrad(:Spectral, 5, categorical = true), vertical = false)
Colorbar(fig[4, 1], limits = (-1, 1), colormap = :heat,
    label = "Temperature", vertical = false, flipaxis = false,
    highclip = :cyan, lowclip = :red)

fig
```

If you pass a `plotobject`, a `heatmap` or `contourf`, the Colorbar is set up automatically such that it tracks these objects' relevant attributes like `colormap`, `colorrange`, `highclip` and `lowclip`. If you want to adjust these attributes afterwards, change them in the plot object, otherwise the Colorbar and the plot object will go out of sync.

```@figure

xs = LinRange(0, 20, 50)
ys = LinRange(0, 15, 50)
zs = [cos(x) * sin(y) for x in xs, y in ys]

fig = Figure()

ax, hm = heatmap(fig[1, 1][1, 1], xs, ys, zs)
Colorbar(fig[1, 1][1, 2], hm)

ax, hm = heatmap(fig[1, 2][1, 1], xs, ys, zs, colormap = :grays,
    colorrange = (-0.75, 0.75), highclip = :red, lowclip = :blue)
Colorbar(fig[1, 2][1, 2], hm)

ax, hm = contourf(fig[2, 1][1, 1], xs, ys, zs,
    levels = -1:0.25:1, colormap = :heat)
Colorbar(fig[2, 1][1, 2], hm, ticks = -1:0.25:1)

ax, hm = contourf(fig[2, 2][1, 1], xs, ys, zs,
    colormap = :Spectral, levels = [-1, -0.5, -0.25, 0, 0.25, 0.5, 1])
Colorbar(fig[2, 2][1, 2], hm, ticks = -1:0.25:1)

fig
```


### Experimental Categorical support

!!! warning
    This feature might change outside breaking releases, since the API is not yet finalized

You can create a true categorical map with good default ticks, by wrapping a colormap into `Makie.Categorical(cmap)`:

```@figure
fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis))
Colorbar(fig[1, 2], pl)
fig
```


We can't use `cgrad(...; categorical=true)` for this, since it has an ambiguous meaning for true categorical values.

### Interfacing with Recipes

To create a Colorbar from a plot various colormapping attributes need to be extracted.
This is done by the `Makie.extract_colormap(plot)` function.
The default implementation will error if the plot has multiple child plots and otherwise call `extract_colormap(only(plot.plots))`.
This continues until a method explicitly extracts the `color`, `colormap`, `colorrange`, `colorscale`, `lowclip`, `highclip` and (optional) `dim_convert4` attributes.
These will then be used to construct the Colorbar.

A custom method of `Makie.extract_colormap` is necessary if a plot has multiple child plots and may be necessary if it processes colormapping directly.
The former case just requires identifying the relevant child plot:

```julia
Makie.extract_colormap(plot::MyPlot) = Makie.extract_colormap(plot.plots[2])
```

The latter case may require modifying/replacing some attributes extracted from a child plot or directly creating a `Dict{Symbol, Any}` containing the colormapping attributes relevant to a plot.

For example `MyPlot` may resolve color values (i.e. Real values) to colors (e.g. RGBA) within the recipe.
Those colors are then passed on to one or more child plots without the already used colormapping attributes.
In this case the attributes need to be extracted for `MyPlot`:

```julia
function Makie.extract_colormap(plot::MyPlot)
    # This should include color, colormap, colorrange, colorscale, lowclip and highclip
    return Dict{Symbol, Any}(
        :color => plot.values,
        :colormap => plot.colormap,
        :colorrange => plot.limits,
        # If a plot does not consider a colormapping attribute it should be set
        # to a reasonable value here. E.g. if MyPlot does not consider colorscale
        # it should be identity
        :colorscale => identity,
        # Note that the lowclip/highclip extensions markers are hidden when
        # lowclip/highclip = automatic and visible if lowclip/highclip is a color.
        # For some plots it may make sense to set them to `automatic` explicitly
        :lowclip => plot.lowclip,
        :highclip => plot.highclip,
    )
end
```

Attributes with the correct name (same as the key) can also be extracted automatically with `Makie.add_default_colorbar_attributes(attr, plot)`, or by implementing `Makie._extratc_colormap` instead:

```julia
# This keeps the default `extract_colormap` method which adds undefined entries
# using attributes from MyPlot.
function Makie._extract_colormap(plot::MyPlot)
    return Dict{Symbol, Any}(
        :color => plot.values,
        :colorrange => plot.limits,
        :colorscale => identity,
    )
end
```

It is also often useful to extract attributes from a child plot and then replace incorrect entries.
For example, if `MyPlot` passes down all the colormapping attributes we could extract them from a child plot and just update `color`:

```julia
function Makie.extract_colormap(plot::MyPlot)
    attr = extract_colormap(plot.plots[1])
    attr[:color] = plot.values
    return attr
end
```

!!! note
    `extract_colormap(plot)` is expected to return a full set of attributes.
    Not doing so may cause attributes from a parent plot to be mixed in, which could be different from the ones used in the plot.
    Its default method fills the result of `_extract_colormap(plot)` with attributes from `plot`.
    Therefore `_extract_colormap(plot)` may return an incomplete set.
    Its default implementation calls `extract_colormap(only(plot.plots))`.
    If you are unsure about which method to use, use `Makie._extract_colormap` when you are implementing a method and `extract_colormap` when you are calling one.

!!! note
    Prior to Makie 0.25 `extract_colormap` was expected to return a `Makie.ColorMapping`.
    This still works but is now deprecated.

## Attributes

```@attrdocs
Colorbar
```
