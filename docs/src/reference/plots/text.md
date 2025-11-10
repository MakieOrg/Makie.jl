# text

```
f, ax, pl = text(args...; kw...) # return a new figure, axis, and plot
   ax, pl = text(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = text!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Text(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `positions::AbstractVector{<:Union{Point2, Point3}}`

  * `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.
  * `xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.
  * `ys`: Defaults `xs` positions to `eachindex(ys)`.

For detailed conversion information, see `Makie.conversion_docs(Text)`.

## Examples

See the [online documentation](https://docs.makie.org/stable/reference/plots/text) for rendered examples.

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

**Default:** `(:black, 0.0)`

Sets the color of the outline around a marker.

### `position`

**Default:** `(0.0, 0.0)`

Deprecated: Specifies the position of the text. Use the positional argument to `text` instead.

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `glowwidth`

**Default:** `0.0`

Sets the size of a glow effect around the text.

### `text`

**Default:** `""`

Specifies one piece of text or a vector of texts to show, where the number has to match the number of positions given. Makie supports `String` which is used for all normal text and `LaTeXString` which layouts mathematical expressions using `MathTeXEngine.jl`.

### `fonts`

**Default:** `@inherit fonts`

Used as a dictionary to look up fonts specified by `Symbol`, for example `:regular`, `:bold` or `:italic`.

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `word_wrap_width`

**Default:** `-1`

Specifies a linewidth limit for text. If a word overflows this limit, a newline is inserted before it. Negative numbers disable word wrapping.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `justification`

**Default:** `automatic`

Sets the alignment of text w.r.t its bounding box. Can be `:left, :center, :right` or a fraction. Will default to the horizontal alignment in `align`.

### `font`

**Default:** `@inherit font`

Sets the font. Can be a `Symbol` which will be looked up in the `fonts` dictionary or a `String` specifying the (partial) name of a font or the file path of a font file

### `align`

**Default:** `(:left, :bottom)`

Sets the alignment of the string w.r.t. `position`. Uses `:left, :center, :right, :top, :bottom, :baseline` or fractions.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `strokewidth`

**Default:** `0`

Sets the width of the outline around a marker.

### `rotation`

**Default:** `0.0`

Rotates text around the given position

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `lineheight`

**Default:** `1.0`

The lineheight multiplier.

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

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `color`

**Default:** `@inherit textcolor`

Sets the color of the text. One can set one color per glyph by passing a `Vector{<:Colorant}`, or one colorant for the whole text. If color is a vector of numbers, the colormap args are used to map the numbers to colors.

### `offset`

**Default:** `(0.0, 0.0)`

The offset of the text from the given position in `markerspace` units.

### `markerspace`

**Default:** `:pixel`

Sets the space in which `fontsize` acts. See `Makie.spaces()` for possible inputs.

### `fontsize`

**Default:** `@inherit fontsize`

The fontsize in units depending on `markerspace`.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `false`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `glowcolor`

**Default:** `(:black, 0.0)`

Sets the color of the glow effect around the text.

### `transform_marker`

**Default:** `false`

Controls whether the model matrix (without translation) applies to the glyph itself, rather than just the positions. (If this is true, `scale!` and `rotate!` will affect the text glyphs.)
