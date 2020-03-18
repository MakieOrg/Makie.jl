using AbstractPlotting
using GLMakie
using GeometryBasics

GLMakie.GLFW.WindowHint(0x0002000C, 0)
1 + 1
scatter(1:4)
lines(1:4)
linesegments(1:4)
surface(0..1, 0..1, rand(9, 11))
meshscatter(rand(Point3f0, 3)) |> display
mesh(Sphere(Point3f0(0), 1f0))
poly(decompose(Point2f0, Circle(Point2f0(0), 1f0)))
image(rand(10, 10))
heatmap(rand(10, 10))
mesh(m, color = :green)

volume(rand(4, 4, 4), algorithm=:iso)
volume(rand(4, 4, 4), algorithm=:mip)
volume(rand(4, 4, 4), algorithm=:absorption)
volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba) |> display
