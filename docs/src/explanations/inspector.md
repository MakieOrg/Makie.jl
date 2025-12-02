# Inspecting data

Makie provides a data inspection tool via `DataInspector(x)` where x can be a
figure, axis or scene. With it you get a floating tooltip with relevant
information for various plots by hovering over one of its elements.

By default the inspector will be able to pick any plot other than `text` and
`volume` based plots. If you wish to ignore a plot, you can set its attribute
`plot.inspectable = false`. With that the next closest plot (in range) will be
picked.

```@docs
DataInspector
```

## Custom text

The text that `DataInspector` displays can be adjusted on a per-plot basis
through the `inspector_label` attribute. It should hold a function
`(plot, index, position) -> "my_string"`, where `plot` is the plot whose label
is getting adjusted, `index` is the index returned by `pick` (see events
documentation) and `position` is the position of the inspected object.

```julia
lbls = ["Type A", "Type B"]
fig, ax, p = scatter(
    rand(10), color = rand(1:2, 10), colormap = [:red, :blue],
    inspector_label = (self, i, pos) -> lbls[self.color[][i]]
)
DataInspector(fig)
fig
```

## Extending `DataInspector`

The inspector implements tooltips for primitive plots and a few non-primitive
plots (i.e. recipes). All other plots fall back to tooltips of one of their
child plots.

For example a `poly` consists of a `mesh` and a `wireframe` plot, where
`wireframe` is implemented as `lines`. Since neither `poly` nor `wireframe` has
a specialized `show_data` method, DataInspector uses either `mesh` or `lines`
to generate the tooltip.

While this means that most plots have a tooltip it also means many may not have
a fitting one. If you wish to implement a more fitting tooltip for a new plot
type you can do so by extending

```julia
function show_data(inspector::DataInspector, my_plot::MyPlot, idx, primitive_child::SomePrimitive)
    ...
end
```

Here `my_plot` is the plot you want to create a custom tooltip for,
`primitive_child` is one of the primitives your plot is made from (scatter,
text, lines, linesegments, mesh, surface, volume, image or heatmap) and `idx` is
the index into that primitive plot. The latter two are the result from
`pick_sorted` at the current mouseposition. In general you will need to adjust
`idx` to be useful for `MyPlot`.

Let's take a look at the `BarPlot` method, which also powers `hist`. It
contains two primitive plots - `Mesh` and `Lines`. The `idx` from picking a
`Mesh` is based on vertices, of which there are four per rectangle. From `Lines`
we get an index based on the end point of a line. To draw the outline of a
rectangle as is done in barplot, we need 5 points and a separator totaling 6.
We thus implement

```julia
import Makie: show_data

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Lines)
    return show_barplot(inspector, plot, div(idx-1, 6)+1)
end

function show_data(inspector::DataInspector, plot::BarPlot, idx, ::Mesh)
    return show_barplot(inspector, plot, div(idx-1, 4)+1)
end
```

to map the primitive `idx` to one identifying the bars in `BarPlot`.
With this we can now get the position of the hovered bar with `plot[1][][idx]` and map that to a label string.
To place the tooltip we also need a pixel space position.
We could either project the position of the hovered element for this, or use the current mouseposition.

```julia
using Makie: update_tooltip_alignment!, position2string

function show_barplot(inspector::DataInspector, plot::BarPlot, idx)
    # Get the position of the bar
    pos = plot[1][][idx]
    if plot.direction[] === :x
        pos = reverse(pos)
    end

    # Get the label for the tooltip
    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(pos)
    else
        plot[:inspector_label][](plot, idx, pos)
    end

    # Get the mouseposition as the anchor point of the tooltip
    # (relative to the root screen which contains the tooltip plot)
    proj_pos = Point2f(mouseposition_px(inspector.root))

    # update the tooltip (setting position, text, visibility, placement internals)
    update_tooltip_alignment!(inspector, proj_pos; text)

    # return true to indicate that we have updated the tooltip
    return true
end
```

Next we want to mark the rectangle we are hovering. In this case we can use the
rectangles which `BarPlot` passes to `Poly`, i.e. `plot.plots[1][1][][idx]`. The
`DataInspector` contains some functionality for keeping track of temporary plots,
so we can plot the indicator to the same `scene` that `BarPlot` uses. Doing so
results in

```julia
using Makie:
    parent_scene, update_tooltip_alignment!, position2string,
    clear_temporary_plots!

function show_barplot(inspector::DataInspector, plot::BarPlot, idx)
    a = inspector.attributes

    if a.enable_indicators[]
        # clean up indicator plots from other plot hovers
        if inspector.selection != plot
            clear_temporary_plots!(inspector, plot)
        end
        a.indicator_visible[] = true

        # Get the bar rectangle from the poly plot in barplot
        bbox = plot.plots[1][1][][idx]
        # Convert it to line points in world space (after transformations)
        ps = apply_transform_and_model(plot, convert_arguments(Lines, bbox)[1])

        # get a lines plot that the DataInspector has or will keep cached
        indicator = get_indicator_plot(inspector, scene, Lines)

        # modify position and visibility to show it and update it as the mouse
        # is moved. Attributes like color, linewidth and linestyle are connected
        # to inspector.attributes already
        update!(indicator, arg1 = ps, visible = true)
    end

    pos = plot[1][][idx]
    if plot.direction[] === :x
        pos = reverse(pos)
    end

    text = if to_value(get(plot, :inspector_label, automatic)) == automatic
        position2string(pos)
    else
        plot[:inspector_label][](plot, idx, pos)
    end

    proj_pos = Point2f(mouseposition_px(inspector.root))
    update_tooltip_alignment!(inspector, proj_pos; text)

    return true
end
```

which finishes the implementation of a custom tooltip for `BarPlot`.

## Per-plot `show_data`

It is also possible to replace a call to `show_data` on a per-plot basis via
the `inspector_hover` attribute. DataInspector assumes this to be a function
`(inspector, this_plot, index, hovered_child) -> Bool`. You can also set up
custom clean up with `plot.inspector_clear = (inspector, plot) -> ...` which is
called whenever the plot is deselected.