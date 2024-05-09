@reference_test "Figure and Subplots" begin
    fig, _ = scatter(RNG.randn(100, 2), color = :red)
    scatter(fig[1, 2], RNG.randn(100, 2), color = :blue)
    scatter(fig[2, 1:2], RNG.randn(100, 2), color = :green)
    scatter(fig[1:2, 3][1:2, 1], RNG.randn(100, 2), color = :black)
    scatter(fig[1:2, 3][3, 1], RNG.randn(100, 2), color = :gray)
    fig
end

@reference_test "Figure with Blocks" begin
    fig = Figure(size = (900, 900))
    ax, sc = scatter(fig[1, 1][1, 1], RNG.randn(100, 2), axis = (;title = "Random Dots", xlabel = "Time"))
    sc2 = scatter!(ax, RNG.randn(100, 2) .+ 2, color = :red)
    ll = fig[1, 1][1, 2] = Legend(fig, [sc, sc2], ["Scatter", "Other"])
    lines(fig[2, 1:2][1, 3][1, 1], 0..3, sin ∘ exp, axis = (;title = "Exponential Sine"))
    heatmap(fig[2, 1:2][1, 1], RNG.randn(30, 30))
    heatmap(fig[2, 1:2][1, 2], RNG.randn(30, 30), colormap = :grays)
    lines!(fig[2, 1:2][1, 2], cumsum(RNG.rand(30)), color = :red, linewidth = 10)
    surface(fig[1, 2], collect(1.0:40), collect(1.0:40), (x, y) -> 10 * cos(x) * sin(y))
    fig[2, 1:2][2, :] = Colorbar(fig, vertical = false,
        height = 20, ticklabelalign = (:center, :top), flipaxis = false)
    fig[3, :] = Menu(fig, options = ["A", "B", "C"])
    lt = fig[0, :] = Label(fig, "Figure Demo")
    fig[5, :] = Textbox(fig)
    fig
end

@reference_test "Figure with boxes" begin
    fig = Figure(size = (900, 900))
    Box(fig[1,1], color = :red, strokewidth = 3, linestyle = :solid, strokecolor = :black)
    Box(fig[1,2], color = (:red, 0.5), strokewidth = 3, linestyle = :dash, strokecolor = :red)
    Box(fig[1,3], color = :white, strokewidth = 3, linestyle = :dot, strokecolor = (:black, 0.5))
    Box(fig[2,1], color = :red, strokewidth = 3, linestyle = :solid, strokecolor = :black, cornerradius = 0)
    Box(fig[2,2], color = (:red, 0.5), strokewidth = 3, linestyle = :dash, strokecolor = :red, cornerradius = 20)
    Box(fig[2,3], color = :white, strokewidth = 3, linestyle = :dot, strokecolor = (:black, 0.5), cornerradius = (0, 10, 20, 30))
    fig
end

@reference_test "menus" begin
    fig = Figure()
    funcs = [sqrt, x->x^2, sin, cos]
    options = zip(["Square Root", "Square", "Sine", "Cosine"], funcs)

    menu1 = Menu(fig, options = ["viridis", "heat", "blues"], default = 1)
    menu2 = Menu(fig, options = options, default = "Square")
    menu3 = Menu(fig, options = options, default = nothing)
    menu4 = Menu(fig, options = options, default = nothing)

    fig[1, 1] = grid!(
        [
            Label(fig, "A", width = nothing) Label(fig, "C", width = nothing);
            menu1                            menu3;
            Label(fig, "B", width = nothing) Label(fig, "D", width = nothing);
            menu2                            menu4;
        ]
    )
    menu2.is_open = true
    menu4.is_open = true
    fig
end

@reference_test "Label with text wrapping" begin
    lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    fig = Figure(size = (1000, 660))
    m!(fig, lbl) = mesh!(fig.scene, lbl.layoutobservables.computedbbox, color = (:red, 0.5), shading=NoShading)
    lbl1 = Label(fig[1, 1:2], "HEADER "^10, fontsize = 40, word_wrap = true)
    m!(fig, lbl1)

    lbl2 = Label(fig[2, 1], lorem_ipsum, word_wrap = true, justification = :left)
    m!(fig, lbl2)
    lbl3 = Label(fig[2, 2], "Smaller label\n <$('-'^12) pad $('-'^12)>")
    m!(fig, lbl3)

    lbl4 = Label(fig[3, 1], "test", word_wrap = true)
    m!(fig, lbl4)
    lbl5 = Label(fig[3, 2], lorem_ipsum, word_wrap = true)
    m!(fig, lbl5)
    fig
end

@reference_test "Axis titles and subtitles" begin
    f = Figure()

    Axis(
        f[1, 1],
        title = "First Title",
        subtitle = "This is a longer subtitle"
    )
    Axis(
        f[1, 2],
        title = "Second Title",
        subtitle = "This is a longer subtitle",
        titlealign = :left,
        subtitlecolor = :gray50,
        titlegap = 10,
        titlesize = 20,
        subtitlesize = 15,
    )
    Axis(
        f[2, 1],
        title = "Third Title",
        titlecolor = :gray50,
        titlefont = "TeX Gyre Heros Bold Italic Makie",
        titlealign = :right,
        titlesize = 25,
    )
    Axis(
        f[2, 2],
        title = "Fourth Title\nWith Line Break",
        subtitle = "This is an even longer subtitle,\nthat also has a line break.",
        titlealign = :left,
        subtitlegap = 2,
        titlegap = 5,
        subtitlefont = "TeX Gyre Heros Italic Makie",
        subtitlelineheight = 0.9,
        titlelineheight = 0.9,
    )

    f
end

# https://github.com/MakieOrg/Makie.jl/issues/3579
@reference_test "Axis yticksmirrored" begin
    f = Figure(size = (200, 200))
    Axis(f[1, 1], yticksmirrored = true, yticksize = 10, ytickwidth = 4, spinewidth = 5)
    Colorbar(f[1, 2])
    f
end
@reference_test "Axis xticksmirrored" begin
    f = Figure(size = (200, 200))
    Axis(f[1, 1], xticksmirrored = true, xticksize = 10, xtickwidth = 4, spinewidth = 5)
    Colorbar(f[0, 1], vertical = false)
    f
end

@reference_test "Legend draw order" begin
    with_theme(Lines = (linewidth = 10,)) do
        f = Figure()
        ax = Axis(f[1, 1], backgroundcolor = :gray80)
        for i in 1:3
            lines!(ax,( 1:10) .* i, label = "$i")
        end
        # To verify that RGB values differ across entries
        axislegend(ax, position = :lt, patchcolor = :red, patchsize = (100, 100), backgroundcolor = :gray50);
        Legend(f[1, 2], ax, patchcolor = :gray80, patchsize = (100, 100), backgroundcolor = :gray50);
        f
    end
end

@reference_test "Legend with scalar colors" begin
    f = Figure()
    ax = Axis(f[1, 1])
    for i in 1:3
        lines!(ax, (1:3) .+ i, color = i, colorrange = (0, 4), colormap = :Blues, label = "Line $i", linewidth = 3)
    end
    for i in 1:3
        scatter!(ax, (1:3) .+ i .+ 3, color = i, colorrange = (0, 4), colormap = :plasma, label = "Scatter $i", markersize = 15)
    end
    for i in 1:3
        barplot!(ax, (1:3) .+ i .+ 8, fillto = (1:3) .+ i .+ 7.5, color = i, colorrange = (0, 4), colormap = :tab10, label = "Barplot $i")
    end
    for i in 1:3
        poly!(ax, [Rect2f((j, i .+ 12 + j), (0.5, 0.5)) for j in 1:3], color = i, colorrange = (0, 4), colormap = :heat, label = "Poly $i")
    end
    Legend(f[1, 2], ax)
    f
end

@reference_test "LaTeXStrings in Axis3 plots" begin
    xs = LinRange(-10, 10, 100)
    ys = LinRange(0, 15, 100)
    zs = [cos(x) * sin(y) for x in xs, y in ys]


    fig = Figure()
    ax = Axis3(fig[1, 1]; xtickformat = xs -> [L"%$x" for x in xs])
    # check that switching to latex later also works
    ax.ytickformat = xs -> [L"%$x" for x in xs]

    surface!(ax, xs, ys, zs)
    fig
end

@reference_test "PolarAxis surface" begin
    f = Figure()
    ax = PolarAxis(f[1, 1])
    zs = [r*cos(phi) for phi in range(0, 4pi, length=100), r in range(1, 2, length=100)]
    p = surface!(ax, 0..2pi, 0..10, zs, shading = NoShading, colormap = :coolwarm, colorrange=(-2, 2))
    rlims!(ax, 0, 11) # verify that r = 10 doesn't end up at r > 10
    translate!(p, 0, 0, -200)
    Colorbar(f[1, 2], p)
    f
end

# may fail in WGLMakie due to missing dashes
@reference_test "PolarAxis scatterlines spine" begin
    f = Figure(size = (800, 400))
    ax1 = PolarAxis(f[1, 1], title = "No spine", spinevisible = false, theta_as_x = false)
    scatterlines!(ax1, range(0, 1, length=100), range(0, 10pi, length=100), color = 1:100)

    ax2 = PolarAxis(f[1, 2], title = "Modified spine")
    ax2.spinecolor[] = :red
    ax2.spinestyle[] = :dash
    ax2.spinewidth[] = 5
    scatterlines!(ax2, range(0, 10pi, length=100), range(0, 1, length=100), color = 1:100)
    f
end

# may fail in CairoMakie due to different text stroke handling
# and in WGLMakie due to missing stroke
@reference_test "PolarAxis decorations" begin
    f = Figure(size = (400, 400), backgroundcolor = :black)
    ax = PolarAxis(
        f[1, 1],
        backgroundcolor = :black,
        rminorgridvisible = true, rminorgridcolor = :red,
        rminorgridwidth = 1.0, rminorgridstyle = :dash,
        thetaminorgridvisible = true, thetaminorgridcolor = :blue,
        thetaminorgridwidth = 1.0, thetaminorgridstyle = :dash,
        rgridwidth = 2, rgridcolor = :red,
        thetagridwidth = 2, thetagridcolor = :blue,
        rticklabelsize = 18, rticklabelcolor = :red, rtickangle = pi/6,
        rticklabelstrokewidth = 1, rticklabelstrokecolor = :white,
        thetaticklabelsize = 18, thetaticklabelcolor = :blue,
        thetaticklabelstrokewidth = 1, thetaticklabelstrokecolor = :white,
        thetaticks = ([0, π/2, π, 3π/2], ["A", "B", "C", rich("D", color = :orange)]), # https://github.com/MakieOrg/Makie.jl/issues/3583
        rticks = ([0.0, 2.5, 5.0, 7.5, 10.0], ["0.0", "2.5", "5.0", "7.5", rich("10.0", color = :orange)])
    )
    f
end

@reference_test "PolarAxis limits" begin
    f = Figure(size = (800, 600))
    for (i, theta_0) in enumerate((0, -pi/6, pi/2))
        for (j, thetalims) in enumerate(((0, 2pi), (-pi/2, pi/2), (0, pi/12)))
            po = PolarAxis(f[i, j], theta_0 = theta_0, thetalimits = thetalims, rlimits = (1 + 2(j-1), 7))
            po.scene.backgroundcolor[] = RGBAf(1,0.5,0.5,1)
            lines!(po, range(0, 20pi, length=201), range(0, 10, length=201), color = :white, linewidth = 5)

            b = Box(f[i, j], color = (:blue, 0.2))
            translate!(b.blockscene, 0, 0, 9001)
        end
    end
    colgap!(f.layout, 5)
    rowgap!(f.layout, 5)
    f
end

@reference_test "PolarAxis radial shift and clip" begin
    phis = range(pi/4, 9pi/4, length=201)
    rs = 1.0 ./ sin.(range(pi/4, 3pi/4, length=51)[1:end-1])
    rs = vcat(rs, rs, rs, rs, rs[1])

    fig = Figure(size = (900, 300))
    ax1 = PolarAxis(fig[1, 1], clip_r = false, radius_at_origin = -2)  # red square, black, blue bulging
    ax2 = PolarAxis(fig[1, 2], clip_r = false, radius_at_origin = 0)   # red flower, black square, blue bulging
    ax3 = PolarAxis(fig[1, 3], clip_r = false, radius_at_origin = 0.5) # red large flower, black star, blue square
    for ax in (ax1, ax2, ax3)
        lines!(ax, phis, rs .- 2, color = :red, linewidth = 4)
        lines!(ax, phis, rs, color = :black, linewidth = 4)
        lines!(ax, phis, rs .+ 0.5, color = :blue, linewidth = 4)
    end
    fig
end

@reference_test "Axis3 axis reversal" begin
    f = Figure(size = (1000, 1000))
    revstr(dir, rev) = rev ? "$dir rev" : ""
    for (i, (x, y, z)) in enumerate(Iterators.product(fill((false, true), 3)...))
        Axis3(f[fldmod1(i, 3)...], title = "$(revstr("x", x)) $(revstr("y", y)) $(revstr("z", z))", xreversed = x, yreversed = y, zreversed = z)
        surface!(0:0.5:10, 0:0.5:10, (x, y) -> (sin(x) + 0.5x) * (cos(y) + 0.5y))
    end
    f
end

@reference_test "Colorbar for recipes" begin
    fig, ax, pl = barplot(1:3; color=1:3, colormap=Makie.Categorical(:viridis), figure=(;size=(800, 800)))
    Colorbar(fig[1, 2], pl; size=100)
    x = LinRange(-1, 1, 20)
    y = LinRange(-1, 1, 20)
    z = LinRange(-1, 1, 20)
    values = [sin(x[i]) * cos(y[j]) * sin(z[k]) for i in 1:20, j in 1:20, k in 1:20]

    # TO not make this fail in CairoMakie, we dont actually plot the volume
    _f, ax, cp = contour(-1..1, -1..1, -1..1, values; levels=10, colormap=:viridis)
    Colorbar(fig[2, 1], cp; size=300)

    _f, ax, vs = volumeslices(x, y, z, values, colormap=:bluesreds)
    Colorbar(fig[2, 2], vs)

    # horizontal colorbars
    Colorbar(fig[1, 3][2, 1]; limits=(0, 10), colormap=:viridis,
             vertical=false)
    Colorbar(fig[1, 3][3, 1]; limits=(0, 5), size=25,
             colormap=cgrad(:Spectral, 5; categorical=true), vertical=false)
    Colorbar(fig[1, 3][4, 1]; limits=(-1, 1), colormap=:heat, vertical=false, flipaxis=false,
             highclip=:cyan, lowclip=:red)
    xs = LinRange(0, 20, 50)
    ys = LinRange(0, 15, 50)
    zs = [cos(x) * sin(y) for x in xs, y in ys]
    ax, hm = contourf(fig[2, 3][1, 1], xs, ys, zs;
                      colormap=:Spectral, levels=[-1, -0.5, -0.25, 0, 0.25, 0.5, 1])
    Colorbar(fig[2, 3][1, 2], hm; ticks=-1:0.25:1)

    ax, hm = contourf(fig[3, :][1, 1], xs, ys, zs;
                      colormap=:Spectral, colorscale=sqrt, levels=[ 0, 0.25, 0.5, 1])
    Colorbar(fig[3, :][1, 2], hm; width=200)

    fig
end

@reference_test "datashader" begin
    airports = Point2f.(eachrow(readdlm(assetpath("airportlocations.csv"))))
    # Dont use the full dataset, since WGLMakie seems to time out if it's too big
    fewer = airports[RNG.rand(1:length(airports), 1000)]
    fig, ax, ds = datashader(fewer; async=false)
    Colorbar(fig[1, 2], ds; width=100)
    hidedecorations!(ax)
    hidespines!(ax)

    normaldist = RNG.randn(Point2f, 100000)
    ds1 = normaldist .+ (Point2f(-1, 0),)
    ds2 = normaldist .+ (Point2f(1, 0),)
    ax, pl = datashader(fig[2, :], Dict("a" => ds1, "b" => ds2); async=false)
    hidedecorations!(ax)
    axislegend(ax)
    fig
end

