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
    filename = normpath(joinpath(@__DIR__, "..", "..", "..", "assets", "icon_transparent.png"))
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
