@reference_test "lines and linestyles" begin
    s = Scene(size = (800, 800), camera = campixel!)
    scalar = 30
    points = Point2f[(1, 1), (1, 2), (2, 3), (2, 1)]
    linestyles = [
        :solid, :dash, :dot, :dashdot, :dashdotdot,
        Linestyle([1, 2, 3]), Linestyle([1, 2, 4, 5])
    ]
    for linewidth in 1:10
        for (i, linestyle) in enumerate(linestyles)
            lines!(s,
                scalar .* (points .+ Point2f(linewidth*2, i * 3.25)),
                linewidth = linewidth,
                linestyle = linestyle,
                color=:black
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
    s
end

# A test case for wide lines and mitering at joints
@reference_test "Miter Joints for line rendering" begin
    scene = Scene()
    cam2d!(scene)
    r = 4
    sep = 4*r
    scatter!(scene, (sep+2*r)*[-1,-1,1,1], (sep+2*r)*[-1,1,-1,1])

    for i=-1:1
        for j=-1:1
            angle = pi/2 + pi/4*i
            x = r*[-cos(angle/2),0,-cos(angle/2)]
            y = r*[-sin(angle/2),0,sin(angle/2)]

            linewidth = 40 * 2.0^j
            lines!(scene, x .+ sep*i, y .+ sep*j, color=RGBAf(0,0,0,0.5), linewidth=linewidth)
            lines!(scene, x .+ sep*i, y .+ sep*j, color=:red)
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
        push!(ps, ps[end] + r * R * normalize(ps[end] - ps[end-1]))
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

#@reference_test "Miter Limit"
begin
    ps = [Point2f(0, -0.5), Point2f(1, -0.5)]
    for phi in [160, -130, 121, 50, 119, -90] # these are 180-miter_angle
        R = Makie.Mat2f(cosd(phi), sind(phi), -sind(phi), cosd(phi))
        push!(ps, ps[end] + (1 + 0.2 * (phi == 50)) * R * normalize(ps[end] - ps[end-1]))
    end
    popfirst!(ps) # for alignment, removes 160° corner

    fig = Figure(size = (400, 400))
    ax = Axis(fig[1, 1], aspect = DataAspect())
    hidedecorations!(ax)
    xlims!(-2.7, 2.4)
    ylims!(-2.5, 2.5)
    lines!(
        ax, ps .+ Point2f(-1.2, -1.2), linewidth = 20, miter_limit = 51pi/180, color = :black,
        joinstyle = :round
    )
    lines!(
        ax, ps .+ Point2f(+1.2, -1.2), linewidth = 20, miter_limit = 129pi/180, color = :black,
        joinstyle = :bevel
    )
    lines!(ax, ps .+ Point2f(-1.2, +1.2), linewidth = 20, miter_limit = 51pi/180, color = :black)
    lines!(ax, ps .+ Point2f(+1.2, +1.2), linewidth = 20, miter_limit = 129pi/180, color = :black)

    fig
end

@reference_test "Lines from outside" begin
    # This tests that lines that start or end in clipped regions are still
    # rendered correctly. For perspective projections this can be tricky as
    # points behind the camera get projected beyond far.
    lps = let
        ps1 = [Point3f(x, 0.2 * (z+1), z) for x in (-8, 0, 8) for z in (-9, -1, -1, 7)]
        ps2 = [Point3f(x, 0.2 * (z+1), z) for z in (-9, -1, 7) for x in (-8, 0, 0, 8)]
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

@reference_test "lines issue #3704" begin
    lines(1:10, sin, color = [fill(0, 9); fill(1, 1)], linewidth = 3, colormap = [:red, :cyan])
end

@reference_test "scatters" begin
    s = Scene(size = (800, 800), camera = campixel!)

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
                color=:black
            )
        end
    end
    s
end

@reference_test "scatter rotations" begin
    s = Scene(size = (800, 800), camera = campixel!)

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
                rotation = rot,
                color=:black
            )
            scatter!(s, p, color = :red, markersize = 6)
        end
    end
    s
end

@reference_test "scatter with stroke" begin
    s = Scene(size = (350, 700), camera = campixel!)

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
    s = Scene(size = (350, 700), camera = campixel!)

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
    s = Scene(size = (100+100*length(pixel_types), 400), camera = campixel!)
    filename = Makie.assetpath("icon_transparent.png")
    marker_image = load(filename)
    for (i, (rot, pxtype)) in enumerate(zip(rotations, pixel_types))
        marker = convert.(pxtype, marker_image)
        p = Point2f((i-1) * 100 + 100, 200)
        scatter!(s,
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
        :hexagon, :octagon, :star4, :star5, :star6, :star8, :vline, :hline, 'x', 'X'
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
        Makie.EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
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
    scatter!(scene, center, color=:black, marker=marker, markersize=markersize, markerspace=:pixel)

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
    scene = Scene(size=(1200, 1200))
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
    zs = [x^2 + y^2 for x in range(-2, 0, length=10), y in range(-2, 0, length=10)]
    ns = copy(zs)
    ns[4, 3:6] .= NaN
    # plot surface
    f, a, p = surface(1..10, 1..10, ns, colormap = [:lightblue, :lightblue])
    # plot a wireframe so we can see what's going on, and in which cells.
    m = Makie.surface2mesh(to_value.(p.converted)...)
    scatter!(a, m.position, color = isnan.(m.normals), depth_shift = -1f-3)
    wireframe!(a, m, depth_shift = -1f-3, color = :black)
    f
end

@reference_test "barplot with TeX-ed labels" begin
    fig = Figure(size = (800, 800))
    lab1 = L"\int f(x) dx"
    lab2 = lab1
    # lab2 = L"\frac{a}{b} - \sqrt{b}" # this will not work until #2667 is fixed

    barplot(fig[1,1], [1, 2], [0.5, 0.2], bar_labels = [lab1, lab2], flip_labels_at = 0.3, direction=:x)
    barplot(fig[1,2], [1, 2], [0.5, 0.2], bar_labels = [lab1, lab2], flip_labels_at = 0.3)

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
        [r w g w b w k w;
         w w w w w w w w;
         r k g k b k w k;
         k k k k k k k k]
    end

    # Use same uvs/texture-sections for every side of one voxel id
    flat_uv_map = [Vec4f(x, x + 1 / 2, y, y + 1 / 4)
                   for x in range(0.0, 1.0; length=3)[1:(end - 1)]
                   for y in range(0.0, 1.0; length=5)[1:(end - 1)]]

    flat_voxels = UInt8[1, 0, 3,
                        0, 0, 0,
                        2, 0, 4,
                        0, 0, 0,
                        0, 0, 0,
                        0, 0, 0,
                        5, 0, 7,
                        0, 0, 0,
                        6, 0, 8]

    # Reshape the flat vector into a 3D array of dimensions 3x3x3.
    voxels_3d = reshape(flat_voxels, (3, 3, 3))

    fig = Figure(; size=(800, 400))
    a1 = LScene(fig[1, 1]; show_axis=false)
    p1 = voxels!(a1, voxels_3d; uvmap=flat_uv_map, color=texture)

    # Use red for x, green for y, blue for z
    sided_uv_map = Matrix{Vec4f}(undef, 1, 6)
    sided_uv_map[1, 1:3] .= flat_uv_map[1:3]
    sided_uv_map[1, 4:6] .= flat_uv_map[5:7]

    sided_voxels = reshape(UInt8[1], 1, 1, 1)
    a2 = LScene(fig[1, 2]; show_axis=false)
    p2 = voxels!(a2, sided_voxels; uvmap=sided_uv_map, color=texture)

    fig
end

@reference_test "Voxel - colors and colormap" begin
    # test direct mapping of ids to colors & upsampling of vector colormap
    fig = Figure(size = (800, 400))
    chunk = reshape(UInt8[1, 0, 2, 0, 0, 0, 3, 0, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 5, 0, 6, 0, 0, 0, 7, 0, 8],
                    (3, 3, 3))

    cs = [:white, :red, :green, :blue, :black, :orange, :cyan, :magenta]
    voxels(fig[1, 1], chunk, color = cs, axis=(show_axis = false,))
    a, p = voxels(fig[1, 2], Float32.(chunk), colormap = [:red, :blue], is_air = x -> x == 0.0, axis=(show_axis = false,))
    fig
end

@reference_test "Voxel - lowclip and highclip" begin
    # test that lowclip and highclip are visible for values just outside the colorrange
    fig = Figure(size = (800, 400))
    chunk = reshape(collect(1:900), 30, 30, 1)
    a1, _ = voxels(fig[1,1], chunk, lowclip = :red, highclip = :red, colorrange = (1.0, 900.0), shading = NoShading)
    a2, _ = voxels(fig[1,2], chunk, lowclip = :red, highclip = :red, colorrange = (1.1, 899.9), shading = NoShading)
    foreach(a -> update_cam!(a.scene, Vec3f(0, 0, 40), Vec3f(0), Vec3f(0,1,0)), (a1, a2))
    fig
end

@reference_test "Voxel - gap attribute" begin
    # test direct mapping of ids to colors & upsampling of vector colormap
    voxels(RNG.rand(3,3,3), gap = 0.3)
end

@reference_test "Plot transform overwrite" begin
    # Tests that (primitive) plots can have different transform function to their
    # parent scene (identity in this case)
    fig = Figure()

    ax = Axis(fig[1, 1], xscale = log10, yscale = log10, backgroundcolor = :transparent)
    xlims!(ax, 1, 10)
    ylims!(ax, 1, 10)
    empty!(ax.scene.lights)
    hidedecorations!(ax)

    heatmap!(ax, 0..0.5, 0..0.5, [i+j for i in 1:10, j in 1:10], transformation = Transformation())
    image!(ax, 0..0.5, 0.5..1, [i+j for i in 1:10, j in 1:10], transformation = Transformation())
    mesh!(ax, Rect2f(0.5, 0.0, 1.0, 0.25), transformation = Transformation(), color = :green)
    p = surface!(ax, 0.5..1, 0.25..0.75, [i+j for i in 1:10, j in 1:10], transformation = Transformation())
    translate!(p, Vec3f(0, 0, -20))
    poly!(ax, Rect2f(0.5, 0.75, 1.0, 1.0), transformation = Transformation(), color = :blue)

    lines!(ax, [0, 1], [0, 0.1], linewidth = 10, color = :red, transformation = Transformation())
    linesegments!(ax, [0, 1], [0.2, 0.3], linewidth = 10, color = :red, transformation = Transformation())
    scatter!(ax, [0.1, 0.9], [0.4, 0.5], markersize = 50, color = :red, transformation = Transformation())
    text!(ax, Point2f(0.5, 0.45), text = "Test", fontsize = 50, color = :red, align = (:center, :center), transformation = Transformation())
    meshscatter!(ax, [0.1, 0.9], [0.6, 0.7], markersize = 0.05, color = :red, transformation = Transformation())

    fig
end
