# attr_list = []
# for func in (atomics..., contour)
#     Typ = to_type(func)
#     attr = keys(default_theme(nothing, Typ))
#     push!(attr_list, attr...)
# end
# attr_list = string.(sort!(unique(attr_list)))
# # filter out fxaa attribute
# attr_list = filter!(x -> x ≠ "fxaa", attr_list)

const attr_desc = Dict{Symbol,Any}(
:absorption        => "Float32. Sets the absorption value for `volume` plots.",
:algorithm        => "Algorithm to be used for `volume` plots. Can be one of `:iso`, `:absorption`, `:mip`, `:absorptionrgba`, or `:indexedabsorption`.",
:align        => "`(:pos, :pos)`. Specify the text alignment, where `:pos` can be `:left`, `:center`, or `:right`.",
:alpha        => "Float in [0,1]. The alpha value (transparency).",
:color        => "The color of the main plot element (markers, lines, etc.).",
:colormap        => "The color map of the main plot.",
:colorrange        => "NTuple{2,Float}, `(x, y)` where `x` and `y` are in [0,1]. Specifies the range of color from the colormap to use.",
:fillrange        => "Bool. Toggles range filling in `contour` plots.",
:font        => "String or Symbol. Specifies the font for title, legend entries, tick labels and guides.",
:glowcolor        => "Color Type. Color of the marker glow (outside the border) in `scatter` plots.",
:glowwidth        => "Number. Width of the marker glow in `scatter` plots.",
:image        => "The image to be plotted on the plot.",
:interpolate        => "Bool. For `heatmap` and `images`. Toggles color interpolation between nearby pixels.",
:isorange        => "Float32. Sets the isorange for `volume` plots.",
:isovalue        => "Float32. Sets the isovalue for `volume` plots.",
:levels        => "Integer. Number of levels for a `contour`-type plot.",
:linestyle        => "Symbol. Style of the line (for `line` and `linesegments` plots). Available styles are `:dash`, `:dot`, `:dashdot`, and `:dashdotdot`.",
:linewidth        => "Number. Width of the line in `line` and `linesegments` plots.",
:marker        => "Symbol, Shape, or AbstractVector.",
:marker_offset        => "Array of `GeometryTypes.Point`'s. Specifies the offset coordinates for the markers.",
:markersize        => "Number or AbstractVector. Specifies size (radius pixels) of the markers.",
:model        => "",
:position        => "NTuple{2,Float}, `(x, y)`. Specify the coordinates to position text at.",
:rotation        => "Number. Specifies the rotation in degrees.",
:rotations        => "AbstractVector. Similar to `:rotation`, except it specifies the rotation for each element in the plot.",
:shading        => "Bool. Specifies if shading should be on or not (for meshes).",
:strokecolor        => "Color Type. Color of the marker stroke (border).",
:strokewidth        => "Number. Width of the marker stroke (in pixels).",
:textsize        => "Integer. Font pointsize for text.",
:transformation        => "`(:plane, location)`. Transforms the `:plane` to the specified location. Possible `:plane`'s are `:xy`, `:yz`, and `:xz`.",
:visible        => "Bool. Toggle visibility of plot."
)
