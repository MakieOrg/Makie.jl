# Plot attributes

Below is the list of all of the available plot attributes for Makie.
You can also get this by doing

```julia
keys(default_theme(nothing, Typ))
```

where `Typ` is the plot type.

See [Plot function signatures](@ref) for the available plot function signatures.


|Symbol          |Description                                                                                                                                                                                                          |
|----------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
|`absorption`    |Float32. Sets the absorption value for `volume` plots.                                                                                                                                                               |
|`algorithm`     |Algorithm to be used for `volume` plots. Can be one of `:iso`, `:absorption`, `:mip`, `:absorptionrgba`, or `:indexedabsorption`.                                                                                    |
|`align`         |`(:pos, :pos)`. Specify the text alignment, where `:pos` can be `:left`, `:center`, or `:right`.                                                                                                                     |
|`alpha`         |Float in [0,1]. The alpha value (transparency).                                                                                                                                                                      |
|`color`         |The color of the main plot element (markers, lines, etc.). Can be a color symbol/string like :red, or a Colorant                                                                                                     |
|`colormap`      |The color map of the main plot. Call available_gradients() to see what gradients are available. Can also be used with any Vector{<: Colorant}, or e.g. [:red, :black]                                                |
|`colorrange`    |A tuple `(min, max)` where `min` and `max` specify the data range to be used for indexing the colormap. E.g. color = [-2, 4] with colorrange = (-2, 4) will map to the lowest and highest color value of the colormap|
|`fillrange`     |Bool. Toggles range filling in `contour` plots.                                                                                                                                                                      |
|`font`          |String or Symbol. Specifies the font and can name any font available on the system                                                                                                                                   |
|`glowcolor`     |Color Type. Color of the marker glow (outside the border) in `scatter` plots.                                                                                                                                        |
|`glowwidth`     |Number. Width of the marker glow in `scatter` plots.                                                                                                                                                                 |
|`image`         |The image to be plotted on the plot.                                                                                                                                                                                 |
|`interpolate`   |Bool. For `heatmap` and `images`. Toggles color interpolation between nearby pixels.                                                                                                                                 |
|`isorange`      |Float32. Sets the isorange for `volume` plots.                                                                                                                                                                       |
|`isovalue`      |Float32. Sets the isovalue for `volume` plots.                                                                                                                                                                       |
|`levels`        |Integer. Number of levels for a `contour`-type plot.                                                                                                                                                                 |
|`linestyle`     |Symbol. Style of the line (for `line` and `linesegments` plots). Available styles are `:dash`, `:dot`, `:dashdot`, and `:dashdotdot`. You can also supply an array describing the length of each gap/fill.           |
|`linewidth`     |Number. Width of the line in `line` and `linesegments` plots.                                                                                                                                                        |
|`marker`        |Symbol, Shape, or AbstractVector.                                                                                                                                                                                    |
|`marker_offset` |Array of `GeometryTypes.Point`'s. Specifies the offset coordinates for the markers. See the ["Marker offset"](@ref) example.                                                                                         |
|`markersize`    |Number or AbstractVector. Specifies size (radius pixels) of the markers.                                                                                                                                             |
|`position`      |NTuple{2,Float}, `(x, y)`. Specify the coordinates to position text at.                                                                                                                                              |
|`rotation`      |Number. Specifies the rotation in degrees.                                                                                                                                                                           |
|`rotations`     |AbstractVector. Similar to `:rotation`, except it specifies the rotation for each element in the plot.                                                                                                               |
|`shading`       |Bool. Specifies if shading should be on or not (for meshes).                                                                                                                                                         |
|`strokecolor`   |Color Type. Color of the marker stroke (border).                                                                                                                                                                     |
|`strokewidth`   |Number. Width of the marker stroke (in pixels).                                                                                                                                                                      |
|`textsize`      |Integer. Font pointsize for text.                                                                                                                                                                                    |
|`transformation`|`(:plane, location)`. Transforms the `:plane` to the specified location. Possible `:plane`'s are `:xy`, `:yz`, and `:xz`.                                                                                            |
|`visible`       |Bool. Toggle visibility of plot.                                                                                                                                                                                     |
