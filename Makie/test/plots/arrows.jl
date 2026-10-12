@testset "arrows - Colorbar" begin
    # Test for:
    # https://github.com/MakieOrg/Makie.jl/issues/3273
    directions = decompose(Point2f, Circle(Point2f(0), 1))
    points = decompose(Point2f, Circle(Point2f(0), 0.5))
    color = range(0, 1, length = length(directions))
    fig, ax, pl = arrows2d(points, directions; color = color)
    cbar = Colorbar(fig[1, 2], pl)
    @test cbar.limits[] == Vec2f(0, 1)
    pl.colorrange = (0.5, 0.6)
    @test cbar.limits[] ≈ Vec2f(0.5, 0.6)
end

@testset "arrows in scaled world" begin
    # https://github.com/MakieOrg/Makie.jl/issues/5711
    onenorm(v) = norm(v) ≈ 1

    ps = rand(Point3f, 5)
    vs = [0.1 .+ rand(Vec3f) for _ in 1:5] #
    f, a, p = arrows3d(ps, vs)
    @testset "unscaled" begin
        @test !all(onenorm.(vs))
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = true
        @test all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "scaled (model)" begin
        scale!(p, 1, 2, 3)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = false
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "model reset/unscaled" begin
        scale!(p, 1, 1, 1)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = true
        @test all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "transform_func scaled" begin
        a.scene.transformation.transform_func[] = Makie.PointTrans{3}(p -> (1.0f0, 2.0f0, 3.0f0) .* p)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = false
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end
end

@testset "arrows color flattening" begin
    cs = 1:8
    f, a, p = arrows3d(rand(2, 4), rand(2, 4), rand(8), rand(8), color = reshape(cs, (2, 4)))
    @test p.resolved_tailcolor[] == cs
    @test p.resolved_shaftcolor[] == cs
    @test p.resolved_tipcolor[] == cs

    f, a, p = arrows2d(
        rand(2), rand(4), p -> rand(Vec2f),
        color = reshape(cs, (2, 4)),
        tailcolor = 4:12, shaftcolor = reshape(8:-1:1, (2, 4))
    )
    @test p.resolved_tailcolor[] == 4:12
    @test p.resolved_shaftcolor[] == 8:-1:1
    @test p.resolved_tipcolor[] == cs

    f, a, p = arrows3d(
        rand(Point3f, 6), rand(Vec3f, 1, 2, 3),
        tipcolor = reshape(1:6, (1, 2, 3)),
        tailcolor = 4:10,
        shaftcolor = reshape(6:-1:1, (1, 2, 3))
    )
    @test p.resolved_tailcolor[] == 4:10
    @test p.resolved_shaftcolor[] == 6:-1:1
    @test p.resolved_tipcolor[] == 1:6
end

@testset "arrows2d with scalar numeric color" begin
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], color = 0.5, colormap = [:black, :white], colorrange = (0, 1))
    @test p.calculated_shaftcolor[] isa RGBAf
    @test p.calculated_tipcolor[] ≈ RGBAf(0.5, 0.5, 0.5, 1)
    @test p.scaled_colorrange[] == Vec2f(0, 1)
end

@testset "arrows2d legend" begin
    # https://github.com/MakieOrg/Makie.jl/issues/4873 (2D part)
    # https://github.com/MakieOrg/Makie.jl/issues/5780
    # https://github.com/MakieOrg/Makie.jl/issues/5527
    function arrow_legend_elements(leg, i = 1)
        return leg.entrygroups[][1][2][i].elements
    end
    # extent of legend element polygons in pixels, given the patchsize
    xrange(ps, w = 20) = w .* Vec2f(extrema(first.(ps)))
    yrange(ps, h = 20) = h .* Vec2f(extrema(last.(ps)))

    f, a, p = arrows2d([0.0, 0.0], [1.0, 1.0], label = "arrow", color = :blue)
    leg = axislegend(a)
    els = arrow_legend_elements(leg)
    # one element combines tail, shaft and tip
    @test length(els) == 1
    el = only(els)
    @test el isa PolyElement
    @test el.polycolor[] == [:blue, :blue, :blue]
    @test el.plots == [p]
    tail, shaft, tip = el.poly[]
    # The tail is not drawn by default and collapses to a point
    @test isempty(faces(tail))
    # The arrow spans the patch horizontally, at the default size in pixels
    # for an arrow of 20 pixels length: shaftwidth = 3, tiplength = 8, tipwidth = 14
    @test Rect3f(shaft) ≈ Rect3f(0, 8.875, 0, 12, 2.25, 0)
    @test Rect3f(tip) ≈ Rect3f(12, 3.375, 0, 8, 13.25, 0)

    # separate component colors and a tail
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow",
        tailcolor = :orange, shaftcolor = :green, tipcolor = :red, taillength = 4, tiplength = 6
    )
    leg = axislegend(a)
    el = only(arrow_legend_elements(leg))
    @test el.polycolor[] == [:orange, :green, :red]
    tail, shaft, tip = el.poly[]
    @test Rect3f(tail) ≈ Rect3f(-3.975, 3.375, 0, 7.975, 13.25, 0)
    @test Rect3f(shaft) ≈ Rect3f(4.0, 8.875, 0.0, 10.0, 2.25, 0.0)
    @test Rect3f(tip) ≈ Rect3f(14.0, 3.375, 0.0, 6.0, 13.25, 0.0)

    # numeric scalar colors are colormapped, alpha is included
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow", alpha = 0.5,
        color = 0.5, colormap = [:black, :white], colorrange = (0, 1)
    )
    el = only(arrow_legend_elements(axislegend(a)))
    @test el.polycolor[] ≈ [0.5, 0.5, 0.5]

    # per-arrow colors can't be represented and fall back to the default
    f, a, p = arrows2d(rand(Point2f, 2), rand(Vec2f, 2), label = "arrow", color = [:red, :blue])
    leg = axislegend(a)
    el = only(arrow_legend_elements(leg))
    @test el.polycolor[] == [leg.polycolor[] for _ in 1:3]

    # legend overrides apply to all components
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow" => (; color = :red), color = :blue)
    el = only(arrow_legend_elements(axislegend(a)))
    @test el.polycolor[] == :red

    # non-square patches stretch the arrow length, not its width
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow")
    el = only(arrow_legend_elements(axislegend(a, patchsize = (40, 20))))
    tail, shaft, tip = el.poly[]
    @test Rect3f(shaft) ≈ Rect3f(0.0, 8.875, 0.0, 32.0, 2.25, 0.0)
    @test Rect3f(tip) ≈ Rect3f(32.0, 3.375, 0.0, 8.0, 13.25, 0.0)

    # the legend follows changes of the plot
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow", color = :blue)
    el = only(arrow_legend_elements(axislegend(a)))
    p.tipcolor = :red
    p.tipwidth = 10
    @test el.polycolor[] == [:blue, :blue, :red]
    tail, shaft, tip = el.poly[]
    @test Rect3f(tip) ≈ Rect3f(12.0, 5.375, 0.0, 8.0, 9.25, 0.0)
    # components that are no longer drawn collapse to a point
    p.tiplength = 0
    tail, shaft, tip = el.poly[]
    @test isempty(faces(tip))
    @test Rect3f(shaft) ≈ Rect3f(0, 8.875, 0, 20, 2.25, 0)
    # and show up again when they are enabled later
    p.tiplength = 8
    tail, shaft, tip = el.poly[]
    @test Rect3f(shaft) ≈ Rect3f(0, 8.875, 0, 12, 2.25, 0)
    @test Rect3f(tip) ≈ Rect3f(12.0, 5.375, 0.0, 8.0, 9.25, 0.0)
    p.taillength = 4
    p.tiplength = 6
    tail, shaft, tip = el.poly[]
    @test Rect3f(tail) ≈ Rect3f(-3.975, 3.375, 0, 7.975, 13.25, 0)

    # custom shapes given by a single outline are used, also from functions
    diamond = Point2f[(0, 0), (0.5, -0.5), (1, 0), (0.5, 0.5)]
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow", taillength = 4, tiplength = 6,
        tail = (l, w, metrics) -> Point2f[(0, -0.5w), (l, 0), (0, 0.5w)],
        shaft = Rect2f(0, -0.25, 1, 0.5), tip = diamond, strokemask = 0
    )
    el = only(arrow_legend_elements(axislegend(a)))
    tail, shaft, tip = el.poly[]
    @test tail.position ≈ Point3f[(0, 3, 0), (4, 10, 0), (0, 17, 0)]
    @test Rect3f(shaft) ≈ Rect3f(4, 9.25, 0, 10, 1.5, 0)
    @test tip.position ≈ Point3f[(14, 10, 0), (17, 3, 0), (20, 10, 0), (17, 17, 0)]

    # other shapes are replaced by the default shapes
    ring = Point2f[(0, -0.5), (1, -0.5), (1, 0.5), (0, 0.5)]
    hole = Point2f[(0.25, -0.25), (0.75, -0.25), (0.75, 0.25), (0.25, 0.25)]
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow", tip = Polygon(ring, [hole]), strokemask = 0)
    el = only(arrow_legend_elements(axislegend(a)))
    ps = GeometryBasics.mesh(Polygon(ring, [hole])).position
    @test Point2f.(el.poly[][3].position) ≈ [(8, 14) .* p .+ Point2f(12, 10) for p in ps]
    # also after changes of the shape type
    p.tip = Point2f[(0, -0.5), (1, -0.5), (0.5, 0.5)]
    @test el.poly[][3].position ≈ Point3f[(12, 3, 0), (20, 3, 0), (16, 17, 0)]
    p.tip = Makie.poly_convert(ring)
    @test el.poly[][3].position ≈ Point3f[(12, 3, 0), (20, 3, 0), (20, 17, 0), (12, 17, 0)]

    # shape functions of components that are not drawn are not called
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow",
        tail = (l, w, metrics) -> l > 0 ? Point2f[(0, -0.5w), (l, 0), (0, 0.5w)] : error("tail is not drawn")
    )
    el = only(arrow_legend_elements(axislegend(a)))
    @test isempty(faces(el.poly[][1]))
end
