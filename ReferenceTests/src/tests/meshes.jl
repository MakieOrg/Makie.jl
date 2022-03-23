using GLMakie, GeometryBasics
using CairoMakie, GeometryBasics
# basic 2d
f, ax, pl = mesh(Rect2f(0, 0, 1, 1))
# basic 3d
f, ax, pl = mesh(Sphere(Point3f(0), 1f0))
# without normals
f, ax, pl = mesh(triangle_mesh(Sphere(Point3f(0), 1f0)))
f, ax, pl = mesh(Sphere(Point3f(0), 1f0), color=rand(100, 100))


heatmap(rand(32, 32))
image!(map(x -> RGBAf(x, 0.5, 0.5, 0.8), rand(32, 32)))
current_figure()


poly([(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
    color=[:red, :green, :blue],
    strokecolor=:black, strokewidth=2)


points = decompose(Point2f, Circle(Point2f(50), 50f0))
fig, ax, pol = poly(points, color=:gray, strokewidth=10, strokecolor=:red)
# Optimized forms
poly!(ax, [Circle(Point2f(50 + 300), 50f0)], color=:gray, strokewidth=10, strokecolor=:red)
poly!(ax, [Circle(Point2f(50 + i, 50 + i), 10f0) for i = 1:100:400], color=:red)
poly!(ax, [Rect2f(50 + i, 50 + i, 20, 20) for i = 1:100:400], strokewidth=2, strokecolor=:green)
linesegments!(ax,
    [Point2f(50 + i, 50 + i) => Point2f(i + 70, i + 70) for i = 1:100:400], linewidth=8, color=:purple
)
fig
