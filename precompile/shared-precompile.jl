# File to run to snoop/trace all functions to compile
using GeometryBasics

@compile poly(Recti(0, 0, 200, 200), strokewidth=20, strokecolor=:red, color=(:black, 0.4))

@compile begin
    f, ax, pl = poly([Rect(0, 0, 20, 20)])
    scatter!(Rect(0, 0, 20, 20), color=:red, markersize=20)
    f
end

@compile scatter(0..1, rand(10), markersize=rand(10) .* 20)
@compile scatter(LinRange(0, 1, 10), rand(10))
@compile scatter(-1..1, x -> x^2)


@compile begin
    f, ax, pl = lines(Rect(0, 0, 1, 1), linewidth=4)
    scatter!([Point2f(0.5, 0.5)], markersize=1, markerspace=:data, marker='I')
    f
end

@compile lines(rand(10), rand(10), color=rand(10), linewidth=10)
@compile lines(rand(10), rand(10), color=rand(RGBAf, 10), linewidth=10)
@compile lines(Circle(Point2f(0), Float32(1)))
@compile lines(-1..1, x -> x^2)


@compile begin
    angles = range(0, stop=2pi, length=20)
    pos = Point2f.(sin.(angles), cos.(angles))
    f, ax, pl = scatter(pos, markersize=0.2, markerspace=:data, rotations=-angles, marker='▲', axis=(;aspect = DataAspect()))
    scatter!(pos, markersize=10, color=:red)
    f
end

@compile heatmap(rand(50, 50), colormap=(:RdBu, 0.2))

@compile contour(rand(10, 100))
@compile contour(rand(100, 10))
@compile contour(randn(100, 90), levels=3)
@compile contour(randn(100, 90), levels=[0.1, 0.5, 0.8])
@compile contour(randn(33, 30), levels=[0.1, 0.5, 0.9], color=[:black, :green, (:blue, 0.4)], linewidth=2)
@compile contour(
    rand(33, 30) .* 6 .- 3, levels=[-2.5, 0.4, 0.5, 0.6, 2.5],
    colormap=[(:black, 0.2), :red, :blue, :green, (:black, 0.2)],
    colorrange=(0.2, 0.8)
)

@compile begin
    v(x::Point2{T}) where T = Point2{T}(x[2], 4 * x[1])
    streamplot(v, -2..2, -2..2, arrow_size=10)
end

@compile meshscatter(rand(10), rand(10), rand(10), color=rand(10))
@compile meshscatter(rand(10), rand(10), rand(10), color=rand(RGBAf, 10), transparency=true)

function xy_data(x, y)
    r = sqrt(x^2 + y^2)
    r == 0.0 ? 1f0 : (sin(r) / r)
end

@compile begin
    NL = 15
    NR = 31

    lspace = range(-10, stop=10, length=NL)
    rspace = range(-10, stop=10, length=NR)

    z = Float32[xy_data(x, y) for x in lspace, y in rspace]
    l = range(0, stop=3, length=NL)
    r = range(0, stop=3, length=NR)
    surface(
        l, r, z,
        colormap=:Spectral
    )
end

@compile begin
    NL = 30
    NR = 31

    lspace = range(-10, stop=10, length=NL)
    rspace = range(-10, stop=10, length=NR)

    z = Float32[xy_data(x, y) for x in lspace, y in rspace]
    l = range(0, stop=3, length=NL)
    r = range(0, stop=3, length=NR)
    surface(
        [l for l in l, r in r], [r for l in l, r in r], z,
        colormap=:Spectral
    )
end

@compile begin
    data =
        hcat(LinRange(2, 3, 4), LinRange(2, 2.5, 4), LinRange(2.5, 3, 4), [1, NaN, NaN, 5])

    fig = Figure()
    heatmap(
        fig[1, 1],
        data,
        colorrange = (2, 3),
        highclip = :red,
        lowclip = :black,
        nan_color = (:green, 0.5),
    )
    surface(
        fig[1, 2],
        zeros(size(data)),
        color = data,
        colorrange = (2, 3),
        highclip = :red,
        lowclip = :black,
        nan_color = (:green, 0.5),
        shading = false,
    )
    surface!(
        Axis(fig[2, 2]),
        data,
        colorrange = (2, 3),
        highclip = :red,
        lowclip = :black,
        nan_color = (:green, 0.5),
        shading = false,
    )
    fig
end

@compile begin
    heatmap(rand(10, 5), axis = (yscale = log10, xscale=log10))
end

@compile begin
    x = [1 0
         2 3]
    heatmap(1:2, 1:-1:0, x)
end

@compile begin
    res = 200
    s = Scene(camera=campixel!, resolution=(res, res))
    half = res / 2
    linewidth = 10
    xstart = half - (half/2)
    xend = xstart + 100
    half_w = linewidth/2

    lines!(s, Point2f[(xstart, half), (xend, half)], linewidth=linewidth)
    scatter!(s, Point2f[(xstart, half + half_w), (xstart, half - half_w), (xend, half + half_w), (xend, half - half_w)], color=:red, markersize=2)

    l2 = linesegments!(s, Point2f[(xstart, half), (xend, half)], linewidth=linewidth, color=:gray)
    s2 = scatter!(s, Point2f[(xstart, half + half_w), (xstart, half - half_w), (xend, half + half_w), (xend, half - half_w)], color=:red, markersize=2)

    for p in (l2, s2)
        translate!(p, 0, 20, 0)
    end

    s
end

@compile begin
    P = Polygon.([Point2f[[0.45, 0.05], [0.64, 0.15], [0.37, 0.62]],
         Point2f[[0.32, 0.66], [0.46, 0.59], [0.09, 0.08]]])
    poly(P, color = [:red, :green], strokecolor = [:blue, :red], strokewidth = 2)
end

@compile begin
    meshscatter(rand(Point3f, 10), axis=(type=Axis3,))
end

@compile begin
    barplot(1:5, color=Makie.LinePattern(linecolor=:red, background_color=:orange))
end
