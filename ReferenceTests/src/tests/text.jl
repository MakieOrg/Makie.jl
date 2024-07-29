@reference_test "heatmap_with_labels" begin
    fig = Figure(size = (600, 600))
    ax = fig[1, 1] = Axis(fig)
    values = RNG.rand(10, 10)

    heatmap!(ax, values)

    text!(ax,
        string.(round.(vec(values'), digits = 2)),
        position = [Point2f(x, y) for x in 1:10 for y in 1:10],
        align = (:center, :center),
        color = ifelse.(vec(values') .< 0.3, :white, :black),
        fontsize = 12)
    fig
end

@reference_test "data space" begin
    pos = [Point2f(0, 0), Point2f(10, 10)]
    fig = text(
        ["0 is the ORIGIN of this", "10 says hi"],
        position = pos,
        axis = (aspect = DataAspect(),),
        markerspace = :data,
        align = (:center, :center),
        fontsize = 2)
    scatter!(pos)
    fig
end

@reference_test "single_strings_single_positions" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3]
    scatter!(scene, points, marker = :circle, markersize = 10px)

    i = 1
    for halign in (:right, :center, :left), valign in (:top, :center, :bottom)

        for rotation in (-pi/6, 0.0, pi/6)
            text!(scene, string(halign) * "/" * string(valign) *
                    " " * string(round(rad2deg(rotation), digits = 0)) * "°",
                color = (:black, 0.5),
                position = points[i],
                align = (halign, valign),
                rotation = rotation)
        end
        i += 1
    end
    scene
end


@reference_test "multi_strings_multi_positions" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    angles = (-pi/6, 0.0, pi/6)
    points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3 for angle in angles]
    aligns = [(halign, valign) for halign in
        (:right, :center, :left) for valign in (:top, :center, :bottom) for rotation in angles]
    rotations = [rotation for _ in
        (:right, :center, :left) for _ in (:top, :center, :bottom) for rotation in angles]

    strings = [string(halign) * "/" * string(valign) *
        " " * string(round(rad2deg(rotation), digits = 0)) * "°"
            for halign in (:right, :center, :left)
            for valign in (:top, :center, :bottom)
            for rotation in angles]

    scatter!(scene, points, marker = :circle, markersize = 10px, color=:black)

    text!(scene, points, text = strings, align = aligns, rotation = rotations,
        color = [(:black, alpha) for alpha in LinRange(0.3, 0.7, length(points))])

    scene
end

@reference_test "single_strings_single_positions_justification" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    points = [Point(x, y) .* 200 for x in 1:3 for y in 1:3]
    scatter!(scene, points, marker = :circle, markersize = 10px, color=:black)

    symbols = (:left, :center, :right)

    for ((justification, halign), point) in zip(Iterators.product(symbols, symbols), points)

        t = text!(scene, "a\nshort\nparagraph",
            color = (:black, 0.5),
            position = point,
            align = (halign, :center),
            justification = justification)

        bb = boundingbox(t, :pixel)
        wireframe!(scene, bb, color = (:red, 0.2))
    end

    for (p, al) in zip(points[3:3:end], (:left, :center, :right))
        text!(scene, p .+ (0, 80), text = "align :" * string(al),
            align = (:center, :baseline))
    end

    for (p, al) in zip(points[7:9], (:left, :center, :right))
        text!(scene, p .+ (80, 0), text = "justification\n:" * string(al),
            align = (:center, :top), rotation = pi/2)
    end

    scene
end

@reference_test "multi_boundingboxes" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    t1 = text!(scene,
        fill("makie", 4),
        position = [(200, 200) .+ 60 * Point2f(cos(a), sin(a)) for a in pi/4:pi/2:7pi/4],
        rotation = pi/4:pi/2:7pi/4,
        align = (:left, :center),
        fontsize = 30,
        markerspace = :data
    )

    wireframe!(scene, boundingbox(t1, :data), color = (:blue, 0.3))

    t2 = text!(scene,
        fill("makie", 4),
        position = [(200, 600) .+ 60 * Point2f(cos(a), sin(a)) for a in pi/4:pi/2:7pi/4],
        rotation = pi/4:pi/2:7pi/4,
        align = (:left, :center),
        fontsize = 30,
        markerspace = :pixel
    )

    wireframe!(scene, boundingbox(t2, :pixel), color = (:red, 0.3))

    scene
end

@reference_test "single_boundingboxes" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    for a in pi/4:pi/2:7pi/4

        t = text!(scene,
            "makie",
            position = (200, 200) .+ 60 * Point2f(cos(a), sin(a)),
            rotation = a,
            align = (:left, :center),
            fontsize = 30,
            markerspace = :data
        )

        wireframe!(scene, boundingbox(t, :data), color = (:blue, 0.3))

        t2 = text!(scene,
            "makie",
            position = (200, 600) .+ 60 * Point2f(cos(a), sin(a)),
            rotation = a,
            align = (:left, :center),
            fontsize = 30,
            markerspace = :pixel
        )

        # these boundingboxes should be invisible because they only enclose the anchor
        wireframe!(scene, boundingbox(t2, :pixel), color = (:red, 0.3))

    end
    scene
end

@reference_test "text_in_3d_axis" begin
    text(
        fill("Makie", 7),
        rotation = [i / 7 * 1.5pi for i in 1:7],
        position = [Point3f(0, 0, i/2) for i in 1:7],
        color = [cgrad(:viridis)[x] for x in LinRange(0, 1, 7)],
        align = (:left, :baseline),
        fontsize = 1,
        markerspace = :data,
        axis=(; type=LScene)
    )
end

@reference_test "empty_lines" begin
    scene = Scene(camera = campixel!, size = (800, 800))

    t1 = text!(scene, "Line1\nLine 2\n\nLine4",
        position = (200, 400), align = (:center, :center), markerspace = :data)

    wireframe!(scene, boundingbox(t1, :data), color = (:red, 0.3))

    t2 = text!(scene, "\nLine 2\nLine 3\n\n\nLine6\n\n",
        position = (400, 400), align = (:center, :center), markerspace = :data)

    wireframe!(scene, boundingbox(t2, :data), color = (:blue, 0.3))

    scene
end


@reference_test "3D screenspace annotations" begin
    positions = RNG.rand(Point3f, 10)
    fig, ax, p = meshscatter(positions, color=:white)
    text!(
        fill("Annotation", 10),
        position = positions,
        align = (:center, :center),
        fontsize = 20,
        markerspace = :pixel,
        overdraw=false)
    fig
end


@reference_test "Text offset" begin
    f = Figure(size = (1000, 1000))
    barplot(f[1, 1], 3:5)
    text!(1, 3, text = "bar 1", offset = (0, 10), align = (:center, :baseline))
    text!([(2, 4), (3, 5)], text = ["bar 2", "bar 3"],
        offset = [(0, -10), (0, -20)],
        align = (:center, :top), color = :white)

    scatter(f[1, 2], Point2f(0, 0))
    text!(0, 0, text = "hello", offset = (40, 0), align = (:left, :center))
    text!(0, 0, text = "hello", offset = (40, 0), align = (:left, :center),
        rotation = -pi/4)
    text!(0, 0, text = "hello", offset = (40, 0), align = (:left, :center),
        rotation = pi/4)

    scatter(f[2, 1], Point2f[(0, 0), (10, 0), (20, 10)])
    text!(0, 0, text = "ABC", markerspace = :data, offset = (0, 0), color = (:red, 0.3), align = (:left, :baseline))
    text!(0, 0, text = "ABC", markerspace = :data, offset = (10, 0), color = (:green, 0.3), align = (:left, :baseline))
    text!(0, 0, text = "ABC", markerspace = :data, offset = (20, 10), color = (:blue, 0.3), align = (:left, :baseline))

    LScene(f[2, 2], show_axis=false)
    scatter!(Point3f[(0, 0, 0), (2, 2, 2)])
    text!(1, 1, 1, text = "hello", offset = (10, 10))

    f
end


@reference_test "Log10 text" begin
    barplot([1, 10, 100], fillto = 0.1, axis = (yscale = log10,))
    text!([(1, 1), (2, 10), (3, 100)], text = ["bar 1", "bar 2", "bar 3"],
        offset = (0, -10), color = :white, align = (:center, :top))
    tightlimits!(current_axis(), Bottom())
    current_figure()
end

@reference_test "latex strings" begin
    f, ax , l = lines(cumsum(RNG.randn(1000)),
        axis = (
                title = L"\sum_k{x y_k}",
                xlabel = L"\lim_{x →\infty} A^j v_{(a + b)_k}^i \sqrt{23.5} x!= \sqrt{\frac{1+6}{4+a+g}}\int_{0}^{2π} \sin(x) dx",
                ylabel = L"x + y - \sin(x) × \tan(y) + \sqrt{2}",
            ),
        figure = (fontsize = 18,)
    )
    text!(500, 0, text = L"\int_{0}^{2π} \sin(x) dx")
    Legend(f[1, 2], [l, l, l], [L"\sum{xy}", L"a\int_0^5x^2+2ab", L"||x-y||^2"])
    f
end

@reference_test "latex hlines in axis" begin
    text(1, 1, text = L"\frac{\sqrt{x + y}}{\sqrt{x + y}}", fontsize = 50, rotation = pi/4,
        align = (:center, :center))
end

@reference_test "latex simple" begin
    s = Scene(camera = campixel!)
    t = text!(s,
        L"\sqrt{2}",
        position = (50, 50),
        rotation = pi/2,
        markerspace = :data)
    s
end

@reference_test "latex bb" begin
    s = Scene(camera = campixel!)
    t = text!(s,
        L"\int_0^5x^2+2ab",
        position = Point2f(50, 50),
        rotation = 0.0,
        markerspace = :data)
    wireframe!(s, boundingbox(t, :data), color=:black)
    s
end

@reference_test "latex updates" begin
    s = Scene(camera = campixel!)
    st = Stepper(s)
    textnode = Observable([L"\int_0^5x^2+2ab", L"\int_0^5x^2+2ab"])
    posnode = Observable(Point2f[(50, 50), (100, 100)])

    t = text!(s,
        textnode,
        position = posnode,
        rotation = 0.0,
        markerspace = :data)

    Makie.step!(st)
    ## change lengths
    textnode[] = push!(textnode[], L"\int_0^5x^2+2ab")
    posnode[] = push!(posnode[], Point2f(150, 150))
    Makie.step!(st)
    st
end

@reference_test "update annotation style" begin
    s = Scene(camera = campixel!)
    st = Stepper(s)
    textposnode = Observable([
        (L"\int_0^5x^2+2ab", Point2f(50, 50)),
        (L"\int_0^5x^2+2ab", Point2f(100, 100)),
    ])

    t = text!(s,
        textposnode,
        markerspace = :data)

    Makie.step!(st)
    ## change lengths
    textposnode[] = push!(textposnode[], (L"\int_0^5x^2+2ab", Point2f(150, 150)))
    Makie.step!(st)
    st
end

@reference_test "latex ticks" begin
    lines(0..25, x -> 4 * sin(x) / (cos(3x) + 4), figure = (fontsize = 25,),
        axis = (
            xticks = (0:10:20, [L"10^{-3.5}", L"10^{-4.5}", L"10^{-5.5}"]),
            yticks = ([-1, 0, 1], [L"\sum_%$i{xy}" for i in 1:3]),
            yticklabelrotation = pi/8,
            title = L"\int_0^1{x^2}",
            xlabel = L"\sum_k{x_k ⋅ y_k}",
            ylabel = L"\int_a^b{\sqrt{abx}}"
        ),
    )
end


@reference_test "dynamic latex ticks" begin
    lines(0..25, x -> 4 * sin(x) / (cos(3x) + 4),
        figure = (fontsize = 16,),
        axis = (xtickformat = (xs -> [L"e^{\sqrt{%$x}}+\sum" for x in xs]), ))
end

@reference_test "Word Wrapping" begin
    lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."

    fig = Figure(size=(600, 500))
    ax = Axis(fig[1, 1])
    text!(ax, 0, 0, text = latexstring(L"$1$ " * lorem_ipsum), word_wrap_width=250, fontsize = 12, align = (:left, :bottom), justification = :left, color = :black)
    text!(ax, 0, 0, text = lorem_ipsum, word_wrap_width=250, fontsize = 12, align = (:left, :top), justification = :right, color = :black)
    text!(ax, 0, 0, text = lorem_ipsum, word_wrap_width=250, fontsize = 12, align = (:right, :bottom), justification = :center, color = :red)
    text!(ax, -0.3, 0, text = lorem_ipsum, word_wrap_width=200, fontsize = 12, align = (:center, :top), color = :blue)
    xlims!(ax, -0.8, 0.8)
    ylims!(ax, -0.8, 0.6)
    fig
end

@reference_test "label type change" begin
    fig = Figure()
    ax = Axis3(fig[1, 1])
    ax.xlabel[] = L"1 + \alpha^2"
    ax.ylabel[] = L"\lim_{x\to\infty} f(x)"
    ax.zlabel[] = L"\sum_{n=1}^{\infty} 2^{-n} = 1"
    fig
end

# test #3232
@reference_test "texture atlas update" begin
    scene = Scene(size = (250, 100))
    campixel!(scene)
    p = text!(scene, "test", fontsize = 85)
    st = Stepper(scene)
    Makie.step!(st)
    p[1][] = "-!ħ█?-" # "!ħ█?" are all new symbols
    Makie.step!(st)
    st
end