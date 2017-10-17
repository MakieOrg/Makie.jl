#julia
using MakiE, GeometryTypes
scene = Scene()

large_sphere = HyperSphere(Point3f0(0), 1f0)
positions = decompose(Point3f0, large_sphere)
linepos = view(positions, rand(1:length(positions), 1000))

lines(linepos, linewidth = 0.1, color = :black)
scatter(positions, strokewidth = 0.01, strokecolor = :white, color = RGBA(0.9, 0.2, 0.4, 0.4))
r = linspace(-0.1, 1.1, 5)
axis(r, r, r)
center!(scene)
