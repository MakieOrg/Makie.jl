# voronoiplot

{{doc voronoiplot}}

## Examples

A `voronoiplot` generates a cell for each passed position similar to `heatmap`,
however the cells are not restricted to a rectangular shape. It can be called with
point based (like `scatter` or `lines`) or `heatmap`-like inputs.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)


f = Figure(size=(1200, 450))
ax = Axis(f[1, 1])
voronoiplot!(ax, rand(Point2f, 50))

ax = Axis(f[1, 2])
voronoiplot!(ax, rand(10, 10), rand(10, 10), rand(10, 10))
f
```
\end{examplefigure}

`voronoiplot` uses the Voronoi tessellation from
[DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl)
to generate the cells. You can also do this yourself and directly plot the
`VoronoiTessellation` object returned.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

points = rand(2, 50)
tri = triangulate(points)
vorn = voronoi(tri)
f, ax, tr = voronoiplot(vorn)
f
```
\end{examplefigure}


When considering standard tessellations the unbounded polygons are clipped at a bounding box determined automatically by default, or from a user-provided clipping shape (a rectangle or circle).
The automatic bounding box is determined by the bounding box of generators of the tessellation, meaning the provided points, extended out by some factor `unbounded_edge_extension_factor` (default `0.1`) proportional to the lengths of the bounding box's sides.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

z = LinRange(0, 1, 250) .* exp.(LinRange(0, 16pi, 250) .* im)
f, ax, tr = voronoiplot(real(z), imag(z), unbounded_edge_extension_factor = 0.4, markersize = 7)
f
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = LinRange(0, 16pi, 50)
y = sin.(x)
bb = BBox(-1, 16pi + 1, -30, 30) # (xmin, xmax, ymin, ymax)
f, ax, tr = voronoiplot(x, y, show_generators=false,
    clip=bb, color=:white, strokewidth=2)
f
```
\end{examplefigure}

For clipped and centroidal tessellations, there are no unbounded polygons.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

points = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
tri = triangulate(points)
refine!(tri; max_area = 0.001)
vorn = voronoi(tri, clip = true)
f, ax, tr = voronoiplot(vorn, show_generators = true, markersize = 13, marker = 'x')
f
```
\end{examplefigure}

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

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
\end{examplefigure}