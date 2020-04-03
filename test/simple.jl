using AbstractPlotting
using GLMakie
using GeometryBasics
using Observables
using GLMakie

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

poly(decompose(Point2f0, Circle(Point2f0(0), 1f0))) |> display

image(rand(10, 10))

heatmap(rand(10, 10)) |> display

volume(rand(4, 4, 4), isovalue=0.5, isorange=0.01, algorithm=:iso) |> display
volume(rand(4, 4, 4), algorithm=:mip)
volume(rand(4, 4, 4), algorithm=:absorption)
volume(rand(RGBAf0, 4, 4, 4), algorithm=:absorptionrgba)
