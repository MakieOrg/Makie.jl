using GeometryBasics
using AbstractPlotting: Axis

@cell "Axis theming" begin
    scene = Scene()
    points = decompose(Point2f0, Circle(Point2f0(10), 10f0), 9)
    lines!(scene, points, linewidth=8, color=:black)
    axis = scene[Axis] # get axis
    axis[:frame][:linewidth] = 5
    axis[:grid][:linewidth] = (1, 5)
    axis[:grid][:linecolor] = ((:red, 0.3), (:blue, 0.5))
    axis[:names][:axisnames] = ("x", "y   ")
    axis[:ticks][:title_gap] = 1
    axis[:names][:rotation] = (0.0, -3 / 8 * pi)
    axis[:names][:textcolor] = ((:red, 1.0), (:blue, 1.0))
    axis[:ticks][:font] = ("Dejavu Sans", "Helvetica")
    axis[:ticks][:rotation] = (0.0, -pi / 2)
    axis[:ticks][:textsize] = (3, 7)
    axis[:ticks][:gap] = 5
    scene
end

@cell "Legend" begin
    scene = Scene(resolution=(500, 500))
    x = map([:dot, :dash, :dashdot], [2, 3, 4]) do ls, lw
        linesegments!(
            range(1, stop=5, length=100), RNG.rand(100), RNG.rand(100),
            linestyle=ls, linewidth=lw,
            color=RNG.rand(RGBAf0)
        )[end]
    end
    x = [x..., scatter!(range(1, stop=5, length=100), RNG.rand(100), RNG.rand(100))[end]]
    center!(scene)
    ls = AbstractPlotting.legend(x, ["attribute $i" for i in 1:4], camera=campixel!, raw=true)
    l = ls[end]
    l[:strokecolor] = RGBAf0(0.8, 0.8, 0.8)
    l[:gap] = 15
    l[:textsize] = 12
    l[:linepattern] = Point2f0[(0, -0.2), (0.5, 0.2), (0.5, 0.2), (1.0, -0.2)]
    l[:scatterpattern] = decompose(Point2f0, Circle(Point2f0(0.5, 0), 0.3f0), 9)
    l[:markersize] = 2f0
    vbox(scene, ls)
end

