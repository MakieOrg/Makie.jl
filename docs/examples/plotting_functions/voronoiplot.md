# voronoiplot 

{{doc voronoiplot}}

## Examples 

The function `voronoiplot` requires a Voronoi tessellation from [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl) as input. 

When considering standard tessellations, without clipping, the unbounded polygons are clipped at a bounding box determined automatically by default, or from a user-provided bounding box (that must contain all polygon vertices). The automatic bounding box is determined by the bounding box of the polygon vertices, extended out some factor `unbounded_edge_extension_factor` (default `0.1`) proportional to the lengths of the bounding box's sides. The tessellation is coloured by Voronoi tile according to the given `colormap`. 

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

\begin{examplefigure}{svg = true}
```julia
using CairoMakie 
using DelaunayTriangulation
CairoMakie.activate!() # hide 

using Random 
Random.seed!(1234)

z = LinRange(0, 1, 250) .* exp.(LinRange(0, 16pi, 250) .* im)
points = tuple.(real(z), imag(z))
tri = triangulate(points)
vorn = voronoi(tri)
f, ax, tr = voronoiplot(vorn, unbounded_edge_extension_factor = 0.4, markersize = 7)
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
points = [x'; y']
tri = triangulate(points)
vorn = voronoi(tri)
f, ax, tr = voronoiplot(vorn, show_generators = false, bounding_box = (-1.0, 16pi + 1.0, -30, 30), polygon_color = :white, strokewidth = 2) # (xmin, xmax, ymin, ymax)
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
vorn = voronoi(tri, true)
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
vorn = voronoi(tri, true)
smooth_vorn = centroidal_smooth(vorn)
f, ax, tr = voronoiplot(smooth_vorn)
f
```
\end{examplefigure}