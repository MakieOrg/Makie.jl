# tricontour

```@shortdocs; canonical=false
tricontour
```

## Related methods
- Use `tricontour` to plot contour lines using unstructured data in 2D.
- Use `tricontourf` to plot filled contours using unstructured data in 2D.
- Use `contour` to plot contour lines using a grid in 2D.
- Use `contour3d` to plot contour lines using a grid in 3D.
- Use `contourf` to plot contour lines using a grid in 2D.
- Use `triplot` to plot a triangulation in 2D

## Triangulations and Relative mode

See the documentation of `tricontourf` to learn about manual triangulations and about passing relative level values.

## Examples

Plot contours for the function $z = x^2 + y^2 + \text{noise}$ using 50 random points with normally distributed values for $x$ and $y$

```@figure
using Random
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

f, ax, tr = tricontour(x, y, z, linewidth = 2, linestyle = :dash)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr)
f
```

Plot contours for the function $z = x*y$ using 200 random points with normally distributed values for $x$ and $y$.
Use 15 equally spaced levels for $z$.

Notice that `triplot` and `tricontour` create the same Delaunay triangulation, so we can call triplot directly on `x` and `y` to visualize the triangulation.

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

f, ax, tr = tricontour(
    x, y, z, colormap = :batlow,
    linewidth = 3, levels = 15
    )
triplot!([x'; y'], strokecolor=(:gray, 0.2), strokewidth = 2)
scatter!(
    x, y, color = z, colormap = :batlow,
    strokecolor = :black, strokewidth = 2
    )
Colorbar(ff[1, 2], tr)
f
```

**Example comparing `:relative` and `:normal` modes**

When `mode = :normal`, the `levels` parameter can be an integer indicating the number of contour lines or a one dimensional array (or range) indicating the desired values of $z$.

When `mode = :relative`, an array of `levels` between 0.0 and 1.0 can be interpreted as the desired percentiles of $z$. The actual values of $z$ to obtain the contours will be computed as $ z_k =  z_{min} +  (z_{max} -z_{min})*l_k $

```@figure
using Random
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

# FIXME: use same colormaps for scatter and contour lines
f = Figure()
ax1 = Axis(f[1,1], title="Normal `levels` (values of z)")
ax2 = Axis(f[1,2], title="Relative `levels` (percentiles of z)")
levels = [0.1, 0.25, 0.5, 0.75, 1.0]
tr_abs_levels = tricontour!(
    ax1, x, y, z, colormap = :viridis, linewidth = 3, alpha=0.5,
    levels = levels, mode=:normal
    )
tr_rel_levels = tricontour!(
    ax2, x, y, z, colormap = :viridis, linewidth = 3, alpha=0.5,
    levels = levels, mode=:relative
    )
scatter!(
    ax1, x, y, color = z, colormap = :viridis,
    strokecolor = :black, strokewidth = 2
    )
scatter!(
    ax2, x, y, color = z, colormap = :viridis,
    strokecolor = :black, strokewidth = 2
    )
Colorbar(f[2, 1], tr_abs_levels, vertical = false)
Colorbar(f[2, 2], tr_rel_levels, vertical = false)
f
```

**Example using a manual triangulation and comparison with `tricontourf`**

This example is adapted from the documentation of `tricontourf`. It shows how to overlay contour lines with filled contours and how to use a manual triangulation.

A triangulation is represented as a 3xN matrix of integers, where each column of three integers specifies the indices of the corners of one triangle in the vector of points.

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

# Left plot with manual triangulation
ff, ax, _ = tricontourf(
    x, y, z, triangulation = triangulation,
    axis = (; aspect = 1, title = "Manual triangulation")
    )
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
tricontour!(x, y, z, triangulation = triangulation, colormap=:reds)

# Right plot with default Delaunay
tricontourf(
    ff[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    axis = (; aspect = 1, title = "Delaunay triangulation")
    )
tricontour!(
    x, y, z, triangulation = Makie.DelaunayTriangulation(), colormap=:reds
    )
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

ff
```

## Attributes

```@attrdocs
Tricontour
```
