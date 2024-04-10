
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
    f = Figure(size = (800, 800))
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
    fig, ax, meshplot = mesh(s)
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
    fig, ax, meshplot = mesh(coordinates, connectivity, color=color, shading=NoShading)
    wireframe!(ax, meshplot[1], color=(:black, 0.6), linewidth=3)
    fig
end

@reference_test "colored triangle" begin
    mesh(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color=[:red, :green, :blue],
        shading=NoShading
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
    sf = Observable(Base.Fix2(v, 0.0))
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
    colors = Makie.DEFAULT_PALETTES.color[]
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

@reference_test "Errorbars log scale" begin
    x = 1:5
    y = sin.(x) .+ 5
    fig = Figure()
    errorbars(fig[1, 1], x, y, y .- 1, y .+ 1; linewidth = 3, whiskerwidth = 20, axis = (; yscale = log10, xscale = log10))
    errorbars(fig[1, 2], y, x, y .- 1, y .+ 1; linewidth = 3, whiskerwidth = 20, direction = :x, axis = (; yscale = log10, xscale = log10))
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
    fig = Figure(size=(800, 800))
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
    fig = Figure(size = (700, 700))
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
                shading = NoShading, color = :blue)
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
    fig = Figure(size = (700, 700))
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
                shading = NoShading, color = :blue)
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
    t = text!(Point2f(100, 0.5), text = "Test", fontsize = 50, transform_marker=true)
    translate!(p, -100, 0, 0)
    translate!(t, -100, 0, 0)

    # Check that scale and rotate don't act on the marker for scatter (only the position)
    p2 = scatter!(ax, Point2f(1, 0), marker= 'a', markersize = 50)
    Makie.rotate!(p2, pi/4)
    scale!(p2, 0.5, 0.5, 1)

    # but do act on glyphs of text
    t2 = text!(ax, 1, 0, text = "Test", fontsize = 50, transform_marker=true)
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
    surface(1:10, 1:10, ones(10, 10); color = [RGBf(x*y/100, 0, 0) for x in 1:10, y in 1:10], shading = NoShading)
end

@reference_test "heatmap and image colormap interpolation" begin
    f = Figure(size=(500, 500))
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
    fig = Figure(size = (500, 250))
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
    fig = Figure(size=(400,200))
    ax = Axis(fig[1,1])
    x = range(0,1,length=50)
    scatter!(fig[1,1],Point2.(x,fill(0.,50)),color=x,colormap=cmap)
    hidedecorations!(ax)
    Colorbar(fig[2,1],vertical=false,colormap=cmap)
    fig
end

@reference_test "colorscale (heatmap)" begin
    x = 10.0.^(1:0.1:4)
    y = 1.0:0.1:5.0
    fig, ax, hm = heatmap(x, y, (x, y) -> x; axis = (; xscale = log10), colorscale = log10)
    Colorbar(fig[1, 2], hm)
    fig
end

@reference_test "colorscale (lines)" begin
    xs = 0:0.01:10
    ys = 2 .* (1 .+ sin.(xs))
    fig = Figure()
    lines(fig[1, 1], xs, ys; linewidth=50, color=ys, colorscale=identity)
    lines(fig[2, 1], xs, ys; linewidth=50, color=ys, colorscale=sqrt)
    fig
end

@reference_test "colorscale (scatter)" begin
    xs = range(0, 10; length = 30)
    ys = 0.5 .* sin.(xs)
    color = (1:30) .^ 2
    markersize = 100
    fig = Figure()
    scatter(fig[1, 1], xs, ys; markersize, color, colorscale = identity)
    scatter(fig[2, 1], xs, ys; markersize, color, colorscale = log10)
    fig
end

@reference_test "colorscale (hexbin)" begin
    x = RNG.randn(10_000)
    y = RNG.randn(10_000)
    fig = Figure()
    hexbin(fig[1, 1], x, y; bins = 40, colorscale = identity)
    hexbin(fig[1, 2], x, y; bins = 40, colorscale = log10)
    fig
end

@reference_test "multi rect with poly" begin
    # use thick strokewidth, so it will make tests fail if something is missing
    poly([Rect2f(0, 0, 1, 1)], color=:green, strokewidth=100, strokecolor=:black)
end

@reference_test "minor grid & scales" begin
    data = LinRange(0.01, 0.99, 200)
    f = Figure(size = (800, 800))
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

@reference_test "tricontourf with boundary nodes" begin
    n = 20
    angles = range(0, 2pi, length = n+1)[1:end-1]
    x = [cos.(angles); 2 .* cos.(angles .+ pi/n)]
    y = [sin.(angles); 2 .* sin.(angles .+ pi/n)]
    z = (x .- 0.5).^2 + (y .- 0.5).^2 .+ 0.5.* RNG.randn.()

    inner = [n:-1:1; n] # clockwise inner
    outer = [(n+1):(2n); n+1] # counter-clockwise outer
    boundary_nodes = [[outer], [inner]]
    tri = triangulate([x'; y'], boundary_nodes = boundary_nodes)
    f, ax, _ = tricontourf(tri, z)
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)
    f
end

@reference_test "tricontourf with boundary nodes and edges" begin
    curve_1 = [
    [(0.0, 0.0), (5.0, 0.0), (10.0, 0.0), (15.0, 0.0), (20.0, 0.0), (25.0, 0.0)],
    [(25.0, 0.0), (25.0, 5.0), (25.0, 10.0), (25.0, 15.0), (25.0, 20.0), (25.0, 25.0)],
    [(25.0, 25.0), (20.0, 25.0), (15.0, 25.0), (10.0, 25.0), (5.0, 25.0), (0.0, 25.0)],
    [(0.0, 25.0), (0.0, 20.0), (0.0, 15.0), (0.0, 10.0), (0.0, 5.0), (0.0, 0.0)]
    ]
    curve_2 = [
        [(4.0, 6.0), (4.0, 14.0), (4.0, 20.0), (18.0, 20.0), (20.0, 20.0)],
        [(20.0, 20.0), (20.0, 16.0), (20.0, 12.0), (20.0, 8.0), (20.0, 4.0)],
        [(20.0, 4.0), (16.0, 4.0), (12.0, 4.0), (8.0, 4.0), (4.0, 4.0), (4.0, 6.0)]
    ]
    curve_3 = [
        [(12.906, 10.912), (16.0, 12.0), (16.16, 14.46), (16.29, 17.06),
        (13.13, 16.86), (8.92, 16.4), (8.8, 10.9), (12.906, 10.912)]
    ]
    curves = [curve_1, curve_2, curve_3]
    points = [
        (3.0, 23.0), (9.0, 24.0), (9.2, 22.0), (14.8, 22.8), (16.0, 22.0),
        (23.0, 23.0), (22.6, 19.0), (23.8, 17.8), (22.0, 14.0), (22.0, 11.0),
        (24.0, 6.0), (23.0, 2.0), (19.0, 1.0), (16.0, 3.0), (10.0, 1.0), (11.0, 3.0),
        (6.0, 2.0), (6.2, 3.0), (2.0, 3.0), (2.6, 6.2), (2.0, 8.0), (2.0, 11.0),
        (5.0, 12.0), (2.0, 17.0), (3.0, 19.0), (6.0, 18.0), (6.5, 14.5),
        (13.0, 19.0), (13.0, 12.0), (16.0, 8.0), (9.8, 8.0), (7.5, 6.0),
        (12.0, 13.0), (19.0, 15.0)
    ]
    boundary_nodes, points = convert_boundary_points_to_indices(curves; existing_points=points)
    edges = Set(((1, 19), (19, 12), (46, 4), (45, 12)))

    tri = triangulate(points; boundary_nodes = boundary_nodes, edges = edges, check_arguments = false)
    z = [(x - 1) * (y + 1) for (x, y) in each_point(tri)]
    f, ax, _ = tricontourf(tri, z, levels = 30)
    f
end

@reference_test "tricontourf with provided triangulation" begin
    θ = [LinRange(0, 2π * (1 - 1/19), 20); 0]
    xy = Vector{Vector{Vector{NTuple{2,Float64}}}}()
    cx = [0.0, 3.0]
    for i in 1:2
        push!(xy, [[(cx[i] + cos(θ), sin(θ)) for θ in θ]])
        push!(xy, [[(cx[i] + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
    end
    boundary_nodes, points = convert_boundary_points_to_indices(xy)
    tri = triangulate(points; boundary_nodes=boundary_nodes, check_arguments=false)
    z = [(x - 3/2)^2 + y^2 for (x, y) in each_point(tri)]

    f, ax, tr = tricontourf(tri, z, colormap = :matter)
    f
end

@reference_test "contour labels 2D" begin
    paraboloid = (x, y) -> 10(x^2 + y^2)

    x = range(-4, 4; length = 40)
    y = range(-4, 4; length = 60)
    z = paraboloid.(x, y')

    fig, ax, hm = heatmap(x, y, z)
    Colorbar(fig[1, 2], hm)

    contour!(
        ax, x, y, z;
        color = :red, levels = 0:20:100, labels = true,
        labelsize = 15, labelfont = :bold, labelcolor = :orange,
    )
    fig
end

@reference_test "contour labels with transform_func" begin
    f = Figure(size = (400, 400))
    a = Axis(f[1, 1], xscale = log10)
    xs = 10 .^ range(0, 3, length=101)
    ys = range(1, 4, length=101)
    zs = [sqrt(x*x + y*y) for x in -50:50, y in -50:50]
    contour!(a, xs, ys, zs, labels = true, labelsize = 20)
    f
end

@reference_test "contour labels 3D" begin
    fig = Figure()
    Axis3(fig[1, 1])

    xs = ys = range(-.5, .5; length = 50)
    zs = @. √(xs^2 + ys'^2)

    levels = .025:.05:.475
    contour3d!(-zs; levels = -levels, labels = true, color = :blue)
    contour3d!(+zs; levels = +levels, labels = true, color = :red, labelcolor = :black)
    fig
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
        f = Figure(size = (800, 800))

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
    f = Figure(size = (800, 800))

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
    f = Figure(size = (800, 800))

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
    f = Figure(size = (800, 800))

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
    f = Figure(size = (800, 800))

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
    f = Figure(size = (800, 800))

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
    hexbin(f[1, 2], x, y, bins = 40, colorscale=log10,
        axis = (aspect = DataAspect(), title = "scale = log10"))
    f
end

# Scatter needs working highclip/lowclip first
@reference_test "hexbin colorrange highclip lowclip" begin
    x = RNG.randn(100000)
    y = RNG.randn(100000)

    f, ax, pl = hexbin(x, y,
        bins = 40,
        axis = (aspect = DataAspect(),),
        colorrange = (10, 300),
        highclip = :red,
        lowclip = :pink,
        strokewidth = 1,
        strokecolor = :gray30
    )
end

@reference_test "Latex labels after the fact" begin
    f = Figure(fontsize = 50)
    ax = Axis(f[1, 1])
    ax.xticks = ([3, 6, 9], [L"x" , L"y" , L"z"])
    ax.yticks = ([3, 6, 9], [L"x" , L"y" , L"z"])
    f
end

@reference_test "Rich text" begin
    f = Figure(fontsize = 30, size = (800, 600))
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

    # https://github.com/MakieOrg/Makie.jl/issues/3569
    b = bracket!(ax,
        [5, 6],
        [1, 2],
        [6, 7],
        [1, 2],
    )

    f
end

@reference_test "Log scale histogram (barplot)" begin
    f = Figure()
    hist(
        f[1, 1],
        RNG.randn(10^6);
        axis=(; yscale=log2)
    )
    hist(
        f[1, 2],
        RNG.randn(10^6);
        axis=(; xscale=log2),
        direction = :x
    )
    # make a gap in histogram as edge case
    hist(
        f[2, 1],
        filter!(x-> x<0 || x > 1.5, RNG.randn(10^6));
        axis=(; yscale=log10)
    )
    hist(
        f[2, 2],
        filter!(x-> x<0 || x > 1.5, RNG.randn(10^6));
        axis=(; xscale=log10),
        direction = :x
    )
    f
end

@reference_test "Histogram" begin
    data = sin.(1:1000)

    fig = Figure(size = (900, 900))
    hist(fig[1, 1], data)
    hist(fig[1, 2], data, bins = 30, color = :orange)
    a, p = hist(fig[1, 3], data, bins = 10, color = :transparent, strokecolor = :red, strokewidth = 4.0)
    a.xgridcolor[] = RGBAf(0,0,0,1); a.ygridcolor[] = RGBAf(0,0,0,1)

    hist(fig[2, 1], data, normalization = :pdf, direction = :x)
    hist(fig[2, 2], data, normalization = :density, color = 1:15)
    hist(fig[2, 3], data, normalization = :probability, scale_to = :flip)

    hist(fig[3, 1], data, offset = 20.0)
    hlines!(0.0, color = :black, linewidth = 3)
    hist(fig[3, 2], data, fillto = 1.0, scale_to = -5.0, direction = :x)
    vlines!(0.0, color = :black, linewidth = 3)
    hist(fig[3, 3], data, bar_labels = :y, label_size = 10, bins = 10)

    hist(
        fig[4, 1], data, scale_to = :flip, offset = 20,
        bar_labels = :x, label_size = 12, label_color = :green
    )
    hlines!(0.0, color = :black, linewidth = 3)
    i12 = mod1.(1:10, 2)
    hist(fig[4, 2], data, scale_to = :flip, bins = 10, direction = :x,
        bar_labels = :x, label_size = [14, 10][i12],
        label_color = [:yellow, :blue][i12], label_offset = [-30, 10][i12]
    )
    hist(fig[4, 3], data, weights = 1.0 ./ (2.0 .+ data))

    fig
end

@reference_test "Stephist" begin
    stephist(RNG.rand(10000))
    current_figure()
end

@reference_test "LaTeXStrings linesegment offsets" begin
    s = Scene(camera = campixel!, size = (600, 600))
    for (i, (offx, offy)) in enumerate(zip([0, 20, 50], [0, 10, 30]))
        for (j, rot) in enumerate([0, pi/4, pi/2])
            scatter!(s, 150i, 150j, color=:black)
            text!(s, 150i, 150j, text = L"\sqrt{x+y}", offset = (offx, offy),
                rotation = rot, fontsize = 30)
        end
    end
    s
end

@reference_test "Scalar colors from colormaps" begin
    f = Figure(size = (600, 600))
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

    fig = Figure(size = (600, 600))
    # Create a recipe plot
    ax, plot_top = heatmap(fig[1, 1], randn(10, 10))
    # Plot some recipes at the level below the contour
    scatterlineplot_1 = scatterlines!(plot_top, 1:10, 1:10; linewidth = 20, markersize = 20, color = :red)
    scatterlineplot_2 = scatterlines!(plot_top, 1:10, 1:10; linewidth = 20, markersize = 30, color = :blue)
    # Translate the lowest level plots (scatters)
    translate!(scatterlineplot_1.plots[2], 0, 0, 1)
    translate!(scatterlineplot_2.plots[2], 0, 0, -1)
    # Display
    fig
end

@reference_test "Plotting empty polygons" begin
    p = Makie.Polygon(Point2f[])
    q = Makie.Polygon(Point2f[(-1.0, 0.0), (1.0, 0.0), (0.0, 1.0)])
    fig, ax, sc = poly([p, q])
    poly!(Axis(fig[1,2]), p, color = :black)
    poly!(Axis(fig[2,1]), [p, q], color = [:red, :blue])
    poly!(Axis(fig[2,2]), [p, q], color = :red)
    poly!(Axis(fig[3,1]), Makie.MultiPolygon([p]), color = :green)
    poly!(Axis(fig[3,2]), Makie.MultiPolygon([p, q]), color = [:black, :red])
    fig
end

@reference_test "lines (some with NaNs) with array colors" begin
    f = Figure()
    ax = Axis(f[1, 1])
    hidedecorations!(ax)
    hidespines!(ax)
    lines!(ax, 1:10, 1:10, color = fill(RGBAf(1, 0, 0, 0.5), 10), linewidth = 5)
    lines!(ax, 1:10, 2:11, color = [fill(RGBAf(1, 0, 0, 0.5), 5); fill(RGBAf(0, 0, 1, 0.5), 5)], linewidth = 5)
    lines!(ax, 1:10, [3, 4, NaN, 6, 7, NaN, 9, 10, 11, NaN], color = [fill(RGBAf(1, 0, 0, 0.5), 5); fill(RGBAf(0, 0, 1, 0.5), 5)], linewidth = 5)
    lines!(ax, 1:10, 4:13, color = repeat([RGBAf(1, 0, 0, 0.5), RGBAf(0, 0, 1, 0.5)], 5), linewidth = 5)
    lines!(ax, 1:10, fill(NaN, 10), color = repeat([RGBAf(1, 0, 0, 0.5), RGBAf(0, 0, 1, 0.5)], 5), linewidth = 5)
    lines!(ax, 1:10, [6, 7, 8, NaN, 10, 11, 12, 13, 14, 15], color = [:red, :blue, fill(:red, 8)...], linewidth = 5)
    lines!(ax, 1:3, [7, 8, 9], color = [:red, :red, :blue], linewidth = 5)
    lines!(ax, 1:3, [8, 9, NaN], color = [:red, :red, :blue], linewidth = 5)
    lines!(ax, 1:3, [NaN, 10, 11], color = [:red, :red, :blue], linewidth = 5)
    lines!(ax, 1:5, [10, 11, NaN, 13, 14], color = [:red, :red, :blue, :blue, :blue], linewidth = [5, 5, 5, 10, 10])
    lines!(ax, 1:10, 11:20, color = [fill(RGBAf(1, 0, 0, 0.5), 5); fill(RGBAf(0, 0, 1, 0.5), 5)], linewidth = 5, linestyle = :dot)
    lines!(ax, 1:10, 12:21, color = fill(RGBAf(1, 0, 0, 0.5), 10), linewidth = 5, linestyle = :dot)
    f
end

@reference_test "contour with single alpha color" begin
    x = range(-π, π; length=50)
    z = @. sin(x) * cos(x')
    fig, ax = contour(x, x, z, color=RGBAf(1,0,0,0.4), linewidth=6)
end

@reference_test "Triplot with points, ghost edges, and convex hull" begin
    pts = RNG.rand(2, 50)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    fig, ax, sc = triplot(tri,
        triangle_color = :lightgray, strokewidth = 4,
        show_points=true, markersize = 20, markercolor = :orange,
        show_ghost_edges=true, ghost_edge_linewidth = 4,
        show_convex_hull=true, convex_hull_linewidth = 4

    )
    fig
end

# TODO: as noted in https://github.com/MakieOrg/Makie.jl/pull/3520#issuecomment-1873382060
# this test has some issues with random number generation across Julia 1.6 and 1, for now
# it's disabled until someone has time to look into it

# @reference_test "Triplot of a constrained triangulation with holes and a custom bounding box" begin
#     curve_1 = [[
#         (0.0, 0.0), (4.0, 0.0), (8.0, 0.0), (12.0, 0.0), (12.0, 4.0),
#         (12.0, 8.0), (14.0, 10.0), (16.0, 12.0), (16.0, 16.0),
#         (14.0, 18.0), (12.0, 20.0), (12.0, 24.0), (12.0, 28.0),
#         (8.0, 28.0), (4.0, 28.0), (0.0, 28.0), (-2.0, 26.0), (0.0, 22.0),
#         (0.0, 18.0), (0.0, 10.0), (0.0, 8.0), (0.0, 4.0), (-4.0, 4.0),
#         (-4.0, 0.0), (0.0, 0.0),
#     ]]
#     curve_2 = [[
#         (4.0, 26.0), (8.0, 26.0), (10.0, 26.0), (10.0, 24.0),
#         (10.0, 22.0), (10.0, 20.0), (8.0, 20.0), (6.0, 20.0),
#         (4.0, 20.0), (4.0, 22.0), (4.0, 24.0), (4.0, 26.0)
#     ]]
#     curve_3 = [[(4.0, 16.0), (12.0, 16.0), (12.0, 14.0), (4.0, 14.0), (4.0, 16.0)]]
#     curve_4 = [[(4.0, 8.0), (10.0, 8.0), (8.0, 6.0), (6.0, 6.0), (4.0, 8.0)]]
#     curves = [curve_1, curve_2, curve_3, curve_4]
#     points = [
#         (2.0, 26.0), (2.0, 24.0), (6.0, 24.0), (6.0, 22.0), (8.0, 24.0), (8.0, 22.0),
#         (2.0, 22.0), (0.0, 26.0), (10.0, 18.0), (8.0, 18.0), (4.0, 18.0), (2.0, 16.0),
#         (2.0, 12.0), (6.0, 12.0), (2.0, 8.0), (2.0, 4.0), (4.0, 2.0),
#         (-2.0, 2.0), (4.0, 6.0), (10.0, 2.0), (10.0, 6.0), (8.0, 10.0), (4.0, 10.0),
#         (10.0, 12.0), (12.0, 12.0), (14.0, 26.0), (16.0, 24.0), (18.0, 28.0),
#         (16.0, 20.0), (18.0, 12.0), (16.0, 8.0), (14.0, 4.0), (14.0, -2.0),
#         (6.0, -2.0), (2.0, -4.0), (-4.0, -2.0), (-2.0, 8.0), (-2.0, 16.0),
#         (-4.0, 22.0), (-4.0, 26.0), (-2.0, 28.0), (6.0, 15.0), (7.0, 15.0),
#         (8.0, 15.0), (9.0, 15.0), (10.0, 15.0), (6.2, 7.8),
#         (5.6, 7.8), (5.6, 7.6), (5.6, 7.4), (6.2, 7.4), (6.0, 7.6),
#         (7.0, 7.8), (7.0, 7.4)]
#     boundary_nodes, points = convert_boundary_points_to_indices(curves; existing_points=points)
#     tri = triangulate(points; boundary_nodes=boundary_nodes, rng = RNG.STABLE_RNG)
#     refine!(tri, max_area = 1e-3get_total_area(tri), rng = RNG.STABLE_RNG)
#     fig, ax, sc = triplot(tri,
#         show_points=true,
#         show_constrained_edges=true,
#         constrained_edge_linewidth=2,
#         strokewidth=0.2,
#         markersize=15,
#         point_color=:blue,
#         show_ghost_edges=true, # not as good because the outer boundary is not convex, but just testing
#         marker='x',
#         bounding_box = (-5,20,-5,35)) # also testing the conversion to Float64 for bbox here
#     fig
# end

@reference_test "Triplot with nonlinear transformation" begin
    f = Figure()
    ax = PolarAxis(f[1, 1])
    points = Point2f[(phi, r) for r in 1:10 for phi in range(0, 2pi, length=36)[1:35]]
    tr = triplot!(ax, points)
    f
end

@reference_test "Triplot after adding points and make sure the representative_point_list is correctly updated" begin
    points = [(0.0,0.0),(0.95,0.0),(1.0,1.4),(0.0,1.0)] # not 1 so that we have a unique triangulation
    tri = Observable(triangulate(points; delete_ghosts = false))
    fig, ax, sc = triplot(tri, show_points = true, markersize = 14, show_ghost_edges = true, recompute_centers = true)
    for p in [(0.3, 0.5), (-1.5, 2.3), (0.2, 0.2), (0.2, 0.5)]
        add_point!(tri[], p)
    end
    convex_hull!(tri[])
    notify(tri)
    ax = Axis(fig[1, 2])
    triplot!(ax, tri[], show_points = true, markersize = 14, show_ghost_edges = true, recompute_centers = true)
    fig
end

@reference_test "Triplot Showing ghost edges for a triangulation with disjoint boundaries" begin
    θ = LinRange(0, 2π, 20) |> collect
    θ[end] = 0 # need to make sure that 2π gives the exact same coordinates as 0
    xy = Vector{Vector{Vector{NTuple{2,Float64}}}}()
    cx = 0.0
    for i in 1:2
        ## Make the exterior circle
        push!(xy, [[(cx + cos(θ), sin(θ)) for θ in θ]])
        ## Now the interior circle - clockwise
        push!(xy, [[(cx + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
        cx += 3.0
    end
    boundary_nodes, points = convert_boundary_points_to_indices(xy)
    tri = triangulate(points; boundary_nodes=boundary_nodes, check_arguments=false)
    fig, ax, sc = triplot(tri, show_ghost_edges=true)
    fig
end

@reference_test "Voronoiplot for a centroidal tessellation with an automatic colormap" begin
    points = [(0.0,0.0),(1.0,0.0),(1.0,1.0),(0.0,1.0)]
    tri = triangulate(points; boundary_nodes = [1,2,3,4,1], rng = RNG.STABLE_RNG)
    refine!(tri; max_area=1e-2, min_angle = 29.871, rng = RNG.STABLE_RNG)
    vorn = voronoi(tri)
    smooth_vorn = centroidal_smooth(vorn; maxiters = 250, rng = RNG.STABLE_RNG)
    cmap = cgrad(:matter)
    fig, ax, sc = voronoiplot(smooth_vorn, markersize=10, strokewidth = 4, markercolor = :red)
    fig
end

@reference_test "Voronoiplot for a tessellation with a custom bounding box" begin
    pts = 25RNG.randn(2, 50)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    vorn = voronoi(tri, false)
    fig, ax, sc = voronoiplot(vorn,
        show_generators=true,
        colormap=:RdBu,
        strokecolor=:white,
        strokewidth=4,
        markersize=25,
        marker = 'x',
        markercolor=:green,
        unbounded_edge_extension_factor=5.0)
    xlims!(ax, -120, 120)
    ylims!(ax, -120, 120)
    fig
end

@reference_test "Voronoiplots with clipped tessellation and unbounded polygons" begin
    pts = 25RNG.randn(2, 10)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    vorn = voronoi(tri, true)
    fig, ax, sc = voronoiplot(vorn, color = (:blue,0.2), markersize = 20, strokewidth = 4)

    # used to be bugged
    points = [(0.0, 1.0), (-1.0, 2.0), (-2.0, -1.0)]
    tri = triangulate(points)
    vorn = voronoi(tri)
    voronoiplot(fig[1,2], vorn, show_generators = true, strokewidth = 4,
        color = [:red, :blue, :green], markercolor = :white, markersize = 20)

    fig
end

@reference_test "Voronoiplot with a nonlinear transform" begin
    f = Figure()
    ax = PolarAxis(f[1, 1], theta_as_x = false)
    points = Point2f[(r, phi) for r in 1:10 for phi in range(0, 2pi, length=36)[1:35]]
    polygon_color = [r for r in 1:10 for phi in range(0, 2pi, length=36)[1:35]]
    polygon_color_2 = [phi for r in 1:10 for phi in range(0, 2pi, length=36)[1:35]]
    tr = voronoiplot!(ax, points, smooth = false, show_generators = false, color = polygon_color)
    Makie.rlims!(ax, 12) # to make rect clip visible if circular clip doesn't happen
    ax = PolarAxis(f[1, 2], theta_as_x = false)
    tr = voronoiplot!(ax, points, smooth = true, show_generators = false, color = polygon_color_2)
    Makie.rlims!(ax, 12)
    f
end

@reference_test "Voronoiplot with some custom bounding boxes may not contain all data sites" begin
    points = [(-3.0, 7.0), (1.0, 6.0), (-1.0, 3.0), (-2.0, 4.0), (3.0, -2.0), (5.0, 5.0), (-4.0, -3.0), (3.0, 8.0)]
    tri = triangulate(points)
    vorn = voronoi(tri)
    color = [:red, :blue, :green, :yellow, :cyan, :magenta, :black, :brown] # the polygon colors should not change even if some are not included (because they're outside of the box)
    fig = Figure()
    ax1 = Axis(fig[1, 1], title = "Default")
    voronoiplot!(ax1, vorn, show_generators = true, markersize=14, strokewidth = 4, color = color)
    ax2 = Axis(fig[1, 2], title = "Some excluded")
    voronoiplot!(ax2, vorn, show_generators = true, markersize=14, strokewidth = 4, color = color, clip = BBox(0.0, 5.0, -15.0, 15.0))
    ax3 = Axis(fig[2, 1], title = "Bigger range")
    voronoiplot!(ax3, vorn, show_generators = true, markersize=14, strokewidth = 4, color = color, clip = (-15.0, 15.0, -15.0, 15.0))
    ax4 = Axis(fig[2, 2], title = "Only one polygon")
    voronoiplot!(ax4, vorn, show_generators = true, markersize=14, strokewidth = 4, color = color, clip = (10.0, 12.0, 2.0, 5.0))
    for ax in fig.content
        xlims!(ax4, -15, 15)
        ylims!(ax4, -15, 15)
    end
    fig
end

@reference_test "Voronoiplot after adding points" begin
    points = Observable([(0.0,0.0), (1.0,0.0), (1.0,1.0), (0.0,1.0)])
    fig, ax, sc = voronoiplot(points, show_generators=true, markersize=36) # make sure any regressions with missing generators are identified, so use 36
    push!(points[], (2.0, 2.0), (0.5, 0.5), (0.25, 0.25), (0.25, 0.75), (0.75, 0.25), (0.75, 0.75))
    notify(points)
    ax2 = Axis(fig[1, 2])
    voronoiplot!(ax2, voronoi(triangulate(points[])), show_generators=true, markersize=36)
    xlims!(ax,-0.5,2.5)
    ylims!(ax,-0.5,2.5)
    xlims!(ax2,-0.5,2.5)
    ylims!(ax2,-0.5,2.5) # need to make sure all generators are shown, and the bounding box is automatically updated
    fig
end

function ppu_test_plot(resolution, px_per_unit, scalefactor)
    fig, ax, pl = scatter(1:4, markersize=100, color=1:4, figure=(; size=resolution), axis=(; titlesize=50, title="ppu: $px_per_unit, sf: $scalefactor"))
    DataInspector(ax)
    hidedecorations!(ax)
    fig
end

@reference_test "px_per_unit and scalefactor" begin
    resolution = (800, 800)
    let st = nothing
        @testset begin
            matr = [(px, scale) for px in [0.5, 1, 2], scale in [0.5, 1, 2]]
            imgs = map(matr) do (px_per_unit, scalefactor)
                img = colorbuffer(ppu_test_plot(resolution, px_per_unit, scalefactor); px_per_unit=px_per_unit, scalefactor=scalefactor)
                @test size(img) == (800, 800) .* px_per_unit
                return img
            end
            fig = Figure()
            st = Makie.RamStepper(fig, Makie.current_backend().Screen(fig.scene), vec(imgs), :png)
        end
        st
    end
end

@reference_test "spurious minor tick (#3487)" begin
    fig = Figure(size=(227, 170))
    ax = Axis(fig[1, 1]; yticks = 0:.2:1, yminorticksvisible = true)
    ylims!(ax, 0, 1)
    fig
end

@reference_test "contourf bug #3683" begin
    x = y = LinRange(0, 1, 4)
    ymin, ymax = 0.4, 0.6
    steepness = 0.1
    f(x, y) = (tanh((y - ymin) / steepness) - tanh((y - ymax) / steepness) - 1)
    z = [f(_x, _y) for _x in x, _y in y]

    fig, ax, cof = contourf(x, y, z, levels = 2)
    Colorbar(fig[1, 2], cof)
    fig
end

@reference_test "Violin plots differently scaled" begin
    fig = Figure()
    xs = vcat([fill(i, i * 1000) for i in 1:4]...)
    ys = vcat(RNG.randn(6000), RNG.randn(4000) * 2)
    for (i, scale) in enumerate([:area, :count, :width])
        ax = Axis(fig[i, 1])
        violin!(ax, xs, ys; scale, show_median=true)
        Makie.xlims!(0.2, 4.8)
        ax.title = "scale=:$(scale)"
    end
    fig
end
