# triplot

{{doc triplot}}

## Examples

A `triplot` generates a triangle mesh from an arbitrary set of points and shows
its wireframe. The input data can either be point based (like `scatter` or
`lines`) or a `Triangulation` from
[DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl).

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

points = randn(Point2f, 50)
f, ax, tr = triplot(points)
scatter!(ax, points)

tri = triangulate(points)
ax, tr = triplot(f[1, 2], tri)
scatter!(ax, points)
f
```
\end{examplefigure}

You can use `triplot` to visualise the [ghost edges](https://danielvandh.github.io/DelaunayTriangulation.jl/stable/boundary_handling/#Ghost-Triangles) surrounding the boundary.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
inner = [n:-1:1; n] # clockwise inner
outer = [(n+1):(2n); n+1] # counter-clockwise outer
boundary_nodes = [[outer], [inner]]
points = [x'; y']
tri = triangulate(points; boundary_nodes = boundary_nodes)

f, ax, tr = triplot(tri; show_ghost_edges = true, show_points = true)
f
```
\end{examplefigure}

You can also highlight the constrained edges and display the convex hull, which is especially useful when the triangulation is no longer convex.

\begin{examplefigure}{svg = true}
```julia
using CairoMakie
using DelaunayTriangulation
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

outer = [
    (0.0,0.0),(2.0,1.0),(4.0,0.0),
    (6.0,2.0),(2.0,3.0),(3.0,4.0),
    (6.0,6.0),(0.0,6.0),(0.0,0.0)
]
inner = [
    (1.0,5.0),(2.0,4.0),(1.01,1.01),
    (1.0,1.0),(0.99,1.01),(1.0,5.0)
]
boundary_points = [[outer], [inner]]
boundary_nodes, points = convert_boundary_points_to_indices(boundary_points)
tri = triangulate(points; boundary_nodes = boundary_nodes, edges = Set(((1, 9),)))
refine!(tri; max_area=1e-3get_total_area(tri))

f, ax, tr = triplot(tri, show_constrained_edges = true, constrained_edge_linewidth = 4, show_convex_hull = true)
f
```
\end{examplefigure}