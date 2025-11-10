# scatter

```
f, ax, pl = scatter(args...; kw...) # return a new figure, axis, and plot
   ax, pl = scatter(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = scatter!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Scatter(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `positions::AbstractVector{<:Union{Point2, Point3}}`

  * `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.
  * `xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.
  * `ys`: Defaults `xs` positions to `eachindex(ys)`.

For detailed conversion information, see `Makie.conversion_docs(Scatter)`.

## Examples

See the [online documentation](https://docs.makie.org/stable/reference/plots/scatter) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.

### `strokecolor`

**Default:** `@inherit markerstrokecolor`

Sets the color of the outline around a marker.

**Example:**

```@figure
fig = Figure()
kwargs = (; markersize = 30, strokewidth = 3)
scatter(fig[1, 1], 1:3; kwargs..., strokecolor = :tomato)
scatter(fig[1, 2], 1:3; kwargs..., strokecolor = [RGBf(1, 0, 0), RGBf(0, 1, 0), RGBf(0, 0, 1)])
fig

```

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

**Example:**

```@figure
fig = Figure()
kwargs = (; markersize = 30, axis = (; limits = (0, 6, 0, 6)))
scatter(fig[1, 1], 1:5; kwargs..., color = 1:5, colormap = :viridis)
scatter(fig[1, 2], 1:5; kwargs..., color = 1:5, colormap = :plasma)
scatter(fig[2, 1], 1:5; kwargs..., color = 1:5, colormap = Reverse(:viridis))
scatter(fig[2, 2], 1:5; kwargs..., color = 1:5, colormap = [:tomato, :slategray2])
fig

```

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `glowwidth`

**Default:** `0.0`

Sets the size of a glow effect around the marker.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `marker_offset`

**Default:** `Vec3f(0)`

The offset of the marker from the given position in `markerspace` units. An offset of 0 corresponds to a centered marker.

**Example:**

```@figure
fig = Figure()
scatter(fig[1, 1], [Point2f(0) for _ in 1:5]; marker = Circle, markersize = 30,
    marker_offset = [(0, 0), (-50, 0), (0, -50), (50, 0), (0, 50)],
    color = [:black, :blue, :green, :red, :orange])
scatter(fig[1, 2], [Point3f(0) for _ in 1:7]; marker = :ltriangle, markersize = 0.2, markerspace = :data,
    marker_offset = Vec3f[(0, 0, 0), (-1, 0, 0), (0, -1, 0), (1, 0, 0), (0, 1, 0), (0, 0, -1), (0, 0, 1)],
    color = [:black, :blue, :green, :red, :orange, :cyan, :purple])
fig

```

### `markersize`

**Default:** `@inherit markersize`

Sets the size of the marker by scaling it relative to its base size which can differ for each marker. A `Real` scales x and y dimensions by the same amount. A `Vec` or `Tuple` with two elements scales x and y separately. An array of either scales each marker separately. Humans perceive the area of a marker as its size which grows quadratically with `markersize`, so multiplying `markersize` by 2 results in a marker that is 4 times as large, visually.

**Example:**

```@figure
fig = Figure()
kwargs = (; marker = Rect, axis = (; limits = (0, 4, 0, 4)))
scatter(fig[1, 1], 1:3; kwargs..., markersize = 30)
scatter(fig[1, 2], 1:3; kwargs..., markersize = (30, 20))
scatter(fig[2, 1], 1:3; kwargs..., markersize = [10, 20, 30])
scatter(fig[2, 2], 1:3; kwargs..., markersize = [(10, 20), (20, 30), (40, 30)])
fig

```

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `depthsorting`

**Default:** `false`

Enables depth-sorting of markers which can improve border artifacts. Currently supported in GLMakie only.

### `font`

**Default:** `"default"`

Sets the font to be used for character markers

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `distancefield`

**Default:** `nothing`

Optional distancefield used for e.g. font and bezier path rendering. Will get set automatically.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `strokewidth`

**Default:** `@inherit markerstrokewidth`

Sets the width of the outline around a marker.

**Example:**

```@figure
fig = Figure()
kwargs = (; markersize = 30, strokecolor = :tomato)
scatter(fig[1, 1], 1:3; kwargs..., strokewidth = 3)
scatter(fig[1, 2], 1:3; kwargs..., strokewidth = [0, 3, 6])
fig

```

### `rotation`

**Default:** `Billboard()`

Sets the rotation of the marker. A `Billboard` rotation is always around the depth axis.

**Example:**

```@figure
fig = Figure()
kwargs = (; marker = :utriangle, markersize = 30, axis = (; limits = (0, 4, 0, 4)))
scatter(fig[1, 1], 1:3; kwargs...)
scatter(fig[1, 2], 1:3; kwargs..., rotation = deg2rad(45))
scatter(fig[1, 3], 1:3; kwargs..., rotation = deg2rad.([0, 45, 90]))
fig

```

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `cycle`

**Default:** `[:color]`

Sets which attributes to cycle when creating multiple plots. The values to cycle through are defined by the parent Theme. Multiple cycled attributes can be set by passing a vector. Elements can

  * directly refer to a cycled attribute, e.g. `:color`
  * map a cycled attribute to a palette attribute, e.g. `:linecolor => :color`
  * map multiple cycled attributes to a palette attribute, e.g. `[:linecolor, :markercolor] => :color`

### `transformation`

**Default:** `:automatic`

Controls the inheritance or directly sets the transformations of a plot. Transformations include the transform function and model matrix as generated by `translate!(...)`, `scale!(...)` and `rotate!(...)`. They can be set directly by passing a `Transformation()` object or inherited from the parent plot or scene. Inheritance options include:

  * `:automatic`: Inherit transformations if the parent and child `space` is compatible
  * `:inherit`: Inherit transformations
  * `:inherit_model`: Inherit only model transformations
  * `:inherit_transform_func`: Inherit only the transform function
  * `:nothing`: Inherit neither, fully disconnecting the child's transformations from the parent

Another option is to pass arguments to the `transform!()` function which then get applied to the plot. For example `transformation = (:xz, 1.0)` which rotates the `xy` plane to the `xz` plane and translates by `1.0`. For this inheritance defaults to `:automatic` but can also be set through e.g. `(:nothing, (:xz, 1.0))`.

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `marker`

**Default:** `@inherit marker`

Sets the scatter marker.

### `color`

**Default:** `@inherit markercolor`

Sets the color of the marker. If no color is set, multiple calls to `scatter!` will cycle through the axis color palette.

**Example:**

```@figure
fig = Figure()
kwargs = (; markersize = 30, axis = (; limits = (0, 4, 0, 4)))
scatter(fig[1, 1], 1:3; kwargs..., color = :tomato)
scatter(fig[1, 2], 1:3; kwargs..., color = [RGBf(1, 0, 0), RGBf(0, 1, 0), RGBf(0, 0, 1)])
scatter(fig[2, 1], 1:3; kwargs..., color = [10, 20, 30])
scatter(fig[2, 2], 1:3; kwargs..., color = [10, 20, 30], colormap = :plasma)
fig

```

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `markerspace`

**Default:** `:pixel`

Sets the space in which `markersize` is given. See `Makie.spaces()` for possible inputs

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `false`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `glowcolor`

**Default:** `(:black, 0.0)`

Sets the color of the glow effect around the marker.

### `transform_marker`

**Default:** `false`

Controls whether the model matrix (without translation) applies to the marker itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the marker.
