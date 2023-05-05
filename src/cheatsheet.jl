using Makie.GeometryBasics
using Makie.SparseArrays
using Makie

function cheatsheet_3d(rn, testimage)
    fig = Figure(resolution=(1000, 1600))
    axs1 = Axis(fig[1, 1], aspect=1)
    axs2 = Axis(fig[1, 2], aspect=1)
    axs3 = Axis(fig[1, 3], aspect=1, xscale=log10, yscale=log10)
    axs4 = Axis(fig[1, 4], aspect=1)
    axs5 = Axis(fig[1, 5], aspect=1)
    axs6 = Axis(fig[2, 1], aspect=1)
    axs7 = Axis3(fig[2, 2], aspect=(1, 1, 1), perspectiveness=0.5, protrusions=0)
    axs8 = Axis3(fig[2, 3], aspect=(1, 1, 1), perspectiveness=0.5, protrusions=0)
    axs9 = Axis3(fig[2, 4], aspect=(1, 1, 1), perspectiveness=0.5, protrusions=0)
    axs10 = Axis3(fig[2, 5], aspect=(1, 1, 1), perspectiveness=0.5, protrusions=0)

    axst = [axs1, axs2, axs3, axs4, axs5, axs6, axs7, axs8, axs9, axs10]

    axs = [Axis3(fig[i, j], aspect=(1, 1, 1),
        perspectiveness=0.5, elevation=pi / 6, protrusions=0)
        for i = 3:7 for j = 1:5]
    [axs[i].titlegap = -15 for i = 1:25]
    #length(axs)

    hexbin!(axs1, rn, rn;
        bins=40, cellsize=0.5, colormap=:Homer1)
    axs1.title = "hexbin(x, y)"
    x = randn(50)
    y = randn(50)
    z = exp.(-x .^ 2 .- y .^ 2) .+ 0.2 .* randn.()
    tricontourf!(axs2, x, y, z, colormap=:linear_protanopic_deuteranopic_kbw_5_98_c40_n256)
    axs2.title = "tricontourf(x,y,z)"
    heatmap!(axs3, 1:10, 1:10, rand(100, 100); colormap=:tableau_sunset_sunrise)
    axs3.title = "heatmap(x,y,z) : scales"

    text!(axs4, "Say something\n funny 😄"; color=:black,
        rotation=π / 4, align=(:center, :center))
    axs4.title = "text(string)"

    text!(axs5, rich("Say", rich(" something", color=:red), "\nfunny !", color=:black, font=:bold);
        rotation=π / 4, align=(:center, :center))
    axs5.title = "text(rich(string))"

    directions = [Vec2f(1), Vec2f(1, -1), Vec2f(1, 0), Vec2f(0, 1),
        [Vec2f(1), Vec2f(1, -1)], [Vec2f(1, 0), Vec2f(0, 1)]]
    colors = [:white, :red, (:green, 0.5), :white, (:navy, 0.85), :black]
    patterns = [Makie.LinePattern(direction=hatch; width=2, tilesize=(5, 5),
        linecolor=colors[indx], background_color=colors[end-indx+1])
                for (indx, hatch) in enumerate(directions)]
    for (idx, pattern) in enumerate(patterns)
        barplot!(axs6, [idx], [idx * (2rand() + 1)], color=pattern, strokewidth=2)
    end
    axs6.title = "barplot(;color=pattern)"

    t = 0:0.2:15
    scatter!(axs7, sin.(t), cos.(t), t / 4; color=:black, markersize=5)
    axs7.title = "scatter(x,y,z)"

    lines!(axs8, sin.(t), cos.(t), t / 4)
    axs8.title = "lines(x,y,z)"

    scatterlines!(axs9, sin.(t), cos.(t), t / 4; color=:black, markersize=7)
    axs9.title = "scatterlines(x,y,z)"

    xs = LinRange(0, 3pi, 15)
    stem!(axs10, 0.5xs, 2 .* sin.(xs), 1.5cos.(xs),
        offset=Point3f.(0.5xs, sin.(xs), cos.(xs)),
        stemcolor=range(0, 1, 15),
        color=range(0, 1, 15),
        stemcolormap=:Spectral_11, stemcolorrange=(0, 0.5))
    axs10.title = "stem(x,y,z)"

    linesegments!(axs[1],
        Point3f.(vec([[x, rand(), rand()] for i = 1:2, x in rand(10)]));
        color=1:20, colormap=:gnuplot)
    axs[1].title = "linesegments(points)"


    xs = LinRange(-4, 4, 10)
    ys = LinRange(-4, 4, 10)
    us = [x + y for x in xs, y in ys]
    vs = [y - x for x in xs, y in ys]
    strength = vec(sqrt.(us .^ 2 .+ vs .^ 2))

    arrows!(axs[2], xs, ys, us, vs;
        arrowsize=5, lengthscale=0.1,
        arrowcolor=strength, linecolor=strength,
        colormap=:Hiroshige)
    axs[2].title = "arrows(x,y,u,v)"

    semiStable(x, y) = Point2f(-y + x * (-1 + x^2 + y^2)^2, x + y * (-1 + x^2 + y^2)^2)
    streamplot!(axs[3], semiStable, -4 .. 4, -4 .. 4,
        gridsize=(24, 24), arrow_size=8)
    axs[3].title = "streamplot(f,x,y)"

    heatmap!(axs[4], rand(10, 10))
    axs[4].title = "heatmap(x,y,z)"

    contour!(axs[5], 0 .. 1, 0 .. 1, rand(20, 20);
        colormap=:plasma)
    axs[5].title = "contour(x,y,z)"

    ps = [Point3f(x, y, z) for x = -3:1:3 for y = -3:1:3 for z = -3:1:3]
    ns = map(p -> 0.1 * Vec3f(p[2], p[1], p[3]), ps)
    lengths = norm.(ns)
    arrows!(axs[6], ps, ns; color=lengths,
        linewidth=0.1, arrowsize=Vec3f(0.3, 0.3, 0.4),
        align=:center)
    axs[6].title = "arrows(pos, dirs)"

    semiStable3(x, y, z) = Point3f(-y + x * (-1 + x^2 + y^2)^2, x + y * (-1 + x^2 + y^2)^2, -x + z * (-1 + x^2 - y^2)^2)
    streamplot!(axs[7], semiStable3, -3 .. 3, -3 .. 3, -3 .. 3,
        gridsize=(6, 6), arrow_size=0.4)
    axs[7].title = "streamplot(f,x,y,z)"

    function peaks(; n=19)
        x = LinRange(-3, 3, n)
        y = LinRange(-3, 3, n)
        a = 3 * (1 .- x') .^ 2 .* exp.(-(x' .^ 2) .- (y .+ 1) .^ 2)
        b = 10 * (x' / 5 .- x' .^ 3 .- y .^ 5) .* exp.(-x' .^ 2 .- y .^ 2)
        c = 1 / 3 * exp.(-(x' .+ 1) .^ 2 .- y .^ 2)
        return (x, y, a .- b .- c)
    end
    x, y, z = peaks()
    wireframe!(axs[8], x, y, z, transparency=true, color=:dodgerblue)
    axs[8].title = "wireframe(x,y,z)"

    x2, y2, z2 = peaks(; n=49)
    contour3d!(axs[9], x2, y2, z2, transparency=true,
        colormap=:diverging_bkr_55_10_c35_n256, levels=14)
    axs[9].title = "contour3d(x,y,z)"

    contourf!(axs[10], x2, y2, z2; levels=14,
        colormap=:diverging_bkr_55_10_c35_n256)
    axs[10].title = "contourf(x,y,z)"

    surface!(
        axs[11],
        x2,
        y2,
        z2,
        #colormap = :diverging_bkr_55_10_c35_n256
    )
    axs[11].title = "surface(x,y,z)"


    image!(axs[12], 0 .. 1, 0 .. 1, testimage,
        transformation=(:yz, 1))
    axs[12].title = "image(;transformation=(:yz,1))"
    zlims!(axs[12], 0, 1)

    x = -1.7:0.05:1.7
    y = -1.7:0.05:1.7
    z = -1.7:0.05:1.7
    r(i, j, k) = sqrt(i^2 + j^2 + k^2)
    vol = [rand() / r(i, j, k)^(2) for i in x, j in y, k in z]
    volume!(axs[13], x, y, z, vol;
        colormap=[:dodgerblue, :orange, :yellow, :white, :gold])
    axs[13].title = "volume(x,y,z,vol)"

    contour!(axs[14], 0 .. 1, 0 .. 1, 0 .. 1, rand(10, 10, 10);
        colormap=:Hiroshige)
    axs[14].title = "contour(x,y,z,vals)"

    rectMesh = Rect3f(Vec3f(-0.5), Vec3f(1))
    recmesh = GeometryBasics.mesh(rectMesh)
    colors = [rand() for v in recmesh.position]
    mesh!(axs[15], recmesh; color=colors, colormap=:rainbow, shading=false)
    axs[15].title = "mesh(Rect3f; color)"

    meshscatter!(axs[16], [Point3f(rand(3)...) for i = 1:4];
        markersize=0.15, marker=Rect3f(Vec3f(0), Vec3f(1)),
        color=1:4)
    limits!(axs[16], 0, 1, 0, 1, 0, 1)
    axs[16].title = "meshscatter(pos;\nmarker=Rect3f)"

    meshscatter!(axs[17], [Point3f(rand(3)...) for i = 1:4];
        markersize=0.1, marker=Sphere(Point3f(0, 0, -0.5), 1),
        color=1:4, colormap=[:dodgerblue, :black, :red])
    limits!(axs[17], 0, 1, 0, 1, 0, 1)

    axs[17].title = "meshscatter(pos;\nmarker=Sphere)"

    mesh!(axs[18], Sphere(Point3f(0), 1); color=rand(50, 50),
        colormap=[:dodgerblue, :black, :yellow, :red])
    axs[18].title = "mesh(Sphere)"


    rectMesh = Rect3f(Vec3f(-0.5, -0.5, 0), Vec3f(0.15, 0.15, 2))
    rectmesh = GeometryBasics.mesh(rectMesh)
    colors = last.(coordinates(rectmesh))

    #pos = [Point3f(i, j, 0) for i in 1:10 for j in 1:10]
    #z = rand(10,10)
    mesh!(axs[19], rectmesh, color=colors, shading=false,
        colormap=:tableau_blue_green, #[:black, :yellow, :red]
    )
    axs[19].title = "mesh(;color)"

    #zlims!(axs[19], 0, 1)
    mesh!(axs[20], rectMesh; color=testimage,
        shading=false, interpolate=false)
    axs[20].title = "mesh(;color=img)"

    mesh!(axs[21], Sphere(Point3f(0), 1);
          color=testimage,
        shading=false)
    axs[21].title = "mesh(;color=img)"

    wireframe!(axs[22], Rect3f(Vec3f(-0.5), Vec3f(1));
        color=:black, transparency=true)
    axs[22].title = "wireframe(Rect3f)"

    lower = [Point3f(i, -i, 0) for i in range(0, 3, 100)]
    upper = [Point3f(i, -i, sin(i) * exp(-(i + i))) for i in range(0, 3, length=100)]
    band!(axs[23], lower, upper, color=repeat(norm.(upper), outer=2), colormap=:Hiroshige)
    axs[23].title = "band(lo, hi)"

    text!(axs[24], Point3f(0, 0, -1),
        text=rich(rich("M", font=:bold, color=:dodgerblue,
                fontsize=32), "akie", fontsize=24),
        align=(:center, :center))
    axs[24].title = "text(pos, rich(string))"

    x = y = z = 1:2:10
    f(x, y, z) = x^2 + y^2 + z^2
    positions = vec([(i, j, k) for i in x, j in y, k in z])
    vals = [f(ix, iy, iz) for ix in x, iy in y, iz in z]

    meshscatter!(axs[25], positions; color=vec(vals),
        marker=Rect3f(Vec3f(-0.5), Vec3f(1.5)),
        markersize=0.9,
        colormap=:seaborn_icefire_gradient, #Reverse(:linear_protanopic_deuteranopic_kbw_5_98_c40_n256),
        colorrange=(minimum(vals), maximum(vals)),
        shading=true,
        transparency=true,
    )
    axs[25].title = "meshscatter(pos;\nmarker=Rect3f)"

    hidedecorations!.(axst, grid=false, ticks=false)
    hidedecorations!.(axs, grid=false, ticks=false)


    Label(fig[end+1, :], rich("Learn more at ", rich("https://juliadatascience.io,", fontsize=18, color=:dodgerblue, font=:bold), " https://docs.makie.org, "))
    Label(fig[0, :], rich("Plotting Functions in Makie.jl ::", rich(" CHEAT SHEET", fontsize=32, font=:bold, color=:black), fontsize=32))
    lines!(fig.scene, [22, 978], [1525, 1525], linestyle=:dash)
    lines!(fig.scene, [22, 978], [37, 37], linestyle=:dot, color=:grey)
    colgap!(fig.layout, 5)
    rowgap!(fig.layout, 8)
    fig
end

function cheatsheet_2d(testimage)
    x = 0:0.5:(2π)
    fig = Figure(; resolution=(1000, 1600))
    axs = [Axis(fig[i, j]; aspect=1) for i in 1:7 for j in 1:5]

    lines!(axs[1], x, sin.(x))
    axs[1].title = "lines(x, y)"

    scatter!(axs[2], x, sin.(x); color=:black)
    axs[2].title = "scatter(x, y)"

    scatterlines!(axs[3], x, sin.(x); color=:red)
    axs[3].title = "scatterlines(x, y)"

    stem!(axs[4], x, sin.(x); color=x)
    axs[4].title = "stem(x, y)"

    linesegments!(axs[5],
                    Point2f.(vec([[x, rand()] for i in 1:2, x in rand(10)]));
                    color=1:20, colormap=:gnuplot)
    axs[5].title = "linesegments(positions)"

    series!(axs[6], rand(10, 5); color=resample_cmap(:plasma, 10))
    axs[6].title = "series(curves)"

    ablines!(axs[7], x, sin.(x); color=resample_cmap(:viridis, length(x)))
    axs[7].title = "ablines(inter, slopes)"

    stairs!(axs[8], -2.5:0.2:2.5, x -> exp(-x^2); color=:dodgerblue)
    axs[8].title = "stairs(x, y)"

    vlines!(axs[9], [pi, 2pi, 3pi]; color=:orangered)
    axs[9].title = "vlines(x, y)"

    hlines!(axs[10], [pi, 2pi, 3pi]; color=:black)
    axs[10].title = "hlines(x, y)"

    vspan!(axs[11], [0, 2pi, 4pi], [pi, 3pi, 5pi];
            color=1:3, colormap=(:blues, 0.5))
    axs[11].title = "vspan(xs_low, xs_high)"

    hspan!(axs[12], [0, 2pi, 4pi], [pi, 3pi, 5pi];
            color=1:3, colormap=(:reds, 0.5))
    axs[12].title = "hspan(ys_low, ys_high)"

    spy!(axs[13], 0 .. 1, 0 .. 1, SparseArrays.sprand(10, 10, 0.05);
            markersize=4, marker=:rect,
            framecolor=:lightgrey,
            colormap=[:black, :red])
    axs[13].title = "spy(x, y, sparseArray)"

    rangebars!(axs[14], rand(5), -rand(5), rand(5);
                whiskerwidth=10, color=1:5)
    axs[14].title = "rangebars(vals, lo, hi)"

    errorbars!(axs[15], rand(5), -rand(5), rand(5);
                whiskerwidth=15)
    axs[15].title = "errorbars(vals, lo, hi)"

    band!(axs[16], x, sin.(x) .- 0.05 * rand(size(x)),
            sin.(x) .+ 0.05 * rand(size(x)); color=(:black, 0.25))
    axs[16].title = "band(x, y-σ, y+σ)"

    crossbar!(axs[17], [1, 2, 3, 4], [1, 2, 3, 4],
                [1, 2, 3, 4] .- 1, [1, 2, 3, 4] .+ 1;
                color=1:4, colormap=[:grey70, :red, :yellow],
                show_notch=true)
    axs[17].title = "crossbar(x,y,ymin,ymax)"

    barplot!(axs[18], [1, 2, 3], rand(3); color=1:3,
                colormap=[:black, :dodgerblue, :gold])
    axs[18].title = "barplot(x,y)"

    hist!(axs[19], randn(1000); color=:values,
            colormap=[:black, :dodgerblue, :grey95])
    axs[19].title = "hist(x)"

    density!(axs[20], randn(1000); normalization=:pdf,
                color=(:grey90, 0.35), strokewidth=2,
                strokecolor=:black, linestyle=:dash)
    axs[20].title = "density(x)"
    xbox = rand(1:3, 1000)
    boxplot!(axs[21], xbox, randn(1000); color=xbox,
                mediancolor=:black, colormap=[:grey, :dodgerblue, :yellow])
    axs[21].title = "boxplot(x, y)"

    violin!(axs[22], xbox, randn(1000); color=:black,
            show_median=true, mediancolor=:white)
    axs[22].title = "boxplot(x, y)"

    ecdfplot!(axs[23], randn(1000); color=:black, npoints=10)
    axs[23].title = "ecdfplot(x)"

    rainclouds!(axs[24], fill("A", 1000), randn(1000);
                orientation=:horizontal, color=(:snow3, 0.75))
    axs[24].title = "rainclouds(cat, y)"

    qqplot!(axs[25], randn(1000), randn(1000);
            qqline=:identity, color=:red, markercolor=:transparent,
            strokewidth=0.2, strokecolor=(:black, 0.5))
    axs[25].title = "qqplot(x, y)"

    poly!(axs[26], [Point2f(0.5, 0.0), Point2f(1, 0.5), Point2f(0.5, 1), Point2f(0, 0.5)];
            color=(:snow3, 0.5), strokewidth=3, strokecolor=:dodgerblue)
    axs[26].title = "poly(points)"

    pie!(axs[27], [0.1, 0.5, 0.2, 0.2];
            color=resample_cmap(:Hiroshige, 4), inner_radius=0.2)
    axs[27].title = "pie(fractions)"

    contour!(axs[28], 0 .. 1, 0 .. 1, rand(20, 20);
                colormap=:Hiroshige)
    axs[28].title = "contour(x,y,vals)"

    xs = LinRange(-4, 4, 15)
    ys = LinRange(-4, 4, 15)
    us = [x + y for x in xs, y in ys]
    vs = [y - x for x in xs, y in ys]
    strength = vec(sqrt.(us .^ 2 .+ vs .^ 2))

    arrows!(axs[29], xs, ys, us, vs;
            arrowsize=5, lengthscale=0.1,
            arrowcolor=strength, linecolor=strength,
            colormap=:Hiroshige)
    axs[29].title = "arrows(x,y,u,v)"

    semiStable(x, y) = Point2f(-y + x * (-1 + x^2 + y^2)^2, x + y * (-1 + x^2 + y^2)^2)
    streamplot!(axs[30], semiStable, -4 .. 4, -4 .. 4;
                gridsize=(24, 24), arrow_size=8)
    axs[30].title = "streamplot(f, x, y)"

    contourf!(axs[31], 0 .. 1, 0 .. 1, rand(20, 20);
                colormap=:plasma)
    axs[31].title = "contourf(x,y,vals)"

    heatmap!(axs[32], 0 .. 1, 0 .. 1, rand(20, 20); colormap=:linear_kbc_5_95_c73_n256)
    axs[32].title = "heatmap(x,y,vals)"

    image!(axs[33], 0 .. 1, 0 .. 1, testimage)
    axs[33].title = "image(x,y,img)"
    vertices = [0.0 0.0
                1.0 0.0
                1.0 1.0
                0.0 1.0]
    facesm = [1 2 3
                3 4 1]
    colors = [:black, :red, :dodgerblue, :orange]
    mesh!(axs[34], vertices, facesm; color=colors)
    axs[34].title = "mesh(v,f)"

    waterfall!(axs[35], randn(5); show_direction=true,
                color=:black)
    axs[35].title = "waterfall(x, y)"
    hidedecorations!.(axs, grid=false, ticks=false)

    Label(fig[end + 1, :],
            rich("Learn more at ",
                rich("https://juliadatascience.io,"; fontsize=18, color=:dodgerblue, font=:bold),
                " https://docs.makie.org, "))
    Label(fig[0, :],
            rich("Plotting Functions in Makie.jl ::",
                rich(" CHEAT SHEET"; fontsize=32, font=:bold, color=:black); fontsize=32))
    lines!(fig.scene, [22, 978], [1520, 1520]; linestyle=:dash)
    lines!(fig.scene, [22, 978], [37, 37]; linestyle=:dot, color=:grey)
    colgap!(fig.layout, 5)
    rowgap!(fig.layout, 8)
    return fig
end


rn = randn(10000)
testimage = Makie.logo()
using GLMakie
cheatsheet_3d(rn, testimage)
