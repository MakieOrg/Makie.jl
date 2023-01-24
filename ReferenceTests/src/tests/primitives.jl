# @reference_test "lines and linestyles" begin
quote
    # For now disabled until we fix GLMakie linestyle
    s = Scene(resolution = (800, 800), camera = campixel!)
    scalar = 30
    points = Point2f[(1, 1), (1, 2), (2, 3), (2, 1)]
    linestyles = [
        :solid, :dash, :dot, :dashdot, :dashdotdot,
        [1, 2, 3], [1, 2, 4, 5]
    ]
    for linewidth in 1:10
        for (i, linestyle) in enumerate(linestyles)
            lines!(s,
                scalar .* (points .+ Point2f(linewidth*2, i * 3.25)),
                linewidth = linewidth,
                linestyle = linestyle,
            )
        end
    end
    s
end

@reference_test "lines with gaps" begin
    s = Scene(resolution = (800, 800), camera = campixel!)
    points = [
        Point2f[(1, 0), (2, 0.5), (NaN, NaN), (4, 0.5), (5, 0)],
        Point2f[(NaN, NaN), (2, 0.5), (3, 0), (4, 0.5), (5, 0)],
        Point2f[(NaN, NaN), (2, 0.5), (3, 0), (4, 0.5), (NaN, NaN)],
        Point2f[(NaN, NaN), (2, 0.5), (NaN, NaN), (4, 0.5), (NaN, NaN)],
        Point2f[(NaN, NaN), (NaN, NaN), (3, 0), (NaN, NaN), (NaN, NaN)],
        Point2f[(NaN, NaN), (NaN, NaN), (NaN, NaN), (NaN, NaN), (NaN, NaN)],
    ]
    for (i, p) in enumerate(points)
        lines!(s, (p .+ Point2f(0, i)) .* 100, linewidth = 10)
    end
    s
end

@reference_test "scatters" begin
    s = Scene(resolution = (800, 800), camera = campixel!)

    markersizes = 0:2:30
    markers = [:circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑'
    ]

    for (i, ms) in enumerate(markersizes)
        for (j, m) in enumerate(markers)
            scatter!(s,
                Point2f(i, j) .* 45,
                marker = m,
                markersize = ms,
            )
        end
    end
    s
end

@reference_test "scatter rotations" begin
    s = Scene(resolution = (800, 800), camera = campixel!)

    rotations = range(0, 2pi, length = 15)
    markers = [:circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑'
    ]

    for (i, rot) in enumerate(rotations)
        for (j, m) in enumerate(markers)
            p = Point2f(i, j) .* 45
            scatter!(s,
                p,
                marker = m,
                markersize = 30,
                rotations = rot,
            )
            scatter!(s, p, color = :red, markersize = 6)
        end
    end
    s
end

@reference_test "scatter with stroke" begin
    s = Scene(resolution = (350, 700), camera = campixel!)

    # half stroke, half glow
    strokes = range(1, 4, length=7)
    outline_colors = [:red, :green, :blue, :yellow, :purple, :cyan, :black]
    colors = [
        :red, :green, :blue,
        :yellow, :purple, :cyan,
        :white, :black,
        RGBAf(1, 0, 0, 0), RGBAf(0, 1, 0, 0), RGBAf(0, 0, 1, 0),
        RGBAf(1, 0, 1, 0), RGBAf(0, 1, 1, 0), RGBAf(1, 1, 0, 0),
    ]

    markers = [:circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑', 'o'
    ]

    for i in eachindex(strokes)
        oc = outline_colors[i]
        strokewidth = strokes[i]
        for (j, (m, c)) in enumerate(zip(markers, colors))
            p = Point2f(i, j) .* 45
            scatter!(s,
                p,
                marker = m, markersize = 30, color = c,
                strokewidth = strokewidth, strokecolor = oc,
            )
        end
    end
    s
end

@reference_test "scatter with glow" begin
    s = Scene(resolution = (350, 700), camera = campixel!)

    # half stroke, half glow
    glows = range(4, 1, length=7)
    outline_colors = [:red, :green, :blue, :yellow, :purple, :cyan, :black]
    colors = [
        :red, :green, :blue,
        :yellow, :purple, :cyan,
        :white, :black,
        RGBAf(1, 0, 0, 0), RGBAf(0, 1, 0, 0), RGBAf(0, 0, 1, 0),
        RGBAf(1, 0, 1, 0), RGBAf(0, 1, 1, 0), RGBAf(1, 1, 0, 0),
    ]

    markers = [:circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑', 'o'
    ]

    for i in eachindex(glows)
        oc = outline_colors[i]
        glowwidth = glows[i]
        for (j, (m, c)) in enumerate(zip(markers, colors))
            p = Point2f(i, j) .* 45
            scatter!(s,
                p,
                marker = m, markersize = 30, color = c,
                glowwidth = glowwidth, glowcolor = oc,
            )
        end
    end
    s
end


@reference_test "scatter image markers" begin
    pixel_types = [ RGBA, RGBAf, RGBA{Float16}, ARGB, ARGB{Float16}, RGB, RGBf, RGB{Float16} ]
    rotations = [ 2pi/3 * (i-1) for i = 1:length(pixel_types) ]
    s = Scene(resolution = (100+100*length(pixel_types), 400), camera = campixel!)
    filename = Makie.assetpath("icon_transparent.png")
    marker_image = FileIO.load(filename)
    for (i, (rot, pxtype)) in enumerate(zip(rotations, pixel_types))
        marker = convert.(pxtype, marker_image)
        p = Point2f((i-1) * 100 + 100, 200)
        scatter!(s,
            p,
            marker = marker,
            markersize = 75,
            rotations = rot,
        )
    end
    s
end


@reference_test "basic polygon shapes" begin
    s = Scene(resolution = (800, 800), camera = campixel!)
    scalefactor = 70
    Pol = Makie.GeometryBasics.Polygon
    polys = [
        # three points
        Pol(Point2f[(1, 1), (1, 2), (2, 1)]),
        # four points
        Pol(Point2f[(1, 1), (1, 2), (2, 2), (2, 1)]),
        # double point
        Pol(Point2f[(1, 1), (1, 2), (2, 2), (2, 2)]),
        # one hole
        Pol(
            Point2f[(1, 1), (1, 2), (2, 2), (2, 1)],
            [Point2f[(1.3, 1.3), (1.3, 1.7), (1.7, 1.7), (1.7, 1.3)]]
        ),
        # two holes
        Pol(
            Point2f[(1, 1), (1, 2), (2, 2), (2, 1)],
            [
                Point2f[(1.15, 1.15), (1.15, 1.85), (1.4, 1.85), (1.4, 1.15)],
                Point2f[(1.6, 1.15), (1.6, 1.85), (1.85, 1.85), (1.85, 1.15)],
            ]
        ),
        # hole half same as exterior
        Pol(
            Point2f[(1, 1), (1, 2), (2, 2), (2, 1)],
            [Point2f[(1, 1), (1, 2), (2, 2)]],
        ),
        # point self intersection
        Pol(
            Point2f[(1, 1), (2, 1), (2, 2), (1.5, 1), (1, 2)],
        ),
    ]

    linewidths = 0:2:9

    for (i, p) in enumerate(polys)
        for (j, lw) in enumerate(linewidths)
            t = Transformation(scale=Vec3f(scalefactor), translation = Vec3f(1.3 * (i-1), 1.3 * j, 0) .* scalefactor)
            poly!(
                s,
                p,
                transformation = t,
                color = (:red, 0.5),
                strokewidth = lw,
            )
        end
    end
    s
end


@reference_test "BezierPath markers" begin
    f = Figure(resolution = (800, 800))
    ax = Axis(f[1, 1])

    markers = [
        :rect,
        :circle,
        :cross,
        :x,
        :utriangle,
        :rtriangle,
        :dtriangle,
        :ltriangle,
        :pentagon,
        :hexagon,
        :octagon,
        :star4,
        :star5,
        :star6,
        :star8,
        :vline,
        :hline,
        # for comparison with characters
        'x',
        'X',
    ]

    for (i, marker) in enumerate(markers)
        scatter!(Point2f.(1:5, i), marker = marker, markersize = range(10, 30, length = 5), color = :black)
        scatter!(Point2f.(1:5, i), markersize = 4, color = :white)
    end

    f
end


@reference_test "complex_bezier_markers" begin
    f = Figure(resolution = (800, 800))
    ax = Axis(f[1, 1])

    arrow = BezierPath([
        MoveTo(Point(0, 0)),
        LineTo(Point(0.3, -0.3)),
        LineTo(Point(0.15, -0.3)),
        LineTo(Point(0.3, -1)),
        LineTo(Point(0, -0.9)),
        LineTo(Point(-0.3, -1)),
        LineTo(Point(-0.15, -0.3)),
        LineTo(Point(-0.3, -0.3)),
        ClosePath()
    ])

    circle_with_hole = BezierPath([
        MoveTo(Point(1, 0)),
        EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
        MoveTo(Point(0.5, 0.5)),
        LineTo(Point(0.5, -0.5)),
        LineTo(Point(-0.5, -0.5)),
        LineTo(Point(-0.5, 0.5)),
        ClosePath(),
    ])

    batsymbol_string = "M96.84 141.998c-4.947-23.457-20.359-32.211-25.862-13.887-11.822-22.963-37.961-16.135-22.041 6.289-3.005-1.295-5.872-2.682-8.538-4.191-8.646-5.318-15.259-11.314-19.774-17.586-3.237-5.07-4.994-10.541-4.994-16.229 0-19.774 21.115-36.758 50.861-43.694.446-.078.909-.154 1.372-.231-22.657 30.039 9.386 50.985 15.258 24.645l2.528-24.367 5.086 6.52H103.205l5.07-6.52 2.543 24.367c5.842 26.278 37.746 5.502 15.414-24.429 29.777 6.951 50.891 23.936 50.891 43.709 0 15.136-12.406 28.651-31.609 37.267 14.842-21.822-10.867-28.266-22.549-5.549-5.502-18.325-21.147-9.341-26.125 13.886z"
    batsymbol = Makie.scale(
        BezierPath(batsymbol_string, fit = true, flipy = true, bbox = Rect2f((0, 0), (1, 1)), keep_aspect = false),
        1.5
    )

    gh_string = "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
    github = BezierPath(gh_string, fit = true, flipy = true)

    two_circles_with_holes = Makie.scale(BezierPath([
        MoveTo(Point(2.25, 0)),
        EllipticalArc(Point(1.25, 0), 1, 1, 0, 0, 2pi),
        ClosePath(),
        MoveTo(Point(-0.25, 0)),
        EllipticalArc(Point(-1.25, 0), 1, 1, 0, 0, 2pi),
        ClosePath(),
        MoveTo(Point(2, 0)),
        EllipticalArc(Point(1.25, 0), 0.75, 0.75, 0, 0, -2pi),
        ClosePath(),
        MoveTo(Point(-1, 0)),
        EllipticalArc(Point(-1.25, 0), 0.25, 0.25, 0, 0, -2pi),
        ClosePath(),
    ]), 0.5)

    markers = [
        arrow,
        circle_with_hole,
        batsymbol,
        github,
        two_circles_with_holes,
    ]

    for (i, marker) in enumerate(markers)
        scatter!(Point2f.(1:5, i), marker = marker, markersize = range(10, 50, length = 5), color = :black)
    end

    limits!(ax, 0, 6, 0, length(markers) + 1)

    f
end

@reference_test "polygon markers" begin
    p_big = decompose(Point2f, Circle(Point2f(0), 1))
    p_small = decompose(Point2f, Circle(Point2f(0), 0.5))
    marker = [Polygon(p_big, [p_small]), Polygon(reverse(p_big), [p_small]), Polygon(p_big, [reverse(p_small)]), Polygon(reverse(p_big), [reverse(p_small)])]
    scatter(1:4, fill(0, 4), marker=marker, markersize=100, color=1:4, axis=(limits=(0, 5, -1, 1),))
end

function centered_rect(w, h)
    wh, hh = w/2, h/2
    return Point2f[(-wh, -hh), (-wh, hh), (wh, hh), (wh, -hh)]
end

function create_marker(inner)
    p_big = decompose(Point2f, Circle(Point2f(0), 0.5))
    p_small = decompose(Point2f, Circle(Point2f(0), inner))
    marker = Polygon(p_big, [p_small])
    return Makie.to_spritemarker(marker)
end

function create_rect(inner)
    p_big = centered_rect(1, 1)
    p_small = centered_rect(inner, inner)
    marker = Polygon(p_big, [p_small])
    return Makie.to_spritemarker(marker)
end

function plot_test!(scene, xoffset, yoffset, inner, reverse=true, marker=create_marker)
    bpath = marker(inner)
    p = [Point2f(xoffset, yoffset) .+ 150]
    if reverse
        scatter!(scene, p, marker=bpath, markersize=280, color=:black)
        scatter!(scene, p, marker=Rect, markersize=280, color=:red)
    else
        scatter!(scene, p, marker=Rect, markersize=280, color=:red)
        scatter!(scene, p, marker=bpath, markersize=280, color=:black)
    end
end

function plot_row!(scene, yoffset, reverse)
    # Create differently sized cut outs, so that we have to write new values into the texture atlas!
    plot_test!(scene, 0, yoffset + 0, 0.4, reverse)
    plot_test!(scene, 300, yoffset + 0, 0.3, reverse)
    plot_test!(scene, 600, yoffset + 0, 0.4, reverse, create_rect)
    plot_test!(scene, 900, yoffset + 0, 0.3, reverse, create_rect)
end

function draw_marker_test!(scene, marker, center; markersize=300)
    # scatter!(scene, center, distancefield=matr, uv_offset_width=Vec4f(0, 0, 1, 1), markersize=600)
    scatter!(scene, center, marker=marker, markersize=markersize, markerspace=:pixel)

    font = Makie.defaultfont()
    charextent = Makie.FreeTypeAbstraction.get_extent(font, marker)
    inkbb = Makie.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    w, h = widths(inkbb) .* markersize
    ox, oy = origin(inkbb) .* markersize
    mhalf = markersize / 2
    bbmin = center .+ Point2f(-w/2, -h/2)
    inkbb_scaled = Rect2f(bbmin..., w, h)

    lines!(scene, inkbb_scaled, linewidth=5, color=:green)
    points = Point2f[(center[1], center[2] - h/2), (center[1], center[2] + h/2), (center[1] - w/2, center[2]), (center[1] + w/2, center[2])]
    linesegments!(scene, points, color=:red)

    scene
end

@reference_test "marke glyph alignment" begin
    scene = Scene(resolution=(1200, 1200))
    campixel!(scene)
    # marker is in front, so it should not be smaller than the background rectangle
    plot_row!(scene, 0, false)
    # marker is in the background, so one shouldnt see a single pixel of the marker
    plot_row!(scene, 300, true)

    center = Point2f(size(scene) ./ 2)

    # Markers should be well aligned to the red cross and just about touch the green
    # boundingbox!
    draw_marker_test!(scene, 'x', Point2f(150, 750); markersize=550)
    draw_marker_test!(scene, 'X', Point2f(450, 750); markersize=400)
    draw_marker_test!(scene, 'I', Point2f(750, 750); markersize=400)
    draw_marker_test!(scene, 'O', Point2f(1050, 750); markersize=300)

    draw_marker_test!(scene, 'L', Point2f(150, 1050); markersize=350)
    draw_marker_test!(scene, 'Y', Point2f(450, 1050); markersize=350)
    draw_marker_test!(scene, 'y', Point2f(750, 1050); markersize=350)
    draw_marker_test!(scene, 'u', Point2f(1050, 1050); markersize=500)

    scene
end

@reference_test "Surface with NaN points" begin
    # prepare surface data
    zs = rand(10, 10)
    ns = copy(zs)
    ns[4, 3:6] .= NaN
    # plot surface
    f, a, p = surface(1..10, 1..10, ns, colormap = [:lightblue, :lightblue])
    # plot a wireframe so we can see what's going on, and in which cells.
    m = let
        xs, ys, zs = to_value.(p.converted)
        ps = Makie.matrix_grid(identity, xs, ys, zs)
        rect = Makie.Tesselation(Rect2f(0, 0, 1, 1), size(zs))
        faces = Makie.decompose(Makie.QuadFace{Int}, rect)
        faces = filter(f -> !any(i -> isnan(ps[i]), f), faces)
        uv = map(x-> Vec2f(1f0 - x[2], 1f0 - x[1]), Makie.decompose_uv(rect))
        Makie.GeometryBasics.Mesh(
            Makie.meta(ps; uv=uv, normals = Makie.nan_aware_normals(ps, faces)), faces, 
        )
    end
    scatter!(a, m.position, color = isnan.(m.normals), depth_shift = -1f-3)
    wireframe!(a, m, depth_shift = -1f-3, color = :black)
    f
end
