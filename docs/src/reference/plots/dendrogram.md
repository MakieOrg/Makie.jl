# dendrogram

```
f, ax, pl = dendrogram(args...; kw...) # return a new figure, axis, and plot
   ax, pl = dendrogram(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = dendrogram!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Dendrogram(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Examples

```@figure
using CairoMakie

# Relative positions of leaf nodes
# These positions will be translated to place the root node at `origin`
leaves = Point2f[
    (1,0),
    (2,0.5),
    (3,1),
    (4,2),
    (5,0)
]

# connections between nodes which merge into a new node
merges = [
    (1, 2), # creates node 6
    (6, 3), # 7
    (4, 5), # 8
    (7, 8), # 9
]

dendrogram(leaves, merges)
```

```@figure
using CairoMakie

leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

# Adding groups for each leaf node will result in branches of a common group
# to be colored the same (based on colormap). Branches with miss-matched groups
# use ungrouped_color
f, a, p = dendrogram(leaves, merges,
    groups = [1, 1, 2, 3, 3],
    colormap = [:red, :green, :blue],
    ungrouped_color = :black)

# Makie.dendrogram_node_positions(plot) can be used to get final node positions
# of all nodes. The N input nodes are the first N returned
textlabel!(a, map(ps -> ps[1:5], Makie.dendrogram_node_positions(p)), text = ["A", "A", "B", "C", "C"],
    shape = Circle(Point2f(0.5), 0.5), keep_aspect = true)
f
```

```@figure
using CairoMakie

leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f, a, p = dendrogram(leaves, merges, rotation = :right, branch_shape = :tree)
dendrogram!(a, leaves, merges, origin = (4, 4), rotation = :left, color = :orange)
f
```

```@figure
using CairoMakie

leaves = Point2f[(1,0), (2,0.5), (3,1), (4,2), (5,0)]
merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

f = Figure()
a = PolarAxis(f[1, 1])
dendrogram!(a, leaves, merges, linewidth = 3, color = :black, linestyle = :dash, origin = Point2f(0, 1))
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/dendrogram) for rendered examples.

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

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.

### `origin`

**Default:** `Point2d(0)`

Sets the position of the tree root.

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

### `branch_shape`

**Default:** `:box`

Specifies how node connections are drawn. Can be `:tree` for direct lines or `:box` for rectangular lines. Other styles can be defined by overloading `dendrogram_connectors!(::Val{:mystyle}, points, parent, child1, child2)` which should add the points connecting the parent node to its children to `points`.

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering at corners. Options are `:miter` for sharp corners, `:bevel` for "cut off" corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `inspector_label`

**Default:** `automatic`

Sets a callback function `(plot, index, position) -> string` which replaces the default label generated by DataInspector.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

### `rotation`

**Default:** `:down`

Sets the rotation of the dendrogram, i.e. where the leaves are relative to the root. Can be `:down`, `:right`, `:up`, `:left` or a float.

### `ungrouped_color`

**Default:** `:gray`

Sets the color of branches with mixed groups if groups are defined.

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

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `groups`

**Default:** `nothing`

Sets a group id for each leaf node. Branches that merge nodes of the same group will use their group to look up a color in the given colormap. Branches that merge different groups will use `ungrouped_color`.

### `linewidth`

**Default:** `@inherit linewidth`

Sets the width of the line in screen units

### `inspectable`

**Default:** `@inherit inspectable`

Sets whether this plot should be seen by `DataInspector`. The default depends on the theme of the parent scene.

### `depth`

**Default:** `automatic`

Scales the dendrogram so that the maximum distance between the root node and leaf nodes is `depth`. By default no scaling is applied, i.e. the depth or height of the dendrogram is derived from the given nodes and connections. (For this each parent node is at least 1 unit above its children.)

### `fxaa`

**Default:** `false`

Adjusts whether the plot is rendered with fxaa (fast approximate anti-aliasing, GLMakie only). Note that some plots implement a better native anti-aliasing solution (scatter, text, lines). For them `fxaa = true` generally lowers quality. Plots that show smoothly interpolated data (e.g. image, surface) may also degrade in quality as `fxaa = true` can cause blurring.

### `width`

**Default:** `automatic`

Scales the dendrogram so that the maximum distance between leaf nodes is `width`. By default no scaling is applied, i.e. the width of the dendrogram is defined by its arguments.
