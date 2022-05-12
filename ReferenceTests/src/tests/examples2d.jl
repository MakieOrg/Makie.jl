
@reference_test "Test heatmap + image overlap" begin
    heatmap(RNG.rand(32, 32))
    image!(map(x -> RGBAf(x, 0.5, 0.5, 0.8), RNG.rand(32, 32)))
    current_figure()
end

@reference_test "poly and colormap" begin
    # example by @Paulms from JuliaPlots/Makie.jl#310
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
        textsize=60,
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
            textsize=50,
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
                    linewidth=2,  arrow_size=20, colormap=:magma, axis=(;title=title_str))
    Record(sp, LinRange(0, 20, 5)) do i
        sf[] = Base.Fix2(v, i)
        title_str[] = "t = $(round(i; sigdigits=2))"
    end
end


@reference_test "Line changing colour" begin
    fig, ax, lineplot = lines(RNG.rand(10); linewidth=10)
    N = 20
    Record(fig, 1:N; framerate=20) do i
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
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange,
                markersize = 5scales[j], space = space, markerspace = mspace)
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                textsize = scales[j], space = space, markerspace = mspace,
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
                ax, Point2f(xs[i][i], xs[i][j]), color = :orange,
                markersize = 5scales[j], space = space, markerspace = mspace)
            text!(
                ax, "$space\n$mspace", position = Point2f(xs[i][i], xs[i][j]),
                textsize = scales[j], space = space, markerspace = mspace,
                align = (:center, :center), color = :black)
        end
    end
    fig
end

@reference_test "Scatter & Text transformations" begin
    # Check that transformations apply in `space = :data`
    fig, ax, p = scatter(Point2f(100, 0.5), marker = 'a', markersize=50)
    t = text!("Test", position = Point2f(100, 0.5), textsize = 50)
    translate!(p, -100, 0, 0)
    translate!(t, -100, 0, 0)

    # Check that scale and rotate don't act on the marker for scatter (only the position)
    p2 = scatter!(ax, Point2f(1, 0), marker= 'a', markersize = 50)
    Makie.rotate!(p2, pi/4)
    scale!(p2, 0.5, 0.5, 1)

    # but do act on glyphs of text
    t2 = text!(ax, "Test", position = Point2f(1, 0), textsize = 50)
    Makie.rotate!(t2, pi/4)
    scale!(t2, 0.5, 0.5, 1)

    xlims!(ax, -0.2, 0.5)
    ylims!(ax, 0, 1)

    fig
end

@reference_test "2D surface with explicit color" begin
    fig, ax, plt = surface(1:10, 1:10, ones(10, 10); color = [RGBf(x*y/100, 0, 0) for x in 1:10, y in 1:10], shading = false)
    fig
end
