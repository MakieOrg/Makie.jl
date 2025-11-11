# voronoiplot

## Examples

### Basic Voronoi plots

```@figure
using Random
Random.seed!(1234)


f = Figure(size=(1200, 450))
ax = Axis(f[1, 1])
voronoiplot!(ax, rand(Point2f, 50))

ax = Axis(f[1, 2])
voronoiplot!(ax, rand(10, 10), rand(10, 10), rand(10, 10))
f
```

### Voronoi tessellation from DelaunayTriangulation

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

points = rand(2, 50)
tri = triangulate(points)
vorn = voronoi(tri)
f, ax, tr = voronoiplot(vorn)
f
```

### Voronoi plot with custom extension factor

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

z = LinRange(0, 1, 250) .* exp.(LinRange(0, 16pi, 250) .* im)
f, ax, tr = voronoiplot(real(z), imag(z), unbounded_edge_extension_factor = 0.4, markersize = 7)
f
```

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

x = LinRange(0, 16pi, 50)
y = sin.(x)
bb = BBox(-1, 16pi + 1, -30, 30) # (xmin, xmax, ymin, ymax)
f, ax, tr = voronoiplot(x, y, show_generators=false,
    clip=bb, color=:white, strokewidth=2)
f
```

For clipped and centroidal tessellations, there are no unbounded polygons.

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

points = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
tri = triangulate(points)
refine!(tri; max_area = 0.001)
vorn = voronoi(tri, clip = true)
f, ax, tr = voronoiplot(vorn, show_generators = true, markersize = 13, marker = 'x')
f
```

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

angles = range(0, 2pi, length = 251)[1:end-1]
x = cos.(angles)
y = sin.(angles)
points = tuple.(x, y)
tri = triangulate(points)
refine!(tri; max_area = 0.001)
vorn = voronoi(tri, clip = true)
smooth_vorn = centroidal_smooth(vorn)
f, ax, tr = voronoiplot(smooth_vorn, show_generators=false)
f
```

See the [online documentation](https://docs.makie.org/stable/reference/plots/voronoiplot) for rendered examples.

## Attributes

### `alpha`

**Default:** `1.0`

The alpha value of the colormap or color attribute. Multiple alphas like in `plot(alpha=0.2, color=(:red, 0.5)`, will get multiplied.

### `strokecolor`

**Default:** `@inherit patchstrokecolor`

Sets the strokecolor of the polygons.

### `colormap`

**Default:** `@inherit colormap :viridis`

Sets the colormap that is sampled for numeric `color`s. `PlotUtils.cgrad(...)`, `Makie.Reverse(any_colormap)` can be used as well, or any symbol from ColorBrewer or PlotUtils. To see all available color gradients, you can call `Makie.available_gradients()`.

### `show_generators`

**Default:** `true`

Determines whether to plot the individual generators.

### `colorscale`

**Default:** `identity`

The color transform function. Can be any function, but only works well together with `Colorbar` for `identity`, `log`, `log2`, `log10`, `sqrt`, `logit`, `Makie.pseudolog10`, `Makie.Symlog10`, `Makie.AsinhScale`, `Makie.SinhScale`, `Makie.LogScale`, `Makie.LuptonAsinhScale`, and `Makie.PowerScale`.

### `highclip`

**Default:** `automatic`

The color for any value above the colorrange.

### `markersize`

**Default:** `@inherit markersize`

Sets the size of the points.

### `clip`

**Default:** `automatic`

Sets the clipping area for the generated polygons which can be a `Rect2` (or `BBox`), `Tuple` with entries `(xmin, xmax, ymin, ymax)` or as a `Circle`. Anything outside the specified area will be removed. If the `clip` is not set it is automatically determined using `unbounded_edge_extension_factor` as a `Rect`.

### `nan_color`

**Default:** `:transparent`

The color for NaN values.

### `strokewidth`

**Default:** `1.0`

Sets the width of the polygon stroke.

### `unbounded_edge_extension_factor`

**Default:** `0.1`

Sets the extension factor for the unbounded edges, used in `DelaunayTriangulation.polygon_bounds`.

### `smooth`

**Default:** `false`

If true, then the Voronoi tessellation is smoothed into a centroidal tessellation.

### `colorrange`

**Default:** `automatic`

The values representing the start and end points of `colormap`.

### `marker`

**Default:** `@inherit marker`

Sets the shape of the points.

### `color`

**Default:** `automatic`

Sets the color of the polygons. If `automatic`, the polygons will be individually colored according to the colormap.

### `markercolor`

**Default:** `@inherit markercolor`

Sets the color of the points.

### `lowclip`

**Default:** `automatic`

The color for any value below the colorrange.
