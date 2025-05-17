
# errorbars {#errorbars}
<details class='jldocstring custom-block' open>
<summary><a id='Makie.errorbars-reference-plots-errorbars' href='#Makie.errorbars-reference-plots-errorbars'><span class="jlbinding">Makie.errorbars</span></a> <Badge type="info" class="jlObjectType jlFunction" text="Function" /></summary>



```julia
errorbars(x, y, error_both; kwargs...)
errorbars(x, y, error_low, error_high; kwargs...)
errorbars(x, y, error_low_high; kwargs...)

errorbars(xy, error_both; kwargs...)
errorbars(xy, error_low, error_high; kwargs...)
errorbars(xy, error_low_high; kwargs...)

errorbars(xy_error_both; kwargs...)
errorbars(xy_error_low_high; kwargs...)
```


Plots errorbars at xy positions, extending by errors in the given `direction`.

If you want to plot intervals from low to high values instead of relative errors, use `rangebars`.

**Plot type**

The plot type alias for the `errorbars` function is `Errorbars`.


<Badge type="info" class="source-link" text="source"><a href="https://github.com/MakieOrg/Makie.jl/blob/c1ff276792827f16c26b5ad51ea371f8a3759971/MakieCore/src/recipes.jl#L520-L602" target="_blank" rel="noreferrer">source</a></Badge>

</details>


## Examples {#Examples}
<a id="example-669846c" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

xs = 0:0.5:10
ys = 0.5 .* sin.(xs)

lowerrors = fill(0.1, length(xs))
higherrors = LinRange(0.1, 0.4, length(xs))

errorbars!(xs, ys, higherrors; color = :red, label="data") # same low and high error

# plot position scatters so low and high errors can be discriminated
scatter!(xs, ys; markersize = 3, color = :black, label="data")

# the `label=` must be the same for merge to work
# without merge, two separate legend items will appear
axislegend(merge=true)

f
```

<img src="./669846c.png" width="600px" height="450px"/>

<a id="example-d287339" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

xs = 0:0.5:10
ys = 0.5 .* sin.(xs)

lowerrors = fill(0.1, length(xs))
higherrors = LinRange(0.1, 0.4, length(xs))

errorbars!(xs, ys, lowerrors, higherrors,
    color = range(0, 1, length = length(xs)),
    whiskerwidth = 10)

# plot position scatters so low and high errors can be discriminated
scatter!(xs, ys, markersize = 3, color = :black)

f
```

<img src="./d287339.png" width="600px" height="450px"/>

<a id="example-1f16088" />


```julia
using CairoMakie
f = Figure()
Axis(f[1, 1])

xs = 0:0.5:10
ys = 0.5 .* sin.(xs)

lowerrors = fill(0.1, length(xs))
higherrors = LinRange(0.1, 0.4, length(xs))

errorbars!(xs, ys, lowerrors, higherrors, whiskerwidth = 3, direction = :x)

# plot position scatters so low and high errors can be discriminated
scatter!(xs, ys, markersize = 3, color = :black)

f
```

<img src="./1f16088.png" width="600px" height="450px"/>


## Attributes {#Attributes}

### alpha {#alpha}

Defaults to `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### clip_planes {#clip_planes}

Defaults to `automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### color {#color}

Defaults to `@inherit linecolor`

The color of the lines. Can be an array to color each bar separately.

### colormap {#colormap}

Defaults to `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### colorrange {#colorrange}

Defaults to `automatic`

The values representing the start and end points of `colormap`.

### colorscale {#colorscale}

Defaults to `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10` and `Makie.Symlog10`.

### cycle {#cycle}

Defaults to `[:color]`

No docs available.

### depth_shift {#depth_shift}

Defaults to `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### direction {#direction}

Defaults to `:y`

The direction in which the bars are drawn. Can be `:x` or `:y`.

### fxaa {#fxaa}

Defaults to `true`

Adjusts whether the plot is rendered with fxaa (anti-aliasing, GLMakie only).

### highclip {#highclip}

Defaults to `automatic`

The color for any value above the colorrange.

### inspectable {#inspectable}

Defaults to `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### inspector_clear {#inspector_clear}

Defaults to `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### inspector_hover {#inspector_hover}

Defaults to `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### inspector_label {#inspector_label}

Defaults to `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### linecap {#linecap}

Defaults to `@inherit linecap`

No docs available.

### linewidth {#linewidth}

Defaults to `@inherit linewidth`

The thickness of the lines in screen units.

### lowclip {#lowclip}

Defaults to `automatic`

The color for any value below the colorrange.

### model {#model}

Defaults to `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### nan_color {#nan_color}

Defaults to `:transparent`

The color for NaN values.

### overdraw {#overdraw}

Defaults to `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### space {#space}

Defaults to `:data`

Sets the transformation space for box encompassing the plot. See `Makie.spaces()` for possible inputs.

### ssao {#ssao}

Defaults to `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### transformation {#transformation}

Defaults to `:automatic`

No docs available.

### transparency {#transparency}

Defaults to `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### visible {#visible}

Defaults to `true`

Controls whether the plot will be rendered or not.

### whiskerwidth {#whiskerwidth}

Defaults to `0`

The width of the whiskers or line caps in screen units.
