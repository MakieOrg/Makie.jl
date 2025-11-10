# lines

```
f, ax, pl = lines(args...; kw...) # return a new figure, axis, and plot
   ax, pl = lines(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = lines!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Lines(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `positions::AbstractVector{<:Union{Point2, Point3}}`

  * `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` or `(x, y, z)` positions.
  * `xs, ys[, zs]`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. `zs` can also be given as a `AbstractMatrix` which will cause `xs` and `ys` to be interpreted per matrix axis.
  * `ys`: Defaults `xs` positions to `eachindex(ys)`.

For detailed conversion information, see `Makie.conversion_docs(Lines)`.

## Examples

### Dealing with outline artifacts in GLMakie

In GLMakie 3D line plots can generate outline artifacts depending on the order line segments are rendered in. Currently there are a few ways to mitigate this problem, but they all come at a cost:

  * `fxaa = true` will disable the native anti-aliasing of line segments and use fxaa instead. This results in less detailed lines.
  * `transparency = true` will disable depth testing to a degree, resulting in all lines being rendered without artifacts. However with this lines will always have some level of transparency.
  * `overdraw = true` will disable depth testing entirely (read and write) for the plot, removing artifacts. This will however change the z-order of line segments and allow plots rendered later to show up on top of the lines plot.

```@figure backend=GLMakie
ps = rand(Point3f, 500)
cs = rand(500)
f = Figure(size = (600, 650))
Label(f[1, 1], "base", tellwidth = false)
lines(f[2, 1], ps, color = cs, fxaa = false)
Label(f[1, 2], "fxaa = true", tellwidth = false)
lines(f[2, 2], ps, color = cs, fxaa = true)
Label(f[3, 1], "transparency = true", tellwidth = false)
lines(f[4, 1], ps, color = cs, transparency = true)
Label(f[3, 2], "overdraw = true", tellwidth = false)
lines(f[4, 2], ps, color = cs, overdraw = true)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/lines) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

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

### `inspector_hover`

**Default:** `automatic`

Sets a callback function `(inspector, plot, index) -> ...` which replaces the default `show_data` methods.

### `clip_planes`

**Default:** `@inherit clip_planes automatic`

Clip planes offer a way to do clipping in 3D space. You can set a Vector of up to 8 `Plane3f` planes here, behind which plots will be clipped (i.e. become invisible). By default clip planes are inherited from the parent plot or scene. You can remove parent `clip_planes` by passing `Plane3f[]`.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `linestyle`

**Default:** `nothing`

Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](@ref).

**Example:**

```@figure
linestyles = [:solid, :dot, :dash, :dashdot, :dashdotdot]
gapstyles = [:normal, :dense, :loose, 10]
fig = Figure()
with_updates_suspended(fig.layout) do
    for (i, ls) in enumerate(linestyles)
        for (j, gs) in enumerate(gapstyles)
            title = gs === :normal ? repr(ls) : "$((ls, gs))"
            ax = Axis(fig[i, j]; title, yautolimitmargin = (0.2, 0.2))
            hidedecorations!(ax)
            hidespines!(ax)
            linestyle = (ls, gs)
            for linewidth in 1:3
                lines!(ax, 1:10, fill(linewidth, 10); linestyle, linewidth)
            end
        end
    end
end
fig

```

```@figure
fig = Figure()
patterns = [
    [0, 1, 2],
    [0, 20, 22],
    [0, 2, 4, 12, 14],
    [0, 2, 4, 6, 8, 10, 20],
    [0, 1, 2, 4, 6, 9, 12],
    [0.0, 4.0, 6.0, 9.5],
]
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2))
for (i, pattern) in enumerate(patterns)
    lines!(ax, [-i, -i], linestyle = Linestyle(pattern), linewidth = 4)
    text!(ax, (1.5, -i), text = "Linestyle($pattern)",
        align = (:center, :bottom), offset = (0, 10))
end
hidedecorations!(ax)
fig

```

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

**Example:**

```@figure
                    
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.05, 0.15))
hidedecorations!(ax)

joinstyles = [:miter, :bevel, :round]
for (i, joinstyle) in enumerate(joinstyles)
    x = (1:3) .+ 5 * (i - 1)
    ys = [[0.5, 3.5, 0.5], [3, 5, 3], [5, 6, 5], [6.5, 7, 6.5]]
    for y in ys
        lines!(ax, x, y; linewidth = 15, joinstyle, color = :black)
    end
    text!(ax, x[2], ys[end][2], text = ":$joinstyle",
        align = (:center, :bottom), offset = (0, 15), font = :bold)
end

text!(ax, 4.5, 4.5, text = "for angles
below miter_limit,
:miter == :bevel",
    align = (:center, :center))

fig

```

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

**Example:**

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.2, 0.2))
hidedecorations!(ax)

linecaps = [:butt, :square, :round]
for (i, linecap) in enumerate(linecaps)
    lines!(ax, [i, i]; color = :tomato, linewidth = 15, linecap)
    lines!(ax, [i, i]; color = :black, linewidth = 15, linecap = :butt)
    text!(1.5, i, text = ":$linecap", font = :bold,
        align = (:center, :bottom), offset = (0, 15))
end
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

### `miter_limit`

**Default:** `@inherit miter_limit`

Sets the minimum inner join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `color`

**Default:** `@inherit linecolor`

The color of the line.

**Example:**

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.1, 0.1), xautolimitmargin = (0.1, 0.1))
hidedecorations!(ax)

lines!(ax, 1:9, iseven.(1:9) .- 0; color = :tomato)
lines!(ax, 1:9, iseven.(1:9) .- 1; color = (:tomato, 0.5))
lines!(ax, 1:9, iseven.(1:9) .- 2; color = 1:9)
lines!(ax, 1:9, iseven.(1:9) .- 3; color = 1:9, colormap = :plasma)
lines!(ax, 1:9, iseven.(1:9) .- 4; color = RGBf.(0, (0:8) ./ 8, 0))
fig

```

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `linewidth`

**Default:** `@inherit linewidth`

Sets the width of the line in screen units

**Example:**

```@figure
fig = Figure()
ax = Axis(fig[1, 1], yautolimitmargin = (0.2, 0.2), xautolimitmargin = (0.1, 0.1))
hidedecorations!(ax)

for linewidth in 1:10
    lines!(ax, iseven.(1:9) .+ linewidth, 1:9; color = :black, linewidth)
    text!(ax, linewidth + 0.5, 9; text = "$linewidth", font = :bold,
        align = (:center, :bottom), offset = (0, 15))
end
fig

```

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `false`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.
