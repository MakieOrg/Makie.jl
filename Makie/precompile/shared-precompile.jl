# File to run to snoop/trace all functions to compile
using GeometryBasics
# macro compile(ex)
#     :(display($ex))
# end
@compile scatter(1:4; color = 1:4, colormap = :turbo, markersize = 20, visible = true)

@compile poly(Recti(0, 0, 200, 200), strokewidth = 20, strokecolor = :red, color = (:black, 0.4))

@compile scatter(0 .. 1, rand(10), markersize = rand(10) .* 20)
@compile scatter(LinRange(0, 1, 10), rand(10))
@compile scatter(-1 .. 1, x -> x^2)

@compile begin
    f, ax, pl = lines(Rect(0, 0, 1, 1), linewidth = 4)
    scatter!([Point2f(0.5, 0.5)], markersize = 1, markerspace = :data, marker = 'I')
    f
end

@compile lines(rand(10), rand(10), color = rand(10), linewidth = 10)
@compile lines(rand(10), rand(10), color = rand(RGBAf, 10), linewidth = 10)
@compile lines(Circle(Point2f(0), Float32(1)))
@compile lines(-1 .. 1, x -> x^2)

@compile heatmap(rand(50, 50), colormap = (:RdBu, 0.2))

@compile contour(randn(100, 90), levels = 3)
@compile contour(randn(33, 30), levels = [0.1, 0.5, 0.9], color = [:black, :green, (:blue, 0.4)], linewidth = 2)

@compile meshscatter(rand(10), rand(10), rand(10), color = rand(10))
@compile meshscatter(rand(Point3f, 10), color = rand(RGBAf, 10), transparency = true)

@compile begin
    l = range(-10, stop = 10, length = 10)
    surface(l, l, rand(10, 10), colormap = :Spectral)
end

@compile begin
    NL = 30
    NR = 31

    l = range(0, stop = 3, length = NL)
    r = range(0, stop = 3, length = NR)
    surface(
        [l for l in l, r in r], [r for l in l, r in r], rand(NL, NR),
        colormap = :Spectral
    )
end

@compile begin
    heatmap(rand(10, 5), axis = (yscale = log10, xscale = log10))
end

@compile begin
    x = [
        1 0
        2 3
    ]
    heatmap(1:2, 1:-1:0, x)
end

@compile begin
    res = 200
    s = Scene(camera = campixel!, size = (res, res))
    half = res / 2
    linewidth = 10
    xstart = half - (half / 2)
    xend = xstart + 100
    half_w = linewidth / 2

    lines!(s, Point2f[(xstart, half), (xend, half)], linewidth = linewidth)
    scatter!(s, Point2f[(xstart, half + half_w), (xstart, half - half_w), (xend, half + half_w), (xend, half - half_w)], color = :red, markersize = 2)

    l2 = linesegments!(s, Point2f[(xstart, half), (xend, half)], linewidth = linewidth, color = :gray)
    s2 = scatter!(s, Point2f[(xstart, half + half_w), (xstart, half - half_w), (xend, half + half_w), (xend, half - half_w)], color = :red, markersize = 2)

    for p in (l2, s2)
        translate!(p, 0, 20, 0)
    end

    s
end

@compile begin
    P = Polygon.(
        [
            Point2f[[0.45, 0.05], [0.64, 0.15], [0.37, 0.62]],
            Point2f[[0.32, 0.66], [0.46, 0.59], [0.09, 0.08]],
        ]
    )
    poly(P, color = [:red, :green], strokecolor = [:blue, :red], strokewidth = 2)
end

@compile begin
    meshscatter(rand(Point3f, 10), axis = (type = Axis3,))
end

@compile begin
    f = Figure()
    ax = Makie.Axis(f)
    Makie.Toggle(f)
    Makie.Slider(f)
    Makie.LScene(f)
    Makie.PolarAxis(f)
    Makie.IntervalSlider(f)
    lines!(ax, 1:2, label = "Line")
    Makie.Legend(f, ax, "Default", nbanks = 2)
    Makie.Box(f)
    Makie.Label(f)
    Makie.Textbox(f)
    Makie.Axis3(f)
    Makie.Colorbar(f)
    Makie.Button(f)
    Makie.Menu(f, options = ["one"])
    Makie.SliderGrid(f, (label = "Label", range = 0:1:2, startvalue = 1))
    f
end
