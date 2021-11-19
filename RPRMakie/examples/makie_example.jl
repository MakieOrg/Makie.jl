using RadeonProRender, GeometryBasics, Colors, Makie
using FileIO, Colors
using RPRMakie, GLMakie
RPR = RadeonProRender
earth = load(Makie.assetpath("earth.png"))
m = uv_mesh(Tesselation(Sphere(Point3f(0), 1.0f0), 60))
f, ax, mplot = Makie.mesh(m; color=earth, shading=false)
Makie.mesh!(ax, Sphere(Point3f(2, 0, 0), 0.1f0); color=:red)
x, y = collect(-8:0.5:8), collect(-8:0.5:8)
z = [sinc(√(X^2 + Y^2) / π) for X ∈ x, Y ∈ y]
wireframe!(ax, -2..2, -2..2, z)
display(f)
context, task, rpr_scene = RPRMakie.replace_scene_rpr!(ax.scene)
