# tricontour

## Examples

### Basic usage

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = sin.(2π .* x) .* cos.(2π .* y)

f, ax, tr = tricontour(x, y, z; levels = 10)
Colorbar(f[1, 2], tr)
f
```

### `color`

Setting `color` to a fixed value draws all isolines in that color instead of sampling from the colormap.

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = sin.(2π .* x) .* cos.(2π .* y)

f, ax, tr = tricontour(x, y, z; levels = 10, color = :black, linewidth = 1.5)
f
```

### `levels`

Explicit isoline values can be passed as a vector.

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontour(x, y, z; levels = -1.5:0.3:0.0, colormap = :plasma)
Colorbar(f[1, 2], tr)
f
```

#### Triangulation modes

A pre-built `Triangulation` from [DelaunayTriangulation.jl](https://github.com/DanielVandH/DelaunayTriangulation.jl) can be passed as the first argument instead of `xs` and `ys`. Manual triangulations can also be passed as a 3×N integer matrix where each column specifies the vertex indices of one triangle.

```@figure
using DelaunayTriangulation
using Random
Random.seed!(123)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

inner = [n:-1:1; n]
outer = [(n+1):(2n); n+1]
boundary_nodes = [[outer], [inner]]
points = [x'; y']
tri = triangulate(points; boundary_nodes = boundary_nodes)

f, ax, tr = tricontour(tri, z; levels = 8, axis = (; aspect = 1))
Colorbar(f[1, 2], tr)
f
```
