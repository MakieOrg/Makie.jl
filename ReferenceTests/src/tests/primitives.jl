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
        BezierPath(batsymbol_string, fit = true, flipy = true),
        1.5
    )

    gh_string = "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
    github = BezierPath(gh_string, fit = true, flipy = true, bbox = Rect2f((0, 0), (1.5, 1)), keep_aspect = false)

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
