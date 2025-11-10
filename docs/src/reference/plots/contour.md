# contour

```
f, ax, pl = contour(args...; kw...) # return a new figure, axis, and plot
   ax, pl = contour(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = contour!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Contour(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

  * `zs`: Defines z values for vertices of a grid using an `AbstractMatrix{<:Real}`.
  * `xs, ys`: Defines the (x, y) positions of grid vertices. A `ClosedInterval{<:Real}` or `Tuple{<:Real, <:Real}` is interpreted as the outer limits of the grid, between which vertices are spaced regularly. An `AbstractVector{<:Real}` defines vertex positions directly for the respective dimension. An `AbstractMatrix{<:Real}` allows grid positions to be defined per vertex, i.e. in a non-repeating fashion. If `xs` and `ys` are omitted they default to `axes(data, dim)`.

For detailed conversion information, see `Makie.conversion_docs(Contour)`.

## Examples

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(xs, ys, zs)

f
```

Omitting the `xs` and `ys` results in the indices of `zs` being used. We can also set arbitrary contour-levels using `levels`

```@figure
f = Figure()
Axis(f[1, 1])

xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
zs = [cos(x) * sin(y) for x in xs, y in ys]

contour!(zs,levels=-1:0.1:1)

f
```

One can also add labels and control label attributes such as `labelsize`, `labelcolor` or `labelfont`.

```@figure
himmelblau(x, y) = (x^2 + y - 11)^2 + (x + y^2 - 7)^2
x = y = range(-6, 6; length=100)
z = himmelblau.(x, y')

levels = 10.0.^range(0.3, 3.5; length=10)
colorscale = ReversibleScale(x -> x^(1 / 10), x -> x^10)
f, ax, ct = contour(x, y, z; labels=true, levels, colormap=:hsv, colorscale)
f
```

### Curvilinear grids

`contour` also supports *curvilinear* grids, where `x` and `y` are both matrices of the same size as `z`. This is similar to the input that [`surface`](@ref) accepts.

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
fig, ax, srf = surface(xs, ys, fill(0f0, size(zs)); color=zs, shading = NoShading, axis = (; type = Axis, aspect = DataAspect()))
ctr = contour!(ax, xs, ys, zs; color = :orange, levels = levels, labels = true, labelfont = :bold, labelsize = 12)

fig
```

### 3D contours

3D contour plots exist in two variants. `contour` implements a variant showing multiple isosurfaces, i.e. surfaces that sample the same value from a 3D array. [contour3d](@ref) computes the same isolines as a 2D `contour` plot but renders them in 3D at z values equal to their level.

```@figure backend=GLMakie
r = range(-pi, pi, length = 21)
data2d = [cos(x) + cos(y) for x in r, y in r]
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 400))
a1 = Axis3(f[1, 1], title = "3D contour()")
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d)

a2 = Axis3(f[1, 2], title = "contour3d()")
contour3d!(a2, r, r, data2d, linewidth = 3, levels = 10)
f
```

```@figure backend=GLMakie
r = range(-pi, pi, length = 21)
data3d = [cos(x) + cos(y) + cos(z) for x in r, y in r, z in r]

f = Figure(size = (700, 300))

# isorange controls the thickness of isosurfaces
# Note that artifacts may appear if isorange becomes too small (< 0.03 here)
a1 = Axis3(f[1, 1])
contour!(a1, -pi .. pi, -pi .. pi, -pi .. pi, data3d, isorange = 0.04)

# small alpha can be used to see into the contour plot
a2 = Axis3(f[1, 2])
contour!(a2, -pi .. pi, -pi .. pi, -pi .. pi, data3d, alpha = 0.05)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/contour) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

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

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `ssao`

**Default:** `false`

Adjusts whether the plot is rendered with ssao (screen space ambient occlusion). Note that this only makes sense in 3D plots and is only applicable with `fxaa = true`.

### `linestyle`

**Default:** `nothing`

Sets the dash pattern of contour lines. See `?lines`.

### `labelformatter`

**Default:** `contour_label_formatter`

Formats the numeric values of the contour levels to strings.

### `labels`

**Default:** `false`

If `true`, adds text labels to the contour lines.

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering at line corners. Options are `:miter` for sharp corners, `:bevel` for cut-off corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `enable_depth`

**Default:** `true`

Controls whether 3D contours consider depth. Turning this off may improve performance.

### `labelcolor`

**Default:** `nothing`

Color of the contour labels, if `nothing` it matches `color` by default.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used for contour lines. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

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

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `miter_limit`

**Default:** `@inherit miter_limit`

" Sets the minimum inner line join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

### `model`

**Default:** `automatic`

Sets a model matrix for the plot. This overrides adjustments made with `translate!`, `rotate!` and `scale!`.

### `color`

**Default:** `nothing`

The color of the contour lines. If `nothing`, the color is determined by the numerical values of the contour levels in combination with `colormap` and `colorrange`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `labelfont`

**Default:** `@inherit font`

The font of the contour labels.

### `isorange`

**Default:** `automatic`

Sets the tolerance for sampling of a `level` in 3D contour plots.

### `labelsize`

**Default:** `10`

Font size of the contour labels

### `linewidth`

**Default:** `1.0`

Sets the width of contour lines.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `levels`

**Default:** `5`

Controls the number and location of the contour lines. Can be either

  * an `Int` that produces n equally wide levels or bands
  * an `AbstractVector{<:Real}` that lists n consecutive edges from low to high, which result in n-1 levels or bands

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.
