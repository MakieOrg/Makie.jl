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
    # all points of the polygons of a legend element
    legend_points(ps::AbstractVector{<:Point}) = ps
    legend_points(polygons) = reduce(vcat, [vcat(p.exterior, p.interiors...) for p in polygons])
    # extent of legend element polygons in pixels, given the patchsize
    xrange(ps, w = 20) = w .* Vec2f(extrema(first.(legend_points(ps))))
    yrange(ps, h = 20) = h .* Vec2f(extrema(last.(legend_points(ps))))

    f, a, p = arrows2d([0.0, 0.0], [1.0, 1.0], label = "arrow", color = :blue)
    leg = axislegend(a)
    els = arrow_legend_elements(leg)
    # tail, shaft and tip
    @test length(els) == 3
    @test all(el -> el isa PolyElement, els)
    @test all(el -> el.polycolor[] == RGBAf(0, 0, 1, 1), els)
    @test all(el -> el.plots == [p], els)
    tail, shaft, tip = [el.polypoints[] for el in els]
    # The tail is not drawn by default and collapses to a point
    @test allequal(legend_points(tail))
    # The arrow spans the patch horizontally, at the default size in pixels
    # for an arrow of 20 pixels length: shaftwidth = 3, tiplength = 8, tipwidth = 14
    @test xrange(shaft) ≈ Vec2f(0, 12)
    @test yrange(shaft) ≈ Vec2f(8.5, 11.5)
    @test xrange(tip) ≈ Vec2f(12, 20)
    @test yrange(tip) ≈ Vec2f(3, 17)
    @test Point2f(1, 0.5) in legend_points(tip)

    # separate component colors and a tail
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow",
        tailcolor = :orange, shaftcolor = :green, tipcolor = :red, taillength = 4, tiplength = 6
    )
    leg = axislegend(a)
    els = arrow_legend_elements(leg)
    @test [el.polycolor[] for el in els] == RGBAf[Makie.to_color(:orange), Makie.to_color(:green), Makie.to_color(:red)]
    tail, shaft, tip = [el.polypoints[] for el in els]
    @test xrange(tail)[2] ≈ 4
    @test xrange(shaft) ≈ Vec2f(4, 14)
    @test xrange(tip) ≈ Vec2f(14, 20)

    # numeric scalar colors are colormapped, alpha is included
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow", alpha = 0.5,
        color = 0.5, colormap = [:black, :white], colorrange = (0, 1)
    )
    els = arrow_legend_elements(axislegend(a))
    @test all(el -> el.polycolor[] ≈ RGBAf(0.5, 0.5, 0.5, 0.5), els)

    # per-arrow colors can't be represented and fall back to the default
    f, a, p = arrows2d(rand(Point2f, 2), rand(Vec2f, 2), label = "arrow", color = [:red, :blue])
    leg = axislegend(a)
    els = arrow_legend_elements(leg)
    @test all(el -> el.polycolor[] == leg.polycolor[], els)

    # legend overrides apply to all components
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow" => (; color = :red), color = :blue)
    els = arrow_legend_elements(axislegend(a))
    @test all(el -> el.polycolor[] == :red, els)

    # non-square patches stretch the arrow length, not its width
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow")
    els = arrow_legend_elements(axislegend(a, patchsize = (40, 20)))
    @test xrange(els[2].polypoints[], 40) ≈ Vec2f(0, 32)
    @test yrange(els[3].polypoints[]) ≈ Vec2f(3, 17)

    # the legend follows changes of the plot
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow", color = :blue)
    els = arrow_legend_elements(axislegend(a))
    p.tipcolor = :red
    p.tipwidth = 10
    @test els[2].polycolor[] == RGBAf(0, 0, 1, 1)
    @test els[3].polycolor[] == RGBAf(1, 0, 0, 1)
    @test yrange(els[3].polypoints[]) ≈ Vec2f(5, 15)
    # components that are no longer drawn collapse to a point
    p.tiplength = 0
    @test allequal(legend_points(els[3].polypoints[]))
    @test xrange(els[2].polypoints[]) ≈ Vec2f(0, 20)
    # and show up again when they are enabled later
    p.tiplength = 8
    @test xrange(els[2].polypoints[]) ≈ Vec2f(0, 12)
    @test xrange(els[3].polypoints[]) ≈ Vec2f(12, 20)
    p.taillength = 4
    p.tiplength = 6
    @test xrange(els[1].polypoints[])[2] ≈ 4

    # custom shapes keep their structure, e.g. holes or disconnected parts
    ring = Point2f[(0, -0.5), (1, -0.5), (1, 0.5), (0, 0.5)]
    hole = Point2f[(0.25, -0.25), (0.75, -0.25), (0.75, 0.25), (0.25, 0.25)]
    dashes = merge([Makie.poly_convert(Rect2f(0, -0.5, 0.4, 1)), Makie.poly_convert(Rect2f(0.6, -0.5, 0.4, 1))])
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow", taillength = 4, tiplength = 6,
        tail = (l, w, metrics) -> Polygon(ring .* Point2f(l, w), [hole .* Point2f(l, w)]),
        shaft = dashes, tip = Polygon(ring, [hole])
    )
    els = arrow_legend_elements(axislegend(a))
    tail, shaft, tip = [el.polypoints[] for el in els]
    tail_polygon = only(tail)
    @test length(tail_polygon.interiors) == 1
    @test xrange(tail_polygon.exterior) ≈ Vec2f(0, 4)
    @test xrange(tail_polygon.interiors[1]) ≈ Vec2f(1, 3)
    # meshes are converted to their outline
    @test length(shaft) == 2
    @test all(polygon -> length(polygon.exterior) == 4, shaft)
    @test xrange(shaft) ≈ Vec2f(4, 14)
    @test !any(p -> 8 + 1.0e-3 < 20 * p[1] < 10 - 1.0e-3, legend_points(shaft))
    tip_polygon = only(tip)
    @test length(tip_polygon.interiors) == 1
    @test xrange(tip_polygon.exterior) ≈ Vec2f(14, 20)
    @test yrange(tip_polygon.interiors[1]) ≈ Vec2f(6.5, 13.5)

    # other geometries supported by the plot work as well
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow",
        shaft = Tessellation(Circle(Point2f(0.5, 0), 0.5f0), 64),
        tip = GeometryBasics.Triangle(Point2f(0, -0.5), Point2f(1, 0), Point2f(0, 0.5))
    )
    els = arrow_legend_elements(axislegend(a))
    @test isapprox(xrange(els[2].polypoints[]), Vec2f(0, 12), atol = 0.1)
    @test xrange(els[3].polypoints[]) ≈ Vec2f(12, 20)
    @test yrange(els[3].polypoints[]) ≈ Vec2f(3, 17)

    # the legend follows changes of the shape type
    f, a, p = arrows2d([Point2f(0)], [Vec2f(1)], label = "arrow")
    els = arrow_legend_elements(axislegend(a))
    p.tip = Polygon(ring, [hole])
    @test length(only(els[3].polypoints[]).interiors) == 1
    p.shaft = dashes
    @test length(els[2].polypoints[]) == 2
    p.shaft = Rect2f(0, -0.5, 1, 1)
    @test length(els[2].polypoints[]) == 1

    # shape functions of components that are not drawn are not called
    f, a, p = arrows2d(
        [Point2f(0)], [Vec2f(1)], label = "arrow",
        tail = (l, w, metrics) -> l > 0 ? Point2f[(0, -0.5w), (l, 0), (0, 0.5w)] : error("tail is not drawn")
    )
    els = arrow_legend_elements(axislegend(a))
    @test allequal(legend_points(els[1].polypoints[]))
end

@testset "arrows2d legend mesh outlines" begin
    # Meshes are drawn by their outline in legends, to avoid seams between triangles
    outline(shape) = Makie._arrow_polygons(Makie.poly_convert(shape))
    merged(shapes...) = merge([Makie.poly_convert(shape) for shape in shapes])
    # area as given by the outlines and as drawn after triangulation, e.g. by GLMakie
    function area(polygons)
        return sum(polygons) do polygon
            return abs(Makie._signed_area(polygon.exterior)) - sum(ring -> abs(Makie._signed_area(ring)), polygon.interiors; init = 0.0)
        end
    end
    function check_area(polygons, expected)
        return isapprox(area(polygons), expected, rtol = 1.0e-5) &&
            isapprox(Makie._triangulated_area(polygons), expected, rtol = 1.0e-5)
    end
    ring = Point2f[(0, -0.5), (1, -0.5), (1, 0.5), (0, 0.5)]
    hole = Point2f[(0.25, -0.25), (0.75, -0.25), (0.75, 0.25), (0.25, 0.25)]
    island = Point2f[(0.4, -0.1), (0.6, -0.1), (0.6, 0.1), (0.4, 0.1)]

    polygons = outline(Rect2f(0, -0.5, 1, 1))
    @test sort(only(polygons).exterior) == sort(ring)
    @test isempty(only(polygons).interiors)
    @test check_area(polygons, 1)

    polygons = outline(Polygon(ring, [hole]))
    @test sort(only(polygons).exterior) == sort(ring)
    @test sort(only(only(polygons).interiors)) == sort(hole)
    @test check_area(polygons, 0.75)

    # merged meshes duplicate vertices, an island inside a hole is a separate polygon
    polygons = Makie._arrow_polygons(merged(Polygon(ring, [hole]), island))
    @test length(polygons) == 2
    @test sort([length(polygon.interiors) for polygon in polygons]) == [0, 1]
    @test check_area(polygons, 0.79)

    # components touching at a vertex are kept as separate rings
    polygons = Makie._arrow_polygons(merged(Rect2f(0, 0, 1, 1), Rect2f(1, 1, 1, 1)))
    @test length(polygons) == 2
    @test all(polygon -> length(polygon.exterior) == 4, polygons)
    @test check_area(polygons, 2)
    polygons = Makie._arrow_polygons(merged(Point2f[(0, 0), (1, 0), (1, 1)], Point2f[(1, 1), (2, 1), (2, 2)], Point2f[(1, 1), (0, 2), (0, 1)]))
    @test length(polygons) == 3
    @test check_area(polygons, 1.5)

    # a hole touching the exterior at a vertex
    polygons = outline(Polygon(ring, [Point2f[(0, 0), (0.5, -0.25), (0.5, 0.25)]]))
    @test check_area(polygons, 0.875)

    # filled components inside others are not holes
    polygons = Makie._arrow_polygons(merged(Rect2f(0, 0, 1, 1), Rect2f(0.4, 0.4, 0.2, 0.2)))
    @test length(polygons) == 2
    @test all(polygon -> isempty(polygon.interiors), polygons)
    @test check_area(polygons, 1.04)

    # duplicate triangles have no consistent outline and are kept as triangles
    polygons = Makie._arrow_polygons(merged(Rect2f(0, 0, 1, 1), Rect2f(0, 0, 1, 1)))
    @test length(polygons) == 4
    @test all(polygon -> length(polygon.exterior) == 3, polygons)
    @test check_area(polygons, 2)

    @test Makie._point_in_ring(Point2f(0.5, 0), ring)
    @test !Makie._point_in_ring(Point2f(0.5, 0), hole .+ Point2f(1, 0))
    @test Makie._signed_area(ring) ≈ 1
    @test Makie._signed_area(reverse(ring)) ≈ -1
end
