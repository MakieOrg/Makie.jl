using GeometryBasics, Makie
using FileIO, Colors
using RPRMakie
RPRMakie.activate!(iterations = 200)
earth = load(Makie.assetpath("earth.png"))
m = uv_mesh(Tessellation(Sphere(Point3f(0), 1.0f0), 60))
f, ax, mplot = Makie.mesh(m; color = earth)
Makie.mesh!(ax, Sphere(Point3f(2, 0, 0), 0.1f0); color = :red)
x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X in x, Y in y]
wireframe!(ax, -2 .. 2, -2 .. 2, z)
display(ax.scene)
