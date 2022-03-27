# @cell "lines and linestyles" begin
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

@cell "lines with gaps" begin
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

@cell "scatters" begin
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

@cell "scatter rotations" begin
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


@cell "basic polygon shapes" begin
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


@cell "BezierPath markers" begin
    f = Figure()
    ax = Axis(f[1, 1])

    batman = BezierPath("""
            M96.84 141.998c-4.947-23.457-20.359-32.211-25.862-13.887-11.822
            -22.963-37.961-16.135-22.041 6.289-3.005-1.295-5.872-2.682-8.538
            -4.191-8.646-5.318-15.259-11.314-19.774-17.586-3.237-5.07-4.994
            -10.541-4.994-16.229 0-19.774 21.115-36.758 50.861-43.694.446
            -.078.909-.154 1.372-.231-22.657 30.039 9.386 50.985 15.258
            24.645l2.528-24.367 5.086 6.52H103.205l5.07-6.52 2.543 24.367
            c5.842 26.278 37.746 5.502 15.414-24.429 29.777 6.951 50.891
            23.936 50.891 43.709 0 15.136-12.406 28.651-31.609 37.267 14.842
            -21.822-10.867-28.266-22.549-5.549-5.502-18.325-21.147-9.341
            -26.125 13.886z""", fit = true, flipy = true)

    markers = [
        Makie.BezierSquare,
        Makie.BezierCircle,
        Makie.BezierCross,
        Makie.BezierUTriangle,
        Makie.BezierDTriangle,
        Makie.BezierRTriangle,
        Makie.BezierLTriangle,
        Makie.scale(batman, 2),
    ]

    for (i, marker) in enumerate(markers)
        scatter!(1:5, (1:5).+i, marker = marker, markersize = 20)
    end

    f
end