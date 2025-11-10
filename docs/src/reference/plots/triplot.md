# triplot

```
f, ax, pl = triplot(args...; kw...) # return a new figure, axis, and plot
   ax, pl = triplot(f[row, col], args...; kw...) # creates an axis in a subfigure grid position
       pl = triplot!(ax::Union{Scene, AbstractAxis}, args...; kw...) # Creates a plot in the given axis or scene.
SpecApi.Triplot(args...; kw...) # Creates a SpecApi plot, which can be used in `S.Axis(plots=[plot])`.
```

## Arguments

**Target signature:** `triangles::AbstractVector{<:Point2}`

  * `positions`: A `VecTypes` (`Point`, `Vec` or `Tuple`) or `AbstractVector{<:VecTypes}` corresponding to `(x, y)` positions.
  * `xs, ys`: Positions given per dimension. Can be `Real` to define a single position, or an `AbstractVector{<:Real}` or `ClosedInterval{<:Real}` to define multiple. Using `ClosedInterval` requires at least one dimension to be given as an array. If omitted, `xs` defaults to `eachindex(ys)`.

For detailed conversion information, see `Makie.conversion_docs(Triplot)`.

## Examples

See the [online documentation](https://docs.makie.org/stable/reference/plots/triplot) for rendered examples.

## Attributes

### `ghost_edge_linestyle`

**Default:** `@inherit linestyle`

Sets the linestyle of the ghost edges.

### `recompute_centers`

**Default:** `false`

Determines whether to recompute the representative points for the ghost edge orientation. Note that this will mutate `tri.representative_point_list` directly.

### `strokecolor`

**Default:** `@inherit patchstrokecolor`

Sets the color of triangle edges.

### `triangle_color`

**Default:** `:transparent`

Sets the color of the triangles.

### `show_ghost_edges`

**Default:** `false`

Determines whether to plot the ghost edges.

### `constrained_edge_linestyle`

**Default:** `@inherit linestyle`

Sets the linestyle of the constrained edges.

### `ghost_edge_color`

**Default:** `:blue`

Sets the color of the ghost edges.

### `show_convex_hull`

**Default:** `false`

Determines whether to plot the convex hull.

### `markersize`

**Default:** `@inherit markersize`

Sets the size of the points.

### `linestyle`

**Default:** `:solid`

Sets the linestyle of triangle edges.

### `joinstyle`

**Default:** `@inherit joinstyle`

Controls the rendering at line corners. Options are `:miter` for sharp corners, `:bevel` for cut-off corners, and `:round` for rounded corners. If the corner angle is below `miter_limit`, `:miter` is equivalent to `:bevel` to avoid long spikes.

### `ghost_edge_linewidth`

**Default:** `@inherit linewidth`

Sets the width of the ghost edges.

### `ghost_edge_extension_factor`

**Default:** `0.1`

Sets the extension factor for the rectangle that the exterior ghost edges are extended onto.

### `strokewidth`

**Default:** `1`

Sets the linewidth of triangle edges.

### `linecap`

**Default:** `@inherit linecap`

Sets the type of line cap used for triangle edges. Options are `:butt` (flat without extrusion), `:square` (flat with half a linewidth extrusion) or `:round`.

### `constrained_edge_linewidth`

**Default:** `@inherit linewidth`

Sets the width of the constrained edges.

### `constrained_edge_color`

**Default:** `:magenta`

Sets the color of the constrained edges.

### `miter_limit`

**Default:** `@inherit miter_limit`

" Sets the minimum inner line join angle below which miter joins truncate. See also `Makie.miter_distance_to_angle`.

### `marker`

**Default:** `@inherit marker`

Sets the shape of the points.

### `convex_hull_linestyle`

**Default:** `:dash`

Sets the linestyle of the convex hull.

### `convex_hull_linewidth`

**Default:** `@inherit linewidth`

Sets the width of the convex hull.

### `show_constrained_edges`

**Default:** `false`

Determines whether to plot the constrained edges.

### `markercolor`

**Default:** `@inherit markercolor`

Sets the color of the points.

### `show_points`

**Default:** `false`

Determines whether to plot the individual points. Note that this will only plot points included in the triangulation.

### `bounding_box`

**Default:** `automatic`

Sets the bounding box for truncating ghost edges which can be a `Rect2` (or `BBox`) or a tuple of the form `(xmin, xmax, ymin, ymax)`. By default, the rectangle will be given by `[a - eΔx, b + eΔx] × [c - eΔy, d + eΔy]` where `e` is the `ghost_edge_extension_factor`, `Δx = b - a` and `Δy = d - c` are the lengths of the sides of the rectangle, and `[a, b] × [c, d]` is the bounding box of the points in the triangulation.

### `convex_hull_color`

**Default:** `:red`

Sets the color of the convex hull.
