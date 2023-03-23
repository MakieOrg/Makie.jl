
@reference_test "Test heatmap + image overlap" begin
    heatmap(RNG.rand(32, 32))
    image!(map(x -> RGBAf(x, 0.5, 0.5, 0.8), RNG.rand(32, 32)))
    current_figure()
end

@reference_test "Test RGB heatmaps" begin
    fig = Figure()
    heatmap(fig[1, 1], RNG.rand(RGBf, 32, 32))
    heatmap(fig[1, 2], RNG.rand(RGBAf, 32, 32))
    fig
end

@reference_test "heatmap_interpolation" begin
    f = Figure(resolution = (800, 800))
    data = RNG.rand(32, 32)
    # the grayscale heatmap hides the problem that interpolation based on values
    # in GLMakie looks different than interpolation based on colors in CairoMakie
    heatmap(f[1, 1], data, interpolate = false, colormap = :grays)
    heatmap(f[1, 2], data, interpolate = true, colormap = :grays)
    data_big = RNG.rand(1000, 1000)
    heatmap(f[2, 1], data_big, interpolate = false, colormap = :grays)
    heatmap(f[2, 2], data_big, interpolate = true, colormap = :grays)
    xs = (1:32) .^ 1.5
    ys = (1:32) .^ 1.5
    data = RNG.rand(32, 32)
    heatmap(f[3, 1], xs, ys, data, interpolate = false, colormap = :grays)
    f
end

@reference_test "poly and colormap" begin
    # example by @Paulms from MakieOrg/Makie.jl#310
    points = Point2f[[0.0, 0.0], [0.1, 0.0], [0.1, 0.1], [0.0, 0.1]]
    colors = [0.0 ,0.0, 0.5, 0.0]
    fig, ax, polyplot = poly(points, color=colors, colorrange=(0.0, 1.0))
    points = Point2f[[0.1, 0.1], [0.2, 0.1], [0.2, 0.2], [0.1, 0.2]]
    colors = [0.5,0.5,1.0,0.3]
    poly!(ax, points, color=colors, colorrange=(0.0, 1.0))
    fig
end

@reference_test "quiver" begin
    x = range(-2, stop=2, length=21)
    arrows(x, x, RNG.rand(21, 21), RNG.rand(21, 21), arrowsize=0.05)
end

@reference_test "Arrows on hemisphere" begin
    s = Sphere(Point3f(0), 0.9f0)
    fig, ax, meshplot = mesh(s, transparency=true, alpha=0.05)
    pos = decompose(Point3f, s)
    dirs = decompose_normals(s)
    arrows!(ax, pos, dirs, arrowcolor=:red, arrowsize=0.1, linecolor=:red)
    fig
end

@reference_test "image" begin
    fig = Figure()
    image(fig[1,1], Makie.logo(), axis = (; aspect = DataAspect()))
    image(fig[1, 2], RNG.rand(100, 500), axis = (; aspect = DataAspect()))
    fig
end

@reference_test "FEM polygon 2D" begin
    coordinates = [
        0.0 0.0;
        0.5 0.0;
        1.0 0.0;
        0.0 0.5;
        0.5 0.5;
        1.0 0.5;
        0.0 1.0;
        0.5 1.0;
        1.0 1.0;
    ]
    connectivity = [
        1 2 5;
        1 4 5;
        2 3 6;
        2 5 6;
        4 5 8;
        4 7 8;
        5 6 9;
        5 8 9;
    ]
    color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
    poly(coordinates, connectivity, color=color, strokecolor=(:black, 0.6), strokewidth=4)
end

@reference_test "FEM mesh 2D" begin
    coordinates = [
        0.0 0.0;
        0.5 0.0;
        1.0 0.0;
        0.0 0.5;
        0.5 0.5;
        1.0 0.5;
        0.0 1.0;
        0.5 1.0;
        1.0 1.0;
    ]
    connectivity = [
        1 2 5;
        1 4 5;
        2 3 6;
        2 5 6;
        4 5 8;
        4 7 8;
        5 6 9;
        5 8 9;
    ]
    color = [0.0, 0.0, 0.0, 0.0, -0.375, 0.0, 0.0, 0.0, 0.0]
    fig, ax, meshplot = mesh(coordinates, connectivity, color=color, shading=false)
    wireframe!(ax, meshplot[1], color=(:black, 0.6), linewidth=3)
    fig
end

@reference_test "colored triangle" begin
    mesh(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color=[:red, :green, :blue],
        shading=false
    )
end

@reference_test "colored triangle with poly" begin
    poly(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
        color=[:red, :green, :blue],
        strokecolor=:black, strokewidth=2
    )
end

@reference_test "scale_plot" begin
    t = range(0, stop=1, length=500) # time steps
    θ = (6π) .* t    # angles
    x =  # x coords of spiral
    y =  # y coords of spiral
    lines(t .* cos.(θ), t .* sin.(θ);
        color=t, colormap=:algae, linewidth=8, axis = (; aspect = DataAspect()))
end

@reference_test "Polygons" begin
    points = decompose(Point2f, Circle(Point2f(50), 50f0))
    fig, ax, pol = poly(points, color=:gray, strokewidth=10, strokecolor=:red)
    # Optimized forms
    poly!(ax, [Circle(Point2f(50 + 300), 50f0)], color=:gray, strokewidth=10, strokecolor=:red)
    poly!(ax, [Circle(Point2f(50 + i, 50 + i), 10f0) for i = 1:100:400], color=:red)
    poly!(ax, [Rect2f(50 + i, 50 + i, 20, 20) for i = 1:100:400], strokewidth=2, strokecolor=:green)
    linesegments!(ax,
        [Point2f(50 + i, 50 + i) => Point2f(i + 70, i + 70) for i = 1:100:400], linewidth=8, color=:purple
    )
    fig
end

@reference_test "Text Annotation" begin
    text(
        ". This is an annotation!",
        position=(300, 200),
        align=(:center,  :center),
        fontsize=60,
        font="Blackchancery"
    )
end

@reference_test "Text rotation" begin
    fig = Figure()
    ax = fig[1, 1] = Axis(fig)
    pos = (500, 500)
    posis = Point2f[]
    for r in range(0, stop=2pi, length=20)
        p = pos .+ (sin(r) * 100.0, cos(r) * 100)
        push!(posis, p)
        text!(ax, "test",
            position=p,
            fontsize=50,
            rotation=1.5pi - r,
            align=(:center, :center)
        )
    end
    scatter!(ax, posis, markersize=10)
    fig
end

@reference_test "Standard deviation band" begin
    # Sample 100 Brownian motion path and plot the mean trajectory together
    # with a ±1σ band (visualizing uncertainty as marginal standard deviation).
    n, m = 100, 101
    t = range(0, 1, length=m)
    X = cumsum(RNG.randn(n, m), dims=2)
    X = X .- X[:, 1]
    μ = vec(mean(X, dims=1)) # mean
    lines(t, μ)              # plot mean line
    σ = vec(std(X, dims=1))  # stddev
    band!(t, μ + σ, μ - σ)   # plot stddev band
    current_figure()
end

@reference_test "Streamplot animation" begin
    v(x::Point2{T}, t) where T = Point2{T}(one(T) * x[2] * t, 4 * x[1])
    sf = Observable(Base.Fix2(v, 0e0))
    title_str = Observable("t = 0.00")
    sp = streamplot(sf, -2..2, -2..2;
                    linewidth=2, colormap=:magma, axis=(;title=title_str))
    Record(sp, LinRange(0, 20, 5); framerate=1) do i
        sf[] = Base.Fix2(v, i)
        title_str[] = "t = $(round(i; sigdigits=2))"
    end
end


@reference_test "Line changing colour" begin
    fig, ax, lineplot = lines(RNG.rand(10); linewidth=10)
    N = 20
    Record(fig, 1:N; framerate=1) do i
        lineplot.color = RGBf(i / N, (N - i) / N, 0) # animate scene
    end
end

let
    struct FitzhughNagumo{T}
        ϵ::T
        s::T
        γ::T
        β::T
    end
    @reference_test "streamplot" begin
        P = FitzhughNagumo(0.1, 0.0, 1.5, 0.8)
        ff(x, P::FitzhughNagumo) = Point2f(
            (x[1] - x[2] - x[1]^3 + P.s) / P.ϵ,
            P.γ * x[1] - x[2] + P.β
        )
        ff(x) = ff(x, P)
        streamplot(ff, -1.5..1.5, -1.5..1.5, colormap=:magma)
    end
end

@reference_test "Transforming lines" begin
    N = 7 # number of colours in default palette
    fig = Figure()
    ax = Axis(fig)
    fig[1,1] = ax
    st = Stepper(fig)

    xs = 0:9        # data
    ys = zeros(10)
    colors = Makie.default_palettes.color[]
    plots = map(1:N) do i # plot lines
        lines!(ax,
            xs, ys;
            color=colors[i],
            linewidth=5
        ) # plot lines with colors
    end

    Makie.step!(st)

    for (i, rot) in enumerate(LinRange(0, π / 2, N))
        Makie.rotate!(plots[i], rot)
        arc!(ax,
            Point2f(0),
            (8 - i),
            pi / 2,
            (pi / 2 - rot);
            color=plots[i].color,
            linewidth=5,
            linestyle=:dash
        )
    end

    Makie.step!(st)
    st
end

@reference_test "Axes label rotations" begin
    axis = (
        xlabel = "a long x label for this axis",
        ylabel = "a long y\nlabel for this axis",
        xlabelrotation = π / 4,
        ylabelrotation = 0,
    )
    fig, ax, _ = scatter(0:1; axis)

    st = Stepper(fig)
    Makie.step!(st)

    ax.yaxisposition[] = :right
    ax.ylabelrotation[] = Makie.automatic
    ax.xlabelrotation[] = -π / 5
    Makie.step!(st)

    ax.xaxisposition[] = :top
    ax.xlabelrotation[] = 3π / 4
    ax.ylabelrotation[] = π / 4
    Makie.step!(st)

    # reset to defaults
    ax.xaxisposition[] = :bottom
    ax.yaxisposition[] = :left
    ax.xlabelrotation[] = ax.ylabelrotation[] = Makie.automatic
    Makie.step!(st)

    st
end

@reference_test "Colorbar label rotations" begin
    axis = (
        xlabel = "x axis label",
        ylabel = "y axis label",
        xlabelrotation = -π / 10,
        ylabelrotation = -π / 3,
        yaxisposition = :right,
    )
    fig, _, _ = scatter(0:1; axis)

    cb_vert = Colorbar(fig[1, 2]; label = "vertical cbar", labelrotation = 0)
    cb_horz = Colorbar(fig[2, 1]; label = "horizontal cbar", labelrotation = π / 5, vertical = false)

    st = Stepper(fig)
    Makie.step!(st)

    # reset to defaults
    cb_vert.labelrotation[] = Makie.automatic
    Makie.step!(st)

    cb_horz.labelrotation[] = Makie.automatic
    Makie.step!(st)

    st
end

@reference_test "Errorbars x y low high" begin
    x = 1:10
    y = sin.(x)
    fig, ax, scatterplot = scatter(x, y)
    errorbars!(ax, x, y, RNG.rand(10) .+ 0.5, RNG.rand(10) .+ 0.5)
    errorbars!(ax, x, y, RNG.rand(10) .+ 0.5, RNG.rand(10) .+ 0.5, color = :red, direction = :x)
    fig
end

@reference_test "Rangebars x y low high" begin
    vals = -1:0.1:1

    lows = zeros(length(vals))
    highs = LinRange(0.1, 0.4, length(vals))

    fig, ax, rbars = rangebars(vals, lows, highs, color = :red)
    rangebars!(ax, vals, lows, highs, color = LinRange(0, 1, length(vals)),
        whiskerwidth = 3, direction = :x)
    fig
end


@reference_test "Simple pie chart" begin
    fig = Figure(resolution=(800, 800))
    pie(fig[1, 1], 1:5, color=collect(1:5), axis=(;aspect=DataAspect()))
    fig
end

@reference_test "Hollow pie chart" begin
    pie(1:5, color=collect(1.0:5), radius=2, inner_radius=1, axis=(;aspect=DataAspect()))
end

@reference_test "Open pie chart" begin
    pie(0.1:0.1:1.0, normalize=false, axis=(;aspect=DataAspect()))
end

@reference_test "intersecting polygon" begin
    x = LinRange(0, 2pi, 100)
    poly(Point2f.(zip(sin.(x), sin.(2x))), color = :white, strokecolor = :blue, strokewidth = 10)
end


@reference_test "Line Function" begin
    x = range(0, stop=3pi)
    fig, ax, lineplot = lines(x, sin.(x))
    lines!(ax, x, cos.(x), color=:blue)
    fig
end

@reference_test "Grouped bar" begin
    x1         = ["a_right", "a_right", "a_right", "a_right"]
    y1         = [2, 3, -3, -2]
    grp_dodge1 = [2, 2,  1,  1]
    grp_stack1 = [1, 2,  1,  2]

    x2         = ["z_left", "z_left", "z_left", "z_left"]
    y2         = [2, 3, -3, -2]
    grp_dodge2 = [1, 2,  1,  2]
    grp_stack2 = [1, 1,  2,  2]

    perm = [1, 4, 2, 7, 5, 3, 8, 6]
    x = [x1; x2][perm]
    x = categorical(x, levels = ["z_left", "a_right"])
    y = [y1; y2][perm]
    grp_dodge = [grp_dodge1; grp_dodge2][perm]
    grp_stack = [grp_stack1; grp_stack2][perm]

    tbl = (; x = x, grp_dodge = grp_dodge, grp_stack = grp_stack, y = y)

    fig = Figure()
    ax = Axis(fig[1,1])

    barplot!(ax, levelcode.(tbl.x), tbl.y, dodge = tbl.grp_dodge, stack = tbl.grp_stack, color = tbl.grp_stack)

    ax.xticks = (1:2, ["z_left", "a_right"])

    fig
end


@reference_test "space 2D" begin
    # This should generate a regular grid with text in a circle in a box. All
    # sizes and positions are scaled to be equal across all options.
    fig = Figure(resolution = (700, 700))
    ax = Axis(fig[1, 1], width = 600, height = 600)
    spaces = (:data, :pixel, :relative, :clip)
    xs = [
        [0.1, 0.35, 0.6, 0.85],
        [0.1, 0.35, 0.6, 0.85] * 600,
        [0.1, 0.35, 0.6, 0.85],
        2 .* [0.1, 0.35, 0.6, 0.85] .- 1
    ]
    scales = (0.02, 12, 0.02, 0.04)
    for (i, space) in enumerate(spaces)
        for (j, mspace) in enumerate(spaces)
            s = 1.5scales[i]
            mesh!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s), space = space,
                shading = false, color = :blue)
            lines!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s),
                space = space, linewidth = 2, color = :red)
            scatter!(
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange, marker = Circle,
                markersize = 5scales[j], space = space, markerspace = mspace)
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                fontsize = scales[j], space = space, markerspace = mspace,
                align = (:center, :center), color = :black)
        end
    end
    xlims!(ax, 0, 1)
    ylims!(ax, 0, 1)
    fig
end

@reference_test "space 2D autolimits" begin
    # Same code as above, but without setting limits. This should look different.
    # Compared to the test above:
    # - (data -> x) column should be centered in x direction
    # - (data -> x) column: meshes and lines should be stretched in x direction
    # - (data -> not data) column: circles and text should keep aspect
    # - (x -> data) row should have stretched circle and text ain x direction
    # - (not data -> data) should keep aspect ratio for mesh and lines
    # - (data -> x) should be slightly missaligned with (not data -> x)
    fig = Figure(resolution = (700, 700))
    ax = Axis(fig[1, 1], width = 600, height = 600)
    spaces = (:data, :pixel, :relative, :clip)
    xs = [
        [0.1, 0.35, 0.6, 0.85],
        [0.1, 0.35, 0.6, 0.85] * 600,
        [0.1, 0.35, 0.6, 0.85],
        2 .* [0.1, 0.35, 0.6, 0.85] .- 1
    ]
    scales = (0.02, 12, 0.02, 0.04)
    for (i, space) in enumerate(spaces)
        for (j, mspace) in enumerate(spaces)
            s = 1.5scales[i]
            mesh!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s), space = space,
                shading = false, color = :blue)
            lines!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s),
                space = space, linewidth = 2, color = :red)
            scatter!(
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange, marker = Circle,
                markersize = 5scales[j], space = space, markerspace = mspace)
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                fontsize = scales[j], space = space, markerspace = mspace,
                align = (:center, :center), color = :black)
        end
    end
    fig
end

@reference_test "Scatter & Text transformations" begin
    # Check that transformations apply in `space = :data`
    fig, ax, p = scatter(Point2f(100, 0.5), marker = 'a', markersize=50)
    t = text!(Point2f(100, 0.5), text = "Test", fontsize = 50)
    translate!(p, -100, 0, 0)
    translate!(t, -100, 0, 0)

    # Check that scale and rotate don't act on the marker for scatter (only the position)
    p2 = scatter!(ax, Point2f(1, 0), marker= 'a', markersize = 50)
    Makie.rotate!(p2, pi/4)
    scale!(p2, 0.5, 0.5, 1)

    # but do act on glyphs of text
    t2 = text!(ax, 1, 0, text = "Test", fontsize = 50)
    Makie.rotate!(t2, pi/4)
    scale!(t2, 0.5, 0.5, 1)

    xlims!(ax, -0.2, 0.5)
    ylims!(ax, 0, 1)

    fig
end

@reference_test "Array of Images Scatter" begin
    img = Makie.logo()
    scatter(1:2, 1:2, marker = [img, img], markersize=reverse(size(img) ./ 10), axis=(limits=(0.5, 2.5, 0.5, 2.5),))
end

@reference_test "Image Scatter different sizes" begin
    img = Makie.logo()
    img2 = load(Makie.assetpath("doge.png"))
    images = [img, img2]
    markersize = map(img-> Vec2f(reverse(size(img) ./ 10)), images)
    scatter(1:2, 1:2, marker = images, markersize=markersize, axis=(limits=(0.5, 2.5, 0.5, 2.5),))
end

@reference_test "2D surface with explicit color" begin
    surface(1:10, 1:10, ones(10, 10); color = [RGBf(x*y/100, 0, 0) for x in 1:10, y in 1:10], shading = false)
end

@reference_test "heatmap and image colormap interpolation" begin
    f = Figure(resolution=(500, 500))
    crange = LinRange(0, 255, 10)
    len = length(crange)
    img = zeros(Float32, len, len + 2)
    img[:, 1] .= 255f0
    for (i, v) in enumerate(crange)
        ib = i + 1
        img[2:end-1, ib] .= v
        img[1, ib] = 255-v
        img[end, ib] = 255-v
    end

    kw(p, interpolate) = (axis=(title="$(p)(interpolate=$(interpolate))", aspect=DataAspect()), interpolate=interpolate, colormap=[:white, :black])

    for (i, p) in enumerate([heatmap, image])
        for (j, interpolate) in enumerate([true, false])
            ax, pl = p(f[i,j], img; kw(p, interpolate)...)
            hidedecorations!(ax)
        end
    end
    f
end

@reference_test "nonlinear colormap" begin
    n = 100
    categorical = [false, true]
    scales = [exp, identity, log, log10]
    fig = Figure(resolution = (500, 250))
    ax = Axis(fig[1, 1])
    for (i, cat) in enumerate(categorical)
        for (j, scale) in enumerate(scales)
            cg = if cat
                cgrad(:viridis, 5; scale = scale, categorical=true)
            else
                cgrad(:viridis; scale = scale, categorical=nothing)
            end
            lines!(ax, Point2f.(LinRange(i+0.1, i+0.9, n), j); color = 1:n, colormap = cg, linewidth = 10)
        end
    end
    ax.xticks[] = ((1:length(categorical)) .+ 0.5, ["categorical=false", "categorical=true"])
    ax.yticks[] = ((1:length(scales)), string.(scales))
    fig
end

@reference_test "colormap with specific values" begin
    cmap = cgrad([:black,:white,:orange],[0,0.2,1])
    fig = Figure(resolution=(400,200))
    ax = Axis(fig[1,1])
    x = range(0,1,length=50)
    scatter!(fig[1,1],Point2.(x,fill(0.,50)),color=x,colormap=cmap)
    hidedecorations!(ax)
    Colorbar(fig[2,1],vertical=false,colormap=cmap)
    fig
end

@reference_test "multi rect with poly" begin
    # use thick strokewidth, so it will make tests fail if something is missing
    poly([Rect2f(0, 0, 1, 1)], color=:green, strokewidth=100, strokecolor=:black)
end

@reference_test "minor grid & scales" begin
    data = LinRange(0.01, 0.99, 200)
    f = Figure(resolution = (800, 800))
    for (i, scale) in enumerate([log10, log2, log, sqrt, Makie.logit, identity])
        row, col = fldmod1(i, 2)
        Axis(f[row, col], yscale = scale, title = string(scale),
            yminorticksvisible = true, yminorgridvisible = true,
            xminorticksvisible = true, xminorgridvisible = true,
            yminortickwidth = 4.0, xminortickwidth = 4.0,
            yminorgridwidth = 6.0, xminorgridwidth = 6.0,
            yminorticks = IntervalsBetween(3))

        lines!(data, color = :blue)
    end
    f
end

@reference_test "Tooltip" begin
    fig, ax, p = scatter(Point2f(0,0))
    xlims!(ax, -10, 10)
    ylims!(ax, -5, 5)
    tt = tooltip!(ax, Point2f(0), text = "left", placement = :left)
    tt.backgroundcolor[] = :red
    tooltip!(
        ax, 0, 0, "above with \nnewline\nand offset",
        placement = :above, textpadding = (8, 5, 3, 2), align = 0.8
    )
    tooltip!(ax, Point2f(0), "below", placement = :below, outline_color = :red, outline_linestyle = :dot)
    tooltip!(
        ax, 0, 0, text = "right", placement = :right, fontsize = 30,
        outline_linewidth = 5, offset = 30, triangle_size = 15,
        strokewidth = 2f0, strokecolor = :cyan
    )
    fig
end

@reference_test "tricontourf" begin
    x = RNG.randn(50)
    y = RNG.randn(50)
    z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* RNG.randn.()

    f, ax, tr = tricontourf(x, y, z)
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
    Colorbar(f[1, 2], tr)
    f
end

@reference_test "tricontourf extendhigh extendlow" begin
    x = RNG.randn(50)
    y = RNG.randn(50)
    z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* RNG.randn.()

    f, ax, tr = tricontourf(x, y, z, levels = -1.8:0.2:-0.4, extendhigh = :red, extendlow = :orange)
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
    Colorbar(f[1, 2], tr)
    f
end

@reference_test "tricontourf relative mode" begin
    x = RNG.randn(50)
    y = RNG.randn(50)
    z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* RNG.randn.()

    f, ax, tr = tricontourf(x, y, z, mode = :relative, levels = 0.2:0.1:1, colormap = :batlow)
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black, colormap = :batlow)
    Colorbar(f[1, 2], tr)
    f
end

@reference_test "tricontourf manual vs delaunay" begin
    n = 20
    angles = range(0, 2pi, length = n+1)[1:end-1]
    x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
    y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
    z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5 .* RNG.randn.()

    triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
    triangulation_outer = reduce(hcat, map(i -> [n-1, n, 0] .+ i, 1:n))
    triangulation = hcat(triangulation_inner, triangulation_outer)

    f, ax, _ = tricontourf(x, y, z, triangulation = triangulation,
        axis = (; aspect = 1, title = "Manual triangulation"))
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

    tricontourf(f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
        axis = (; aspect = 1, title = "Delaunay triangulation"))
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

    f
end

@reference_test "marker offset in data space" begin
    f = Figure()
    ax = Axis(f[1, 1]; xticks=0:1, yticks=0:10)
    scatter!(ax, fill(0, 10), 0:9, marker=Rect, marker_offset=Vec2f(0,0), transform_marker=true, markerspace=:data, markersize=Vec2f.(1, LinRange(0.1, 1, 10)))
    lines!(ax, Rect(0, 0, 1, 10), color=:red)
    f
end

@reference_test "trimspine" begin
    with_theme(Axis = (limits = (0.5, 5.5, 0.3, 3.4), spinewidth = 8, topspinevisible = false, rightspinevisible = false)) do
        f = Figure(resolution = (800, 800))

        for (i, ts) in enumerate([(true, true), (true, false), (false, true), (false, false)])
            Label(f[0, i], string(ts), tellwidth = false)
            Axis(f[1, i], xtrimspine = ts)
            Axis(f[2, i], ytrimspine = ts)
            Axis(f[3, i], xtrimspine = ts, xreversed = true)
            Axis(f[4, i], ytrimspine = ts, yreversed = true)
        end

        for (i, l) in enumerate(["x", "y", "x reversed", "y reversed"])
            Label(f[i, 5], l, tellheight = false)
        end

        f
    end
end

@reference_test "hexbin bin int" begin
    f = Figure(resolution = (800, 800))

    x = RNG.rand(300)
    y = RNG.rand(300)

    for i in 2:5
        ax = Axis(f[fldmod1(i-1, 2)...], title = "bins = $i", aspect = DataAspect())
        hexbin!(ax, x, y, bins = i)
        wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
        scatter!(ax, x, y, color = :red, markersize = 5)
    end

    f
end

@reference_test "hexbin bin tuple" begin
    f = Figure(resolution = (800, 800))

    x = RNG.rand(300)
    y = RNG.rand(300)

    for i in 2:5
        ax = Axis(f[fldmod1(i-1, 2)...], title = "bins = (3, $i)", aspect = DataAspect())
        hexbin!(ax, x, y, bins = (3, i))
        wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
        scatter!(ax, x, y, color = :red, markersize = 5)
    end

    f
end



@reference_test "hexbin two cellsizes" begin
    f = Figure(resolution = (800, 800))

    x = RNG.rand(300)
    y = RNG.rand(300)

    for (i, cellsize) in enumerate([0.1, 0.15, 0.2, 0.25])
        ax = Axis(f[fldmod1(i, 2)...], title = "cellsize = ($cellsize, $cellsize)", aspect = DataAspect())
        hexbin!(ax, x, y, cellsize = (cellsize, cellsize))
        wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
        scatter!(ax, x, y, color = :red, markersize = 5)
    end

    f
end

@reference_test "hexbin one cellsize" begin
    f = Figure(resolution = (800, 800))

    x = RNG.rand(300)
    y = RNG.rand(300)

    for (i, cellsize) in enumerate([0.1, 0.15, 0.2, 0.25])
        ax = Axis(f[fldmod1(i, 2)...], title = "cellsize = $cellsize", aspect = DataAspect())
        hexbin!(ax, x, y, cellsize = cellsize)
        wireframe!(ax, Rect2f(Point2f.(x, y)), color = :red)
        scatter!(ax, x, y, color = :red, markersize = 5)
    end

    f
end

@reference_test "hexbin threshold" begin
    f = Figure(resolution = (800, 800))

    x = RNG.randn(100000)
    y = RNG.randn(100000)

    for (i, threshold) in enumerate([1, 10, 100, 500])
        ax = Axis(f[fldmod1(i, 2)...], title = "threshold = $threshold", aspect = DataAspect())
        hexbin!(ax, x, y, cellsize = 0.4, threshold = threshold)
    end
    f
end

@reference_test "hexbin scale" begin
    x = RNG.randn(100000)
    y = RNG.randn(100000)

    f = Figure()
    hexbin(f[1, 1], x, y, bins = 40,
        axis = (aspect = DataAspect(), title = "scale = identity"))
    hexbin(f[1, 2], x, y, bins = 40, scale=log10,
        axis = (aspect = DataAspect(), title = "scale = log10"))
    f
end

# Scatter needs working highclip/lowclip first
# @reference_test "hexbin colorrange highclip lowclip" begin
#     x = RNG.randn(100000)
#     y = RNG.randn(100000)

#     hexbin(x, y,
#         bins = 40,
#         axis = (aspect = DataAspect(),),
#         colorrange = (10, 300),
#         highclip = :red,
#         lowclip = :pink,
#         strokewidth = 1,
#         strokecolor = :gray30
#     )
# end

@reference_test "Latex labels after the fact" begin
    f = Figure(fontsize = 50)
    ax = Axis(f[1, 1])
    ax.xticks = ([3, 6, 9], [L"x" , L"y" , L"z"])
    ax.yticks = ([3, 6, 9], [L"x" , L"y" , L"z"])
    f
end

@reference_test "Rich text" begin
    f = Figure(fontsize = 30, resolution = (800, 600))
    ax = Axis(f[1, 1],
        limits = (1, 100, 0.001, 1),
        xscale = log10,
        yscale = log2,
        title = rich("A ", rich("title", color = :red, font = :bold_italic)),
        xlabel = rich("X", subscript("label", fontsize = 25)),
        ylabel = rich("Y", superscript("label")),
    )
    Label(f[1, 2], rich("Hi", rich("Hi", offset = (0.2, 0.2), color = :blue)), tellheight = false)
    Label(f[1, 3], rich("X", superscript("super"), subscript("sub")), tellheight = false)
    f
end

@reference_test "bracket scalar" begin
    f, ax, l = lines(0..9, sin; axis = (; xgridvisible = false, ygridvisible = false))
    ylims!(ax, -1.5, 1.5)

    bracket!(pi/2, 1, 5pi/2, 1, offset = 5, text = "Period length", style = :square)

    bracket!(pi/2, 1, pi/2, -1, text = "Amplitude", orientation = :down,
        linestyle = :dash, rotation = 0, align = (:right, :center), textoffset = 4, linewidth = 2, color = :red, textcolor = :red)

    bracket!(2.3, sin(2.3), 4.0, sin(4.0),
        text = "Falling", offset = 10, orientation = :up, color = :purple, textcolor = :purple)

    bracket!(Point(5.5, sin(5.5)), Point(7.0, sin(7.0)),
        text = "Rising", offset = 10, orientation = :down, color = :orange, textcolor = :orange, 
        fontsize = 30, textoffset = 30, width = 50)
    f
end

@reference_test "bracket vector" begin
    f = Figure()
    ax = Axis(f[1, 1])

    bracket!(ax,
        1:5,
        2:6,
        3:7,
        2:6,
        text = ["A", "B", "C", "D", "E"],
        orientation = :down,
    )

    bracket!(ax,
        [(Point2f(i, i-0.7), Point2f(i+2, i-0.7)) for i in 1:5],
        text = ["F", "G", "H", "I", "J"],
        color = [:red, :blue, :green, :orange, :brown],
        linestyle = [:dash, :dot, :dash, :dot, :dash],
        orientation = [:up, :down, :up, :down, :up],
        textcolor = [:red, :blue, :green, :orange, :brown],
        fontsize = range(12, 24, length = 5),
    )

    f
end

@reference_test "Stephist" begin
    stephist(RNG.rand(10000))
    current_figure()
end

@reference_test "LaTeXStrings linesegment offsets" begin
    s = Scene(camera = campixel!, resolution = (600, 600))
    for (i, (offx, offy)) in enumerate(zip([0, 20, 50], [0, 10, 30]))
        for (j, rot) in enumerate([0, pi/4, pi/2])
            scatter!(s, 150i, 150j)
            text!(s, 150i, 150j, text = L"\sqrt{x+y}", offset = (offx, offy),
                rotation = rot, fontsize = 30)
        end
    end
    s
end

@reference_test "Scalar colors from colormaps" begin
    f = Figure(resolution = (600, 600))
    ax = Axis(f[1, 1])
    hidedecorations!(ax)
    hidespines!(ax)
    colormap = :tab10
    colorrange = (1, 10)
    for i in 1:10
        color = i
        lines!(ax, i .* [10, 10], [10, 590]; color, colormap, colorrange, linewidth = 5)
        scatter!(ax, fill(10 * i + 130, 50), range(10, 590, length = 50); color, colormap, colorrange)
        poly!(ax, Ref(Point2f(260, i * 50)) .+ Point2f[(0, 0), (50, 0), (25, 40)]; color, colormap, colorrange)
        text!(ax, 360, i * 50, text = "$i"; color, colormap, colorrange, fontsize = 40)
        poly!(ax, [Ref(Point2f(430 + 20 * j, 20 * j + i * 50)) .+ Point2f[(0, 0), (30, 0), (15, 22)] for j in 1:3]; color, colormap, colorrange)
    end
    f
end

@reference_test "Z-translation within a recipe" begin
    # This is testing whether backends respect the 
    # z-level of plots within recipes in 2d.
    # Ideally, the output of this test
    # would be a blue line with red scatter markers.
    # However, if a backend does not correctly pick up on translations,
    # then this will be drawn in the drawing order, and blue
    # will completely obscure red.
    
    # It seems like we can't define recipes in `@reference_test` yet,
    # so we'll have to fake a recipe's structure.
    
    fig = Figure(resolution = (600, 600))
    # Create a recipe plot
    ax, plot_top = contour(randn(10, 10))
    # Plot some recipes at the level below the contour
    scatterlineplot_1 = scatterlines!(plot_top, 1:10, 1:10; linewidth = 20, markersize = 20, color = :red)
    scatterlineplot_2 = scatterlines!(plot_top, 1:10, 1:10; linewidth = 20, markersize = 30, color = :blue)
    # Translate the lowest level plots (scatters)
    translate!(scatterlineplot_1.plots[2], 0, 0, 1)
    translate!(scatterlineplot_2.plots[2], 0, 0, -1)
    # Display
    fig
end
