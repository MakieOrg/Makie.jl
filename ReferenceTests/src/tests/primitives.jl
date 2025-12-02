@reference_test "lines and linestyles" begin
    s = Scene(size = (800, 800), camera = campixel!)
    scalar = 30
    points = Point2f[(1, 1), (1, 2), (2, 3), (2, 1)]
    linestyles = [
        :solid, :dash, :dot, :dashdot, :dashdotdot,
        Linestyle([1, 2, 3]), Linestyle([1, 2, 4, 5]),
    ]
    for linewidth in 1:10
        for (i, linestyle) in enumerate(linestyles)
            lines!(
                s,
                scalar .* (points .+ Point2f(linewidth * 2, i * 3.25)),
                linewidth = linewidth,
                linestyle = linestyle,
                color = :black
            )
        end
    end
    s
end

@reference_test "lines with gaps" begin
    s = Scene(size = (800, 800), camera = campixel!)
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
    # These are "doesn't break" tests. They should not display anything
    lines!(s, Point2f[])
    lines!(s, Point2f[(100, 100)])
    s
end

# A test case for wide lines and mitering at joints
@reference_test "Miter Joints for line rendering" begin
    scene = Scene()
    cam2d!(scene)
    r = 4
    sep = 4 * r
    scatter!(scene, (sep + 2 * r) * [-1, -1, 1, 1], (sep + 2 * r) * [-1, 1, -1, 1])

    for i in -1:1
        for j in -1:1
            angle = pi / 2 + pi / 4 * i
            x = r * [-cos(angle / 2), 0, -cos(angle / 2)]
            y = r * [-sin(angle / 2), 0, sin(angle / 2)]

            linewidth = 40 * 2.0^j
            lines!(scene, x .+ sep * i, y .+ sep * j, color = RGBAf(0, 0, 0, 0.5), linewidth = linewidth)
            lines!(scene, x .+ sep * i, y .+ sep * j, color = :red)
        end
    end
    center!(scene)
    scene
end

@reference_test "Linecaps and joinstyles" begin
    fig = Figure(size = (550, 450))
    ps = [Point2f(-2, 0), Point2f(0), Point2f(2, 0)]
    r = 2.0
    for phi in [130, -121, 119, 90, -60]
        R = Makie.Mat2f(cosd(phi), sind(phi), -sind(phi), cosd(phi))
        r += 0.2
        push!(ps, ps[end] + r * R * normalize(ps[end] - ps[end - 1]))
    end

    for i in 1:3, j in 1:3
        ax = Axis(fig[i, j], aspect = DataAspect())
        hidedecorations!(ax)
        xlims!(-4.7, 4.2)
        ylims!(-1.0, 5.5)
        p = lines!(
            ax, ps, linewidth = 20,
            linecap = (:butt, :square, :round)[i],
            joinstyle = (:miter, :bevel, :round)[j]
        )
        scatterlines!(ax, ps, color = :orange)
    end

    fig
end

@reference_test "Line loops" begin
    # check for issues with self-overlap of line segments with loops, interplay
    # between loops, lines, nan separation
    loop(p) = Point2f[p, p .+ Point2f(0.8, 0), p .+ Point2f(0, 0.8), p, Point2f(NaN)]
    line(p) = Point2f[p, p .+ Point2f(0.8, 0), p .+ Point2f(0, 0.8), Point2f(NaN)]

    nan = [Point2f(NaN)]
    ps = vcat(
        nan, nan, nan, loop((0, -1)), loop((1, -1)),
        line((-1, 0)), line((0, 0)),
        nan, nan, line((1, 0)), nan,
        loop((-1, 1)), nan, loop((0, 1)),
        nan, [Point2f(1, 1)], nan
    )

    f, a, p = lines(loop((-1, -1)), linewidth = 20, linecap = :round, alpha = 0.5)
    lines!(ps, linewidth = 20, linecap = :round, alpha = 0.5)
    lines!(vcat(nan, nan, line((1, 1)), nan), linewidth = 20, linecap = :round, alpha = 0.5)
    lines!([-1.2, -1.2, 2, 2, 1, 0, -1.2], [-1.2, 2, 2, -1.2, -1.2, -1.2, -1.2], linewidth = 20, alpha = 0.5)
    f
end

@reference_test "Miter Limit" begin
    ps = [Point2f(0, -0.5), Point2f(1, -0.5)]
    for phi in [160, -130, 121, 50, 119, -90] # these are 180-miter_angle
        R = Makie.Mat2f(cosd(phi), sind(phi), -sind(phi), cosd(phi))
        push!(ps, ps[end] + (1 + 0.2 * (phi == 50)) * R * normalize(ps[end] - ps[end - 1]))
    end
    popfirst!(ps) # for alignment, removes 160° corner

    fig = Figure(size = (400, 400))
    ax = Axis(fig[1, 1], aspect = DataAspect())
    hidedecorations!(ax)
    xlims!(-2.7, 2.4)
    ylims!(-2.5, 2.5)
    lines!(
        ax, ps .+ Point2f(-1.2, -1.2), linewidth = 20, miter_limit = 51pi / 180, color = :black,
        joinstyle = :round
    )
    lines!(
        ax, ps .+ Point2f(+1.2, -1.2), linewidth = 20, miter_limit = 129pi / 180, color = :black,
        joinstyle = :bevel
    )
    lines!(ax, ps .+ Point2f(-1.2, +1.2), linewidth = 20, miter_limit = 51pi / 180, color = :black)
    lines!(ax, ps .+ Point2f(+1.2, +1.2), linewidth = 20, miter_limit = 129pi / 180, color = :black)

    fig
end

@reference_test "Lines from outside" begin
    # This tests that lines that start or end in clipped regions are still
    # rendered correctly. For perspective projections this can be tricky as
    # points behind the camera get projected beyond far.
    lps = let
        ps1 = [Point3f(x, 0.2 * (z + 1), z) for x in (-8, 0, 8) for z in (-9, -1, -1, 7)]
        ps2 = [Point3f(x, 0.2 * (z + 1), z) for z in (-9, -1, 7) for x in (-8, 0, 0, 8)]
        vcat(ps1, ps2)
    end
    cs = [i for i in (1, 12, 2, 11, 3, 10, 4, 9, 5, 8, 6, 7) for _ in 1:2]

    fig = Figure()

    for (i, func) in enumerate((lines, linesegments))
        for (j, ls) in enumerate((:solid, :dot))
            a, p = func(fig[i, j], lps, color = cs, linewidth = 5, linestyle = ls)
            cameracontrols(a).settings.center[] = false # avoid recenter on display
            a.show_axis[] = false
            update_cam!(a.scene, Vec3f(-0.2, 0.5, 0), Vec3f(-0.2, 0.2, -1), Vec3f(0, 1, 0))
        end
    end

    fig
end

@reference_test "line color interpolation with clipping" begin
    # Clipping should not change the color interpolation of a line piece, so
    # these boxes should match in color
    fig = Figure()
    ax = Axis(fig[1, 1])
    ylims!(ax, -0.1, 1.1)
    lines!(
        ax, Rect2f(0, 0, 1, 10), color = 1:5, linewidth = 5,
        clip_planes = [Plane3f(Point3f(0, 1.0, 0), Vec3f(0, -1, 0))]
    )
    lines!(ax, Rect2f(0.1, 0.0, 0.8, 10.0), color = 1:5, linewidth = 5)

    ax = Axis(fig[1, 2])
    ylims!(ax, -0.1, 1.1)
    cs = [1, 2, 2, 3, 3, 4, 4, 5]
    linesegments!(
        ax, Rect2f(0, 0, 1, 10), color = cs, linewidth = 5,
        clip_planes = [Plane3f(Point3f(0, 1.0, 0), Vec3f(0, -1, 0))]
    )
    linesegments!(ax, Rect2f(0.1, 0.0, 0.8, 10.0), color = cs, linewidth = 5)
    fig
end

@reference_test "scatters" begin
    s = Scene(size = (800, 800), camera = campixel!)

    markersizes = 0:2:30
    markers = [
        :circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑',
    ]

    for (i, ms) in enumerate(markersizes)
        for (j, m) in enumerate(markers)
            scatter!(
                s,
                Point2f(i, j) .* 45,
                marker = m,
                markersize = ms,
                color = :black
            )
        end
    end
    s
end

@reference_test "scatter rotations" begin
    s = Scene(size = (800, 800), camera = campixel!)

    rotations = range(0, 2pi, length = 15)
    markers = [
        :circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑',
    ]

    for (i, rot) in enumerate(rotations)
        for (j, m) in enumerate(markers)
            p = Point2f(i, j) .* 45
            scatter!(
                s,
                p,
                marker = m,
                markersize = 30,
                rotation = rot,
                color = :black
            )
            scatter!(s, p, color = :red, markersize = 6)
        end
    end
    s
end

function make_billboard_rotations_test_fig(marker)
    r = Rect3f(Point3f(-0.5), Vec3f(1))
    ps = coordinates(r)
    phis = collect(range(0, 2pi, length = 8))
    quats = Makie.to_rotation(phis)

    fig = Figure(size = (500, 800))
    for (k, transform_marker) in zip(0:1, [true, false])
        for (i, space, ms) in zip(1:2, [:data, :pixel], [1, 30])
            for (j, rot, lbl) in zip(1:3, [Billboard(phis), phis, quats], ["Billboard", "angles", "Quaternion"])
                Label(fig[i + 2k, j][1, 1], "$space | $lbl | $transform_marker", tellwidth = false)
                a, p = scatter(
                    fig[i + 2k, j][2, 1], ps, marker = marker,
                    strokewidth = 2, strokecolor = :black, color = :yellow,
                    markersize = ms, markerspace = space, rotation = rot,
                    transform_marker = transform_marker
                )

                Makie.rotate!(p, Vec3f(1, 0.5, 0.1), 1.0)
                a.scene.camera_controls.settings[:center] = false
                Makie.update_cam!(a.scene, r)
            end
        end
    end

    return fig
end

@reference_test "scatter Billboard and transform_marker for Char markers" begin
    make_billboard_rotations_test_fig('L')
end
@reference_test "scatter Billboard and transform_marker for Rect markers" begin
    make_billboard_rotations_test_fig(Rect)
end
@reference_test "scatter Billboard and transform_marker for Circle markers" begin
    make_billboard_rotations_test_fig(Circle)
end
@reference_test "scatter Billboard and transform_marker for BezierPath markers" begin
    make_billboard_rotations_test_fig(:utriangle)
end
@reference_test "scatter Billboard and transform_marker for image markers" begin
    make_billboard_rotations_test_fig(Makie.FileIO.load(Makie.assetpath("cow.png")))
end

@reference_test "scatter with stroke" begin
    s = Scene(size = (350, 700), camera = campixel!)

    # half stroke, half glow
    strokes = range(1, 4, length = 7)
    outline_colors = [:red, :green, :blue, :yellow, :purple, :cyan, :black]
    colors = [
        :red, :green, :blue,
        :yellow, :purple, :cyan,
        :white, :black,
        RGBAf(1, 0, 0, 0), RGBAf(0, 1, 0, 0), RGBAf(0, 0, 1, 0),
        RGBAf(1, 0, 1, 0), RGBAf(0, 1, 1, 0), RGBAf(1, 1, 0, 0),
    ]

    markers = [
        :circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑', 'o',
    ]

    for i in eachindex(strokes)
        oc = outline_colors[i]
        strokewidth = strokes[i]
        for (j, (m, c)) in enumerate(zip(markers, colors))
            p = Point2f(i, j) .* 45
            scatter!(
                s,
                p,
                marker = m, markersize = 30, color = c,
                strokewidth = strokewidth, strokecolor = oc,
            )
        end
    end
    s
end

@reference_test "scatter with glow" begin
    s = Scene(size = (350, 700), camera = campixel!)

    # half stroke, half glow
    glows = range(4, 1, length = 7)
    outline_colors = [:red, :green, :blue, :yellow, :purple, :cyan, :black]
    colors = [
        :red, :green, :blue,
        :yellow, :purple, :cyan,
        :white, :black,
        RGBAf(1, 0, 0, 0), RGBAf(0, 1, 0, 0), RGBAf(0, 0, 1, 0),
        RGBAf(1, 0, 1, 0), RGBAf(0, 1, 1, 0), RGBAf(1, 1, 0, 0),
    ]

    markers = [
        :circle, :rect, :cross, :utriangle, :dtriangle,
        'a', 'x', 'h', 'g', 'Y', 'J', 'α', '↑', 'o',
    ]

    for i in eachindex(glows)
        oc = outline_colors[i]
        glowwidth = glows[i]
        for (j, (m, c)) in enumerate(zip(markers, colors))
            p = Point2f(i, j) .* 45
            scatter!(
                s,
                p,
                marker = m, markersize = 30, color = c,
                glowwidth = glowwidth, glowcolor = oc,
            )
        end
    end
    s
end


@reference_test "scatter image markers" begin
    pixel_types = [RGBA, RGBAf, RGBA{Float16}, ARGB, ARGB{Float16}, RGB, RGBf, RGB{Float16}]
    rotations = [ 2pi / 3 * (i - 1) for i in 1:length(pixel_types) ]
    s = Scene(size = (100 + 100 * length(pixel_types), 400), camera = campixel!)
    filename = Makie.assetpath("icon_transparent.png")
    marker_image = load(filename)
    for (i, (rot, pxtype)) in enumerate(zip(rotations, pixel_types))
        marker = convert.(pxtype, marker_image)
        p = Point2f((i - 1) * 100 + 100, 200)
        scatter!(
            s,
            p,
            marker = marker,
            markersize = 75,
            rotation = rot,
        )
    end
    s
end


@reference_test "basic polygon shapes" begin
    s = Scene(size = (800, 800), camera = campixel!)
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
            t = Transformation(scale = Vec3f(scalefactor), translation = Vec3f(1.3 * (i - 1), 1.3 * j, 0) .* scalefactor)
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
    f = Figure(size = (800, 800))
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

        # # Debug - show bbox outline
        # if !(marker isa Char)
        #     scene = Makie.get_scene(ax)
        #     bb = Makie.bbox(Makie.DEFAULT_MARKER_MAP[marker])
        #     w, h = widths(bb)
        #     ox, oy = origin(bb)
        #     xy = map(pv -> Makie.project(pv, Vec2f(widths(viewport(scene)[])), Point2f(5, i)), scene.camera.projectionview)
        #     bb = map(xy -> Rect2f(xy .+ 30 * Vec2f(ox, oy), 30 * Vec2f(w, h)), xy)
        #     lines!(bb, linewidth = 1, color = :orange, space = :pixel, linestyle = :dash)
        # end
    end

    f
end

@reference_test "BezierPath marker stroke" begin
    f = Figure(size = (800, 800))
    ax = Axis(f[1, 1])

    # Same as above
    markers = [
        :rect, :circle, :cross, :x, :utriangle, :rtriangle, :dtriangle, :ltriangle, :pentagon,
        :hexagon, :octagon, :star4, :star5, :star6, :star8, :vline, :hline, 'x', 'X',
    ]

    for (i, marker) in enumerate(markers)
        scatter!(
            Point2f.(1:5, i), marker = marker,
            markersize = range(10, 30, length = 5), color = :orange,
            strokewidth = 2, strokecolor = :black
        )
    end

    f
end


@reference_test "complex_bezier_markers" begin
    f = Figure(size = (800, 800))
    ax = Axis(f[1, 1])

    arrow = BezierPath(
        [
            MoveTo(Point(0, 0)),
            LineTo(Point(0.3, -0.3)),
            LineTo(Point(0.15, -0.3)),
            LineTo(Point(0.3, -1)),
            LineTo(Point(0, -0.9)),
            LineTo(Point(-0.3, -1)),
            LineTo(Point(-0.15, -0.3)),
            LineTo(Point(-0.3, -0.3)),
            ClosePath(),
        ]
    )

    circle_with_hole = BezierPath(
        [
            MoveTo(Point(1, 0)),
            Makie.EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
            MoveTo(Point(0.5, 0.5)),
            LineTo(Point(0.5, -0.5)),
            LineTo(Point(-0.5, -0.5)),
            LineTo(Point(-0.5, 0.5)),
            ClosePath(),
        ]
    )

    batsymbol_string = "M96.84 141.998c-4.947-23.457-20.359-32.211-25.862-13.887-11.822-22.963-37.961-16.135-22.041 6.289-3.005-1.295-5.872-2.682-8.538-4.191-8.646-5.318-15.259-11.314-19.774-17.586-3.237-5.07-4.994-10.541-4.994-16.229 0-19.774 21.115-36.758 50.861-43.694.446-.078.909-.154 1.372-.231-22.657 30.039 9.386 50.985 15.258 24.645l2.528-24.367 5.086 6.52H103.205l5.07-6.52 2.543 24.367c5.842 26.278 37.746 5.502 15.414-24.429 29.777 6.951 50.891 23.936 50.891 43.709 0 15.136-12.406 28.651-31.609 37.267 14.842-21.822-10.867-28.266-22.549-5.549-5.502-18.325-21.147-9.341-26.125 13.886z"
    batsymbol = Makie.scale(
        BezierPath(batsymbol_string, fit = true, flipy = true, bbox = Rect2f((0, 0), (1, 1)), keep_aspect = false),
        1.5
    )

    gh_string = "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
    github = BezierPath(gh_string, fit = true, flipy = true)

    two_circles_with_holes = Makie.scale(
        BezierPath(
            [
                MoveTo(Point(2.25, 0)),
                Makie.EllipticalArc(Point(1.25, 0), 1, 1, 0, 0, 2pi),
                ClosePath(),
                MoveTo(Point(-0.25, 0)),
                Makie.EllipticalArc(Point(-1.25, 0), 1, 1, 0, 0, 2pi),
                ClosePath(),
                MoveTo(Point(2, 0)),
                Makie.EllipticalArc(Point(1.25, 0), 0.75, 0.75, 0, 0, -2pi),
                ClosePath(),
                MoveTo(Point(-1, 0)),
                Makie.EllipticalArc(Point(-1.25, 0), 0.25, 0.25, 0, 0, -2pi),
                ClosePath(),
            ]
        ), 0.5
    )

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
    scatter(1:4, fill(0, 4), marker = marker, markersize = 100, color = 1:4, axis = (limits = (0, 5, -1, 1),))
end

function centered_rect(w, h)
    wh, hh = w / 2, h / 2
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

function plot_test!(scene, xoffset, yoffset, inner, reverse = true, marker = create_marker)
    bpath = marker(inner)
    p = [Point2f(xoffset, yoffset) .+ 150]
    return if reverse
        scatter!(scene, p, marker = bpath, markersize = 280, color = :black)
        scatter!(scene, p, marker = Rect, markersize = 280, color = :red)
    else
        scatter!(scene, p, marker = Rect, markersize = 280, color = :red)
        scatter!(scene, p, marker = bpath, markersize = 280, color = :black)
    end
end

function plot_row!(scene, yoffset, reverse)
    # Create differently sized cut outs, so that we have to write new values into the texture atlas!
    plot_test!(scene, 0, yoffset + 0, 0.4, reverse)
    plot_test!(scene, 300, yoffset + 0, 0.3, reverse)
    plot_test!(scene, 600, yoffset + 0, 0.4, reverse, create_rect)
    return plot_test!(scene, 900, yoffset + 0, 0.3, reverse, create_rect)
end

function draw_marker_test!(scene, marker, center; markersize = 300)
    # scatter!(scene, center, distancefield=matr, uv_offset_width=Vec4f(0, 0, 1, 1), markersize=600)
    scatter!(scene, center, color = :black, marker = marker, markersize = markersize, markerspace = :pixel)

    font = Makie.defaultfont()
    charextent = Makie.FreeTypeAbstraction.get_extent(font, marker)
    inkbb = Makie.FreeTypeAbstraction.inkboundingbox(charextent)

    # scale normalized bbox by font size
    w, h = widths(inkbb) .* markersize
    ox, oy = origin(inkbb) .* markersize
    mhalf = markersize / 2
    bbmin = center .+ Point2f(-w / 2, -h / 2)
    inkbb_scaled = Rect2f(bbmin..., w, h)

    lines!(scene, inkbb_scaled, linewidth = 5, color = :green)
    points = Point2f[(center[1], center[2] - h / 2), (center[1], center[2] + h / 2), (center[1] - w / 2, center[2]), (center[1] + w / 2, center[2])]
    linesegments!(scene, points, color = :red)

    return scene
end

@reference_test "marke glyph alignment" begin
    scene = Scene(size = (1200, 1200))
    campixel!(scene)
    # marker is in front, so it should not be smaller than the background rectangle
    plot_row!(scene, 0, false)
    # marker is in the background, so one shouldn't see a single pixel of the marker
    plot_row!(scene, 300, true)

    center = Point2f(size(scene) ./ 2)

    # Markers should be well aligned to the red cross and just about touch the green
    # boundingbox!
    draw_marker_test!(scene, 'x', Point2f(150, 750); markersize = 550)
    draw_marker_test!(scene, 'X', Point2f(450, 750); markersize = 400)
    draw_marker_test!(scene, 'I', Point2f(750, 750); markersize = 400)
    draw_marker_test!(scene, 'O', Point2f(1050, 750); markersize = 300)

    draw_marker_test!(scene, 'L', Point2f(150, 1050); markersize = 350)
    draw_marker_test!(scene, 'Y', Point2f(450, 1050); markersize = 350)
    draw_marker_test!(scene, 'y', Point2f(750, 1050); markersize = 350)
    draw_marker_test!(scene, 'u', Point2f(1050, 1050); markersize = 500)

    scene
end

@reference_test "Surface with NaN points" begin
    # This is supposed to verify a couple of things:
    # - cells with nan in positions are not drawn
    # - colors align to cell centers (via color checkerboard)
    # - all normals are valid and interpolate correctly (lighting)
    data = [x^2 + y^2 for x in range(-2, 0, length = 11), y in range(-2, 0, length = 11)]
    cs = reshape([(:red, :blue)[mod1(i, 2)] for i in eachindex(data)], size(data))

    f = Figure(size = (500, 1000), backgroundcolor = RGBf(0.3, 0.3, 0.3), figure_padding = (0, 0, 0, 0))

    # Test NaN in positions
    for i in 1:3, j in 1:2
        if j == 1
            xs = collect(1.0:11.0)
            ys = collect(1.0:11.0)
        else
            xs = Float32[x for x in 1:11, y in 1:11]
            ys = Float32[y for x in 1:11, y in 1:11]
        end
        zs = copy(data)

        # shift to second row if matrix
        if i == 1
            xs[(3:6) .+ (j - 1) * 44] .= NaN
        elseif i == 2
            ys[(3:6) .+ (j - 1) * 44] .= NaN
        elseif i == 3
            zs[4, 3:6] .= NaN
        end

        a, p = surface(f[i, j], xs, ys, zs, color = cs, nan_color = :red, axis = (show_axis = false,))
        Makie.set_ambient_light!(a.scene, RGBf(0, 0, 0))
        Makie.set_lights!(a.scene, [DirectionalLight(RGBf(2, 2, 2), Vec3f(0.5, -1, -0.8))])
        # plot a wireframe so we can see what's going on, and in which cells.
        m = Makie.surface2mesh(xs, ys, zs)
        wireframe!(a, m, depth_shift = -1.0f-3, color = RGBf(0, 0.9, 0), linewidth = 1)
    end

    # Test NaN in color
    cs = copy(data)
    cs[4, 3:6] .= NaN
    for i in 1:2
        nan_color = ifelse(i == 1, :transparent, :red)
        a, p = surface(
            f[4, i], 1 .. 11, 1 .. 11, data, color = cs, colormap = [:white, :white];
            nan_color, axis = (show_axis = false,)
        )
        Makie.set_ambient_light!(a.scene, RGBf(0, 0, 0))
        Makie.set_lights!(a.scene, [DirectionalLight(RGBf(2, 2, 2), Vec3f(0.5, -1, -0.8))])
        m = Makie.surface2mesh(to_value.(p.converted[])...)
        w = wireframe!(a, m, depth_shift = -1.0f-3, color = RGBf(0, 0.9, 0), linewidth = 1)
    end

    colgap!(f.layout, 0.0)
    rowgap!(f.layout, 0.0)

    f
end

@reference_test "Surface invert_normals" begin
    fig = Figure(size = (400, 200))
    for (i, invert) in ((1, false), (2, true))
        surface(
            fig[1, i],
            range(-1, 1, length = 21),
            -cos.(range(-pi, pi, length = 21)),
            [sin(y) for x in range(-0.5pi, 0.5pi, length = 21), y in range(-0.5pi, 0.5pi, length = 21)],
            axis = (show_axis = false,),
            invert_normals = invert
        )
    end
    fig
end

@reference_test "barplot with TeX-ed labels" begin
    fig = Figure(size = (800, 800))
    lab1 = L"\int f(x) dx"
    lab2 = lab1
    # lab2 = L"\frac{a}{b} - \sqrt{b}" # this will not work until #2667 is fixed

    barplot(fig[1, 1], [1, 2], [0.5, 0.2], bar_labels = [lab1, lab2], flip_labels_at = 0.3, direction = :x)
    barplot(fig[1, 2], [1, 2], [0.5, 0.2], bar_labels = [lab1, lab2], flip_labels_at = 0.3)

    fig
end

@reference_test "Voxel - texture mapping" begin
    texture = let
        w = RGBf(1, 1, 1)
        r = RGBf(1, 0, 0)
        g = RGBf(0, 1, 0)
        b = RGBf(0, 0, 1)
        o = RGBf(1, 1, 0)
        c = RGBf(0, 1, 1)
        m = RGBf(1, 0, 1)
        k = RGBf(0, 0, 0)
        [
            r w g w b w k w;
            w w w w w w w w;
            r k g k b k w k;
            k k k k k k k k
        ]
    end

    # Use same uvs/texture-sections for every side of one voxel id
    flat_uv_map = [
        Vec4f(x, x + 1 / 2, y, y + 1 / 4)
            for x in range(0.0, 1.0; length = 3)[1:(end - 1)]
            for y in range(0.0, 1.0; length = 5)[1:(end - 1)]
    ]

    flat_voxels = UInt8[
        1, 0, 3,
        0, 0, 0,
        2, 0, 4,
        0, 0, 0,
        0, 0, 0,
        0, 0, 0,
        5, 0, 7,
        0, 0, 0,
        6, 0, 8,
    ]

    # Reshape the flat vector into a 3D array of dimensions 3x3x3.
    voxels_3d = reshape(flat_voxels, (3, 3, 3))

    fig = Figure(; size = (800, 400))
    a1 = LScene(fig[1, 1]; show_axis = false)
    p1 = voxels!(a1, voxels_3d; uvmap = flat_uv_map, color = texture)

    # Use red for x, green for y, blue for z
    sided_uv_map = Matrix{Vec4f}(undef, 1, 6)
    sided_uv_map[1, 1:3] .= flat_uv_map[1:3]
    sided_uv_map[1, 4:6] .= flat_uv_map[5:7]

    sided_voxels = reshape(UInt8[1], 1, 1, 1)
    a2 = LScene(fig[1, 2]; show_axis = false)
    p2 = voxels!(a2, sided_voxels; uvmap = sided_uv_map, color = texture)

    fig
end

@reference_test "Voxel uvs" begin
    texture = FileIO.load(Makie.assetpath("debug_texture.png"))
    f, a, p = voxels(ones(UInt8, 3, 3, 3), uv_transform = [I], color = texture)
    st = Stepper(f)
    Makie.step!(st)
    update_cam!(a.scene, 5pi / 4, -pi / 4)
    Makie.step!(st)
    st
end

@reference_test "Voxel - colors and colormap" begin
    # test direct mapping of ids to colors & upsampling of vector colormap
    fig = Figure(size = (800, 400))
    chunk = reshape(
        UInt8[1, 0, 2, 0, 0, 0, 3, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 6, 0, 0, 0, 7, 0, 8],
        (3, 3, 3)
    )

    cs = [:white, :red, :green, :blue, :black, :orange, :cyan, :magenta]
    voxels(fig[1, 1], chunk, color = cs, axis = (show_axis = false,))
    a, p = voxels(fig[1, 2], Float32.(chunk), colormap = [:red, :blue], is_air = x -> x == 0.0, axis = (show_axis = false,))
    Makie.rotate!(p, Vec3f(1, 2, 3), 0.8)
    fig
end

@reference_test "Voxel - lowclip and highclip" begin
    # test that lowclip and highclip are visible for values just outside the colorrange
    fig = Figure(size = (800, 400))
    chunk = reshape(collect(1:900), 30, 30, 1)
    a1, _ = voxels(fig[1, 1], chunk, lowclip = :orange, highclip = :red, colorrange = (1.0, 900.0), shading = NoShading)
    a2, p = voxels(fig[1, 2], chunk, lowclip = :orange, highclip = :red, colorrange = (1.1, 899.9), shading = NoShading)
    foreach(a -> update_cam!(a.scene, Vec3f(0, 0, 35), Vec3f(0), Vec3f(0, 1, 0)), (a1, a2))
    Colorbar(fig[1, 3], p)
    fig
end

@reference_test "Voxel - gap attribute" begin
    # test direct mapping of ids to colors & upsampling of vector colormap
    voxels(RNG.rand(3, 3, 3), gap = 0.3)
end

@reference_test "Plot transform overwrite" begin
    # Tests that (primitive) plots can have different transform function
    # (identity) from their parent scene (log10, log10)
    fig = Figure()

    ax = Axis(fig[1, 1], xscale = log10, yscale = log10, backgroundcolor = :transparent)
    Makie.update!(ax.scene.compute, shading = NoShading)
    xlims!(ax, 1, 10)
    ylims!(ax, 1, 10)
    hidedecorations!(ax)

    heatmap!(ax, 0 .. 0.5, 0 .. 0.5, [i + j for i in 1:10, j in 1:10], transformation = Transformation())
    image!(ax, 0 .. 0.5, 0.5 .. 1, [i + j for i in 1:10, j in 1:10], transformation = Transformation())
    mesh!(ax, Rect2f(0.5, 0.0, 1.0, 0.25), transformation = Transformation(), color = :green)
    p = surface!(ax, 0.5 .. 1, 0.25 .. 0.75, [i + j for i in 1:10, j in 1:10], transformation = Transformation())
    translate!(p, Vec3f(0, 0, -20))
    poly!(ax, Rect2f(0.5, 0.75, 1.0, 1.0), transformation = Transformation(), color = :blue)

    lines!(ax, [0, 1], [0, 0.1], linewidth = 10, color = :red, transformation = Transformation())
    linesegments!(ax, [0, 1], [0.2, 0.3], linewidth = 10, color = :red, transformation = Transformation())
    scatter!(ax, [0.1, 0.9], [0.4, 0.5], markersize = 50, color = :red, transformation = Transformation())
    text!(ax, Point2f(0.5, 0.45), text = "Test", fontsize = 50, color = :red, align = (:center, :center), transformation = Transformation())
    meshscatter!(ax, [0.1, 0.9], [0.6, 0.7], markersize = 0.05, color = :red, transformation = Transformation())

    fig
end

@reference_test "uv_transform" begin
    fig = Figure(size = (400, 400))
    img = [RGBf(1, 0, 0) RGBf(0, 1, 0); RGBf(0, 0, 1) RGBf(1, 1, 1)]

    function create_block(f, gl, args...; kwargs...)
        ax, p = f(gl[1, 1], args..., uv_transform = I; kwargs...)
        hidedecorations!(ax)
        ax, p = f(gl[1, 2], args..., uv_transform = :rotr90; kwargs...)
        hidedecorations!(ax)
        ax, p = f(gl[2, 1], args..., uv_transform = (Vec2f(0.5), Vec2f(0.5)); kwargs...)
        hidedecorations!(ax)
        ax, p = f(gl[2, 2], args..., uv_transform = Makie.Mat{2, 3, Float32}(-1, 0, 0, -1, 1, 1); kwargs...)
        hidedecorations!(ax)
    end

    gl = fig[1, 1] = GridLayout()
    create_block(mesh, gl, Rect2f(0, 0, 1, 1), color = img)

    gl = fig[1, 2] = GridLayout()
    create_block(surface, gl, 0 .. 1, 0 .. 1, zeros(10, 10), color = img)

    gl = fig[2, 1] = GridLayout()
    create_block(
        meshscatter, gl, Point2f[(0, 0), (0, 1), (1, 0), (1, 1)], color = img,
        marker = Makie.uv_normal_mesh(Rect2f(0, 0, 1, 1)), markersize = 1.0
    )

    gl = fig[2, 2] = GridLayout()
    create_block(image, gl, 0 .. 1, 0 .. 1, img)

    fig
end

@reference_test "per element uv_transform" begin
    cow = load(assetpath("cow.png"))
    N = 8; M = 10
    f = Figure(size = (500, 400))
    a, p = meshscatter(
        f[1, 1],
        [Point2f(x, y) for x in 1:M for y in 1:N],
        color = cow,
        uv_transform = [
            Makie.uv_transform(:rotr90) *
                Makie.uv_transform(Vec2f(x, y + 1 / N), Vec2f(1 / M, -1 / N))
                for x in range(0, 1, length = M + 1)[1:M]
                for y in range(0, 1, length = N + 1)[1:N]
        ],
        markersize = Vec3f(0.9, 0.9, 1),
        marker = uv_normal_mesh(Rect2f(-0.5, -0.5, 1, 1))
    )
    hidedecorations!(a)
    xlims!(a, 0.3, M + 0.7)
    ylims!(a, 0.3, N + 0.7)
    f
end

@reference_test "Scatter with FastPixel" begin
    f = Figure()
    row = [(1, :pixel, 20), (2, :data, 0.5)]
    points3d = decompose(Point3f, Rect3(Point3f(0), Vec3f(1)))
    column = [
        (1, points3d, Axis3), (2, points3d, LScene),
        (3, 1:4, Axis),
    ]
    for (i, space, msize) in row
        for (j, data, AT) in column
            ax = AT(f[i, j])
            if ax isa Union{Axis, Axis3}
                ax isa Axis && (ax.aspect = DataAspect())
                ax.title = "$space"
            end
            scatter!(ax, data; markersize = msize, markerspace = space, marker = Makie.FastPixel())
            scatter!(
                ax, data;
                markersize = msize, markerspace = space, marker = Rect,
                strokewidth = 2, strokecolor = :red, color = :transparent,
            )
        end
    end
    f
end

@reference_test "Reverse image, heatmap and surface axes" begin
    img = [2 0 0 3; 0 0 0 0; 1 1 0 0; 1 1 0 4]

    f = Figure(size = (600, 400))
    to_tuple(x) = (first(x), last(x))
    to_tuple(x::Makie.Interval) = (Makie.leftendpoint(x), Makie.rightendpoint(x))

    for (i, interp) in enumerate((true, false))
        for (j, plot_func) in enumerate(
                (
                    (fp, x, y, cs, interp) -> image(fp, to_tuple(x), to_tuple(y), cs, colormap = :viridis, interpolate = interp),
                    (fp, x, y, cs, interp) -> heatmap(fp, x, y, cs, colormap = :viridis, interpolate = interp),
                    (fp, x, y, cs, interp) -> surface(fp, x, y, zeros(size(cs)), color = cs, colormap = :viridis, interpolate = interp, shading = NoShading),
                )
            )

            gl = GridLayout(f[i, j])

            # Test forwards + backwards for each: Tuple, Interval, Range, Vector

            a, p = plot_func(gl[1, 1], 1:4, (1, 4), img, interp)
            hidedecorations!(a)
            a, p = plot_func(gl[2, 1], [1, 2, 3, 4], 4 .. 1, img, interp)
            hidedecorations!(a)
            a, p = plot_func(gl[1, 2], 4:-1:1, 1 .. 4, img, interp)
            hidedecorations!(a)
            a, p = plot_func(gl[2, 2], (4, 1), [4, 3, 2, 1], img, interp)
            hidedecorations!(a)
        end
    end

    f
end

@reference_test "meshscatter + scatter marker conversions" begin
    fig = Figure(size = (600, 500))
    Label(fig[0, 1], tellwidth = false, "meshscatter")
    Label(fig[0, 2], tellwidth = false, "mesh")
    Label(fig[0, 3], tellwidth = false, "scatter-like")
    Label(fig[1, 0], tellheight = false, rotation = pi / 2, "simple")
    Label(fig[2, 0], tellheight = false, rotation = pi / 2, "log10")
    Label(fig[3, 0], tellheight = false, rotation = pi / 2, "float32convert")

    kwargs = (markersize = 1, transform_marker = false, shading = NoShading)
    kwargs2 = (color = Makie.wong_colors()[1], shading = NoShading)
    kwargs3 = (markerspace = :data, transform_marker = false)

    # no special transformations, must match
    limits = (0.8, 3.2, 0.8, 3.2)
    ax = Axis(fig[1, 1], limits = limits)
    meshscatter!(ax, [Point2f(2)], marker = Circle(Point2f(0), 1.0f0); kwargs...)
    ax = Axis(fig[1, 2], limits = limits)
    mesh!(ax, Circle(Point2f(2), 1.0f0); kwargs2...)
    ax = Axis(fig[1, 3], limits = limits)
    scatter!(ax, [Point2f(1.5)], marker = Circle; markersize = 0.5, kwargs3...)
    scatter!(ax, [Point2f(2.5)], marker = FastPixel(), markersize = 0.5; kwargs3...)
    text!(ax, [Point2f(2)], text = "Test", fontsize = 0.4, align = (:center, :center); kwargs3...)

    # log10 transform, center must match (meshscatter does not transform vertices
    # because that would destroy performance)
    ticks = (10.0 .^ (-0.4:0.4:0.4), [rich("10", superscript(string(x))) for x in -0.4:0.4:0.4])
    axis_kwargs = (xscale = log10, yscale = log10, xticks = ticks, yticks = ticks, limits = (0.25, 4, 0.25, 4))
    ax = Axis(fig[2, 1]; axis_kwargs...)
    meshscatter!(ax, [Point2f(1)], marker = Circle(Point2f(0), 0.5f0); kwargs...)
    ax = Axis(fig[2, 2]; axis_kwargs...)
    mesh!(ax, Circle(Point2f(1), 0.5f0); kwargs2...)
    ax = Axis(fig[2, 3]; axis_kwargs...)
    scatter!(ax, [Point2f(10^-0.4)], marker = Circle; markersize = 0.3, kwargs3...)
    scatter!(ax, [Point2f(10^0.4)], marker = FastPixel(), markersize = 0.3; kwargs3...)
    text!(ax, [Point2f(1)], text = "Test", fontsize = 0.3, align = (:center, :center); kwargs3...)

    # f32c can be applied
    ticks = (1.0e12 .+ (-1.0f6:1.0f6:1.0f6), string.(-1:1) .* ("f6",))
    axis_kwargs = (xticks = ticks, yticks = ticks, limits = 1.0e12 .+ (-1.2e6, 1.2e6, -1.2e6, 1.2e6))
    ax1 = Axis(fig[3, 1]; axis_kwargs...)
    meshscatter!(ax1, [Point2f(1.0e12)], marker = Circle(Point2f(0), 1.0f6); kwargs...)
    ax2 = Axis(fig[3, 2]; axis_kwargs...)
    mesh!(ax2, Circle(Makie.Point2d(1.0e12), 1.0e6); kwargs2...)
    ax = Axis(fig[3, 3]; axis_kwargs...)
    scatter!(ax, [Makie.Point2d(1.0e12 - 1.0e6)], marker = Circle; markersize = 3.0e5, kwargs3...)
    scatter!(ax, [Makie.Point2d(1.0e12 + 1.0e6)], marker = FastPixel(), markersize = 3.0e5; kwargs3...)
    text!(ax, [Makie.Point2d(1.0e12)], text = "Test", fontsize = 3.0e5, align = (:center, :center); kwargs3...)
    fig
end

@reference_test "meshscatter + scatter marker conversions with model" begin
    fig = Figure(size = (1000, 500))
    Label(fig[0, 1], tellwidth = false, "meshscatter")
    Label(fig[0, 2], tellwidth = false, "mesh")
    Label(fig[0, 3], tellwidth = false, "meshscatter\ntransformable")
    Label(fig[0, 4], tellwidth = false, "scatter-like")
    Label(fig[0, 5], tellwidth = false, "scatter-like\ntransformable")
    Label(fig[1, 0], tellheight = false, rotation = pi / 2, "simple")
    Label(fig[2, 0], tellheight = false, rotation = pi / 2, "log10")
    Label(fig[3, 0], tellheight = false, rotation = pi / 2, "float32convert")

    kwargs = (markersize = 1, shading = NoShading)
    kwargs2 = (color = Makie.wong_colors()[1], shading = NoShading)
    kwargs3 = (markerspace = :data, transform_marker = false)

    function transform!(p, x, rotate = true)
        scale!(p, 0.5, 0.5, 0.5)
        if rotate
            Makie.rotate!(p, pi / 2)
            translate!(p, x, 0, 0)
        else
            translate!(p, x, x, 0)
        end
    end

    # scale shrinks so left should be 2x bigger than rest
    limits = (-0.2, 2.2, -0.2, 2.2)
    ax = Axis(fig[1, 1], limits = limits)
    p1 = meshscatter!(ax, [Point2f(2)], marker = Circle(Point2f(0), 1.0f0); transform_marker = false, kwargs...)
    ax = Axis(fig[1, 2], limits = limits)
    p2 = mesh!(ax, Circle(Point2f(2), 1.0f0); kwargs2...)
    ax = Axis(fig[1, 3], limits = limits)
    p3 = meshscatter!(ax, [Point2f(2)], marker = Circle(Point2f(0), 1.0f0); transform_marker = true, kwargs...)
    ax = Axis(fig[1, 4], limits = limits)
    p4 = scatter!(ax, [Point2f(1)], marker = Circle; transform_marker = false, markersize = 0.5, kwargs3...)
    p5 = scatter!(ax, [Point2f(3)], marker = FastPixel(), transform_marker = false, markersize = 0.5; kwargs3...)
    p6 = text!(ax, [Point2f(2)], text = "Test", transform_marker = false, fontsize = 0.4, align = (:center, :center); kwargs3...)
    ax = Axis(fig[1, 5], limits = limits)
    p7 = scatter!(ax, [Point2f(1)], marker = Circle; transform_marker = true, markersize = 0.5, kwargs3...)
    p8 = scatter!(ax, [Point2f(3)], marker = FastPixel(), transform_marker = true, markersize = 0.5; kwargs3...)
    p9 = text!(ax, [Point2f(2)], text = "Test", transform_marker = true, fontsize = 0.4, align = (:center, :center); kwargs3...)

    transform!.((p1, p2, p3, p4, p5, p6, p7, p8, p9), 2)

    # center must match, left 2x bigger than right
    ticks = (10.0 .^ (-0.4:0.4:0.4), [rich("10", superscript(string(x))) for x in -0.4:0.4:0.4])
    axis_kwargs = (xscale = log10, yscale = log10, xticks = ticks, yticks = ticks, limits = (0.25, 4, 0.25, 4))
    ax = Axis(fig[2, 1]; axis_kwargs...)
    p1 = meshscatter!(ax, [Point2f(1)], marker = Circle(Point2f(0), 0.5f0); transform_marker = false, kwargs...)
    ax = Axis(fig[2, 2]; axis_kwargs...)
    p2 = mesh!(ax, Circle(Point2f(1), 0.5f0); kwargs2...)
    ax = Axis(fig[2, 3]; axis_kwargs...)
    p3 = meshscatter!(ax, [Point2f(1)], marker = Circle(Point2f(0), 0.5f0); transform_marker = true, kwargs...)
    ax = Axis(fig[2, 4]; axis_kwargs...)
    p4 = scatter!(ax, [Point2f(10^-0.8)], marker = Circle; transform_marker = false, markersize = 0.3, kwargs3...)
    p5 = scatter!(ax, [Point2f(10^0.8)], marker = FastPixel(), transform_marker = false, markersize = 0.3; kwargs3...)
    p6 = text!(ax, [Point2f(1)], text = "Test", transform_marker = false, fontsize = 0.3, align = (:center, :center); kwargs3...)
    ax = Axis(fig[2, 5]; axis_kwargs...)
    p7 = scatter!(ax, [Point2f(10^-0.8)], marker = Circle; transform_marker = true, markersize = 0.3, kwargs3...)
    p8 = scatter!(ax, [Point2f(10^0.8)], marker = FastPixel(), transform_marker = true, markersize = 0.3; kwargs3...)
    p9 = text!(ax, [Point2f(1)], text = "Test", transform_marker = true, fontsize = 0.3, align = (:center, :center); kwargs3...)

    transform!.((p1, p2, p3, p4, p5, p6, p7, p8, p9), 0)

    # center must match, left 2x bigger than rest
    ticks = (1.0e12 .+ (-10.0f5:5.0f5:10.0f5), string.(-10:5:10) .* ("f5",))
    axis_kwargs = (xticks = ticks, yticks = ticks, limits = 1.0e12 .+ (-1.2e6, 1.2e6, -1.2e6, 1.2e6))
    ax1 = Axis(fig[3, 1]; axis_kwargs...)
    p1 = meshscatter!(ax1, [Point2f(1.0e12)], marker = Circle(Point2f(0), 1.0f6); transform_marker = false, kwargs...)
    ax2 = Axis(fig[3, 2]; axis_kwargs...)
    p2 = mesh!(ax2, Circle(Makie.Point2d(1.0e12), 1.0e6); kwargs2...)
    ax3 = Axis(fig[3, 3]; axis_kwargs...)
    p3 = meshscatter!(ax3, [Point2f(1.0e12)], marker = Circle(Point2f(0), 1.0f6); transform_marker = true, kwargs...)
    ax = Axis(fig[3, 4]; axis_kwargs...)
    p4 = scatter!(ax, [Point2f(1.0e12 - 1.0e6)], marker = Circle; transform_marker = false, markersize = 6.0e5, kwargs3...)
    p5 = scatter!(ax, [Point2f(1.0e12 + 1.0e6)], marker = FastPixel(), transform_marker = false, markersize = 6.0e5; kwargs3...)
    p6 = text!(ax, [Point2f(1.0e12)], text = "Test", transform_marker = false, fontsize = 6.0e5, align = (:center, :center); kwargs3...)
    ax = Axis(fig[3, 5]; axis_kwargs...)
    p7 = scatter!(ax, [Point2f(1.0e12 - 1.0e6)], marker = Circle; transform_marker = true, markersize = 6.0e5, kwargs3...)
    p8 = scatter!(ax, [Point2f(1.0e12 + 1.0e6)], marker = FastPixel(), transform_marker = true, markersize = 6.0e5; kwargs3...)
    p9 = text!(ax, [Point2f(1.0e12)], text = "Test", transform_marker = true, fontsize = 6.0e5, align = (:center, :center); kwargs3...)

    transform!.((p1, p2, p3, p4, p5, p6, p7, p8, p9), 5.0e11, false)

    fig
end

@reference_test "scatter marker_offset 2D" begin
    fig = Figure(size = (450, 500))
    ax = Axis(fig[1, 1])
    xlims!(ax, -6.5, 6.5); ylims!(ax, -10, 10)
    ax.xticks[] = (-5:2:5, ["BezierPath", "Circle", "Rect", "Char", "FastPixel", "Image"])
    ax.yticks[] = ([-7.5, -2.75, 2.25, 7.25], [":pixel", ":data", ":relative", ":clip"])
    ax.yticklabelrotation[] = pi / 2

    img = [RGBf(r, 0.7, b) for r in range(0, 1, length = 4), b in range(0, 1, length = 4)]
    rect_corners = Point2f[(-0.5, -0.5), (-0.5, 0.5), (0.5, 0.5), (0.5, -0.5), (-0.5, -0.5), (NaN, NaN)]

    for (y, offset, space, markersize) in [
            (-8.5, (0, 0), :pixel, 40), (-5.5, (0, -20), :pixel, 40),
            (-4, (0, 0), :data, 1.8), (-0.5, (0, -1), :data, 1.8),
            (+1, (0, 0), :relative, 0.1), (+4.5, (0, -0.05), :relative, 0.1),
            (+6, (0, 0), :clip, 0.2), (+9.5, (0, -0.1), :clip, 0.2),
        ]

        # Generate scatter plots with different marker types
        kwargs = (markerspace = space, markersize = markersize, marker_offset = offset)
        scatter!(ax, Point2f(-5, y), marker = :ltriangle; kwargs...)
        scatter!(ax, Point2f(-3, y), marker = Circle; kwargs...)
        scatter!(ax, Point2f(-1, y), marker = Rect; kwargs...)
        scatter!(ax, Point2f(1, y), marker = 'x'; kwargs...)
        if space in (:data, :pixel)
            scatter!(ax, Point2f(3, y), marker = FastPixel(); kwargs...)
        end
        scatter!(ax, Point2f(5, y), marker = img; kwargs...)

        # Generate outlines (transform to markerspace, generate rect based on markersize, add offset)
        xs = space in (:data, :pixel) ? (-5:2:5) : [-5, -3, -1, 1, 5]
        transformed = map(Point2f.(xs, y)) do pos
            pos_ms = Makie.project(ax.scene, :data, space, pos)[Vec(1, 2)]
            rect_ps = [pos_ms .+ markersize .* xy .+ offset for xy in rect_corners]
            return rect_ps
        end
        p = lines!(ax, vcat(transformed...), color = :black, linewidth = 2, space = space)
    end

    fig
end

# Above without FastPixel since FastPixel doesn't rotate
@reference_test "scatter marker_offset 2D with billboarded rotation" begin
    fig = Figure(size = (450, 500))
    ax = Axis(fig[1, 1])
    xlims!(ax, -6.5, 6.5); ylims!(ax, -10, 10)
    ax.xticks[] = (-5:2.5:5, ["BezierPath", "Circle", "Rect", "Char", "Image"])
    ax.yticks[] = ([-7.5, -2.75, 2.25, 7.25], [":pixel", ":data", ":relative", ":clip"])
    ax.yticklabelrotation[] = pi / 2

    img = [RGBf(r, 0.7, b) for r in range(0, 1, length = 4), b in range(0, 1, length = 4)]
    rotation = 0.3f0
    rect_corners = [Point2f(cos(a), sin(a)) ./ sqrt(2) for a in (range(0.0, 2pi, length = 5) .+ pi / 4 .+ rotation)]
    push!(rect_corners, Point2f(NaN))

    for (y, offset, space, markersize) in [
            (-8.5, (0, 0), :pixel, 40), (-5.5, (0, -20), :pixel, 40),
            (-4, (0, 0), :data, 1.8), (-0.5, (0, -1), :data, 1.8),
            (+1, (0, 0), :relative, 0.1), (+4.5, (0, -0.05), :relative, 0.1),
            (+6, (0, 0), :clip, 0.2), (+9.5, (0, -0.1), :clip, 0.2),
        ]

        # Generate scatter plots with different marker types
        kwargs = (markerspace = space, markersize = markersize, marker_offset = offset, rotation = rotation)
        scatter!(ax, Point2f(-5, y), marker = :ltriangle; kwargs...)
        scatter!(ax, Point2f(-2.5, y), marker = Circle; kwargs...)
        scatter!(ax, Point2f(0, y), marker = Rect; kwargs...)
        scatter!(ax, Point2f(2.5, y), marker = 'x'; kwargs...)
        scatter!(ax, Point2f(5, y), marker = img; kwargs...)

        # Generate outlines (transform to markerspace, generate rect based on markersize, add offset)
        transformed = map(Point2f.(-5:2.5:5, y)) do pos
            pos_ms = Makie.project(ax.scene, :data, space, pos)[Vec(1, 2)]
            rect_ps = [pos_ms .+ markersize .* xy .+ offset for xy in rect_corners]
            return rect_ps
        end
        p = lines!(ax, vcat(transformed...), color = :black, linewidth = 2, space = space)
    end

    fig
end

@reference_test "scatter marker_offset 3D with rotation" begin
    fig = Figure(size = (500, 400))
    ax = LScene(fig[1, 1], show_axis = false)
    update_cam!(ax.scene, Vec3f(12), Vec3f(1, 2, -2))
    cameracontrols(ax).settings.center[] = false

    img = [RGBf(r, 0.7, b) for r in range(0, 1, length = 4), b in range(0, 1, length = 4)]
    rotation = qrotation(Vec3f(1), 0.8)
    rect_corners = Point2f[(-0.5, -0.5), (-0.5, 0.5), (0.5, 0.5), (0.5, -0.5), (-0.5, -0.5), (NaN, NaN)]

    for (y, offset, space, markersize) in [
            (-8.5, (0, 0, 0), :pixel, 20), (-6, (0, -10, 0), :pixel, 20),
            (-2, (0, 0, 0), :data, 1.5), (1, (0, -1, 0), :data, 1.5),
            (+3, (0, 0, 0), :relative, 0.05), (+4.5, (0, -0.025, 0), :relative, 0.05),
            (+8, (0, 0, 0), :clip, 0.1), (+9, (0, -0.05, 0), :clip, 0.1),
        ]

        # Generate scatter plots with different marker types
        kwargs = (markerspace = space, markersize = markersize, marker_offset = offset, rotation = rotation)
        scatter!(ax, Point2f(-5, y), marker = :ltriangle; kwargs...)
        scatter!(ax, Point2f(-2.5, y), marker = Circle; kwargs...)
        scatter!(ax, Point2f(0, y), marker = Rect; kwargs...)
        scatter!(ax, Point2f(2.5, y), marker = 'x'; kwargs...)
        scatter!(ax, Point2f(5, y), marker = img; kwargs...)

        # Generate outlines (transform to markerspace, generate rect based on markersize, add offset)
        transformed = map(ax.scene.camera.projectionview) do _
            transformed = map(Point3f.(-5:2.5:5, y, 0)) do pos
                pos_ms = Makie.project(ax.scene, :data, space, pos) .+ offset
                rect_ps = [pos_ms .+ rotation * to_ndim(Vec3f, markersize .* xy, 0) for xy in rect_corners]

                return rect_ps
            end
            vcat(transformed...)
        end
        p = lines!(ax, transformed, color = :black, linewidth = 2, space = space, depth_shift = -5.0f-2)
    end

    fig
end

@reference_test "Scatter fonts" begin
    scene = Scene(size = (150, 150), camera = campixel!)

    # Just needs to not be Fira Mona here, but good to test the default too
    @test Makie.to_font(Makie.automatic) == Makie.to_font("TeX Gyre Heros Makie")

    scatter!(scene, (40, 40), marker = Rect, markersize = 45, color = :black, strokecolor = :red, strokewidth = 1)
    scatter!(scene, (40, 40), marker = '◇', markersize = 45, color = :white)
    scatter!(scene, (110, 40), marker = Rect, markersize = 45, color = :green, strokecolor = :red, strokewidth = 1)
    text!(scene, (110, 40), text = "◇", fontsize = 45, align = (:center, :center), color = :white)

    scatter!(scene, (40, 110), marker = Rect, font = "Fira Mono", markersize = 45, color = :black, strokecolor = :red, strokewidth = 1)
    scatter!(scene, (40, 110), marker = '◇', font = "Fira Mono", markersize = 45, color = :white)
    scatter!(scene, (110, 110), marker = Rect, font = "Fira Mono", markersize = 45, color = :green, strokecolor = :red, strokewidth = 1)
    text!(scene, (110, 110), text = "◇", font = "Fira Mono", fontsize = 45, align = (:center, :center), color = :white)

    scene
end

@reference_test "Subpixel Scatter" begin
    scene = Scene(size = (100, 100), camera = campixel!)
    scatter!(scene, [(x, y) for x in 0:50  for y in 0:50 ], markersize = 0.0, color = :black, marker = Rect)
    scatter!(scene, [(x, y) for x in 0:50  for y in 51:100], markersize = 0.4, color = :black, marker = Rect)
    scatter!(scene, [(x, y) for x in 51:100 for y in 0:50 ], markersize = 0.7, color = :black, marker = Rect)
    scatter!(scene, [(x, y) for x in 51:100 for y in 51:100], markersize = 1.0, color = :black, marker = Rect)
    scene
end

@reference_test "Anisotropic markers" begin
    scene = Scene(size = (250, 250))
    scatter!(
        scene,
        [-0.5, -0.5, -0.5], [-0.5, 0.5, 0],
        marker = :rect, markersize = [Vec2f(50, 10), Vec2f(10, 50), Vec2f(50)]
    )
    scatter!(scene, 0, +0.5, markersize = (50, 10))
    scatter!(scene, 0, 0.0, markersize = 50)
    scatter!(scene, 0, -0.5, markersize = (10, 50))
    scatter!(scene, 0.5, 0.5, marker = 'o', markersize = 50)
    scatter!(scene, 0.5, 0, marker = 'L', markersize = 50, rotation = Quaternionf(0.3, 0.7, 0.5, 0.2))
    scatter!(scene, 0.5, -0.5, marker = 'L', markersize = (20, 100), rotation = Quaternionf(0.3, 0.7, 0.5, 0.2), color = :black)
    scene
end

@reference_test "transformed surface" begin
    xs = [cos(phi) * cos(theta) for phi in range(0, 2pi, length = 21), theta in range(0, pi / 2, length = 11)]
    ys = [sin(phi) * cos(theta) for phi in range(0, 2pi, length = 21), theta in range(0, pi / 2, length = 11)]
    zs = [sin(theta) for phi in range(0, 2pi, length = 21), theta in range(0, pi / 2, length = 11)]

    f = Figure(size = (500, 500))
    for i in 1:2
        for j in 1:2
            a = LScene(f[i, j], show_axis = false)
            p1 = surface!(a, xs, ys, zs, colormap = [:white, :white])
            p2 = meshscatter!(a, Point3f.(xs, ys, zs)[:], markersize = 0.03, color = :white, shading = NoShading)
            if j == 2
                for p in (p1, p2)
                    Makie.rotate!(p, Vec3f(0, 0, 1), pi)
                    scale!(p, Vec3f(1.2, 1.2, 0.6))
                end
            end
        end
    end
    f.content[3].scene.transformation.transform_func[] = p -> -p
    f.content[4].scene.transformation.transform_func[] = p -> -p

    # make lighting more sensitive to normals
    for a in f.content
        update!(a.scene.plots[1], diffuse = Vec3f(0.5, -0.2, 1.5), specular = Vec3f(0.75, 1.25, -1))
        set_ambient_light!(a, RGBf(0, 0, 0))
        set_directional_light!(a, color = RGBf(1, 1, 1), direction = Vec3f(0, 0, -1))
    end

    f
end
