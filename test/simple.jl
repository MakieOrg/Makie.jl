using AbstractPlotting
using GLMakie
using GeometryBasics

using GLFW
GLFW.WindowHint(GLFW.FLOATING, true)

scatter(1:4, color=1:4) |> display
scatter(1:4, color=rand(RGBAf0, 4))
scatter(1:4, color=rand(RGBf0, 4))
scatter(1:4, color=:red)

scatter(1:4, marker='☼')
scatter(1:4, marker=['☼', '◒', '◑', '◐'])
scatter(1:4, marker="☼◒◑◐")
scatter(1:4, marker=rand(RGBf0, 10, 10), markersize=20px) |> display

# Lines
positions = Point2f0.([1:4; NaN; 1:4], [1:4; NaN; 2:5])
lines(positions)
lines(positions, linestyle=:dot)
lines(positions, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
lines(positions, color=1:9)
lines(positions, color=rand(RGBf0, 9), linewidth=4)

# Linesegments
linesegments(1:4)
linesegments(1:4, linestyle=:dot)
linesegments(1:4, linestyle=[0.0, 1.0, 2.0, 3.0, 4.0])
linesegments(1:4, color=1:4)
linesegments(1:4, color=rand(RGBf0, 4), linewidth=4)

# Surface
data = AbstractPlotting.peaks()
surface(-10..10, -10..10, data)
surface(-10..10, -10..10, data, color=rand(size(data)...)) |> display
surface(-10..10, -10..10, data, color=rand(RGBf0, size(data)...))
# surface(-10..10, -10..10, data, colormap=:magma, colorrange=(0.0, 2.0))

# Mesh
mesh(Sphere(Point3f0(0), 1f0)) |> display
mesh(Sphere(Point3f0(0), 1f0), color=:red)

tocolor(x) = RGBf0(x...)
positions = decompose(Point3f0, Sphere(Point3f0(0), 1f0))
triangles = decompose(GLTriangleFace, Sphere(Point3f0(0), 1f0))
uv = GeometryBasics.decompose_uv(Sphere(Point3f0(0), 1f0))

xyz_vertex_color = tocolor.(positions)
mesh_normals = GeometryBasics.normals(positions, triangles)
coords = meta(positions, color=xyz_vertex_color, normals=mesh_normals)
vertexcolor_mesh = GeometryBasics.Mesh(coords, triangles)
scren = mesh(vertexcolor_mesh, show_axis=false) |> display

texsampler = AbstractPlotting.sampler(rand(RGBf0, 4, 4), uv)
coords = meta(positions, color=texsampler, normals=mesh_normals)
texture_mesh = GeometryBasics.Mesh(coords, triangles)

scren = mesh(texture_mesh, show_axis=false) |> display


texsampler = AbstractPlotting.sampler(:viridis, rand(length(positions)))
coords = meta(positions, color=texsampler, normals=mesh_normals)
texture_mesh = GeometryBasics.Mesh(coords, triangles)

scren = mesh(texture_mesh, show_axis=false) |> display


poly(decompose(Point2f0, Circle(Point2f0(0), 1f0))) |> display

image(rand(10, 10))

heatmap(rand(10, 10)) |> display


volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso)
volume(rand(4, 4, 4), algorithm=:mip)
volume(rand(4, 4, 4), algorithm=:absorption)
volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
