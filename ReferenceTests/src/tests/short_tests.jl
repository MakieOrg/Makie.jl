@reference_test "thick arc" arc(Point2f(0), 10f0, 0f0, pi, linewidth=20)

@reference_test "stroked rect poly" poly(Recti(0, 0, 200, 200), strokewidth=20, strokecolor=:red, color=(:black, 0.4))

@reference_test "array of rects poly" begin
    f, ax, pl = poly([Rect(0, 0, 20, 20)])
    scatter!(Rect(0, 0, 20, 20), color=:red, markersize=20)
    f
end

@reference_test "char marker scenespace" begin
    f, ax, pl = lines(Rect(0, 0, 1, 1), linewidth=4)
    scatter!([Point2f(0.5, 0.5)], markersize=1, markerspace=:data, marker='I')
    f
end

@reference_test "lines number color" lines(RNG.rand(10), RNG.rand(10), color=RNG.rand(10), linewidth=10)
@reference_test "lines array of colors" lines(RNG.rand(10), RNG.rand(10), color=RNG.rand(RGBAf, 10), linewidth=10)
@reference_test "scatter interval" scatter(0..1, RNG.rand(10), markersize=RNG.rand(10) .* 20)
@reference_test "scatter linrange" scatter(LinRange(0, 1, 10), RNG.rand(10))

@reference_test "scatter rotation" begin
    angles = range(0, stop=2pi, length=20)
    pos = Point2f.(sin.(angles), cos.(angles))
    f, ax, pl = scatter(pos, markersize=0.2, markerspace=:data, rotations=-angles, marker='▲', axis=(;aspect = DataAspect()))
    scatter!(pos, markersize=10, color=:red)
    f
end

@reference_test "heatmap transparent colormap" heatmap(RNG.rand(50, 50), colormap=(:RdBu, 0.2))

@reference_test "contour small x" contour(RNG.rand(10, 100))
@reference_test "contour small y" contour(RNG.rand(100, 10))
@reference_test "contour with levels" contour(RNG.randn(100, 90), levels=3)

@reference_test "contour with levels array" contour(RNG.randn(100, 90), levels=[0.1, 0.5, 0.8])
@reference_test "contour with color per level" contour(RNG.randn(33, 30), levels=[0.1, 0.5, 0.9], color=[:black, :green, (:blue, 0.4)], linewidth=2)

@reference_test "contour with colorrange" contour(
    RNG.rand(33, 30) .* 6 .- 3, levels=[-2.5, 0.4, 0.5, 0.6, 2.5],
    colormap=[(:black, 0.2), :red, :blue, :green, (:black, 0.2)],
    colorrange=(0.2, 0.8)
)

@reference_test "circle line" lines(Circle(Point2f(0), Float32(1)))

@reference_test "streamplot with func" begin
    v(x::Point2{T}) where T = Point2{T}(x[2], 4 * x[1])
    streamplot(v, -2..2, -2..2, arrow_size=10)
end

@reference_test "lines with func" lines(-1..1, x -> x^2)
@reference_test "scatter with func" scatter(-1..1, x -> x^2)

@reference_test "volume translated" begin
    r = range(-3pi, stop=3pi, length=100)
    fig, ax, vplot = Makie.volume(r, r, r, (x, y, z) -> cos(x) + sin(y) + cos(z), algorithm=:iso, isorange=0.1f0, axis = (;show_axis=false))
    v2 = volume!(ax, r, r, r, (x, y, z) -> cos(x) + sin(y) + cos(z), algorithm=:mip,
                 transformation=(translation=Vec3f(6pi, 0, 0),))
    fig
end

@reference_test "meshscatter color numbers" meshscatter(RNG.rand(10), RNG.rand(10), RNG.rand(10), color=RNG.rand(10))
@reference_test "meshscatter color array" meshscatter(RNG.rand(10), RNG.rand(10), RNG.rand(10), color=RNG.rand(RGBAf, 10), transparency=true)

@reference_test "transparent mesh texture" begin
    s1 = uv_mesh(Sphere(Point3f(0), 1f0))
    f, ax, pl = mesh(uv_mesh(Sphere(Point3f(0), 1f0)), color=RNG.rand(50, 50))
    # ugh, bug In GeometryTypes for UVs of non unit spheres.
    s2 = uv_mesh(Sphere(Point3f(0), 1f0))
    s2.position .= s2.position .+ (Point3f(0, 2, 0),)
    mesh!(s2, color=RNG.rand(RGBAf, 50, 50))
    f
end

@reference_test "Unequal x and y sizes in surface" begin
    NL = 15
    NR = 31
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end
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

@reference_test "Matrices of data in surfaces" begin
    NL = 30
    NR = 31
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r) / r)
    end
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

@reference_test "heatmaps & surface" begin
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

@reference_test "log10 heatmap" begin
    heatmap(RNG.rand(10, 5), axis = (yscale = log10, xscale=log10))
end

@reference_test "reverse range heatmap" begin
    x = [1 0
         2 3]
    heatmap(1:2, 1:-1:0, x)
end

@reference_test "lines linesegments width test" begin
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

@reference_test "multipoly with multi strokes" begin
    P = Polygon.([Point2f[[0.45, 0.05], [0.64, 0.15], [0.37, 0.62]],
         Point2f[[0.32, 0.66], [0.46, 0.59], [0.09, 0.08]]])
    poly(P, color = [:red, :green], strokecolor = [:blue, :red], strokewidth = 2)
end

@reference_test "fast pixel marker" begin
    scatter(RNG.rand(Point2f, 10000), marker=Makie.FastPixel())
end

@reference_test "axsi3" begin
    meshscatter(RNG.rand(Point3f, 10), axis=(type=Axis3,))
end

@reference_test "pattern barplot" begin
    barplot(1:5, color=Makie.LinePattern(linecolor=:red, background_color=:orange))
end

@reference_test "barplot lowclip highclip nan_color" begin
    f = Figure()
    attrs = (color=[-Inf, 2, NaN, Inf], colorrange=(2, 3), highclip = :red, lowclip=:green, nan_color=:black)
    barplot(f[1, 1], 1:4; attrs...)
    poly(
        f[1, 2],
        [
            Point2f[(2, 0), (4, 0), (4, 1), (2, 1)],
            Point2f[(0, 0), (2, 0), (2, 1), (0, 1)],
            Point2f[(2, 1), (4, 1), (4, 2), (2, 2)],
            Point2f[(0, 1), (2, 1), (2, 2), (0, 2)],
        ];
        strokewidth=2, attrs...
    )
    meshscatter(f[2, 1], 1:4, zeros(4), 1:4; attrs...)
    volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)
    ax, cf = contourf(f[2, 2], volcano, levels = range(100, 180, length = 10), extendlow = :green, extendhigh = :red, nan_color=:black)
    Colorbar(f[:, 3], cf)
    f
end

@reference_test "Colorbar" begin
    f = Figure()
    Colorbar(f[1, 1]; size = 200)
    f
end

@reference_test "scene visibility" begin
    f, ax, pl = scatter(1:4, markersize=200)
    ax2, pl = scatter(f[1, 2][1, 1], 1:4, color=1:4, markersize=200)
    ax3, pl = scatter(f[1, 2][2, 1], 1:4, color=1:4, markersize=200)
    ax3.scene.visible[] = false
    ax2.scene.visible[] = false
    ax2.blockscene.visible[] = false
    f
end

@reference_test "redisplay after closing screen" begin
    # https://github.com/MakieOrg/Makie.jl/issues/2392
    Makie.inline!(false)
    f = Figure()
    Menu(f[1,1], options=["one", "two", "three"])
    screen = display(f; visible=false)
    # Close the window & redisplay
    close(screen)
    # Now, menu should be displayed again and not stay blank!
    f
end

@reference_test "space test in transformed axis" begin
    f = lines(exp.(0.1*(1.0:100));  axis=(yscale=log10,))
    poly!(Rect(1, 1, 100, 100), color=:red, space=:pixel)
    scatter!(2*mod.(1:100:10000, 97), 2*mod.(1:101:10000, 97), color=:blue, space=:pixel)
    scatter!(Point2f(0, 0.25), space=:clip)
    lines!([0.5,0.5], [0, 1];  space=:relative)
    lines!([50,50], [0, 100];  space=:pixel)
    lines!([0,1], [0.25, 0.25];  space=:clip)
    scatter!(Point2f(0.5, 0), space=:relative)
    f
end


# Needs a way to disable autolimits on show
# @reference_test "interactions after close" begin
#     # After saving, interactions may be cleaned up:
#     # https://github.com/MakieOrg/Makie.jl/issues/2380
#     f = Figure()
#     ax = Axis(f[1,1])
#     # Show something big for reference tests to make a difference
#     lines!(ax, 1:5, 1:5, linewidth=20)
#     scatter!(ax, decompose(Point2f, Circle(Point2f(2.5), 2.5)), markersize=50)
#     display(f; visible=false)
#     save("test.png", f)
#     rm("test.png")
#     # Trigger zoom interactions
#     f.scene.events.mouseposition[] = (200, 200)
#     f.scene.events.scroll[] = (0, -10)
#     # reference test the zoomed out plot
#     f
# end
