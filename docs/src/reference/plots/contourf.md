# contourf

```
f, ax, pl = contourf(args...; kw...) # return a new figure, axis, and plot
   ax, pl = contourf(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = contourf!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Contourf(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

  * `zs`: Defines z values for vertices of a grid using an `AbstractMatrix{<:Real}`.
  * `xs, ys`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex positions directly for the respective dimension. An `AbstractMatrix{<:Real}` allows grid positions to be defined per vertex, i.e. in a non-repeating fashion. If `xs` and `ys` are omitted they default to `axes(data, dim)`.

For detailed conversion information, see `Makie.conversion_docs(Contourf)`.

## Examples

```@figure
using DelimitedFiles


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure()
Axis(f[1, 1])

co = contourf!(volcano, levels = 10)

Colorbar(f[1, 2], co)

f
```

```@figure
using DelimitedFiles


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure()
ax = Axis(f[1, 1])

co = contourf!(volcano,
    levels = range(100, 180, length = 10),
    extendlow = :cyan, extendhigh = :magenta)

tightlimits!(ax)

Colorbar(f[1, 2], co)

f
```

```@figure
using DelimitedFiles


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure()
ax = Axis(f[1, 1])

co = contourf!(volcano,
    levels = range(100, 180, length = 10),
    extendlow = :auto, extendhigh = :auto)

tightlimits!(ax)

Colorbar(f[1, 2], co)

f
```

#### Relative mode

Sometimes it's beneficial to drop one part of the range of values, usually towards the outer boundary. Rather than specifying the levels to include manually, you can set the `mode` attribute to `:relative` and specify the levels from 0 to 1, relative to the current minimum and maximum value.

```@figure
using DelimitedFiles


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure(size = (800, 400))

Axis(f[1, 1], title = "Relative mode, drop lowest 30%")
contourf!(volcano, levels = 0.3:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(volcano, levels = 10)

f
```

### Curvilinear grids

`contourf` also supports *curvilinear* grids, where `x` and `y` are both matrices of the same size as `z`. This is similar to the input that [`surface`](@ref) accepts.

Let's warp a regular grid of `x` and `y` by some nonlinear function, and plot its contours:

```@figure
x = -10:10
y = -10:10
# The curvilinear grid:
xs = [x + 0.01y^3 for x in x, y in y]
ys = [y + 10cos(x/40) for x in x, y in y]
# Now, for simplicity, we calculate the `zs` values to be
# the radius from the center of the grid (0, 10).
zs = sqrt.(xs .^ 2 .+ (ys .- 10) .^ 2)
# We can use Makie's tick finders to get some nice looking contour levels:
levels = Makie.get_tickvalues(Makie.LinearTicks(7), extrema(zs)...)
# and now, we plot!
f = Figure()
ax1 = Axis(f[1, 1])
ctrf1 = contourf!(ax1, x, y, zs; levels = levels)
ax2 = Axis(f[1, 2])
ctrf2 = contourf!(ax2, xs, ys, zs; levels = levels)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/contourf) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### `visible`

**Default:** `true`

Controls whether the plot gets rendered or not.

### `space`

**Default:** `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `extendlow`

**Default:** `nothing`

In `:normal` mode, if you want to show a band from `-Inf` to the low edge, set `extendlow` to `:auto` to give the extension the same color as the first level, or specify a color directly (default `nothing` means no extended band).

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `extendhigh`

**Default:** `nothing`

In `:normal` mode, if you want to show a band from the high edge to `Inf`, set `extendhigh` to `:auto` to give the extension the same color as the last level, or specify a color directly (default `nothing` means no extended band).

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `mode`

**Default:** `:normal`

Determines how the `levels` attribute is interpreted, either `:normal` or `:relative`. In `:normal` mode, the levels correspond directly to the z values. In `:relative` mode, you specify edges by the fraction between minimum and maximum value of `zs`. This can be used for example to draw bands for the upper 90% while excluding the lower 10% with `levels = 0.1:0.1:1.0, mode = :relative`.

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

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

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `levels`

**Default:** `10`

Can be either

  * an `Int` that produces n equally wide levels or bands
  * an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands

If `levels` is an `Int`, the contourf plot will be rectangular as all `zs` values will be covered edge to edge. This is why `Axis` defaults to tight limits for such contourf plots. If you specify `levels` as an `AbstractVector{<:Real}`, however, note that the axis limits include the default margins because the contourf plot can have an irregular shape. You can use `tightlimits!(ax)` to tighten the limits similar to the `Int` behavior.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.
