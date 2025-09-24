@reference_test "RGB heatmap, heatmap + image overlap" begin
    fig = Figure()
    heatmap(fig[1, 1], RNG.rand(32, 32))
    image!(map(x -> RGBAf(x, 0.5, 0.5, 0.8), RNG.rand(32, 32)))

    heatmap(fig[2, 1], RNG.rand(RGBf, 32, 32))
    heatmap(fig[2, 2], RNG.rand(RGBAf, 32, 32))
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
    colors = [0.0, 0.0, 0.5, 0.0]
    fig, ax, polyplot = poly(points, color = colors, colorrange = (0.0, 1.0))
    points = Point2f[[0.1, 0.1], [0.2, 0.1], [0.2, 0.2], [0.1, 0.2]]
    colors = [0.5, 0.5, 1.0, 0.3]
    poly!(ax, points, color = colors, colorrange = (0.0, 1.0))
    fig
end

@reference_test "quiver" begin
    x = range(-2, stop = 2, length = 21)
    arrows(x, x, RNG.rand(21, 21), RNG.rand(21, 21), arrowsize = 0.05)
end

@reference_test "Arrows on hemisphere" begin
    s = Sphere(Point3f(0), 0.9f0)
    fig, ax, meshplot = mesh(s)
    pos = decompose(Point3f, s)
    dirs = decompose_normals(s)
    arrows!(ax, pos, dirs, arrowcolor = :red, arrowsize = 0.1, linecolor = :red)
    fig
end

@reference_test "image" begin
    fig = Figure()
    image(fig[1, 1], Makie.logo(), axis = (; aspect = DataAspect()))
    image(fig[1, 2], RNG.rand(100, 500), axis = (; aspect = DataAspect()))
    fig
end

@reference_test "FEM poly and mesh" begin
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

    f = Figure()
    poly(f[1, 1], coordinates, connectivity, color = color, strokecolor = (:black, 0.6), strokewidth = 4)

    a, meshplot = mesh(f[2, 1], coordinates, connectivity, color = color, shading = NoShading)
    wireframe!(meshplot[1], color = (:black, 0.6), linewidth = 3)

    cat = loadasset("cat.obj")
    vertices = decompose(Point3f, cat)
    faces = decompose(TriangleFace{Int}, cat)
    coordinates = [vertices[i][j] for i in 1:length(vertices), j in 1:3]
    connectivity = [faces[i][j] for i in 1:length(faces), j in 1:3]
    mesh(
        f[1:2, 2],
        coordinates, connectivity,
        color = RNG.rand(length(vertices))
    )

    f
end

@reference_test "colored triangle (mesh, poly, 3D) + poly stroke" begin
    f = Figure()
    mesh(
        f[1, 1],
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
        shading = NoShading
    )

    poly(
        f[1, 2],
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)],
        color = [:red, :green, :blue],
        strokecolor = :black, strokewidth = 2
    )

    x = [0, 1, 2, 0]
    y = [0, 0, 1, 2]
    z = [0, 2, 0, 1]
    color = [:red, :green, :blue, :yellow]
    i = [0, 0, 0, 1]
    j = [1, 2, 3, 2]
    k = [2, 3, 1, 3]
    # indices interpreted as triangles (every 3 sequential indices)
    indices = [1, 2, 3, 1, 3, 4, 1, 4, 2, 2, 3, 4]
    mesh(f[2, 1], x, y, z, indices, color = color)

    ax, p = poly(f[2, 2], [Rect2f(0, 0, 1, 1)], color = :green, strokewidth = 50, strokecolor = :black)
    xlims!(ax, -0.5, 1.5)
    ylims!(ax, -0.5, 1.5)

    f
end

@reference_test "scale_plot" begin
    t = range(0, stop = 1, length = 500) # time steps
    θ = (6π) .* t    # angles
    x =  # x coords of spiral
        y =  # y coords of spiral
        lines(
        t .* cos.(θ), t .* sin.(θ);
        color = t, colormap = :algae, linewidth = 8, axis = (; aspect = DataAspect())
    )
end

@reference_test "Polygons" begin
    points = decompose(Point2f, Circle(Point2f(50), 50.0f0))
    fig, ax, pol = poly(points, color = :gray, strokewidth = 10, strokecolor = :red)
    # Optimized forms
    poly!(ax, [Circle(Point2f(50 + 300), 50.0f0)], color = :gray, strokewidth = 10, strokecolor = :red)
    poly!(ax, [Circle(Point2f(50 + i, 50 + i), 10.0f0) for i in 1:100:400], color = :red)
    poly!(ax, [Rect2f(50 + i, 50 + i, 20, 20) for i in 1:100:400], strokewidth = 2, strokecolor = :orange)
    linesegments!(
        ax,
        [Point2f(50 + i, 50 + i) => Point2f(i + 70, i + 70) for i in 1:100:400], linewidth = 8, color = :purple
    )
    poly!(
        ax, [Polygon(decompose(Point2f, Rect2f(150, 0, 100, 100))), Polygon(decompose(Point2f, Circle(Point2f(350, 200), 50)))],
        color = :gray, strokewidth = 10, strokecolor = :red
    )
    # single objects
    poly!(ax, Circle(Point2f(50, 350), 50), color = :gray, strokewidth = 10, strokecolor = :red)
    poly!(ax, Rect2f(0, 150, 100, 100), color = :gray, strokewidth = 10, strokecolor = :red)
    poly!(ax, Polygon(decompose(Point2f, Rect2f(150, 300, 100, 100))), color = :gray, strokewidth = 10, strokecolor = :red)
    fig
end

@reference_test "Standard deviation band" begin
    # Sample 100 Brownian motion path and plot the mean trajectory together
    # with a ±1σ band (visualizing uncertainty as marginal standard deviation).
    n, m = 100, 101
    t = range(0, 1, length = m)
    X = cumsum(RNG.randn(n, m), dims = 2)
    X = X .- X[:, 1]
    μ = vec(mean(X, dims = 1)) # mean
    f, ax, p = lines(t, μ, color = :yellow, linewidth = 2) # plot mean line
    translate!(p, 0, 0, 1) # make it draw on top
    σ = vec(std(X, dims = 1))  # stddev
    band!(ax, t, μ + σ, μ - σ)   # plot stddev band

    # vertical version
    ax2, p = lines(f[1, 2], μ, t, color = :yellow, linewidth = 2)
    translate!(p, 0, 0, 1)
    band!(ax2, t, μ + σ, μ - σ, direction = :y, alpha = 0.5)   # plot stddev band

    # array colors
    band(f[2, 1], t, μ + σ, μ - σ, direction = :x, color = eachindex(t))
    band(f[2, 2], t, μ + σ, μ - σ, direction = :y, color = eachindex(t), colormap = :Blues, alpha = 0.5)
    f
end

@reference_test "Band with NaN" begin
    f = Figure()
    ax1 = Axis(f[1, 1])

    # NaN in the middle
    band!(ax1, 1:5, [1, 2, NaN, 4, 5], [1.5, 3, 4, 5, 6.5])
    band!(ax1, 1:5, [3, 4, 5, 6, 7], [3.5, 5, NaN, 7, 8.5])
    band!(ax1, [1, 2, NaN, 4, 5], [5, 6, 7, 8, 9], [5.5, 7, 8, 9, 10.5])

    ax2 = Axis(f[1, 2])

    # NaN at the beginning and end
    band!(ax2, 1:5, [NaN, 2, 3, 4, NaN], [1.5, 3, 4, 5, 6.5])
    band!(ax2, 1:5, [3, 4, 5, 6, 7], [NaN, 5, 6, 7, NaN])
    band!(ax2, [NaN, 2, 3, 4, NaN], [5, 6, 7, 8, 9], [5.5, 7, 8, 9, 10.5])

    ax3 = Axis(f[2, 1])

    # No complete section
    band!(ax3, 1:5, [NaN, 2, NaN, 4, NaN], [1.5, 3, 4, 5, 6.5])
    band!(ax3, 1:5, [3, 4, 5, 6, 7], [NaN, 5, NaN, 7, NaN])
    band!(ax3, [NaN, 2, NaN, 4, NaN], [5, 6, 7, 8, 9], [5.5, 7, 8, 9, 10.5])

    ax4 = Axis(f[2, 2])
    # Two adjacent NaNs
    band!(ax4, 1:6, [1, 2, NaN, NaN, 5, 6], [1.5, 3, 4, 5, 6, 7.5])
    band!(ax4, 1:6, [3, 4, 5, 6, 7, 8], [3.5, 5, NaN, NaN, 8, 9.5])
    band!(ax4, [1, 2, NaN, NaN, 5, 6], [5, 6, 7, 8, 9, 10], [5.5, 7, 8, 9, 10, 11.5])

    linkaxes!(ax1, ax2, ax3, ax4)

    f
end

@reference_test "Streamplot animation" begin
    v(x::Point2{T}, t) where {T} = Point2{T}(one(T) * x[2] * t, 4 * x[1])
    sf = Observable(Base.Fix2(v, 0.0))
    title_str = Observable("t = 0.00")
    sp = streamplot(
        sf, -2 .. 2, -2 .. 2;
        linewidth = 2, colormap = :magma, axis = (; title = title_str)
    )
    Record(sp, LinRange(0, 20, 5); framerate = 1) do i
        sf[] = Base.Fix2(v, i)
        title_str[] = "t = $(round(i; sigdigits = 2))"
    end
end


@reference_test "Line changing colour" begin
    fig, ax, lineplot = lines(RNG.rand(10); linewidth = 10)
    N = 20
    Record(fig, 1:N; framerate = 1) do i
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
        streamplot(ff, -1.5 .. 1.5, -1.5 .. 1.5, colormap = :magma)
    end
end

@reference_test "Transforming lines" begin
    N = 7 # number of colours in default palette
    fig = Figure()
    ax = Axis(fig)
    fig[1, 1] = ax
    st = Stepper(fig)

    xs = 0:9        # data
    ys = zeros(10)
    colors = Makie.DEFAULT_PALETTES.color[]
    plots = map(1:N) do i # plot lines
        lines!(
            ax,
            xs, ys;
            color = colors[i],
            linewidth = 5
        ) # plot lines with colors
    end

    Makie.step!(st)

    for (i, rot) in enumerate(LinRange(0, π / 2, N))
        Makie.rotate!(plots[i], rot)
        arc!(
            ax,
            Point2f(0),
            (8 - i),
            pi / 2,
            (pi / 2 - rot);
            color = plots[i].color,
            linewidth = 5,
            linestyle = :dash
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
    rangebars!(
        ax, vals, lows, highs, color = LinRange(0, 1, length(vals)),
        whiskerwidth = 3, direction = :x
    )
    fig
end


@reference_test "Simple pie charts" begin
    fig = Figure()
    pie(fig[1, 1], 1:5, color = collect(1:5), axis = (; aspect = DataAspect()))
    pie(fig[1, 2], 1:5, color = collect(1.0:5), radius = 2, inner_radius = 1, axis = (; aspect = DataAspect()))
    pie(fig[2, 1], 0.1:0.1:1.0, normalize = false, axis = (; aspect = DataAspect()))
    fig
end

@reference_test "Pie with Segment-specific Radius" begin
    fig = Figure()
    ax = Axis(fig[1, 1]; autolimitaspect = 1)

    kw = (; offset_radius = 0.4, strokecolor = :transparent, strokewidth = 0)
    pie!(ax, ones(7); radius = sqrt.(2:8) * 3, kw..., color = Makie.wong_colors(0.8)[1:7])

    vs = [2, 3, 4, 5, 6, 7, 8]
    vs_inner = [1, 1, 1, 1, 2, 2, 2]
    rs = 8
    rs_inner = sqrt.(vs_inner ./ vs) * rs

    lp = Makie.Pattern(; direction = Makie.Vec2f(1, -1), width = 2, tilesize = (12, 12), linecolor = :darkgrey, backgroundcolor = :transparent)
    # draw the inner pie twice since `color` can not be vector of `LinePattern` currently
    pie!(ax, 20, 0, vs; radius = rs_inner, inner_radius = 0, kw..., color = Makie.wong_colors(0.4)[eachindex(vs)])
    pie!(ax, 20, 0, vs; radius = rs_inner, inner_radius = 0, kw..., color = lp)
    pie!(ax, 20, 0, vs; radius = rs, inner_radius = rs_inner, kw..., color = Makie.wong_colors(0.8)[eachindex(vs)])

    fig
end

@reference_test "Pie Position" begin
    fig = Figure()
    ax = Axis(fig[1, 1]; autolimitaspect = 1)

    vs = 0:6 |> Vector
    vs_ = vs ./ sum(vs) .* (3 / 2 * π)
    cs = Makie.wong_colors()
    Δx = [1, 1, 1, -1, -1, -1, 1] ./ 10
    Δy = [1, 1, 1, 1, 1, -1, -1] ./ 10
    Δr1 = [0, 0, 0.2, 0, 0.2, 0, 0]
    Δr2 = [0, 0, 0.2, 0, 0, 0, 0]

    pie!(ax, vs; color = cs)
    pie!(ax, 3 .+ Δx, 0, vs; color = cs)
    pie!(ax, 0, 3 .+ Δy, vs; color = cs)
    pie!(ax, 3 .+ Δx, 3 .+ Δy, vs; color = cs)

    pie!(ax, 7, 0, vs; color = cs, offset_radius = Δr1)
    pie!(ax, 7, 3, vs; color = cs, offset_radius = 0.2)
    pie!(ax, 10 .+ Δx, 3 .+ Δy, vs; color = cs, offset_radius = 0.2)
    pie!(ax, 10, 0, vs_; color = cs, offset_radius = Δr1, normalize = false, offset = π / 2)

    pie!(ax, Point2(0.5, -3), vs_; color = cs, offset_radius = Δr2, normalize = false, offset = π / 2)
    pie!(ax, Point2.(3.5, -3 .+ Δy), vs_; color = cs, offset_radius = Δr2, normalize = false, offset = π / 2)
    pie!(ax, Point2.(6.5 .+ Δx, -3), vs_; color = cs, offset_radius = Δr2, normalize = false, offset = π / 2)
    pie!(ax, Point2.(9.5 .+ Δx, -3 .+ Δy), vs_; color = cs, offset_radius = Δr2, normalize = false, offset = π / 2)

    pie!(ax, 0.5, -6, vs_; inner_radius = 0.2, color = cs, offset_radius = 0.2, normalize = false, offset = π / 2)
    pie!(ax, 3.5, -6 .+ Δy, vs_; inner_radius = 0.2, color = cs, offset_radius = 0.2, normalize = false, offset = π / 2)
    pie!(ax, 6.5 .+ Δx, -6, vs_; inner_radius = 0.2, color = cs, offset_radius = 0.2, normalize = false, offset = π / 2)
    pie!(ax, 9.5 .+ Δx, -6 .+ Δy, vs_; inner_radius = 0.2, color = cs, offset_radius = 0.2, normalize = false, offset = π / 2)

    fig
end

@reference_test "intersecting polygon" begin
    x = LinRange(0, 2pi, 100)
    poly(Point2f.(zip(sin.(x), sin.(2x))), color = :white, strokecolor = :blue, strokewidth = 10)
end

@reference_test "Grouped bar" begin
    x1 = ["a_right", "a_right", "a_right", "a_right"]
    y1 = [2, 3, -3, -2]
    grp_dodge1 = [2, 2, 1, 1]
    grp_stack1 = [1, 2, 1, 2]

    x2 = ["z_left", "z_left", "z_left", "z_left"]
    y2 = [2, 3, -3, -2]
    grp_dodge2 = [1, 2, 1, 2]
    grp_stack2 = [1, 1, 2, 2]

    perm = [1, 4, 2, 7, 5, 3, 8, 6]
    x = [x1; x2][perm]
    x = categorical(x, levels = ["z_left", "a_right"])
    y = [y1; y2][perm]
    grp_dodge = [grp_dodge1; grp_dodge2][perm]
    grp_stack = [grp_stack1; grp_stack2][perm]

    tbl = (; x = x, grp_dodge = grp_dodge, grp_stack = grp_stack, y = y)

    fig = Figure()
    ax = Axis(fig[1, 1])

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
        2 .* [0.1, 0.35, 0.6, 0.85] .- 1,
    ]
    scales = (0.02, 12, 0.02, 0.04)
    for (i, space) in enumerate(spaces)
        for (j, mspace) in enumerate(spaces)
            s = 1.5scales[i]
            mesh!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s), space = space,
                shading = NoShading, color = :blue
            )
            lines!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s),
                space = space, linewidth = 2, color = :red
            )
            scatter!(
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange, marker = Circle,
                markersize = 5scales[j], space = space, markerspace = mspace
            )
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                fontsize = scales[j], space = space, markerspace = mspace,
                align = (:center, :center), color = :black
            )
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
        2 .* [0.1, 0.35, 0.6, 0.85] .- 1,
    ]
    scales = (0.02, 12, 0.02, 0.04)
    for (i, space) in enumerate(spaces)
        for (j, mspace) in enumerate(spaces)
            s = 1.5scales[i]
            mesh!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s), space = space,
                shading = NoShading, color = :blue
            )
            lines!(
                ax, Rect2f(xs[i][i] - 2s, xs[i][j] - 2s, 4s, 4s),
                space = space, linewidth = 2, color = :red
            )
            scatter!(
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange, marker = Circle,
                markersize = 5scales[j], space = space, markerspace = mspace
            )
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                fontsize = scales[j], space = space, markerspace = mspace,
                align = (:center, :center), color = :black
            )
        end
    end
    fig
end

@reference_test "Scatter & Text transformations" begin
    # Check that transformations apply in `space = :data`
    fig, ax, p = scatter(Point2f(100, 0.5), marker = 'a', markersize = 50)
    t = text!(Point2f(100, 0.5), text = "Test", fontsize = 50, transform_marker = true)
    translate!(p, -100, 0, 0)
    translate!(t, -100, 0, 0)

    # Check that scale and rotate don't act on the marker for scatter (only the position)
    p2 = scatter!(ax, Point2f(1, 0), marker = 'a', markersize = 50)
    Makie.rotate!(p2, pi / 4)
    scale!(p2, 0.5, 0.5, 1)

    # but do act on glyphs of text
    t2 = text!(ax, 1, 0, text = "Test", fontsize = 50, transform_marker = true)
    Makie.rotate!(t2, pi / 4)
    scale!(t2, 0.5, 0.5, 1)

    xlims!(ax, -0.2, 0.5)
    ylims!(ax, 0, 1)

    fig
end

@reference_test "Array of Images Scatter" begin
    img = Makie.logo()
    scatter(1:2, 1:2, marker = [img, img], markersize = reverse(size(img) ./ 10), axis = (limits = (0.5, 2.5, 0.5, 2.5),))

    img2 = load(Makie.assetpath("doge.png"))
    images = [img, img2]
    markersize = map(img -> Vec2f(reverse(size(img) ./ 10)), images)
    scatter!(2:-1:1, 1:2, marker = images, markersize = markersize)
    current_figure()
end

@reference_test "2D surface with explicit color" begin
    surface(1:10, 1:10, ones(10, 10); color = [RGBf(x * y / 100, 0, 0) for x in 1:10, y in 1:10], shading = NoShading)
end

@reference_test "heatmap and image colormap interpolation" begin
    f = Figure(size = (500, 500))
    crange = LinRange(0, 255, 10)
    len = length(crange)
    img = zeros(Float32, len, len + 2)
    img[:, 1] .= 255.0f0
    for (i, v) in enumerate(crange)
        ib = i + 1
        img[2:(end - 1), ib] .= v
        img[1, ib] = 255 - v
        img[end, ib] = 255 - v
    end

    kw(p, interpolate) = (axis = (title = "$(p)(interpolate=$(interpolate))", aspect = DataAspect()), interpolate = interpolate, colormap = [:white, :black])

    for (i, p) in enumerate([heatmap, image])
        for (j, interpolate) in enumerate([true, false])
            ax, pl = p(f[i, j], img; kw(p, interpolate)...)
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
                cgrad(:viridis, 5; scale = scale, categorical = true)
            else
                cgrad(:viridis; scale = scale, categorical = nothing)
            end
            lines!(ax, Point2f.(LinRange(i + 0.1, i + 0.9, n), j); color = 1:n, colormap = cg, linewidth = 10)
        end
    end
    ax.xticks[] = ((1:length(categorical)) .+ 0.5, ["categorical=false", "categorical=true"])
    ax.yticks[] = ((1:length(scales)), string.(scales))
    fig
end

@reference_test "colormap with specific values" begin
    cmap = cgrad([:black, :white, :orange], [0, 0.2, 1])
    fig = Figure(size = (400, 200))
    ax = Axis(fig[1, 1])
    x = range(0, 1, length = 50)
    scatter!(fig[1, 1], Point2.(x, fill(0.0, 50)), color = x, colormap = cmap)
    hidedecorations!(ax)
    Colorbar(fig[2, 1], vertical = false, colormap = cmap)
    fig
end

@reference_test "colorscale (heatmap)" begin
    x = 10.0 .^ (1:0.1:4)
    y = 1.0:0.1:5.0
    fig, ax, hm = heatmap(x, y, (x, y) -> x; axis = (; xscale = log10), colorscale = log10)
    Colorbar(fig[1, 2], hm)
    fig
end

@reference_test "colorscale (lines)" begin
    xs = 0:0.01:10
    ys = 2 .* (1 .+ sin.(xs))
    fig = Figure()
    lines(fig[1, 1], xs, ys; linewidth = 50, color = ys, colorscale = identity)
    lines(fig[2, 1], xs, ys; linewidth = 50, color = ys, colorscale = sqrt)
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

@reference_test "minor grid & scales" begin
    data = LinRange(0.01, 0.99, 200)
    f = Figure(size = (800, 800))
    for (i, scale) in enumerate([log10, log2, log, sqrt, Makie.logit, identity])
        row, col = fldmod1(i, 2)
        Axis(
            f[row, col], yscale = scale, title = string(scale),
            yminorticksvisible = i != 6, yminorgridvisible = true,
            xminorticksvisible = i != 6, xminorgridvisible = true,
            yminortickwidth = 3.0, xminortickwidth = 3.0,
            yminorticksize = 8.0, xminorticksize = 8.0,
            yminorgridwidth = 3.0, xminorgridwidth = 3.0,
            yminortickcolor = :red, xminortickcolor = :red,
            yminorgridcolor = :lightgreen, xminorgridcolor = :lightgreen,
            yminorticks = IntervalsBetween(3)
        )

        lines!(data, color = :blue)
    end
    f
end

@reference_test "textlabel" begin
    f = Figure(size = (500, 500))
    ax = Axis(f[1, 1])
    textlabel!(
        ax,
        [1, 2, 3], [1, 1, 1], ["Label $i" for i in 1:3],
        background_color = :white, text_align = (:left, :bottom)
    )
    textlabel!(ax, [("Lbl 1", (1, 0)), ("Lbl 2", (2, 0))])
    p = textlabel!(
        ax, "Wrapped Label", position = Point2f(3, 0),
        background_color = :orange,
        text_rotation = pi / 8,
        word_wrap_width = 8,
        cornerradius = 10,
        cornervertices = 2,
        justification = :center,
        text_align = (:center, :center)
    )
    textlabel!(ax, Point2f(1.5, 0), text = rich("A ", rich("title", color = :red, font = :bold_italic)), fontsize = 20)
    textlabel!(ax, Point2f(2.5, 0), text = L"\sum_a^b{xy} + \mathscr{L}", fontsize = 10)

    textlabel!(
        ax, (1, -1), "Circle",
        shape = Circle(Point2f(0.5), 0.5),
        padding = Vec4f(5),
        keep_aspect = true
    )

    textlabel!(
        ax, 2, -1, text = "~ ~ ~ ~ ~ ~\nStylized Label\n~ ~ ~ ~ ~ ~",
        background_color = RGBf(0.7, 0.8, 1),
        strokecolor = RGBf(0, 0.1, 0.4),
        strokewidth = 3,
        linestyle = :dash,
        joinstyle = :round,
        stroke_alpha = 0.8,
        alpha = 0.5,
        text_color = RGBf(1, 0.2, 0),
        font = "Noto Sans",
        text_strokecolor = RGBf(0.7, 0, 0.1),
        text_strokewidth = 2,
        text_glowcolor = RGBAf(0.8, 1, 0.3),
        text_glowwidth = 2,
        text_align = (:center, :center),
        fontsize = 20,
        justification = :center,
        lineheight = 0.7,
        offset = (0.0, -10.0),
        text_alpha = 0.8,

        shape = Circle(Point2f(0), 1),
        shape_limits = Rect2f(-1, -1, 2, 2),
        padding = Vec4f(10),
    )

    textlabel!(
        ax, (3, -1), "Below",
        cornerradius = 10, fontsize = 20, text_align = (:center, :center),
        draw_on_top = false
    )

    mp = mesh!(ax, Rect2f(0.9, -1, 2.4, 2.2), color = RGBf(0.7, 1, 0.8), shading = NoShading)
    translate!(mp, 0, 0, 10)

    xlims!(ax, 0.8, 3.4)
    ylims!(ax, -1.6, 1.4)

    ax = Axis3(f[2, 1])
    m = load(assetpath("brain.stl"))
    mesh!(ax, m, color = [RGBf(abs.(n)...) for n in normals(m)])
    textlabel!(ax, Point3f(0), text = "Brain", background_color = :white)

    textlabel!(
        ax,
        ["-x -x", "+z\n+z", "-y -y"], position = [(-65, 0, 0), (0, 0, 45), (0, -90, 0)],
        background_color = :lightgray, text_align = (:center, :center),
        draw_on_top = false
    )

    f
end

@reference_test "Tooltip" begin
    fig, ax, p = scatter(Point2f(0, 0))
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
        strokewidth = 2.0f0, strokecolor = :cyan
    )
    # Test depth (this part is expected to fail in CairoMakie)
    p = tooltip!(ax, -5, -4, "test line\ntest line", backgroundcolor = :lightblue)
    translate!(p, 0, 0, 100)
    mesh!(
        ax,
        Point3f.([-7, -7, -3, -3], [-4, -2, -4, -2], [99, 99, 101, 101]), [1 2 3; 2 3 4],
        shading = NoShading, color = :orange
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
    angles = range(0, 2pi, length = n + 1)[1:(end - 1)]
    x = [cos.(angles); 2 .* cos.(angles .+ pi / n)]
    y = [sin.(angles); 2 .* sin.(angles .+ pi / n)]
    z = (x .- 0.5) .^ 2 + (y .- 0.5) .^ 2 .+ 0.5 .* RNG.randn.()

    triangulation_inner = reduce(hcat, map(i -> [0, 1, n] .+ i, 1:n))
    triangulation_outer = reduce(hcat, map(i -> [n - 1, n, 0] .+ i, 1:n))
    triangulation = hcat(triangulation_inner, triangulation_outer)

    f, ax, _ = tricontourf(
        x, y, z, triangulation = triangulation,
        axis = (; aspect = 1, title = "Manual triangulation")
    )
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

    tricontourf(
        f[1, 2], x, y, z, triangulation = Makie.DelaunayTriangulation(),
        axis = (; aspect = 1, title = "Delaunay triangulation")
    )
    scatter!(x, y, color = z, strokewidth = 1, strokecolor = :black)

    f
end

@reference_test "tricontourf with boundary nodes" begin
    n = 20
    angles = range(0, 2pi, length = n + 1)[1:(end - 1)]
    x = [cos.(angles); 2 .* cos.(angles .+ pi / n)]
    y = [sin.(angles); 2 .* sin.(angles .+ pi / n)]
    z = (x .- 0.5) .^ 2 + (y .- 0.5) .^ 2 .+ 0.5 .* RNG.randn.()

    inner = [n:-1:1; n] # clockwise inner
    outer = [(n + 1):(2n); n + 1] # counter-clockwise outer
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
        [(0.0, 25.0), (0.0, 20.0), (0.0, 15.0), (0.0, 10.0), (0.0, 5.0), (0.0, 0.0)],
    ]
    curve_2 = [
        [(4.0, 6.0), (4.0, 14.0), (4.0, 20.0), (18.0, 20.0), (20.0, 20.0)],
        [(20.0, 20.0), (20.0, 16.0), (20.0, 12.0), (20.0, 8.0), (20.0, 4.0)],
        [(20.0, 4.0), (16.0, 4.0), (12.0, 4.0), (8.0, 4.0), (4.0, 4.0), (4.0, 6.0)],
    ]
    curve_3 = [
        [
            (12.906, 10.912), (16.0, 12.0), (16.16, 14.46), (16.29, 17.06),
            (13.13, 16.86), (8.92, 16.4), (8.8, 10.9), (12.906, 10.912),
        ],
    ]
    curves = [curve_1, curve_2, curve_3]
    points = [
        (3.0, 23.0), (9.0, 24.0), (9.2, 22.0), (14.8, 22.8), (16.0, 22.0),
        (23.0, 23.0), (22.6, 19.0), (23.8, 17.8), (22.0, 14.0), (22.0, 11.0),
        (24.0, 6.0), (23.0, 2.0), (19.0, 1.0), (16.0, 3.0), (10.0, 1.0), (11.0, 3.0),
        (6.0, 2.0), (6.2, 3.0), (2.0, 3.0), (2.6, 6.2), (2.0, 8.0), (2.0, 11.0),
        (5.0, 12.0), (2.0, 17.0), (3.0, 19.0), (6.0, 18.0), (6.5, 14.5),
        (13.0, 19.0), (13.0, 12.0), (16.0, 8.0), (9.8, 8.0), (7.5, 6.0),
        (12.0, 13.0), (19.0, 15.0),
    ]
    boundary_nodes, points = convert_boundary_points_to_indices(curves; existing_points = points)
    edges = Set(((1, 19), (19, 12), (46, 4), (45, 12)))

    tri = triangulate(points; boundary_nodes = boundary_nodes, segments = edges, check_arguments = false)
    z = [(x - 1) * (y + 1) for (x, y) in DelaunayTriangulation.each_point(tri)]
    f, ax, _ = tricontourf(tri, z, levels = 30)
    f
end

@reference_test "tricontourf with provided triangulation" begin
    θ = [LinRange(0, 2π * (1 - 1 / 19), 20); 0]
    xy = Vector{Vector{Vector{NTuple{2, Float64}}}}()
    cx = [0.0, 3.0]
    for i in 1:2
        push!(xy, [[(cx[i] + cos(θ), sin(θ)) for θ in θ]])
        push!(xy, [[(cx[i] + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
    end
    boundary_nodes, points = convert_boundary_points_to_indices(xy)
    tri = triangulate(points; boundary_nodes = boundary_nodes, check_arguments = false)
    z = [(x - 3 / 2)^2 + y^2 for (x, y) in DelaunayTriangulation.each_point(tri)]

    f, ax, tr = tricontourf(tri, z, colormap = :matter)
    f
end

@reference_test "tricontourf alpha transparency" begin
    dxy = 1.0
    x = [0.0, dxy, 0.0, -dxy, 0.0, dxy / 2, -dxy / 2, dxy / 2, -dxy / 2]
    y = [0.0, 0.0, dxy, 0.0, -dxy, dxy / 2, dxy / 2, -dxy / 2, -dxy / 2]
    @. f1(x, y) = x^2 + y^2
    z = f1(x, y)

    f = Figure()
    ax1 = Axis(f[1, 1], title = "alpha = 1.0 (default)")
    ax2 = Axis(f[1, 2], title = "alpha = 0.5 (semitransparent)")
    hlines!(ax1, [-0.5, 0.0, 0.5])
    hlines!(ax2, [-0.5, 0.0, 0.5])
    tricontourf!(ax1, x, y, z, levels = 3)
    tricontourf!(ax2, x, y, z, levels = 3, alpha = 0.5)
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
    xs = 10 .^ range(0, 3, length = 101)
    ys = range(1, 4, length = 101)
    zs = [sqrt(x * x + y * y) for x in -50:50, y in -50:50]
    contour!(a, xs, ys, zs, labels = true, labelsize = 20)
    f
end

@reference_test "contour 2d with curvilinear grid" begin
    x = -10:10
    y = -10:10
    # The curvilinear grid:
    xs = [x + 0.01y^3 for x in x, y in y]
    ys = [y + 10cos(x / 40) for x in x, y in y]

    # Now, for simplicity, we calculate the `Z` values to be
    # the radius from the center of the grid (0, 10).
    zs = sqrt.(xs .^ 2 .+ (ys .- 10) .^ 2)

    # We can use Makie's tick finders to get some nice looking contour levels.
    # This could also be Makie.get_tickvalues(Makie.LinearTicks(7), extrema(zs)...)
    # but it's more stable as a test if we hardcode it.
    levels = 0:4:20

    # and now, we plot!
    fig, ax, srf = surface(xs, ys, fill(0.0f0, size(zs)); color = zs, shading = NoShading, axis = (; type = Axis, aspect = DataAspect()))
    ctr = contour!(ax, xs, ys, zs; color = :orange, levels = levels, labels = true, labelfont = :bold, labelsize = 12)

    fig
end

@reference_test "filled contour 2d with curvilinear grid" begin
    x = -10:10
    y = -10:10
    # The curvilinear grid:
    xs = [x + 0.01y^3 for x in x, y in y]
    ys = [y + 10cos(x / 40) for x in x, y in y]

    # Now, for simplicity, we calculate the `Z` values to be
    # the radius from the center of the grid (0, 10).
    zs = sqrt.(xs .^ 2 .+ (ys .- 10) .^ 2)

    # We can use Makie's tick finders to get some nice looking contour levels.
    # This could also be Makie.get_tickvalues(Makie.LinearTicks(7), extrema(zs)...)
    # but it's more stable as a test if we hardcode it.
    levels = 0:4:20

    # and now, we plot!
    fig, ax, ctr = contourf(xs, ys, zs; levels = levels)

    fig
end

@reference_test "contour labels 3D" begin
    fig = Figure()
    Axis3(fig[1, 1])

    xs = ys = range(-0.5, 0.5; length = 50)
    zs = @. √(xs^2 + ys'^2)

    levels = 0.025:0.05:0.475
    contour3d!(-zs; levels = -levels, labels = true, color = :blue)
    contour3d!(+zs; levels = +levels, labels = true, color = :red, labelcolor = :black)
    fig
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
        ax = Axis(f[fldmod1(i - 1, 2)...], title = "bins = $i", aspect = DataAspect())
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
        ax = Axis(f[fldmod1(i - 1, 2)...], title = "bins = (3, $i)", aspect = DataAspect())
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

    x = RNG.randn(100_000)
    y = RNG.randn(100_000)

    for (i, threshold) in enumerate([1, 10, 100, 500])
        ax = Axis(f[fldmod1(i, 2)...], title = "threshold = $threshold", aspect = DataAspect())
        hexbin!(ax, x, y, cellsize = 0.4, threshold = threshold)
    end
    f
end

@reference_test "hexbin scale" begin
    x = RNG.randn(100_000)
    y = RNG.randn(100_000)

    f = Figure()
    hexbin(
        f[1, 1], x, y, bins = 40,
        axis = (aspect = DataAspect(), title = "scale = identity")
    )
    hexbin(
        f[1, 2], x, y, bins = 40, colorscale = log10,
        axis = (aspect = DataAspect(), title = "scale = log10")
    )
    f
end

# Scatter needs working highclip/lowclip first
@reference_test "hexbin colorrange highclip lowclip" begin
    x = RNG.randn(100_000)
    y = RNG.randn(100_000)

    hexbin(
        x, y,
        bins = 40,
        axis = (aspect = DataAspect(),),
        colorrange = (10, 300),
        highclip = :red,
        lowclip = :pink,
        strokewidth = 1,
        strokecolor = :gray30
    )
end

@reference_test "hexbin logscale" begin
    # https://github.com/MakieOrg/Makie.jl/issues/4895
    x = RNG.randn(100_000)
    y = RNG.randn(100_000) .|> exp

    hexbin(x, y; axis = (; yscale = log10))
end

@reference_test "bracket scalar" begin
    f, ax, l = lines(0 .. 9, sin; axis = (; xgridvisible = false, ygridvisible = false))
    ylims!(ax, -1.5, 1.5)

    bracket!(pi / 2, 1, 5pi / 2, 1, offset = 5, text = "Period length", style = :square)

    bracket!(
        pi / 2, 1, pi / 2, -1, text = "Amplitude", orientation = :down,
        linestyle = :dash, rotation = 0, align = (:right, :center), textoffset = 4, linewidth = 2, color = :red, textcolor = :red
    )

    bracket!(
        2.3, sin(2.3), 4.0, sin(4.0),
        text = "Falling", offset = 10, orientation = :up, color = :purple, textcolor = :purple
    )

    bracket!(
        Point(5.5, sin(5.5)), Point(7.0, sin(7.0)),
        text = "Rising", offset = 10, orientation = :down, color = :orange, textcolor = :orange,
        fontsize = 30, textoffset = 30, width = 50
    )
    f
end

@reference_test "bracket vector" begin
    f = Figure()
    ax = Axis(f[1, 1])

    bracket!(
        ax,
        1:5,
        2:6,
        3:7,
        2:6,
        text = ["A", "B", "C", "D", "E"],
        orientation = :down,
    )

    bracket!(
        ax,
        [(Point2f(i, i - 0.7), Point2f(i + 2, i - 0.7)) for i in 1:5],
        text = ["F", "G", "H", "I", "J"],
        color = [:red, :blue, :green, :orange, :brown],
        linestyle = [:dash, :dot, :dash, :dot, :dash],
        orientation = [:up, :down, :up, :down, :up],
        textcolor = [:red, :blue, :green, :orange, :brown],
        fontsize = range(12, 24, length = 5),
    )

    # https://github.com/MakieOrg/Makie.jl/issues/3569
    b = bracket!(
        ax,
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
        axis = (; yscale = log2)
    )
    hist(
        f[1, 2],
        RNG.randn(10^6);
        axis = (; xscale = log2),
        direction = :x
    )
    # make a gap in histogram as edge case
    hist(
        f[2, 1],
        filter!(x -> x < 0 || x > 1.5, RNG.randn(10^6));
        axis = (; yscale = log10)
    )
    hist(
        f[2, 2],
        filter!(x -> x < 0 || x > 1.5, RNG.randn(10^6));
        axis = (; xscale = log10),
        direction = :x
    )
    f
end

@reference_test "Barplot label positions" begin
    f = Figure(size = (450, 450))
    func(fpos; label_position, direction) = barplot(
        fpos, [1, 1, 2], [1, 2, 3];
        stack = [1, 1, 2], bar_labels = ["One", "Two", "Three"], label_position,
        color = [:tomato, :bisque, :slategray2], direction, label_font = :bold
    )
    func(f[1, 1]; label_position = :end, direction = :y)
    ylims!(0, 4)
    func(f[1, 2]; label_position = :end, direction = :x)
    xlims!(0, 4)
    func(f[2, 1]; label_position = :center, direction = :y)
    ylims!(0, 4)
    func(f[2, 2]; label_position = :center, direction = :x)
    xlims!(0, 4)
    f
end

@reference_test "Histogram" begin
    data = sin.(1:1000)

    fig = Figure(size = (900, 900))
    hist(fig[1, 1], data)
    hist(fig[1, 2], data, bins = 30, color = :orange)
    a, p = hist(fig[1, 3], data, bins = 10, color = :transparent, strokecolor = :red, strokewidth = 4.0)
    a.xgridcolor[] = RGBAf(0, 0, 0, 1); a.ygridcolor[] = RGBAf(0, 0, 0, 1)

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
    hist(
        fig[4, 2], data, scale_to = :flip, bins = 10, direction = :x,
        bar_labels = :x, label_size = [14, 10][i12],
        label_color = [:yellow, :blue][i12], label_offset = [-30, 10][i12]
    )
    hist(fig[4, 3], data, weights = 1.0 ./ (2.0 .+ data))

    fig
end

@reference_test "hist(...; gap=0.1)" begin
    fig = Figure(size = (400, 400))
    hist(fig[1, 1], RNG.randn(1000); gap = 0.1)
    fig
end

@reference_test "Stephist" begin
    stephist(RNG.rand(10000))
    current_figure()
end

@reference_test "LaTeXStrings linesegment offsets" begin
    s = Scene(camera = campixel!, size = (600, 600))
    for (i, (offx, offy)) in enumerate(zip([0, 20, 50], [0, 10, 30]))
        for (j, rot) in enumerate([0, pi / 4, pi / 2])
            scatter!(s, 150i, 150j, color = :black)
            text!(
                s, 150i, 150j, text = L"\sqrt{x+y}", offset = (offx, offy),
                rotation = rot, fontsize = 30
            )
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
    nan_color = :cyan
    for i in -1:13
        color = i == 13 ? NaN : i
        lowclip = i == 0 ? Makie.automatic : :bisque
        highclip = i == 11 ? Makie.automatic : :black
        lines!(ax, i .* [8, 8], [10, 590]; color, colormap, colorrange, lowclip, highclip, nan_color, linewidth = 5)
        scatter!(ax, fill(8 * i + 130, 50), range(10, 590, length = 50); color, colormap, colorrange, lowclip, highclip, nan_color)
        poly!(ax, Ref(Point2f(260, i * 50)) .+ Point2f[(0, 0), (50, 0), (25, 40)]; color, colormap, colorrange, lowclip, highclip, nan_color)
        text!(ax, 360, i * 50, text = "$i"; color, colormap, colorrange, lowclip, highclip, nan_color, fontsize = 40)
        poly!(ax, [Ref(Point2f(430 + 20 * j, 20 * j + i * 50)) .+ Point2f[(0, 0), (30, 0), (15, 22)] for j in 1:3]; color, colormap, colorrange, lowclip, highclip, nan_color)
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
    ax, plot_top = heatmap(fig[1, 1], randn(10, 10), colormap = [:transparent])
    # Plot some recipes at the level below the contour
    scatterlineplot_1 = scatterlines!(ax, 1:10, 1:10; linewidth = 20, markersize = 20, color = :red)
    scatterlineplot_2 = scatterlines!(ax, 1:10, 1:10; linewidth = 20, markersize = 30, color = :blue)
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
    poly!(Axis(fig[1, 2]), p, color = :black)
    poly!(Axis(fig[2, 1]), [p, q], color = [:red, :blue])
    poly!(Axis(fig[2, 2]), [p, q], color = :red)
    poly!(Axis(fig[3, 1]), Makie.MultiPolygon([p]), color = :green)
    poly!(Axis(fig[3, 2]), Makie.MultiPolygon([p, q]), color = [:black, :red])
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
    x = range(-π, π; length = 50)
    z = @. sin(x) * cos(x')
    fig, ax = contour(x, x, z, color = RGBAf(1, 0, 0, 0.4), linewidth = 6)
end

@reference_test "Triplot with points, ghost edges, and convex hull" begin
    pts = RNG.rand(2, 50)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    fig, ax, sc = triplot(
        tri,
        triangle_color = :lightgray, strokewidth = 4,
        show_points = true, markersize = 20, markercolor = :orange,
        show_ghost_edges = true, ghost_edge_linewidth = 4,
        show_convex_hull = true, convex_hull_linewidth = 4

    )
    fig
end

@reference_test "Triplot of a constrained triangulation with holes and a custom bounding box" begin
    curve_1 = [
        [
            (0.0, 0.0), (4.0, 0.0), (8.0, 0.0), (12.0, 0.0), (12.0, 4.0),
            (12.0, 8.0), (14.0, 10.0), (16.0, 12.0), (16.0, 16.0),
            (14.0, 18.0), (12.0, 20.0), (12.0, 24.0), (12.0, 28.0),
            (8.0, 28.0), (4.0, 28.0), (0.0, 28.0), (-2.0, 26.0), (0.0, 22.0),
            (0.0, 18.0), (0.0, 10.0), (0.0, 8.0), (0.0, 4.0), (-4.0, 4.0),
            (-4.0, 0.0), (0.0, 0.0),
        ],
    ]
    curve_2 = [
        [
            (4.0, 26.0), (8.0, 26.0), (10.0, 26.0), (10.0, 24.0),
            (10.0, 22.0), (10.0, 20.0), (8.0, 20.0), (6.0, 20.0),
            (4.0, 20.0), (4.0, 22.0), (4.0, 24.0), (4.0, 26.0),
        ],
    ]
    curve_3 = [[(4.0, 16.0), (12.0, 16.0), (12.0, 14.0), (4.0, 14.0), (4.0, 16.0)]]
    curve_4 = [[(4.0, 8.0), (10.0, 8.0), (8.0, 6.0), (6.0, 6.0), (4.0, 8.0)]]
    curves = [curve_1, curve_2, curve_3, curve_4]
    points = [
        (2.0, 26.0), (2.0, 24.0), (6.0, 24.0), (6.0, 22.0), (8.0, 24.0), (8.0, 22.0),
        (2.0, 22.0), (0.0, 26.0), (10.0, 18.0), (8.0, 18.0), (4.0, 18.0), (2.0, 16.0),
        (2.0, 12.0), (6.0, 12.0), (2.0, 8.0), (2.0, 4.0), (4.0, 2.0),
        (-2.0, 2.0), (4.0, 6.0), (10.0, 2.0), (10.0, 6.0), (8.0, 10.0), (4.0, 10.0),
        (10.0, 12.0), (12.0, 12.0), (14.0, 26.0), (16.0, 24.0), (18.0, 28.0),
        (16.0, 20.0), (18.0, 12.0), (16.0, 8.0), (14.0, 4.0), (14.0, -2.0),
        (6.0, -2.0), (2.0, -4.0), (-4.0, -2.0), (-2.0, 8.0), (-2.0, 16.0),
        (-4.0, 22.0), (-4.0, 26.0), (-2.0, 28.0), (6.0, 15.0), (7.0, 15.0),
        (8.0, 15.0), (9.0, 15.0), (10.0, 15.0), (6.2, 7.8),
        (5.6, 7.8), (5.6, 7.6), (5.6, 7.4), (6.2, 7.4), (6.0, 7.6),
        (7.0, 7.8), (7.0, 7.4),
    ]
    boundary_nodes, points = convert_boundary_points_to_indices(curves; existing_points = points)
    tri = triangulate(points; randomise = false, boundary_nodes = boundary_nodes, rng = RNG.STABLE_RNG)
    fig, ax, sc = triplot(
        tri,
        show_points = true,
        show_constrained_edges = true,
        constrained_edge_linewidth = 2,
        strokewidth = 0.2,
        markersize = 15,
        markercolor = :blue,
        show_ghost_edges = true, # not as good because the outer boundary is not convex, but just testing
        marker = 'x',
        bounding_box = (-5, 20, -5, 35)
    ) # also testing the conversion to Float64 for bbox here
    fig
end

@reference_test "Triplot with nonlinear transformation" begin
    f = Figure()
    ax = PolarAxis(f[1, 1])
    points = Point2f[(phi, r) for r in 1:10 for phi in range(0, 2pi, length = 36)[1:35]]
    noise = i -> 1.0f-4 * (isodd(i) ? 1 : -1) * i / sqrt(50) # should have small discrepancy
    points = points .+ [Point2f(noise(i), noise(i)) for i in eachindex(points)]
    # The noise forces the triangulation to be unique. Not using RNG to not disrupt the RNG stream later
    tr = triplot!(ax, points)
    f
end

@reference_test "Triplot after adding points and make sure the representative_point_list is correctly updated" begin
    points = [(0.0, 0.0), (0.95, 0.0), (1.0, 1.4), (0.0, 1.0)] # not 1 so that we have a unique triangulation
    tri = Observable(triangulate(points; delete_ghosts = false))
    fig, ax, sc = triplot(tri, show_points = true, markersize = 14, show_ghost_edges = true, recompute_centers = true, linestyle = :dash)
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
    xy = Vector{Vector{Vector{NTuple{2, Float64}}}}()
    cx = 0.0
    for i in 1:2
        ## Make the exterior circle
        push!(xy, [[(cx + cos(θ), sin(θ)) for θ in θ]])
        ## Now the interior circle - clockwise
        push!(xy, [[(cx + 0.5cos(θ), 0.5sin(θ)) for θ in reverse(θ)]])
        cx += 3.0
    end
    boundary_nodes, points = convert_boundary_points_to_indices(xy)
    tri = triangulate(points; boundary_nodes = boundary_nodes, check_arguments = false)
    fig, ax, sc = triplot(tri, show_ghost_edges = true)
    fig
end

@reference_test "Voronoiplot for a centroidal tessellation with an automatic colormap" begin
    points = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.2, 0.2), (0.25, 0.6), (0.5, 0.3), (0.1, 0.15)]
    tri = triangulate(points; boundary_nodes = [1, 2, 3, 4, 1], rng = RNG.STABLE_RNG)
    vorn = voronoi(tri)
    smooth_vorn = centroidal_smooth(vorn; maxiters = 250, rng = RNG.STABLE_RNG)
    cmap = cgrad(:matter)
    fig, ax, sc = voronoiplot(smooth_vorn, markersize = 10, strokewidth = 4, markercolor = :red)
    fig
end

@reference_test "Voronoiplot for a tessellation with a custom bounding box" begin
    pts = 25RNG.randn(2, 50)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    vorn = voronoi(tri, clip = false)
    fig, ax, sc = voronoiplot(
        vorn,
        show_generators = true,
        colormap = :RdBu,
        strokecolor = :white,
        strokewidth = 4,
        markersize = 25,
        marker = 'x',
        markercolor = :green,
        unbounded_edge_extension_factor = 5.0
    )
    xlims!(ax, -120, 120)
    ylims!(ax, -120, 120)
    fig
end

@reference_test "Voronoiplots with clipped tessellation and unbounded polygons" begin
    pts = 25RNG.randn(2, 10)
    tri = triangulate(pts; rng = RNG.STABLE_RNG)
    vorn = voronoi(tri, clip = true)
    fig, ax, sc = voronoiplot(vorn, color = (:blue, 0.2), markersize = 20, strokewidth = 4)

    # used to be bugged
    points = [(0.0, 1.0), (-1.0, 2.0), (-2.0, -1.0)]
    tri = triangulate(points)
    vorn = voronoi(tri)
    voronoiplot(
        fig[1, 2], vorn, show_generators = true, strokewidth = 4,
        color = [:red, :blue, :green], markercolor = :white, markersize = 20
    )

    fig
end

@reference_test "Voronoiplot with a nonlinear transform" begin
    f = Figure()
    ax = PolarAxis(f[1, 1], theta_as_x = false)
    points = Point2d[(r, phi) for r in 1:10 for phi in range(0, 2pi, length = 36)[1:35]]
    noise = i -> 1.0f-4 * (isodd(i) ? 1 : -1) * i / sqrt(50) # should have small discrepancy
    points = points .+ [Point2f(noise(i), noise(i)) for i in eachindex(points)] # make triangulation unique
    polygon_color = [r for r in 1:10 for phi in range(0, 2pi, length = 36)[1:35]]
    polygon_color_2 = [phi for r in 1:10 for phi in range(0, 2pi, length = 36)[1:35]]
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
    voronoiplot!(ax1, vorn, show_generators = true, markersize = 14, strokewidth = 4, color = color)
    ax2 = Axis(fig[1, 2], title = "Some excluded")
    voronoiplot!(ax2, vorn, show_generators = true, markersize = 14, strokewidth = 4, color = color, clip = BBox(0.0, 5.0, -15.0, 15.0))
    ax3 = Axis(fig[2, 1], title = "Bigger range")
    voronoiplot!(ax3, vorn, show_generators = true, markersize = 14, strokewidth = 4, color = color, clip = (-15.0, 15.0, -15.0, 15.0))
    ax4 = Axis(fig[2, 2], title = "Only one polygon")
    voronoiplot!(ax4, vorn, show_generators = true, markersize = 14, strokewidth = 4, color = color, clip = (10.0, 12.0, 2.0, 5.0))
    for ax in fig.content
        xlims!(ax4, -15, 15)
        ylims!(ax4, -15, 15)
    end
    fig
end

@reference_test "Voronoiplot after adding points" begin
    points = Observable([(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)])
    fig, ax, sc = voronoiplot(points, show_generators = true, markersize = 36) # make sure any regressions with missing generators are identified, so use 36
    push!(points[], (2.0, 2.0), (0.5, 0.5), (0.25, 0.25), (0.25, 0.75), (0.75, 0.25), (0.75, 0.75))
    notify(points)
    ax2 = Axis(fig[1, 2])
    voronoiplot!(ax2, voronoi(triangulate(points[])), show_generators = true, markersize = 36)
    xlims!(ax, -0.5, 2.5)
    ylims!(ax, -0.5, 2.5)
    xlims!(ax2, -0.5, 2.5)
    ylims!(ax2, -0.5, 2.5) # need to make sure all generators are shown, and the bounding box is automatically updated
    fig
end

@reference_test "Voronoiplot with empty polygons and automatic color generation" begin
    points = [
        0.153071 0.210363 0.447987 0.765468 -0.681145 1.88393 -1.05474 -0.52126 1.102 0.675978 1.75767 1.19744;
        -0.16884 -0.492721 -1.30937 0.573229 -2.39049 -0.249817 -1.15057 -0.480175 0.226354 1.18442 1.66382 -1.23949
    ]
    tri = triangulate(points)
    xmin, xmax, ymin, ymax = -1 / 2, 1 / 2, -1.0, 1.0
    clip_points = ((xmin, ymin), (xmax, ymin), (xmax, ymax), (xmin, ymax))
    clip_vertices = (1, 2, 3, 4, 1)
    clip_polygon = (clip_points, clip_vertices)
    clipped_vorn = voronoi(tri, clip = true, clip_polygon = clip_polygon)
    voronoiplot(clipped_vorn)
end

function ppu_test_plot(resolution, px_per_unit, scalefactor)
    fig, ax, pl = scatter(1:4, markersize = 100, color = 1:4, figure = (; size = resolution), axis = (; titlesize = 50, title = "ppu: $px_per_unit, sf: $scalefactor"))
    DataInspector(ax)
    hidedecorations!(ax)
    return fig
end

@reference_test "px_per_unit and scalefactor" begin
    resolution = (800, 800)
    let st = nothing
        @testset begin
            matr = [(px, scale) for px in [0.5, 1, 2], scale in [0.5, 1, 2]]
            imgs = map(matr) do (px_per_unit, scalefactor)
                img = colorbuffer(ppu_test_plot(resolution, px_per_unit, scalefactor); px_per_unit = px_per_unit, scalefactor = scalefactor)
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
    fig = Figure(size = (227, 170))
    ax = Axis(fig[1, 1]; yticks = 0:0.2:1, yminorticksvisible = true)
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
    ax, p = violin(fig[1, 1], xs, ys; scale = :area, show_median = true)
    Makie.xlims!(0.2, 4.8); ax.title = "scale=:area"
    ax, p = violin(fig[2, 1], xs, ys; scale = :count, mediancolor = :red, medianlinewidth = 5)
    Makie.xlims!(0.2, 4.8); ax.title = "scale=:count"
    ax, p = violin(fig[3, 1], xs, ys; scale = :width, show_median = true, mediancolor = :orange, medianlinewidth = 5)
    Makie.xlims!(0.2, 4.8); ax.title = "scale=:width"
    fig
end

@reference_test "Violin" begin
    fig = Figure()

    categories = vcat(fill(1, 300), fill(2, 300), fill(3, 300))
    values = vcat(RNG.randn(300), (1.5 .* RNG.rand(300)) .^ 2, -(1.5 .* RNG.rand(300)) .^ 2)
    violin(fig[1, 1], categories, values)

    dodge = RNG.rand(1:2, 900)
    violin(
        fig[1, 2], categories, values, dodge = dodge,
        color = map(d -> d == 1 ? :yellow : :orange, dodge),
        strokewidth = 2, strokecolor = :black, gap = 0.1, dodge_gap = 0.5
    )

    violin(
        fig[2, 1], categories, values, orientation = :horizontal,
        color = :gray, side = :left
    )

    violin!(
        categories, values, orientation = :horizontal,
        color = :yellow, side = :right, strokewidth = 2, strokecolor = :black,
        weights = abs.(values)
    )

    # TODO: test bandwidth, boundary

    fig
end

@reference_test "Clip planes - CairoMakie overrides" begin
    f = Figure()
    a = Axis(f[1, 1])
    a.scene.theme[:clip_planes][] = [Plane3f(Vec3f(1, 0, 0), 0)]
    xlims!(a, -3.5, 3.5)
    ylims!(a, -3.5, 3.5)

    poly!(a, Rect2f(Point2f(-3.0, 1.8), Vec2f(6, 1)), strokewidth = 2)
    poly!(a, Point2f[(-3, 1.5), (3, 1.5), (3, 0.5), (-3, 0.5), (-3, 1.5)], strokewidth = 2)
    xs = range(-3.0, 3.0, length = 101)
    b = band!(a, xs, -0.4 .* sin.(3 .* xs) .- 2.5, 0.4 .* sin.(3 .* xs) .- 1.0)

    x = RNG.randn(50)
    y = RNG.randn(50)
    z = -sqrt.(x .^ 2 .+ y .^ 2) .+ 0.1 .* RNG.randn()
    p = tricontourf!(a, x, y, z)
    translate!(p, 0, 0, 1)

    f
end

@reference_test "Spy" begin
    f = Figure()
    data = RNG.rand(10, 10)
    spy(f[1, 1], (0, 1), (0, 1), data)
    # if all colorvalues are 1, colorrange will be (0.5, 1.5), mapping everything to blue
    # TODO, maybe not ideal for spy?
    sdata = sparse(data .> 0.5)
    spy(f[1, 2], sdata; colormap = [:black, :blue, :white])
    spy(f[2, 1], sdata; color = :black, alpha = 0.7)
    data[1, 1] = NaN
    spy(f[2, 2], data; highclip = :red, lowclip = (:grey, 0.5), nan_color = :black, colorrange = (0.3, 0.7))
    f
end

@reference_test "Datashader AggCount" begin
    data = [RNG.randn(Point2f, 10_000); (Ref(Point2f(1, 1)) .+ 0.3f0 .* RNG.randn(Point2f, 10_000))]
    f = Figure()
    ax = Axis(f[1, 1])
    datashader!(ax, data; async = false)
    ax2 = Axis(f[1, 2])
    datashader!(ax2, data; async = false, binsize = 3)
    ax3 = Axis(f[2, 1])
    datashader!(ax3, data; async = false, operation = xs -> log10.(xs .+ 1))
    ax4 = Axis(f[2, 2])
    datashader!(ax4, data; async = false, point_transform = -)
    f
end

@reference_test "Datashader AggMean" begin
    with_z(p2) = Point3f(p2..., cos(p2[1]) * sin(p2[2]))
    data2d = RNG.randn(Point2f, 100_000)
    data3d = map(with_z, data2d)
    f = Figure()
    ax = Axis(f[1, 1])
    datashader!(ax, data3d; agg = Makie.AggMean(), operation = identity, async = false)
    ax2 = Axis(f[1, 2])
    datashader!(ax2, data3d; agg = Makie.AggMean(), operation = identity, async = false, binsize = 3)
    f
end

@reference_test "Heatmap Shader" begin
    data = Makie.peaks(10_000)
    data2 = map(data) do x
        Float32(round(x))
    end
    f = Figure()
    ax1, pl1 = heatmap(f[1, 1], Resampler(data))
    ax2, pl2 = heatmap(f[1, 2], Resampler(data))
    limits!(ax2, 2800, 4800, 2800, 5000)
    ax3, pl3 = heatmap(f[2, 1], Resampler(data2))
    ax4, pl4 = heatmap(f[2, 2], Resampler(data2))
    limits!(ax4, 3000, 3090, 3460, 3500)
    heatmap(f[3, 1], (1000, 2000), (500, 1000), Resampler(data2))
    ax = Axis(f[3, 2])
    limits!(ax, (0, 1), (0, 1))
    heatmap!(ax, (1, 2), (1, 2), Resampler(data2))
    Colorbar(f[:, 3], pl1)
    sleep(1) # give the async operations some time
    f
end

@reference_test "boxplot" begin
    fig = Figure()

    categories = vcat(fill(1, 300), fill(2, 300), fill(3, 300))
    values = RNG.randn(900) .+ range(-1, 1, length = 900)
    boxplot(fig[1, 1], categories, values)

    dodge = RNG.rand(1:2, 900)
    boxplot(
        fig[1, 2], categories, values, dodge = dodge, show_notch = true,
        color = map(d -> d == 1 ? :blue : :red, dodge),
        outliercolor = RNG.rand([:red, :green, :blue, :black, :orange], 900)
    )

    ax_vert = Axis(
        fig[2, 1];
        xlabel = "categories",
        ylabel = "values",
        xticks = (1:3, ["one", "two", "three"])
    )
    ax_horiz = Axis(
        fig[2, 2];
        xlabel = "values",
        ylabel = "categories",
        yticks = (1:3, ["one", "two", "three"])
    )

    weights = 1.0 ./ (1.0 .+ abs.(values))
    boxplot!(
        ax_vert, categories, values, orientation = :vertical, weights = weights,
        gap = 0.5,
        show_notch = true, notchwidth = 0.75,
        markersize = 5, strokewidth = 2.0, strokecolor = :black,
        medianlinewidth = 5, mediancolor = :orange,
        whiskerwidth = 1.0, whiskerlinewidth = 3, whiskercolor = :green,
        outlierstrokewidth = 1.0, outlierstrokecolor = :red,
        width = 1.5,
    )
    boxplot!(ax_horiz, categories, values; orientation = :horizontal, width = categories ./ 3)

    fig
end

@reference_test "crossbar" begin
    fig = Figure()

    xs = [1, 1, 2, 2, 3, 3]
    ys = RNG.rand(6)
    ymins = ys .- 1
    ymaxs = ys .+ 1
    dodge = [1, 2, 1, 2, 1, 2]

    crossbar(fig[1, 1], xs, ys, ymins, ymaxs, dodge = dodge, show_notch = true)

    crossbar(
        fig[1, 2], xs, ys, ymins, ymaxs,
        dodge = dodge, dodge_gap = 0.25,
        gap = 0.05,
        midlinecolor = :blue, midlinewidth = 5,
        show_notch = true, notchwidth = 0.3,
        notchmin = ys .- (0.05:0.05:0.3), notchmax = ys .+ (0.3:-0.05:0.05),
        strokewidth = 2, strokecolor = :black,
        orientation = :horizontal, color = (:gray, 0.5)
    )
    fig
end

@reference_test "ecdfplot" begin
    f = Figure(size = (500, 250))

    x = RNG.randn(200)
    ecdfplot(f[1, 1], x, color = (:blue, 0.3))
    ecdfplot!(x, color = :red, npoints = 10, step = :pre, linewidth = 3)
    ecdfplot!(x, color = :orange, npoints = 10, step = :center, linewidth = 3)
    ecdfplot!(x, color = :green, npoints = 10, step = :post, linewidth = 3)

    w = @. x^2 * (1 - x)^2
    ecdfplot(f[1, 2], x)
    ecdfplot!(x; weights = w, color = :orange)

    f
end

@reference_test "qqnorm" begin
    fig = Figure()
    xs = 2 .* RNG.randn(10) .+ 3
    qqnorm(fig[1, 1], xs, qqline = :fitrobust, strokecolor = :cyan, strokewidth = 2)
    qqnorm(fig[1, 2], xs, qqline = :none, markersize = 15, marker = Rect, markercolor = :red)
    qqnorm(fig[2, 1], xs, qqline = :fit, linestyle = :dash, linewidth = 6)
    qqnorm(fig[2, 2], xs, qqline = :identity, color = :orange)
    fig
end

@reference_test "qqplot" begin
    fig = Figure()
    xs = 2 .* RNG.randn(10) .+ 3; ys = RNG.randn(10)
    qqplot(fig[1, 1], xs, ys, qqline = :fitrobust, strokecolor = :cyan, strokewidth = 2)
    qqplot(fig[1, 2], xs, ys, qqline = :none, markersize = 15, marker = Rect, markercolor = :red)
    qqplot(fig[2, 1], xs, ys, qqline = :fit, linestyle = :dash, linewidth = 6)
    qqplot(fig[2, 2], xs, ys, qqline = :identity, color = :orange)
    fig
end

@reference_test "rainclouds" begin
    Makie.RAINCLOUD_RNG[] = RNG.STABLE_RNG
    data = RNG.randn(1000)
    data[1:200] .+= 3
    data[201:500] .-= 3
    data[501:end] .= 3 .* abs.(data[501:end]) .- 3
    labels = vcat(fill("red", 500), fill("green", 500))

    fig = Figure()
    rainclouds(
        fig[1, 1], labels, data, plot_boxplots = false, cloud_width = 2.0,
        markersize = 5.0
    )
    rainclouds(fig[1, 2], labels, data, color = labels, orientation = :horizontal, cloud_width = 2.0)
    rainclouds(
        fig[2, 1], labels, data, clouds = hist, hist_bins = 30, boxplot_nudge = 0.1,
        center_boxplot = false, boxplot_width = 0.2, whiskerwidth = 1.0, strokewidth = 3.0
    )
    rainclouds(fig[2, 2], labels, data, color = labels, side = :right, violin_limits = extrema)
    fig
end

@reference_test "series" begin
    fig = Figure()
    data = cumsum(RNG.randn(4, 21), dims = 2)

    ax, sp = series(
        fig[1, 1], data, labels = ["label $i" for i in 1:4],
        linewidth = 4, linestyle = :dot, markersize = 15, solid_color = :black
    )
    axislegend(ax, position = :lt)

    ax, sp = series(
        fig[2, 1], data, labels = ["label $i" for i in 1:4], markersize = 10.0,
        marker = Circle, markercolor = :transparent, strokewidth = 2.0, strokecolor = :black
    )
    axislegend(ax, position = :lt)

    fig
end

@reference_test "stairs" begin
    f = Figure()

    xs = LinRange(0, 4pi, 21)
    ys = sin.(xs)

    stairs(f[1, 1], xs, ys)
    stairs(f[2, 1], xs, ys; step = :post, color = :blue, linestyle = :dash)
    stairs(f[3, 1], xs, ys; step = :center, color = :red, linestyle = :dot)

    f
end

@reference_test "stem" begin
    f = Figure()

    xs = LinRange(0, 4pi, 30)
    stem(f[1, 1], xs, sin.(xs))

    stem(
        f[1, 2], xs, sin,
        offset = 0.5, trunkcolor = :blue, marker = :rect,
        stemcolor = :red, color = :orange,
        markersize = 15, strokecolor = :red, strokewidth = 3,
        trunklinestyle = :dash, stemlinestyle = :dashdot
    )

    stem(
        f[2, 1], xs, sin.(xs),
        offset = LinRange(-0.5, 0.5, 30),
        color = LinRange(0, 1, 30), colorrange = (0, 0.5),
        trunkcolor = LinRange(0, 1, 30), trunkwidth = 5
    )

    ax, p = stem(
        f[2, 2], 0.5xs, 2 .* sin.(xs), 2 .* cos.(xs),
        offset = Point3f.(0.5xs, sin.(xs), cos.(xs)),
        stemcolor = LinRange(0, 1, 30), stemcolormap = :Spectral, stemcolorrange = (0, 0.5)
    )

    center!(ax.scene)
    zoom!(ax.scene, 0.8)
    ax.scene.camera_controls.settings[:center] = false

    f
end

@reference_test "waterfall" begin
    y = [6, 4, 2, -8, 3, 5, 1, -2, -3, 7]

    fig = Figure()
    waterfall(fig[1, 1], y)
    waterfall(
        fig[1, 2], y, show_direction = true, marker_pos = :cross,
        marker_neg = :hline, direction_color = :yellow
    )

    colors = Makie.wong_colors()
    x = repeat(1:2, inner = 5)
    group = repeat(1:5, outer = 2)

    waterfall(
        fig[2, 1], x, y, dodge = group, color = colors[group],
        show_direction = true, show_final = true, final_color = (colors[6], 1 // 3),
        dodge_gap = 0.1, gap = 0.05
    )

    x = repeat(1:5, outer = 2)
    group = repeat(1:2, inner = 5)

    waterfall(
        fig[2, 2], x, y, dodge = group, color = colors[group],
        show_direction = true, stack = :x, show_final = true
    )

    fig
end

@reference_test "ablines + hvlines + hvspan" begin
    f = Figure()

    ax = Axis(f[1, 1])
    hspan!(ax, -1, -0.9, color = :lightblue, alpha = 0.5, strokewidth = 2, strokecolor = :black)
    hspan!(ax, 0.9, 1, xmin = 0.2, xmax = 0.8)
    vspan!(ax, -1, -0.9)
    vspan!(ax, 0.9, 1, ymin = 0.2, ymax = 0.8, strokecolor = RGBf(0, 1, 0.1), strokewidth = 3)

    ablines!([0.3, 0.7], [-0.2, 0.2], color = :orange, linewidth = 4, linestyle = :dash)

    hlines!(ax, -0.8)
    hlines!(ax, 0.8, xmin = 0.2, xmax = 0.8)
    vlines!(ax, -0.8, color = :green, linewidth = 3)
    vlines!(ax, 0.8, ymin = 0.2, ymax = 0.8, color = :red, linewidth = 3, linestyle = :dot)

    f
end

@reference_test "hvlines + hvspan with transform_func" begin
    f = Figure()

    ax = Axis(f[1, 1], xscale = log10, yscale = log10)
    hspan!(ax, 0.1, 0.12, color = :lightblue, alpha = 0.5, strokewidth = 2, strokecolor = :black)
    hspan!(ax, 0.9, 1, xmin = 0.2, xmax = 0.8)
    vspan!(ax, 0.1, 0.12)
    vspan!(ax, 0.9, 1, ymin = 0.2, ymax = 0.8, strokecolor = RGBf(0, 1, 0.1), strokewidth = 3)

    hlines!(ax, 0.2, linewidth = 5)
    hlines!(ax, 0.8, xmin = 0.2, xmax = 0.8, linewidth = 5)
    vlines!(ax, 0.2, color = :green, linewidth = 3)
    vlines!(ax, 0.8, ymin = 0.2, ymax = 0.8, color = :red, linewidth = 3, linestyle = :dot)

    f
end

@reference_test "Color Patterns" begin
    f = Figure()
    a = Axis(f[1, 1], aspect = DataAspect()) #autolimitaspect = 1)

    pattern = Makie.Pattern('x', width = 0.7, linecolor = (:red, 0.5), backgroundcolor = (:blue, 0.5))
    mesh!(a, Circle(Point2f(0, 3), 1.0f0), color = pattern, shading = NoShading)

    r = range(0, 2pi, length = 21)[1:(end - 1)]
    img = [RGBf(0.5 + 0.5 * sin(x), 0.2, 0.5 + 0.5 * cos(y)) for x in r, y in r]
    mesh!(a, Circle(Point2f(3, 3), 1.0f0), color = Makie.Pattern(img), shading = NoShading)

    surface!(a, -1 .. 1, -1 .. 1, zeros(4, 4), color = Makie.Pattern('/'), shading = NoShading)
    meshscatter!(
        a, [Point2f(x, y) for x in 2:4 for y in -1:1], markersize = 0.5,
        color = Makie.Pattern('+', tilesize = (8, 8)), shading = NoShading
    )
    f

    st = Stepper(f)
    Makie.step!(st)
    translate!(a.scene, 0.1, 0.05) # test that pattern are anchored to the plot
    Makie.step!(st)
    st
end

# Since the above is rather symmetric...
@reference_test "Color Pattern orientation" begin
    img = fill(RGBf(1, 1, 1), 16, 16)
    img[1:8, 1:8] .= RGBf(1, 0, 0)
    img[12:16, 1:8] .= RGBf(0, 1, 0)
    img[1:8, 12:16] .= RGBf(0, 0, 1)
    f, a, p = mesh(Rect2f(0, 0, 1, 1), color = Makie.ImagePattern(img), shading = false)
    surface(f[1, 2], -1 .. 1, -1 .. 1, zeros(4, 4), color = Makie.ImagePattern(img), shading = false)
    meshscatter(f[2, 1:2], [1, 2, 3], [1, 1, 1], marker = Rect2f(0, 0, 1, 1), markersize = 0.5, color = Makie.ImagePattern(img), shading = false)
    f
end

@reference_test "Color patterns in recipes" begin
    pattern = Makie.Pattern('x', linecolor = :darkgreen, backgroundcolor = RGBf(0.7, 0.8, 0.5))

    f = Figure(size = (500, 400))
    a = Axis(f[1, 1])
    xlims!(-0.25, 6.6)

    vs = [1, 2, 2, 3, 3, 3]
    hist!(a, 0.5 .* vs, color = pattern, bins = 3, gap = 0.2, direction = :x)
    density!(a, vs, color = pattern)
    poly!(a, [0, 0, 1, 1], [2, 3, 3, 2], color = pattern)
    band!(a, [2, 3, 4], [2.5, 3, 2], [3.5, 3.5, 3], color = pattern)
    barplot!(a, [5, 6], [3, 2], color = pattern)
    pie!(a, 4, 1, vs, radius = 0.5, color = pattern) # TODO: per element
    hspan!(a, 4, 4.5, color = pattern)

    st = Stepper(f)
    Makie.step!(st)
    translate!(a.scene, 0.1, 0.05) # test that pattern are anchored to the plot
    Makie.step!(st)
    st
end

@reference_test "Transformed 2D Arrows" begin
    ps = [Point2f(i, 2^i) for i in 1:10]
    vs = [Vec2f(1, 100) for _ in 1:10]
    f, a, p = arrows2d(ps, vs, color = log10.(norm.(ps)), colormap = :RdBu)
    arrows2d(f[1, 2], ps, vs, color = log10.(norm.(ps)), axis = (yscale = log10,))

    ps = coordinates(Rect2f(-1, -1, 2, 2))
    a, p = arrows2d(f[2, 1], ps, ps)
    scatter!(a, 0, 0, markersize = 50, marker = '+')
    translate!(p, 1, 1, 0)

    a, p = arrows2d(f[2, 2], ps, ps)
    scatter!(a, 0, 0, markersize = 50, marker = '+')
    scale!(p, 1.0 / sqrt(2), 1.0 / sqrt(2), 1)
    Makie.rotate!(p, pi / 4)

    f
end

@reference_test "arrow min- and maxshaftlength scaling" begin
    # widths should not scale while the tip ends in the gray area (between min
    # and maxshaftlength)
    scene = Scene(camera = campixel!, size = (500, 500))
    min = 30; max = 60
    linesegments!(scene, [-10, 510], [0.5(min + max), 0.5(min + max)] .+ 40, color = :lightgray, linewidth = max - min)
    heights = [10, min - 10, min, min + 10, max - 10, max, max + 10, 180] .+ 40
    p = arrows2d!(
        scene,
        50:50:400, zeros(8),
        zeros(8), heights,
        minshaftlength = min, maxshaftlength = max,
        shaftwidth = 20, tipwidth = 40, tiplength = 40,
        strokemask = 0
    )
    scatter!(scene, 50:50:400, fill(20, 8), marker = Rect, markersize = 20, color = :red)

    component_widths = widths.(Rect3f.(p.plots[1].args[][1]))
    for i in 1:8
        scale = heights[i] / (clamp(heights[i] - p.tiplength[], min, max) + p.tiplength[])
        @test component_widths[2i - 1][1] ≈ p.shaftwidth[] * scale # shaft
        @test component_widths[2i][1] ≈ p.tipwidth[] * scale   # tip
    end

    linesegments!(scene, [-10, 510], [0.5(min + max), 0.5(min + max)] .+ 290, color = :lightgray, linewidth = max - min)
    p = arrows3d!(
        scene,
        50:50:400, fill(250, 8),
        zeros(8), heights,
        minshaftlength = min, maxshaftlength = max,
        shaftradius = 10, tipradius = 20, tiplength = 40,
        markerscale = 1.0
    )
    sp = scatter!(scene, 50:50:400, fill(270, 8), marker = Rect, markersize = 20, color = :red)
    translate!(sp, 0, 0, 100)

    for i in 1:8
        scale = heights[i] / (clamp(heights[i] - p.tiplength[], min, max) + p.tiplength[])
        @test p.plots[2].markersize[][i][1] ≈ 2 * p.shaftradius[] * scale # shaft
        @test p.plots[3].markersize[][i][1] ≈ 2 * p.tipradius[] * scale   # tip
    end

    scene
end

function arrow_align_test(plotfunc, tail, taillength)
    function draw_row!(ax, y; kwargs...)
        plotfunc(ax, (1, y), (0, 1), align = -0.5; kwargs...)
        plotfunc(ax, (2, y), (0, 1), align = :tail; kwargs...)
        plotfunc(ax, (3, y), (0, 1), align = :center; kwargs...)
        plotfunc(ax, (4, y), (0, 1), align = :tip; kwargs...)
        return plotfunc(ax, (5, y), (0, 1), align = 1.5; kwargs...)
    end

    fig = Figure()
    ax = Axis(fig[1, 1])

    hlines!(ax, [1, 3, 5])

    draw_row!(ax, 1)
    draw_row!(ax, 3; lengthscale = 0.5, color = RGBf(0.8, 0.2, 0.1), alpha = 0.3)
    draw_row!(
        ax, 5; tail = tail, taillength = taillength,
        tailcolor = :orange, shaftcolor = RGBAf(0.1, 0.9, 0.2, 0.5), tipcolor = :red
    )

    plotfunc(ax, (1, 7), (1, 8), argmode = :endpoints, lengthscale = 0.5, align = -0.5)
    plotfunc(ax, (2, 7), (2, 8), argmode = :endpoints, lengthscale = 0.5, align = :tail)
    plotfunc(ax, (3, 7), (3, 8), argmode = :endpoints, lengthscale = 0.5, align = :center)
    plotfunc(ax, (4, 7), (4, 8), argmode = :endpoints, lengthscale = 0.5, align = :tip)
    plotfunc(ax, (5, 7), (5, 8), argmode = :endpoints, lengthscale = 0.5, align = 1.5)
    hlines!(ax, [7, 8], color = :red)

    return fig
end

@reference_test "arrows2d alignment" begin
    arrow_align_test(arrows2d!, Point2f[(0, 0), (1, -0.5), (1, 0.5)], 8)
end

@reference_test "arrows3d alignment" begin
    arrow_align_test(arrows3d!, Makie.Cone(Point3f(0, 0, 1), Point3f(0, 0, 0), 0.5f0), 0.4)
end

@reference_test "arrows2d updates" begin
    grad_func(p) = 0.2 * p .- 0.01 * p .^ 3
    ps = [Point2f(x, y) for x in -5:5, y in -5:5]
    f, a, p = arrows2d(ps, grad_func)

    st = Makie.Stepper(f)
    Makie.step!(st)

    p.color[] = :orange
    p[1] = vec(ps .+ Point2f(0.2))
    p.lengthscale[] = 1.5
    p.tiplength = 4
    p.tipwidth = 8
    p.shaftwidth = 1
    p.taillength = 8
    p.tailwidth = 6
    Makie.step!(st)

    p.arg2[] = p -> 0.01 * p .^ 3 - 0.2 * p + 0.00001 * p .^ 5
    p.align = :center
    p.shaftcolor = :blue
    p.tail = Rect2f(0, -0.5, 1, 1)
    p.tailwidth = 8
    Makie.step!(st)
    st
end

# Adjusted from 2d version
@reference_test "arrows3d updates" begin
    grad_func(p) = 0.2 * p .- 0.01 * p .^ 3
    ps = [Point2f(x, y) for x in -5:5, y in -5:5]
    f, a, p = arrows3d(ps, grad_func)

    st = Makie.Stepper(f)
    Makie.step!(st)

    p.color[] = :orange
    p[1] = vec(ps .+ Point2f(0.2))
    p.lengthscale[] = 1.5
    p.tiplength = 0.2
    p.tipradius = 0.08
    p.shaftradius = 0.1
    p.tail = Rect3f(-0.5, -0.5, 0, 1, 1, 1)
    p.taillength = 0.2
    p.tailradius = 0.2
    Makie.step!(st)

    p.arg2[] = p -> 0.01 * p .^ 3 - 0.2 * p + 0.00001 * p .^ 5
    p.align = :center
    p.shaftcolor = :blue
    Makie.step!(st)
    st
end

@reference_test "Dendrogram" begin
    leaves = Point2f[(1, 0), (2, 0.5), (3, 1), (4, 2), (5, 0)]
    merges = [(1, 2), (6, 3), (4, 5), (7, 8)]

    f = Figure(size = (400, 700))
    a = Axis(f[1, 1], aspect = DataAspect())
    # TODO: vary more attributes to confirm that they work
    #       (i.e. Lines attributes, colors w/o grouping, branch_style)
    dendrogram!(leaves, merges; origin = Point2f(0, -2), rotation = :down, ungrouped_color = :gray, groups = [1, 1, 2, 3, 3], colormap = [:blue, :orange, :purple])
    dendrogram!(leaves, merges; origin = Point2f(2, 0), rotation = :right, ungrouped_color = :red, groups = [1, 1, 2, 3, 3])
    dendrogram!(leaves, merges; origin = Point2f(0, 2), rotation = :up, color = :blue, branch_shape = :tree, linestyle = :dot, linewidth = 3)
    p = dendrogram!(leaves, merges; origin = Point2f(-2, 0), rotation = :left, color = :black, width = 8, depth = 5)
    textlabel!(map(ps -> ps[1:5], Makie.dendrogram_node_positions(p)), text = ["A", "A", "B", "C", "C"])
    dendrogram!(leaves, merges; origin = Point2f(4, 4), rotation = 3pi / 4, ungrouped_color = :orange, groups = [1, 1, 2, 3, 3], colormap = [:blue, :orange, :purple])

    a = PolarAxis(f[2, 1])
    rlims!(a, 0, 6)
    p = dendrogram!(a, leaves, merges; origin = (0, 1), rotation = 3pi / 4, groups = [1, 1, 2, 3, 3], linewidth = 10, joinstyle = :round, linecap = :round)
    scatter!(a, Makie.dendrogram_node_positions(p), markersize = 20)
    f
end

@reference_test "annotation pointcloud" begin
    f = Figure(size = (700, 350))

    points = [(-2.15, -0.19), (-1.66, 0.78), (-1.56, 0.87), (-0.97, -1.91), (-0.96, -0.25), (-0.79, 2.6), (-0.74, 1.68), (-0.56, -0.44), (-0.36, -0.63), (-0.32, 0.67), (-0.15, -1.11), (-0.07, 1.23), (0.3, 0.73), (0.72, -1.48), (0.8, 1.12)]

    fruit = [
        "Apple", "Banana", "Cherry", "Date", "Elderberry", "Fig", "Grape", "Honeydew",
        "Indian Fig", "Jackfruit", "Kiwi", "Lychee", "Mango", "Nectarine", "Orange",
    ]

    ax = Axis(f[1, 1])

    scatter!(ax, points)
    annotation!(ax, points, text = fruit)

    hidedecorations!(ax)

    points2 = [10 .^ p for p in points]
    ax2 = Axis(f[1, 2], yscale = log10, xscale = log10)

    scatter!(ax2, points2)
    annotation!(ax2, points2, text = fruit)

    hidedecorations!(ax2)

    f
end

@reference_test "annotation manual" begin
    f, ax, _ = lines(0 .. 10, sin, figure = (; size = (600, 450)))

    annotation!(
        ax, 0, -100, pi / 2, 1.0,
        text = "Peak", style = Ann.Styles.LineArrow(), color = :red,
        textcolor = :orange, align = (:right, :top)
    )
    annotation!(
        ax, 0, 100, 3pi / 2, -1.0,
        text = "Trough", style = Ann.Styles.LineArrow(), font = :bold,
        fontsize = 24,
    )
    annotation!(
        ax, -100, 0, 5pi / 2, 1.0,
        text = "Second\nPeak",
        style = Ann.Styles.LineArrow(
            head = Ann.Arrows.Head(),
            tail = Ann.Arrows.Head(length = 20, color = :cyan, notch = 0.3)
        ),
        path = Ann.Paths.Arc(-0.3), justification = :right,
    )
    annotation!(
        ax, 7, -0.5, 3pi / 2, -1.0,
        text = "Corner", path = Ann.Paths.Corner(), labelspace = :data,
        linewidth = 3, shrink = (0, 30)
    )

    f
end

@reference_test "Transformed rotations" begin
    f = Figure(size = (600, 700))
    a = PolarAxis(f[1, 1])
    p = streamplot!(a, p -> Point2f(1, 0), 0 .. 2pi, 0 .. 5, gridsize = (10, 10))
    a = PolarAxis(f[2, 1])
    p = contour!(
        a, 0 .. 2pi, 0 .. 5, [sqrt(x^2 + y^2) for x in range(-1, 1, 30), y in range(-1, 1, 30)],
        labels = true, colormap = :magma, linewidth = 3
    )

    a = LScene(f[1, 2])
    p = streamplot!(
        a, p -> Point3f(p[2], p[3], p[1]), -1 .. 1, -1 .. 1, -1 .. 1, gridsize = (5, 5, 5),
        arrow_size = 0.2, transformation = Transformation(Makie.PointTrans{3}(p -> Point(p[2], p[3], p[1])))
    )
    a = LScene(f[2, 2])
    cam3d!(a)
    p = contour3d!(
        a, -1 .. 1, -1 .. 1,
        [cos(x) - sin(y) - x * y for x in range(-1, 1, 30), y in range(-1, 1, 30)],
        labels = true, colormap = :magma, linewidth = 3,
        transformation = Transformation(Makie.PointTrans{3}(p -> Point(p[2], p[3], p[1])))
    )

    f
end
