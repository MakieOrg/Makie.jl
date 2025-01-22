# tricontourf

```@shortdocs; canonical=false
tricontourf
```


## Examples

```@figure
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

f, ax, tr = tricontourf(x, y, z, colormap = :batlow)
scatter!(x, y, color = z, colormap = :batlow, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

#### Triangulation modes

Manual triangulations can be passed as a 3xN matrix of integers, where each column of three integers specifies the indices of the corners of one triangle in the vector of points.

```@figure
using Random
Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
triangulation = hcat(triangulation_inner, triangulation_outer)

f, ax, _ = tricontourf(x, y, z, triangulation = triangulation,
    axis = (; aspect = 1, title = "Manual triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

tricontourf(f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    axis = (; aspect = 1, title = "Delaunay triangulation"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

f
```

By default, `tricontourf` performs unconstrained triangulations.
Greater control over the triangulation, such as allowing for enforced boundaries, can be achieved by using [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl) and passing the resulting triangulation as the first argument of `tricontourf`.
For example, the above annulus can also be plotted as follows:

```@figure
using DelaunayTriangulation
using Random

Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

inner = [n:-1:1; n] # clockwise inner 
outer = [(n+1):(2n); n+1] # counter-clockwise outer
boundary_nodes = [[outer], [inner]]
points = [x'; y']
tri = triangulate(points; boundary_nodes = boundary_nodes)
f, ax, _ = tricontourf(tri, z;
    axis = (; aspect = 1, title = "Constrained triangulation\nvia DelaunayTriangulation.jl"))
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
f
```

Boundary nodes make it possible to support more complicated regions, possibly with holes, than is possible by only providing points themselves.

```@figure
using DelaunayTriangulation

## Start by defining the boundaries, and then convert to the appropriate interface 
curve_1 = [
    [(0.0, 0.0), (5.0, 0.0), (10.0, 0.0), (15.0, 0.0), (20.0, 0.0), (25.0, 0.0)],
    [(25.0, 0.0), (25.0, 5.0), (25.0, 10.0), (25.0, 15.0), (25.0, 20.0), (25.0, 25.0)],
    [(25.0, 25.0), (20.0, 25.0), (15.0, 25.0), (10.0, 25.0), (5.0, 25.0), (0.0, 25.0)],
    [(0.0, 25.0), (0.0, 20.0), (0.0, 15.0), (0.0, 10.0), (0.0, 5.0), (0.0, 0.0)]
] # outer-most boundary: counter-clockwise  
curve_2 = [
    [(4.0, 6.0), (4.0, 14.0), (4.0, 20.0), (18.0, 20.0), (20.0, 20.0)],
    [(20.0, 20.0), (20.0, 16.0), (20.0, 12.0), (20.0, 8.0), (20.0, 4.0)],
    [(20.0, 4.0), (16.0, 4.0), (12.0, 4.0), (8.0, 4.0), (4.0, 4.0), (4.0, 6.0)]
] # inner boundary: clockwise 
curve_3 = [
    [(12.906, 10.912), (16.0, 12.0), (16.16, 14.46), (16.29, 17.06),
    (13.13, 16.86), (8.92, 16.4), (8.8, 10.9), (12.906, 10.912)]
] # this is inside curve_2, so it's counter-clockwise 
curves = [curve_1, curve_2, curve_3]
points = [
    (3.0, 23.0), (9.0, 24.0), (9.2, 22.0), (14.8, 22.8), (16.0, 22.0),
    (23.0, 23.0), (22.6, 19.0), (23.8, 17.8), (22.0, 14.0), (22.0, 11.0),
    (24.0, 6.0), (23.0, 2.0), (19.0, 1.0), (16.0, 3.0), (10.0, 1.0), (11.0, 3.0),
    (6.0, 2.0), (6.2, 3.0), (2.0, 3.0), (2.6, 6.2), (2.0, 8.0), (2.0, 11.0),
    (5.0, 12.0), (2.0, 17.0), (3.0, 19.0), (6.0, 18.0), (6.5, 14.5),
    (13.0, 19.0), (13.0, 12.0), (16.0, 8.0), (9.8, 8.0), (7.5, 6.0),
    (12.0, 13.0), (19.0, 15.0)
]
boundary_nodes, points = convert_boundary_points_to_indices(curves; existing_points=points)
edges = Set(((1, 19), (19, 12), (46, 4), (45, 12)))

## Extract the x, y 
tri = triangulate(points; boundary_nodes = boundary_nodes, segments = edges)
z = [(x - 1) * (y + 1) for (x, y) in DelaunayTriangulation.each_point(tri)] # note that each_point preserves the index order
f, ax, _ = tricontourf(tri, z, levels = 30; axis = (; aspect = 1))
f
```

```@figure
using DelaunayTriangulation

using Random
Random.seed!(1234)

θ = [LinRange(0, 2π * (1 - 1/19), 20); 0]
xy = Vector{Vector{Vector{NTuple{2,Float64}}}}()
cx = [0.0, 3.0]
for i in 1:2
    push!(xy, [[(cx[i] + cos(θ), sin(θ)) for θ in θ]])
    push!(xy, [[(cx[i] + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
end
boundary_nodes, points = convert_boundary_points_to_indices(xy)
tri = triangulate(points; boundary_nodes=boundary_nodes)
z = [(x - 3/2)^2 + y^2 for (x, y) in DelaunayTriangulation.each_point(tri)] # note that each_point preserves the index order

f, ax, tr = tricontourf(tri, z, colormap = :matter)
f
```

#### Relative mode

Sometimes it's beneficial to drop one part of the range of values, usually towards the outer boundary.
Rather than specifying the levels to include manually, you can set the `mode` attribute
to `:relative` and specify the levels from 0 to 1, relative to the current minimum and maximum value.

```@figure
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontourf(x, y, z, mode = :relative, levels = 0.2:0.1:1)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

## Attributes

```@attrdocs
Tricontourf
```
