# Inspecting Data

Makie provides a data inspection tool via `DataInspector(x)` where x can be a
figure, axis or scene. With it you get a floating tooltip with relevant
information for various plots by hovering over one of its elements.

By default the inspector will be able to pick any plot other than `text` and
`volume` based plots. If you wish to ignore a plot, you can set its attribute
`plot.inspectable[] = false`. With that the next closest plot (in range) will be
picked.

{{doc DataInspector}}

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
    inspector_label = (self, i, p) -> lbls[self.color[][i]]
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

to map the primitive `idx` to one identifying the bars in `BarPlot`. With this 
we can now get the position of the hovered bar with `plot[1][][idx]`. To align 
the tooltip to the selection we need to compute the relevant position in screen 
space and update the tooltip position.

```julia
using Makie: parent_scene, shift_project, update_tooltip_alignment!, position2string

function show_barplot(inspector::DataInspector, plot::BarPlot, idx)
    # Get the tooltip plot
    tt = inspector.plot

    # Get the scene BarPlot lives in
    scene = parent_scene(plot)

    # Get the hovered data-space position
    pos = plot[1][][idx]
    # project to screen space and shift it to be correct on the root scene
    proj_pos = shift_project(scene, to_ndim(Point3f, pos, 0))
    # anchor the tooltip at the projected position
    update_tooltip_alignment!(inspector, proj_pos)

    # Update the final text of the tooltip.
    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = position2string(pos)
    end
    # Show the tooltip
    tt.visible[] = true

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
    parent_scene, shift_project, update_tooltip_alignment!, position2string,
    clear_temporary_plots!

function show_data(inspector::DataInspector, plot::BarPlot, idx)
    # inspector.attributes holds some attributes relevant to indicators and is
    # used as a cache for indicator observables
    a = inspector.attributes
    tt = inspector.plot
    scene = parent_scene(plot)

    pos = plot[1][][idx]
    proj_pos = shift_project(scene, plot, to_ndim(Point3f, pos, 0))
    update_tooltip_alignment!(inspector, proj_pos)

    # We only want to mark the rectangle if that setting is enabled
    if a.enable_indicators[]
        # Get the relevant rectangle
        bbox = plot.plots[1][1][][idx]

        # If we haven't yet created an indicator create it
        if inspector.selection != plot
            # clear old indicators
            clear_temporary_plots!(inspector, plot)

            # Create the new indicator using some settings from `DataInspector`.
            p = wireframe!(
                scene, bbox, model = plot.model[], color = a.indicator_color,
                strokewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
                visible = a.indicator_visible, inspectable = false
            )

            # tooltips are pushed forward a certain amount to make sure they're
            # drown on top of other things. This indicator should also be pushed
            # forward that much
            translate!(p, Vec3f(0, 0, a.depth[]))

            # Keep track of the indicator plot
            push!(inspector.temp_plots, p)

        # If we have already created an indicator plot we just need to update 
        # it. In this case we only need to update the rectangle.
        elseif !isempty(inspector.temp_plots)
            p = inspector.temp_plots[1]
            p[1][] = bbox
        end

        # Moving away from a plot will automatically set this to false, so we 
        # always need to set it to true.
        a.indicator_visible[] = true
    end

    if haskey(plot, :inspector_label)
        tt.text[] = plot[:inspector_label][](plot, idx, pos)
    else
        tt.text[] = position2string(pos)
    end
    tt.visible[] = true

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