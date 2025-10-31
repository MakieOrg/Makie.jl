# DataInspector

## Basic Usage

`DataInspector` provides a way to display tooltips when hovering over plots.
By default these tooltips will contain relevant data for plot which is usually the position of the plot element or cursor.
To initialize DataInspector it needs to be constructed with an axis-like Block or with a scene.

```@figure backend=GLMakie
f, a, p = lines(0..2pi, sin)
inspector = Makie.DataInspector(a)
events(f).mouseposition[] = (300, 300) # hide
colorbuffer(f) # hide
while !inspector.dynamic_tooltip.visible[] # hide
	yield() # hide
end # hide
f
```

!!! note
	`DataInspector` has been reworked in Makie TODO.
	It now works per scene rather than globally, uses a new callback syntax for `inspector_label` and is no longer extended using `show_data(...)` methods.

### Persistent Tooltips

DataInspector allows you to make a tooltip persistent by pressing `shift` and left clicking a plot element.
It can later be removed with a `shift + left click` on the tooltip.

### Custom Tooltip Labels

DataInspector will check the `inspector_label` attribute of the hovered plot when building the tooltip.
You have three options for setting it.
The first is a plain String, which will be displayed when hovering any element of the plot.

```@figure backend=GLMakie
f, a, p = lines(0..2pi, sin, inspector_label = "constant label")
inspector = Makie.DataInspector(a)
events(f).mouseposition[] = (300, 300) # hide
colorbuffer(f) # hide
while !inspector.dynamic_tooltip.visible[] # hide
	yield() # hide
end # hide
f
```

The second is an array (or other indexable collection) of strings.
This will map the labels to the elements of the plot.
For this the plot needs to be discrete like `scatter` rather than continuous like `lines`.

```@figure backend=GLMakie
f, a, p = scatter(1:10, inspector_label = ["Label $i" for i in 1:10])
inspector = Makie.DataInspector(a)
events(f).mouseposition[] = (340, 255) # hide
colorbuffer(f) # hide
while !inspector.dynamic_tooltip.visible[] # hide
	yield() # hide
end # hide
f
```

The third option is to manually construct a label from plot data using a callback function.
It will be called with a `PlotElement` and the position of the tooltip.
The position should be in the same space as the arguments passed to the function.

The `PlotElement` combines the plot with indexing or interpolation information to represent the currently hovered element.
When accessing an attribute on a `PlotElement`, e.g. `element.color`, the attribute will automatically be indexed or interpolated.

```@figure backend=GLMakie
function mylabel(element, pos)
	# As a discrete plot, scatter elements contain an index.
`element.attribute`
	# will apply that index when possible so element.color will return the value
	# of the `color` attribute at the hovered marker
	picked_color = element.color
	return "color = $picked_color\npos = $pos"
end

f,a,p = scatter(1:10, color = range(0, 1, 10), inspector_label = mylabel)
inspector = Makie.DataInspector(a)
events(f).mouseposition[] = (340, 255) # hide
colorbuffer(f) # hide
while !inspector.dynamic_tooltip.visible[] # hide
	yield() # hide
end # hide
f
```

Note that `PlotElement` also contains the plot type as the first type parameter.
If you want to write a whole suite of custom label functions, you can use that for dispatch:

```julia
mylabel(e::PlotElement{<:Scatter}, pos) = ...
mylabel(e::PlotElement{<:Lines}, pos) = ...
mylabel(e::PlotElement{<:Hist}, pos) = ...
```

### Disabling Tooltips

Tooltips can be disabled per-plot using the `inspectable` attribute.
When it is set to false DataInspector will not generate a tooltip for the given plot.
If there are other plots nearby, tooltips will be generated for the next closest plot.

```@figure backend=GLMakie
f, a, p = scatter(1:10, inspectable = false)
inspector = Makie.DataInspector(a)
f
```

### Indicators

For some plots DataInspector generates additional "indicators" to highlight the picked element or plot.
These can be turned off by setting `enable_indicators = false` either in DataInspector or in individual plots.

### DataInspector Attributes

```@docs
DataInspector
```

## Extending DataInspector

In order for DataInspector to produce useful tooltips for a recipe it may be necessary to extend some of its interface functions.

Tooltip generation begins with reacting to events which may affect the tooltip.
From there `pick_sorted(...)` is called to find primitive plots around the cursor.
They are iterated closest to farthest, calling `update_tooltip!(inspector, plot, index)` if they are `inspectable` and within the relevant scene.
The `update_tooltip!(...)` function then attempts to build/update the tooltip.

### `pick_element` and PlotElement Generation

The first step converts the primitive plot and index returned by `pick_sorted` into a `PlotElement`.
The `PlotElement` abstracts the picked element (e.g. a marker, a point on a line, etc.) of a higher level plot.
It primarily contains two parts.
The first is a trace of plots from the (user created) recipe plot down to the picked primitive plot.
This is referred to as a the plot stack.
The other is indexing or interpolation information which is referred to as an accessor.

Accessors are generated by methods of `get_accessor(plot, index, plot_stack)` where the `plot` is the plot to be accessed (typically the root parent), `index` is the index returned by `pick_sorted` and `plot_stack` is the plot stack starting after `plot`.
If no specialized method exists, `get_accessor(plot, index, plot_stack)` is called with the next lower level plot.
Thus you don't need to implement a method for a recipe plot which has the same element format as its children.
For example if a recipe visualizes N discrete elements using child plots that also visualize N discrete elements and the indices don't get reordered, then the default `get_accessor(...)` will be enough.

If the formats do change, a new `get_accessor(...)` method should implemented.
This typically involves getting the result of a lower level plot and transforming it.
Let's consider `errorbars` as an example.
The plot visualizes confidence intervals for discrete data using `linesegments` for the bars and `scatter` for the whiskers.
Linesegments are considered continuous and both child plots contain two elements (points) per error bar.
To generate the appropriate `IndexedAccessor` we can thus implement the following methods:

```julia
function get_accessor(plot::Union{Errorbars, Rangebars}, idx, plot_stack::Tuple{<:LineSegments, Vararg{Plot}})
	# Produce the InterpolatedAccessor for the linesegments
	child_accessor = get_accessor(first(plot_stack), index, Base.tail(plot_stack))

	# The InterpolatedAccessor contains indices of type CartesianIndex for the start
	# and end points of the interpolation. These are always the start and end points
	# of bars
	start_index = child_accessor.index0[1]
	bar_index = fld1(start_index, 2)

	# An IndexedAccessor also needs the number of discrete elements, i.e. the
	# number of errorbars drawn
    return IndexedAccessor(bar_index, length(plot.val_low_high[]))
end

function get_accessor(plot::Union{Errorbars, Rangebars}, idx, plot_stack::Tuple{<:Scatter, Vararg{Plot}})
	# Scatter already produces an IndexedAccessor so we just need to divide by 2
	child_accessor = get_accessor(first(plot_stack), index, Base.tail(plot_stack))
    return IndexedAccessor(fld1(child_accessor.index[1], 2), length(plot.val_low_high[]))
end
```

In this case we can further simplify the methods by using the `idx` from `pick` directly.
For a scatter plot `idx` is the index of the picked marker.
For `linesegments` it is the index of the start point of a line segment.
So in both cases `idx` is the index we feed to `fld1(..., 2).

```julia
function get_accessor(plot::Union{Errorbars, Rangebars}, idx, plot_stack)
	return IndexedElement(fld1(idx, 2), length(plot.val_low_high[]))
end
```

### `get_tooltip_position(...)`

After generating a `PlotElement` the tooltip construction continues by getting the position where the tooltip should be anchored.
This position is produced by `get_tooltip_position(element::PlotElement)`.
Like with the `PlotElement` construction this method falls back onto child plots.
For this the `PlotElement` and its accessor are not regenerated, so a new method will be necessary if the accessor is incompatible with child plots.

Let's consider `errorbars` again.
An `IndexedAccessor` works with both child plots, but the fetched positions are incorrect due to the doubling of points.
Thus we need to implement a new method to grab the correct ones.
For `errorbars` specifically, `val_low_high` contains four values, the x and y position, an error downwards and an error upwards.
If we want to anchor tooltips at the origin of the errorbar, we can just use the (x, y) position from there.

```julia
function get_tooltip_position(element::PlotElement{<:Errorbars})
	# Using getproperty(element, attribute_name) will automatically
	# apply the accessor to the respective attribute of the parent plot.
	# So `element.attribute` is equivalent to:
	#	get_plot(element).attribute[][element.index]
	# (if the element is iterable)
	x, y, low, high = element.val_low_high
	return Point(x, y)
end
```

Note that `get_tooltip_position(...)` methods should not rely on child plots to generate positions.
In order for the position of tooltip to be correct, it also needs to match the `space` and transformations of the plot which the position comes from.
To do that `update_tooltip!(...)` manually searches for an applicable `get_tooltip_position(...)` method.
It then uses the plot associated with that method to copy `space` and transformations from.

### Default labels

If no `inspector_label` is passed to the inspected plot a default tooltip label is generated.
It can be adjusted by extending `get_default_tooltip_label(formatter, element, position)` or `get_default_tooltip_label(element, position)`.
If a string is returned be either method, it is used as the default label.
If other data is returned it is converted to a string using the formatter.
Like the other two systems this one also falls back onto child plots.

For our `errorbars` example we want the tooltip to show errors, i.e. the `low, high` values from above.
The simplest way to do this is to have `get_default_tooltip_label()` return them:

```julia
function get_default_tooltip_label(element::PlotElement{<:Errorbars}, pos)
	x, y, low, high = element.val_low_high
	return low, high
end
```

This will generate `"$low\n$high"` as a string, with `low` and `high` truncated to a few significant digits.
If we want to improve this we can also construct our own string.
We can use `"±$low"` for symmetric (`low == high`) and `"+$high\n-$low` for asymmetric errorbars like this:

```julia
function get_default_tooltip_label(formatter, element::PlotElement{<:Errorbars}, pos)
    x, y, low, high = element.val_low_high
    if low ≈ high
		# apply formatter so numbers continue to get truncated
        return "±" * apply_tooltip_format(formatter, low)
    else
		# Passing a tuple (a, b) results in "$a\n$b"
        return "+" * apply_tooltip_format(formatter, (high, -low))
    end
end
```

### Indicators

Indicators are extra visualizations shown when inspecting specific plots.
To add them for a given recipe a specialized method of `update_indicator!(...)` needs to be implemented.
As the name suggests, it should update the indicator plot(s) according to the currently selected element.
Let's look at barplot to give a relatively easy example.
Barplot processes user given x positions and heights into discrete bars, represented by 2D rectangles.
The `PlotElement` will select one of these bars/rectangles.
To highlight it, we will need to get the rectangle and draw its outline with `lines`.
Since `barplot` has not yet been updated to use the compute graph, we can't get the generated rectangles directly from the plot.
Instead we need to check the input of the `poly` child plot.

```julia
poly_element = child(element)
rect = poly_element.arg1
```

To draw the outline we need a `lines` plot.
These kinds of plots are cached to avoid constant deletion and re-creation by indicator updates.
We can get the cached plot from the DataInspector using `get_indicator(inspector, PlotType)`.
This requires `construct_indicator_plot(inspector, PlotType)` to exist.
For `Lines` this function already exists and looks like this:

```julia
function construct_indicator_plot(di::DataInspector, ::Type{<:Lines})
    a = di.inspector_attributes
    return lines!(
        di.parent, Point3d[], color = a.indicator_color,
        linewidth = a.indicator_linewidth, linestyle = a.indicator_linestyle,
        visible = false, inspectable = false, depth_shift = -1.0f-6
    )
end
```

Note that the plot is created with `Point3d[]`.
This fixes the argument type of a vector of 3D points.
We can convert our rectangle to that with `convert_arguments(...)` and `to_ndim(...)`.
The whole `update_indicator!(...)` then becomes:

```julia
function update_indicator!(di::DataInspector, element::PlotElement{<:BarPlot}, pos)
    poly_element = child(element)
    rect = poly_element.arg1
    ps = to_ndim.(Point3d, convert_arguments(Lines, rect)[1], 0)

    indicator = get_indicator_plot(di, Lines)
    update!(indicator, arg1 = ps, visible = true)

    return
end
```