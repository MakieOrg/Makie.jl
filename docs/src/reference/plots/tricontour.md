# tricontour

```@shortdocs; canonical=false
tricontour
```

## Related methods
- Use `tricontour`(@ref) to plot contour lines using unstructured data in 2D.
- Use `tricontourf`(@ref) to plot filled contours using unstructured data in 2D.
- Use `contour`(@ref) to plot contour lines using a grid in 2D.
- Use `contour3d`(@ref) to plot contour lines using a grid in 3D.
- Use `contourf`(@ref) to plot contour lines using a grid in 2D.
- Use `triplot`(@ref) to plot a triangulation in 2D

## Triangulations and Relative mode

See the documentation of `tricontourf`(@ref) to learn about manual triangulations and about passing relative level values.

## Examples

**Example: Evaluate a function at random points to obtain its contour plot**

Plot contours for the function $z = x^2 + y^2 + \text{noise}$ using 50 random points with normally distributed values for $x$ and $y$.
Compare a discrete colormap (left axis) with a continuous colormap (right axis)

```@figure
using CairoMakie
using Random

CairoMakie.activate!()
Random.seed!(1234)

x = randn(50)
y = randn(50)
z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* randn.()

# Notice that tr.plots[1] references the labels, 
# and tr.plots[2] references the contours

f, ax, tr = tricontour(x, y, z, linewidth = 2, linestyle = :dash, levels=5)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 2], tr.plots[2])
ax.title = "Discrete colormap (default)"

ax2 = Axis(f[1,3], title="Continuous colormap")
tr2 = tricontour!(
    ax2, x, y, z, linewidth = 2, linestyle = :dash, 
    discretize_colormap=false, levels=5)
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
Colorbar(f[1, 4], tr2.plots[2])
f
```

**Example: comparison of  `contour` and `tricontour`**

Compare contours lines of $z = cos(x) * sin(y)$ obtained with  `contour` over a
rectangular domain, with those obtained with and `tricontour` over a subdomain with the shape of an ellipse.
In this example, a mask is used to filter points inside the ellipse.

```@figure
using CairoMakie
using Random

CairoMakie.activate!()
Random.seed!(1234)

f = Figure()
ax1 = Axis(f[1, 1], title="contour and tricontour", aspect = DataAspect())
xs = LinRange(0, 10, 100)
ys = LinRange(0, 15, 100)
xs1 = [x for x in xs, y in ys]
ys1 = [y for x in xs, y in ys]
zs1 = [cos(x) * sin(y) for x in xs, y in ys]

levels = -1:0.1:1
contour!(ax1, xs1, ys1, zs1, levels=levels)

mask_region(x, y) = ((x-5)/4)^2 + ((y-7)/6)^2 < 1

xs2 = [x for x in xs, y in ys if mask_region(x,y)]
ys2 = [y for x in xs, y in ys if mask_region(x,y)]
zs2 = [cos(x) * sin(y) for x in xs, y in ys if mask_region(x,y)]
tr = tricontour!(
    ax1, xs2[:], ys2[:], zs2[:], levels=levels,
    color=:black, linestyle = :dash
    )
f
```

**Example: visualization of contours generated from random points**

Plot contours for the function $z = x*y$ using 200 random points with normally distributed values for $x$ and $y$.
Use 15 equally spaced levels for $z$.

Notice that `triplot` and `tricontour` create the same Delaunay triangulation, so we can call triplot directly on `x` and `y` to visualize the triangulation.

```@figure
using CairoMakie
using Random

CairoMakie.activate!()
Random.seed!(1234)

x = randn(200)
y = randn(200)
z = x .* y

f, ax, tr = tricontour(
    x, y, z, colormap = :batlow, linewidth = 3, levels = 15
    )
triplot!([x'; y'], strokecolor=(:gray, 0.2), strokewidth = 2)
scatter!(
    x, y, color = z, colormap = :batlow,
    strokecolor = :black, strokewidth = 2
    )
Colorbar(f[1, 2], tr.plots[2])
f
```

**Example comparing `:relative` and `:normal` modes of for levels in `tricontour`**

When `mode = :normal`, the `levels` parameter can be an integer indicating the number of contour lines or a one dimensional array (or range) indicating the desired values of $z$.

When `mode = :relative`, an array of `levels` between 0.0 and 1.0 can be interpreted as the desired percentiles of $z$. The actual values of $z$ to obtain the contours will be computed as $ z_k =  z_{min} +  (z_{max} -z_{min})*l_k $

```@figure
using CairoMakie
using Random

CairoMakie.activate!()
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
Colorbar(f[2, 1], tr_abs_levels.plots[2], vertical = false)
Colorbar(f[2, 2], tr_rel_levels.plots[2], vertical = false)
f
```

**Example using a manual triangulation and comparison with `tricontourf`**

This example is adapted from the documentation of `tricontourf`. It shows how to overlay contour lines with filled contours and how to use a manual triangulation.

A triangulation is represented as a 3xN matrix of integers, where each column of three integers specifies the indices of the corners of one triangle in the vector of points.

```@figure
using CairoMakie
using Random

CairoMakie.activate!()
Random.seed!(1234)

n = 20
angles = range(0, 2pi, length = n+1)[1:end-1]
x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.*randn.()

triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
triangulation = hcat(triangulation_inner, triangulation_outer)

num_lines = 5
num_bands = num_lines + 1

num_lines = [1.0, 1.5, 3 ,5]
num_bands = num_lines
# Left plot with manual triangulation
f, ax, _ = tricontourf(
    x, y, z, triangulation = triangulation, levels = num_bands,
    axis = (; aspect = 1, title = "Manual triangulation")
    )
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
tricontour!(
    x, y, z, triangulation = triangulation, colormap=:reds,
    levels = num_lines
    )

# Right plot with default Delaunay
tricontourf(
    f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
    levels = num_bands,
    axis = (; aspect = 1, title = "Delaunay triangulation")
    )
tricontour!(
    x, y, z, triangulation = Makie.DelaunayTriangulation(), colormap=:reds,
    levels = num_lines
    )
scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

f
```

**Example: create a Delaunay triangulation for an irregular domain and use it to draw contour lines for $z = f(x,y)$**

```@figure
using CairoMakie
using DelaunayTriangulation

CairoMakie.activate!()

outer = [
    (0.0,0.0),(2.0,1.0),(4.0,0.0),
    (6.0,2.0),(2.0,3.0),(3.0,4.0),
    (6.0,6.0),(0.0,6.0),(0.0,0.0)
];
inner = [
    (1.0,5.0),(2.0,4.0),(1.01,1.01),
    (1.0,1.0),(0.99,1.01),(1.0,5.0)
];
boundary_points = [[outer], [inner]]
boundary_nodes, points = convert_boundary_points_to_indices(boundary_points)
tri = triangulate(points; boundary_nodes = boundary_nodes)

refine!(tri; max_area=1e-3*get_area(tri))

f, ax, tr = triplot(
    tri, show_constrained_edges = true, constrained_edge_linewidth = 3,
    constrained_edge_color = :black,
    show_convex_hull = true, strokecolor=(:gray, 0.2), strokewidth = 2
    )

x = [p[1] for p in tri.points];
y = [p[2] for p in tri.points];
z = @. (sin(x)-3)^2 + (cos(y)-3)^2 - 10;

tr = tricontour!(
    ax, tri, z, labels=true, levels = collect(-2:2:16),
    linewidth=3.0, labelsize=12, colormap = :cividis, labelcolor=:red,)


Colorbar(f[1,2] ,tr.plots[2])
ax.title[]= L"f(x,y) = (sin(x) - 3)^2 + (cos(y) - 3)^2 - 10"
f
```

**Example: Use contour z=0 to plot the intersection of surfaces**

Contour plots can be used to find the intersections of 3D surfaces. Given three cones $c1(x,y)$, $c2(x,y)$, $c3(x,y)$, their pairwise intersections occur where their heights are equal.

$$ci(x,y) - cj(x,y) = 0$$

Using `tricontour`, we can plot these intersection curves as a contour level with $z=0$.

Notice how the three cones intersect at exactly two points.

```@figure
using GLMakie
GLMakie.activate!()
# Define inline functions for conic surfaces
c1 = (x,y) -> 7.0 * sqrt((x - 0.1)^2 + (y + 0.3)^2) - 1.0
c2 = (x,y) -> 4.0 * sqrt((0.2*x - 0.3)^2 + (y + 0.2)^2) 
c3 = (x,y) -> 5.0 * sqrt((x + 0.1)^2 + (y - 0.2)^2)

# Generate sample points
xs, ys = range(-1, 1, length=50), range(-1, 1, length=50)
X = [x for x in xs, y in ys][:]
Y = [y for x in xs, y in ys][:]

Z1 = c1.(X, Y)
Z2 = c2.(X,Y)
Z3 = c3.(X,Y)

# Plot surfaces
fig = Figure()
ax = Axis3(fig[1,1], title = "Intersection of three cones")
s1 = scatter!(ax, X, Y, Z1; color=:blue, alpha=0.3, label="cone c1")
s2 = scatter!(ax, X, Y, Z2, color=:red, alpha=0.3, label="cone c2")
s3 = scatter!(ax, X, Y, Z3, color=:green, alpha=0.3, label="cone c3")

# Plot contours of each surface
tr1 = tricontour!(
    X, Y, Z1; colormap=:blues, alpha=0.7)
tr2 = tricontour!(
    X, Y, Z2; colormap=:reds, alpha=0.7)
tr3 = tricontour!(
    X, Y, Z3; colormap=:greens, alpha=0.7)
# Plot zero-level contour to obtain intersection
tr_int = tricontour!(
    X, Y, Z1 - Z2, levels=[0.0], linewidth=2, color=:magenta, label="intersection c1-c2"
    )
tr_int = tricontour!(
    X, Y, Z1 - Z3, levels=[0.0], linewidth=2, color=:yellow, label="intersection c1-c3"
    )    
tr_int = tricontour!(
    X, Y, Z2 - Z3, levels=[0.0], linewidth=2, color=:cyan, label="intersection c2-c3"
    )    
axislegend(ax)
display(fig)
```

**Example: animate the contours of a function with a changing parameter**

Make a video of the contours for the function $z = a*x^2 + y^2$ as $a$ changes from -2 to +2,
using 300 random points with normally distributed values for $x$ and $y$ in [-1, 1]

```@figure
using GLMakie
using Random

GLMakie.activate!()
Random.seed!(1234)

# Set up
npoints = 300  # Number of random points
x = 2 .* rand(npoints) .- 1  # Random x in [-1, 1]
y = 2 .* rand(npoints) .- 1  # Random y in [-1, 1]

# Function to compute z values
a = Observable(0.0)
z = @lift $a .* x .^ 2 .+ y .^ 2

# Create a reactive title using `lift`
b = @lift round($a; digits=2)
title_text = @lift "z = $($b) * x^2 + y^2"

# Set up figure
fig = Figure()

ax = Axis(fig[1, 1], xlabel = "x", ylabel = "y",title = title_text)
scatter!(ax, x, y)
contour_plot = tricontour!(ax, x, y, z, levels=10, colormap=:viridis, labels=true)
Colorbar(fig[1,2], contour_plot.plots[2])
display(fig)
# Animation loop
framerate = 30
duration = 8  # Desired duration in seconds
total_frames = framerate * duration  # Total number of frames
aa = range(-2, 2, length=total_frames)  # Generate `total_frames` values for `a`

record(fig, "my_contour_animation.mp4", aa;
        framerate = framerate) do ak
    a[] = ak
end
```

## Attributes

```@attrdocs
Tricontour
```
