# barplot

```
f, ax, pl = barplot(args...; kw...) # return a new figure, axis, and plot
   ax, pl = barplot(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = barplot!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Barplot(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `positions::AbstractVector{<:Union{Point2, Point3}}`

  * `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.
  * `xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.
  * `ys`: Defaults `xs` positions to `eachindex(ys)`.

For detailed conversion information, see `Makie.conversion_docs(Barplot)`.

## Examples

```@figure
f = Figure()
Axis(f[1, 1])

xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot!(xs, ys, color = :red, strokecolor = :black, strokewidth = 1)
barplot!(xs, ys .- 1, fillto = -1, color = xs, strokecolor = :black, strokewidth = 1)

f
```

```@figure
xs = 1:0.2:10
ys = 0.5 .* sin.(xs)

barplot(xs, ys, gap = 0, color = :gray85, strokecolor = :black, strokewidth = 1)
```

```@figure barplot
tbl = (cat = [1, 1, 1, 2, 2, 2, 3, 3, 3],
       height = 0.1:0.1:0.9,
       grp = [1, 2, 3, 1, 2, 3, 1, 2, 3],
       grp1 = [1, 2, 2, 1, 1, 2, 1, 1, 2],
       grp2 = [1, 1, 2, 1, 2, 1, 1, 2, 1]
       )

barplot(tbl.cat, tbl.height,
        stack = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Stacked bars"),
        )
```

```@figure barplot
barplot(tbl.cat, tbl.height,
        dodge = tbl.grp,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged bars"),
        )
```

```@figure barplot
barplot(tbl.cat, tbl.height,
        dodge = tbl.grp1,
        stack = tbl.grp2,
        color = tbl.grp,
        axis = (xticks = (1:3, ["left", "middle", "right"]),
                title = "Dodged and stacked bars"),
        )
```

```@figure barplot
colors = Makie.wong_colors()

# Figure and Axis
fig = Figure()
ax = Axis(fig[1,1], xticks = (1:3, ["left", "middle", "right"]),
        title = "Dodged bars with legend")

# Plot
barplot!(ax, tbl.cat, tbl.height,
        dodge = tbl.grp,
        color = colors[tbl.grp])

# Legend
labels = ["group 1", "group 2", "group 3"]
elements = [PolyElement(polycolor = colors[i]) for i in 1:length(labels)]
title = "Groups"

Legend(fig[1,2], elements, labels, title)

fig
```

```@figure barplot
barplot(
    tbl.cat, tbl.height,
    dodge = tbl.grp,
    color = tbl.grp,
    bar_labels = :y,
    axis = (xticks = (1:3, ["left", "middle", "right"]),
            title = "Dodged bars horizontal with labels"),
    colormap = [:red, :green, :blue],
    color_over_background=:red,
    color_over_bar=:white,
    flip_labels_at=0.85,
    direction=:x,
)
```

```@figure
barplot([-1, -0.5, 0.5, 1],
    bar_labels = :y,
    axis = (title="Fonts + flip_labels_at",),
    label_size = 20,
    flip_labels_at=(-0.8, 0.8),
    label_color=[:white, :green, :black, :white],
    label_formatter = x-> "Flip at $(x)?",
    label_offset = 10
)
```

```@figure
gantt = (
    machine = [1, 2, 1, 2],
    job = [1, 1, 2, 3],
    task = [1, 2, 3, 3],
    start = [1, 3, 3.5, 5],
    stop = [3, 4, 5, 6]
)

fig = Figure()
ax = Axis(
    fig[2,1],
    yticks = (1:2, ["A","B"]),
    ylabel = "Machine",
    xlabel = "Time"
)
xlims!(ax, 0, maximum(gantt.stop))

cmap = Makie.to_colormap(:tab10)

barplot!(
    gantt.machine,
    gantt.stop,
    fillto = gantt.start,
    direction = :x,
    color = gantt.job,
    colormap = cmap,
    colorrange = (1, length(cmap)),
    gap = 0.5,
    bar_labels = ["task #$i" for i in gantt.task],
    label_position = :center,
    label_color = :white,
    label = ["job #$i" => (; color = i) for i in unique(gantt.job)]
)

Legend(fig[1,1], ax, "Jobs", orientation=:horizontal, tellwidth = false, tellheight = true)

fig
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/barplot) for rendered examples.

## Attributes

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `strokecolor`

**Default:** `@inherit patchstrokecolor`

Sets the outline color of bars.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `bar_labels`

**Default:** `nothing`

Labels added at the end of each bar.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `strokewidth`

**Default:** `@inherit patchstrokewidth`

Sets the outline linewidth of bars.

### `transformation`

**Default:** `:automatic`

Controls the inheritance or directly sets the transformations of a plot. Transformations include the transform function and model matrix as generated by `translate!(...)`, `scale!(...)` and `rotate!(...)`. They can be set directly by passing a `Transformation()` object or inherited from the parent plot or scene. Inheritance options include:

  * `:automatic`: Inherit transformations if the parent and child `space` is compatible
  * `:inherit`: Inherit transformations
  * `:inherit_model`: Inherit only model transformations
  * `:inherit_transform_func`: Inherit only the transform function
  * `:nothing`: Inherit neither, fully disconnecting the child's transformations from the parent

Another option is to pass arguments to the `transform!()` function which then get applied to the plot. For example `transformation = (:xz, 1.0)` which rotates the `xy` plane to the `xz` plane and translates by `1.0`. For this inheritance defaults to `:automatic` but can also be set through e.g. `(:nothing, (:xz, 1.0))`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `gap`

**Default:** `0.2`

The final width of the bars is calculated as `w * (1 - gap)` where `w` is the width of each bar as determined with the `width` attribute. When `dodge` is used the `w` corresponds to the width of undodged bars, making this control the gap between groups.

### `fillto`

**Default:** `automatic`

Controls the baseline of the bars. This is zero in the default `automatic` case unless the barplot is in a log-scaled `Axis`. With a log scale, the automatic default is half the minimum value because zero is an invalid value for a log scale.

### `color_over_bar`

**Default:** `automatic`

Sets the color of labels that are drawn inside of/over bars. Defaults to `label_color`

### `label_size`

**Default:** `@inherit fontsize`

The font size of the bar labels.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `dodge`

**Default:** `automatic`

Dodge can be used to separate bars drawn at the same `position`. For this each bar is given an integer value corresponding to its position relative to the given `positions`. E.g. with `positions = [1, 1, 1, 2, 2, 2]` we have 3 bars at each position which can be separated by `dodge = [1, 2, 3, 1, 2, 3]`.

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `n_dodge`

**Default:** `automatic`

Sets the maximum integer for `dodge`. This sets how many bars can be placed at a given position, controlling their width.

### `label_rotation`

**Default:** `0π`

Sets the text rotation of labels in radians.

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `dodge_gap`

**Default:** `0.03`

Sets the gap between dodged bars relative to the size of the dodged bars.

### `color`

**Default:** `@inherit patchcolor`

Sets the color of bars.

### `flip_labels_at`

**Default:** `Inf`

Sets a `height` value beyond which labels are drawn inside the bar instead of outside.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `label_font`

**Default:** `@inherit font`

The font of the bar labels.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `label_align`

**Default:** `automatic`

Sets the text alignment of labels.

### `cycle`

**Default:** `[:color => :patchcolor]`

Sets which attributes to cycle when creating multiple plots. The values to cycle through are defined by the parent Theme. Multiple cycled attributes can be set by passing a vector. Elements can

  * directly refer to a cycled attribute, e.g. `:color`
  * map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
  * map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `direction`

**Default:** `:y`

Controls the direction of the bars. can be `:y` (`height` is vertical) or `:x` (`height` is horizontal).

### `width`

**Default:** `automatic`

The gapless width of the bars. If `automatic`, the width `w` is calculated as `minimum(diff(sort(unique(positions)))`. The actual width of the bars is calculated as `w * (1 - gap)`.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `label_offset`

**Default:** `5`

The distance of the labels from the bar ends in screen units. Does not apply when `label_position = :center`.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `stack`

**Default:** `automatic`

Similar to `dodge`, this allows bars at the same `positions` to be stacked by identifying their stack position with integers. E.g. with `positions = [1, 1, 1, 2, 2, 2]` each group of 3 bars can be stacked with `stack = [1, 2, 3, 1, 2, 3]`.

### `label_position`

**Default:** `:end`

The position of each bar's label relative to the bar. Possible values are `:end` or `:center`.

### `label_color`

**Default:** `@inherit textcolor`

Sets the color of labels.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `label_formatter`

**Default:** `bar_label_formatter`

Formatting function which is applied to bar labels before they are passed on `text()`

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `offset`

**Default:** `0.0`

Offsets all bars by the given real value. Can also be set per-bar.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `color_over_background`

**Default:** `automatic`

Sets the color of labels that are drawn outside of bars. Defaults to `label_color`
