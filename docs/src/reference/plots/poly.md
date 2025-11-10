# poly

```
f, ax, pl = poly(args...; kw...) # return a new figure, axis, and plot
   ax, pl = poly(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = poly!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Poly(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

  * `polygon`: A `Polygon`, `MultiPolygon`, `Circle`, `Rect`, `AbstractMesh`, `VecTypes`, or `AbstractVector{<:VecTypes}` defining the polygon(s) to draw. Can also be an `AbstractVector` of any of these types to draw multiple polygons.
  * `xs, ys`: Two `AbstractVector{<:Real}` defining the x and y coordinates of polygon vertices.
  * `vertices, indices`: Vertex and index arrays defining a mesh (same as `Mesh` plot).

For detailed conversion information, see `Makie.conversion_docs(Poly)`.

## Examples

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

poly!(Point2f[(0, 0), (2, 0), (3, 1), (1, 1)], color = :red, strokecolor = :black, strokewidth = 1)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# polygon with hole
p = Polygon(
    Point2f[(0, 0), (2, 0), (3, 1), (1, 1)],
    [Point2f[(0.75, 0.25), (1.75, 0.25), (2.25, 0.75), (1.25, 0.75)]]
)

poly!(p, color = :blue)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = 1:15,
    colormap = :heat
)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1], aspect = DataAspect())

# shape decomposition
poly!(Circle(Point2f(0, 0), 15f0), color = :pink)

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1]; backgroundcolor = :gray15)

# vector of polygons
ps = [Polygon(rand(Point2f, 3) .+ Point2f(i, j))
    for i in 1:5 for j in 1:10]

poly!(ps, color = rand(RGBf, length(ps)))

f
```

```@figure
using Makie.GeometryBasics


f = Figure()
Axis(f[1, 1])

# vector of shapes
poly!(
    [Rect(i, j, 0.75, 0.5) for i in 1:5 for j in 1:3],
    color = :white,
    strokewidth = 2,
    strokecolor = 1:15,
    strokecolormap=:plasma,
)

f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/poly) for rendered examples.

## Attributes

### `transparency`

**Default:** `false`

Adjusts how the plot deals with transparency. In GLMakie `transparency = true` results in using Order Independent Transparency.

### `stroke_depth_shift`

**Default:** `-1.0e-5`

Depth shift of stroke plot. This is useful to avoid z-fighting between the stroke and the fill.

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `strokecolor`

**Default:** `@inherit patchstrokecolor`

Sets the color of the outline around a marker.

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

### `strokecolormap`

**Default:** `@inherit colormap`

Sets the colormap that is sampled for numeric `color`s.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `linestyle`

**Default:** `nothing`

Sets the dash pattern of the line. Options are `:solid` (equivalent to `nothing`), `:dot`, `:dash`, `:dashdot` and `:dashdotdot`. These can also be given in a tuple with a gap style modifier, either `:normal`, `:dense` or `:loose`. For example, `(:dot, :loose)` or `(:dashdot, :dense)`.

For custom patterns have a look at [`Makie.Linestyle`](@ref).

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering of outline corners. Options are `:miter` for sharp corners, `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `strokewidth`

**Default:** `@inherit patchstrokewidth`

Sets the width of the outline.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used for outlines. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

### `overdraw`

**Default:** `false`

Controls if the plot will draw over other plots. This specifically means ignoring depth checks in GL backends

### `cycle`

**Default:** `[:color => :patchcolor]`

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

Sets the minimum inner join angle below which miter line joins truncate. See also `Makie.miter_distance_to_angle`.

### `depth_shift`

**Default:** `0.0`

Adjusts the depth value of a plot after all other transformations, i.e. in clip space, where `-1 <= depth <= 1`. This only applies to GLMakie and WGLMakie and can be used to adjust render order (like a tunable overdraw).

### `color`

**Default:** `@inherit patchcolor`

Sets the color of the poly. Can be a `Vector{<:Colorant}` for per vertex colors or a single `Colorant`. A `Matrix{<:Colorant}` can be used to color the mesh with a texture, which requires the mesh to contain texture coordinates. Vector or Matrices of numbers can be used as well, which will use the colormap arguments to map the numbers to colors. One can also use a `<: AbstractPattern`, to cover the poly with a regular pattern, e.g. for hatching.

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `shading`

**Default:** `false`

Controls whether lights affect the polygon.

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `fxaa`

**Default:** `true`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `inspector_clear`

**Default:** `automatic`

Sets a callback function `(inspector, plot) -> ...` for cleaning up custom indicators in DataInspector.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.
