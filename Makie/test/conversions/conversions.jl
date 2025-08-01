using Makie:
    to_vertices,
    categorical_colors,
    (..)
using Makie: plotfunc, plotfunc!, func2type

@testset "Conversions" begin
    # NoConversion
    struct NoConversionTestType end
    conversion_trait(::NoConversionTestType) = NoConversion()

    let nctt = NoConversionTestType(),
            ncttt = conversion_trait(nctt)
        @test convert_arguments(ncttt, 1, 2, 3) == (1, 2, 3)
    end

end

@testset "Heatmapshader with ranges" begin
    hm = Heatmap(((0, 1), (0, 1), Resampler(zeros(4, 4))), Dict{Symbol, Any}())
    @test hm.converted[][1] isa Makie.EndPoints{Float32}
    @test hm.converted[][2] isa Makie.EndPoints{Float32}
    @test hm.converted[][3].data == Resampler(zeros(4, 4)).data
end

@testset "changing input types" begin
    input = Observable{Any}(decompose(Point2f, Circle(Point2f(0), 2.0f0)))
    f, ax, pl = mesh(input)
    m = Makie.triangle_mesh(Circle(Point2f(0), 1.0f0))
    input[] = m
    @test pl[1][] == m
end

@testset "to_vertices" begin
    X1 = [Point(rand(3)...) for i in 1:10]
    V1 = to_vertices(X1)
    @test (X1[7][1]) == V1[7][1]

    X2 = [tuple(rand(3)...) for i in 1:10]
    V2 = to_vertices(X2)
    @test (X2[7][1]) == V2[7][1]
    X4 = rand(2, 10)
    V4 = to_vertices(X4)
    @test (X4[1, 7]) == V4[7][1]

    X5 = rand(3, 10)
    V5 = to_vertices(X5)
    @test (X5[1, 7]) == V5[7][1]

    X6 = rand(10, 2)
    V6 = to_vertices(X6)
    @test (X6[7, 1]) == V6[7][1]

    X7 = rand(10, 3)
    V7 = to_vertices(X7)
    @test (X7[7, 1]) == V7[7][1]

    # I dont like this, but this was the original behavior
    # AND it stopped working because of type unstable code,
    # so I guess its worth it
    @test Makie.to_vertices(fill(0, (0, 3))) == Point{3, Float64}[]
end

@testset "GeometryBasics Lines & Polygons" begin
    pts = [Point(1, 2), Point(4, 5), Point(10, 8), Point(1, 2)]
    ls = LineString(pts)
    p = convert_arguments(Makie.PointBased(), ls)
    @test p[1] == pts

    pts_empty = Point2f[]
    ls_empty = LineString(pts_empty)
    p_empty = convert_arguments(Makie.PointBased(), ls_empty)
    @test p_empty[1] == pts_empty

    pts1 = [Point(5, 2), Point(4, 8), Point(2, 8), Point(5, 2)]
    ls1 = LineString(pts1)
    lsa = [ls, ls1]
    p1 = convert_arguments(Makie.PointBased(), lsa)
    @test p1[1][1:4] == pts
    @test p1[1][6:9] == pts1

    mls = MultiLineString(lsa)
    p2 = convert_arguments(Makie.PointBased(), mls)
    @test p2[1][1:4] == pts
    @test p2[1][6:9] == pts1

    mls_emtpy = MultiLineString([LineString(pts_empty)])
    p_empty = convert_arguments(Makie.PointBased(), mls_emtpy)
    @test p_empty[1] == pts_empty

    pol_e = Polygon(ls)
    p3_e = convert_arguments(Makie.PointBased(), pol_e)
    @test p3_e[1][1:end] == pts # for poly we repeat last point

    pol = Polygon(ls, [ls1])
    p3 = convert_arguments(Makie.PointBased(), pol)
    @test p3[1][1:4] == pts
    @test p3[1][6:9] == pts1

    pol_emtpy = Polygon(pts_empty)
    p_empty = convert_arguments(Makie.PointBased(), pol_emtpy)
    @test p_empty[1] == pts_empty

    pts2 = Point{2, Int}[(5, 1), (3, 3), (4, 8), (1, 2), (5, 1)]
    pts3 = Point{2, Int}[(2, 2), (2, 3), (3, 4), (2, 2)]
    pts4 = Point{2, Int}[(2, 2), (3, 8), (5, 6), (3, 4), (2, 2)]
    ls2 = LineString(pts2)
    ls3 = LineString(pts3)
    ls4 = LineString(pts4)
    pol1 = Polygon(ls2, [ls3, ls4])
    apol = [pol, pol1]
    p4 = convert_arguments(Makie.PointBased(), apol)
    mpol = MultiPolygon([pol, pol1])
    @test p4[1][1:4] == pts
    @test p4[1][6:9] == pts1
    @test p4[1][11:15] == pts2
    @test p4[1][17:20] == pts3
    @test p4[1][22:end] == pts4

    mpol_emtpy = MultiPolygon(typeof(pol_emtpy)[])
    p_empty = convert_arguments(Makie.PointBased(), mpol_emtpy)
    @test p_empty[1] == pts_empty
end

@testset "MultiPoint" begin
    x = MultiPoint(rand(Point2f, 100))
    f, ax, pl = plot(x)
    @test pl.converted[][1] == x.points
    f, ax, pl = plot([x, x])
    @test pl.converted[][1] == [x.points; x.points]
end

@testset "intervals" begin
    x = [1, 5, 10]
    y = [1 .. 2, 1 .. 3, 2 .. 3]
    @test convert_arguments(Band, x, y) == (Point2f.([1, 5, 10], [1, 1, 2]), Point2f.([1, 5, 10], [2, 3, 3]))
    @test convert_arguments(Rangebars, x, y) == (Vec3f.([1, 5, 10], [1, 1, 2], [2, 3, 3]),)
    @test convert_arguments(HSpan, 1 .. 2) == (1, 2)
    @test convert_arguments(VSpan, 1 .. 2) == (1, 2)
    @test convert_arguments(HSpan, y) == ([1, 1, 2], [2, 3, 3])
    @test convert_arguments(VSpan, y) == ([1, 1, 2], [2, 3, 3])
end

@testset "functions" begin
    x = -pi .. pi
    (xy,) = convert_arguments(Lines, x, sin)
    @test xy[1][1] ≈ -pi
    @test xy[end][1] ≈ pi
    for (val, fval) in xy
        @test fval ≈ sin(val) atol = 1.0f-6
    end

    x = range(-pi, stop = pi, length = 100)
    (xy,) = convert_arguments(Lines, x, sin)
    @test xy[1][1] ≈ -pi
    @test xy[end][1] ≈ pi
    for (val, fval) in xy
        @test fval ≈ sin(val) atol = 1.0f-6
    end
end

using Makie: check_line_pattern, line_diff_pattern

@testset "Linetype" begin
    @test isnothing(check_line_pattern("-."))
    @test isnothing(check_line_pattern("--"))
    @test_throws ArgumentError check_line_pattern("-.*")

    # for readability, the length of dash and dot
    dash, dot = 3.0, 1.0

    @test line_diff_pattern(:dash) ==
        line_diff_pattern("-", :normal) == [dash, 3.0]
    @test line_diff_pattern(:dot) ==
        line_diff_pattern(".", :normal) == [dot, 2.0]
    @test line_diff_pattern(:dashdot) ==
        line_diff_pattern("-.", :normal) == [dash, 3.0, dot, 3.0]
    @test line_diff_pattern(:dashdotdot) ==
        line_diff_pattern("-..", :normal) == [dash, 3.0, dot, 2.0, dot, 3.0]

    @test line_diff_pattern(:dash, :loose) == [dash, 6.0]
    @test line_diff_pattern(:dot, :loose) == [dot, 4.0]
    @test line_diff_pattern("-", :dense) == [dash, 2.0]
    @test line_diff_pattern(".", :dense) == [dot, 1.0]
    @test line_diff_pattern(:dash, 0.5) == [dash, 0.5]
    @test line_diff_pattern(:dot, 0.5) == [dot, 0.5]
    @test line_diff_pattern("-", (0.4, 0.6)) == [dash, 0.6]
    @test line_diff_pattern(:dot, (0.4, 0.6)) == [dot, 0.4]
    @test line_diff_pattern("-..", (0.4, 0.6)) == [dash, 0.6, dot, 0.4, dot, 0.6]

    # gaps must be Symbol, a number, or two numbers
    @test_throws ArgumentError line_diff_pattern(:dash, :NORMAL)
    @test_throws ArgumentError line_diff_pattern(:dash, ())
    @test_throws ArgumentError line_diff_pattern(:dash, (1, 2, 3))
end

struct MyVector{T}
    v::Vector{T}
end

struct MyNestedVector{T}
    v::MyVector{T}
end

@testset "single conversions" begin
    myvector = MyVector(collect(1:10))
    mynestedvector = MyNestedVector(MyVector(collect(11:20)))
    @test convert_arguments(Lines, myvector, mynestedvector) ===
        (myvector, mynestedvector)

    Makie.convert_single_argument(v::MyNestedVector) = v.v
    Makie.convert_single_argument(v::MyVector) = v.v

    @test convert_arguments(Lines, myvector, mynestedvector) == (Point2f.(1:10, 11:20),)

    @test isequal(
        convert_arguments(Lines, [1, missing, 2]),
        (Point2f[(1, 1), (2, NaN), (3, 2)],)
    )

    @test isequal(
        convert_arguments(Lines, [Point(1, 2), missing, Point(3, 4)]),
        (Point2f[(1.0, 2.0), (NaN, NaN), (3.0, 4.0)],)
    )
    x = Any[]
    @test x === Makie.convert_single_argument(x) # should not be converted (and also not stackoverflow!)
end

@testset "categorical colors" begin
    @test categorical_colors([to_color(:red)], 1) == [to_color(:red)]
    @test categorical_colors([:red], 1) == [to_color(:red)]
    @test_throws ErrorException categorical_colors([to_color(:red)], 2)
    @test categorical_colors(:darktest, 1) == to_color.(Makie.PlotUtils.palette(:darktest))[1:1]
    @test_throws ErrorException to_colormap(:viridis, 10) # deprecated
    @test categorical_colors(:darktest, 1) == to_color.(Makie.PlotUtils.palette(:darktest))[1:1]
    @test categorical_colors(:viridis, 10) == to_colormap(:viridis)[1:10]
    # TODO why don't they exactly match?
    @test categorical_colors(:Set1, 9) ≈ to_colormap(:Set1)

    @test_throws ArgumentError Makie.categorical_colors(:PuRd, 20) # not enough categories
end

@testset "resample colormap" begin
    cs = Makie.resample_cmap(:viridis, 10; alpha = LinRange(0, 1, 10))
    @test Colors.alpha.(cs) == Float32.(LinRange(0, 1, 10))
    cs = Makie.resample_cmap(:viridis, 2; alpha = 0.5)
    @test all(x -> x == 0.5, Colors.alpha.(cs))
    @test Colors.color.(cs) == Colors.color.(Makie.resample(to_colormap(:viridis), 2))
    cs = Makie.resample_cmap(:Set1, 100)
    @test all(x -> x == 1.0, Colors.alpha.(cs))
    @test Colors.color.(cs) == Colors.color.(Makie.resample(to_colormap(:Set1), 100))
    cs = Makie.resample_cmap(:Set1, 10; alpha = (0, 1))
    @test Colors.alpha.(cs) == Float32.(LinRange(0, 1, 10))
end

@testset "heatmap from three vectors" begin
    x = [2, 1, 2]
    y = [2, 3, 3]
    z = [1, 2, 3]
    xx, yy, zz = convert_arguments(Heatmap, x, y, z)
    @test xx == Float32[0.5, 1.5, 2.5]
    @test yy == Float32[1.5, 2.5, 3.5]
    @test isequal(zz, [NaN 2; 1 3])

    x = [1, 2]
    @test_throws ErrorException convert_arguments(Heatmap, x, y, z)
    x = copy(y)
    @test_throws ErrorException convert_arguments(Heatmap, x, y, z)
    x = [NaN, 1, 2]
    @test_throws ErrorException convert_arguments(Heatmap, x, y, z)
end

@testset "to_colormap" begin
    @test to_colormap([HSL(0, 10, 20)]) isa Vector{RGBAf}
    @test to_colormap([:red, :green]) isa Vector{RGBAf}
    @test to_colormap([(:red, 0.1), (:green, 0.2)]) isa Vector{RGBAf}
    @test to_colormap((:viridis, 0.1)) isa Vector{RGBAf}
    @test to_colormap(Reverse(:viridis)) isa Vector{RGBAf}
    @test to_colormap(:cividis) isa Vector{RGBAf}
    @test to_colormap(cgrad(:cividis, 8, categorical = true)) isa Vector{RGBAf}
    @test to_colormap(cgrad(:cividis, 8)) isa Vector{RGBAf}
    @test to_colormap(cgrad(:cividis)) isa Vector{RGBAf}
    @test alpha(to_colormap(cgrad(:cividis, 8; alpha = 0.5))[1]) == 0.5
    @test alpha(to_colormap(cgrad(:cividis, 8; alpha = 0.5, categorical = true))[1]) == 0.5


    @inferred to_colormap([HSL(0, 10, 20)])
    @inferred to_colormap([:red, :green])
    @inferred to_colormap([(:red, 0.1), (:green, 0.2)])
    @inferred to_colormap((:viridis, 0.1))
    @inferred to_colormap(Reverse(:viridis))
    @inferred to_colormap(:cividis)
    @inferred to_colormap(cgrad(:cividis, 8, categorical = true))
    @inferred to_colormap(cgrad(:cividis, 8))
    @inferred to_colormap(cgrad(:cividis))
    @inferred to_colormap(cgrad(:cividis, 8; alpha = 0.5))
    @inferred to_colormap(cgrad(:cividis, 8; alpha = 0.5, categorical = true))
end


@testset "empty poly" begin
    # Geometry Primitive
    f, ax, pl = poly(Rect2f[])
    pl[1] = [Rect2f(0, 0, 1, 1)]
    @test pl.plots[1].arg1[] == [GeometryBasics.triangle_mesh(Rect2f(0, 0, 1, 1))]

    # Empty Polygon
    f, ax, pl = poly(Polygon(Point2f[]))
    pl[1] = Polygon(Point2f[(1, 0), (1, 1), (0, 1)])
    @test pl.plots[1].arg1[] == GeometryBasics.triangle_mesh(pl[1][])

    f, ax, pl = poly(Polygon[])
    pl[1] = [Polygon(Point2f[(1, 0), (1, 1), (0, 1)])]
    @test pl.plots[1].arg1[] == GeometryBasics.triangle_mesh.(pl[1][])

    # PointBased inputs
    f, ax, pl = poly(Point2f[])
    points = decompose(Point2f, Circle(Point2f(0), 1))
    pl[1] = points
    @test pl.plots[1].arg1[] == Makie.poly_convert(points)

    f, ax, pl = poly(Vector{Point2f}[])
    pl[1] = [points]
    @test pl.plots[1].arg1[][1] == Makie.poly_convert(points)
end

@testset "Poly with matrix" begin
    x1 = [0.0, 1, 1, 0, 0]
    y1 = [0.0, 0, 1, 1, 0]
    @test convert_arguments(Poly, hcat(x1, y1))[1] == Point.(x1, y1)
end

@testset "GridBased and ImageLike conversions" begin
    # type tree
    @test GridBased <: ConversionTrait
    @test CellGrid <: GridBased
    @test VertexGrid <: GridBased
    @test ImageLike <: ConversionTrait

    # Plot to trait
    @test conversion_trait(Image) === ImageLike()
    @test conversion_trait(Heatmap) === CellGrid()
    @test conversion_trait(Surface) === VertexGrid()
    @test conversion_trait(Contour) === VertexGrid()
    @test conversion_trait(Contourf) === VertexGrid()

    m1 = [x for x in 1:10, y in 1:6]
    m2 = [y for x in 1:10, y in 1:6]
    m3 = rand(10, 6)

    r1 = 1:10
    r2 = 1:6

    v1 = collect(1:10)
    v2 = collect(1:6)
    v3 = reverse(v1)

    i1 = 1 .. 10
    i2 = 1 .. 6
    i3 = 10 .. 1

    o3 = Float32.(m3)

    t1 = (1, 10)
    t2 = (1, 6)

    xx = convert_arguments(Image, m3)
    xx == ((0.0f0, 10.0f0), (0.0f0, 6.0f0), o3)
    @testset "ImageLike conversion" begin
        @test convert_arguments(Image, m3) == ((0.0f0, 10.0f0), (0.0f0, 6.0f0), o3)
        @test convert_arguments(Image, i1, i2, m3) == ((1.0, 10.0), (1.0, 6.0), o3)
        @test convert_arguments(Image, i1, t2, m3) == ((1.0, 10.0), (1.0, 6.0), o3)
        @test convert_arguments(Image, t1, t2, m3) == ((1.0, 10.0), (1.0, 6.0), o3)

        @test_throws ErrorException convert_arguments(Image, v1, r2, m3)
        @test_throws ErrorException convert_arguments(Image, i1, v2, m3)
        @test_throws ErrorException convert_arguments(Image, v3, i1, m3)
        @test_throws ErrorException convert_arguments(Image, v1, i3, m3)

        # TODO: Should probably fail because it's not accepted by backends?
        @test convert_arguments(Image, m1, m2, m3) === (m1, m2, m3)
    end

    @testset "VertexGrid conversion" begin
        vo1 = Float32.(v1)
        vo2 = Float32.(v2)
        mo1 = Float32.(m1)
        mo2 = Float32.(m2)
        @test convert_arguments(Surface, m3) == (vo1, vo2, o3)
        @test convert_arguments(Contour, i1, v2, m3) == (vo1, vo2, o3)
        @test convert_arguments(Contourf, v1, r2, m3) == (vo1, vo2, o3)
        @test convert_arguments(Surface, m1, m2, m3) == (mo1, mo2, o3)
        @test convert_arguments(Surface, m1, m2) == (mo1, mo2, zeros(Float32, size(o3)))
    end

    @testset "CellGrid conversion" begin
        @test convert_arguments(Heatmap, m1, m2) === (m1, m2)
        o1 = (0.5, 10.5)
        o2 = (0.5, 6.5)
        or1 = (0.5:1:10.5)
        or2 = (0.5:1:6.5)
        convert_arguments(Heatmap, m3)
        Makie.expand_dimensions(CellGrid(), m3)
        @test convert_arguments(Heatmap, m3) == (o1, o2, o3)
        @test convert_arguments(Heatmap, r1, i2, m3) == (or1, or2, o3)
        @test convert_arguments(Heatmap, v1, r2, m3) == (or1, or2, o3)
        @test convert_arguments(Heatmap, 0:10, v2, m3) == (collect(0.0f0:10.0f0), or2, o3)
        # TODO, this throws ERROR: MethodError: no method matching adjust_axes(::CellGrid, ::Matrix{Int64}, ::Matrix{Int64}, ::Matrix{Float64})
        # Is this what we want to test for?
        @test_throws MethodError convert_arguments(Heatmap, m1, m2, m3) === (m1, m2, m3)
        @test convert_arguments(Heatmap, m1, m2) === (m1, m2)
        # https://github.com/MakieOrg/Makie.jl/issues/3515
        @test convert_arguments(Heatmap, 1:8, 1:8, Array{Union{Float64, Missing}}(zeros(8, 8))) ==
            (0.5:8.5, 0.5:8.5, zeros(8, 8))
    end
    @testset "1 length arrays" begin
        ranges = [((1, 1), (1, 3)), ((1, 3), (1, 1)), ((1, 1), (1, 1))]
        for (x, y) in ranges
            data = zeros(x[2] - x[1] + 1, y[2] - y[1] + 1)
            args = [(data,), (x, y, data), (x[1] .. x[2], y[1] .. y[2], data)]
            res = ((x[1] - 0.5, x[2] + 0.5), (y[1] - 0.5, y[2] + 0.5), data)
            for arg in args
                @test convert_arguments(Heatmap, data) == res
            end
        end
    end
end

@testset "Triplot" begin
    xs = rand(Float32, 10)
    ys = rand(Float32, 10)
    ps = Point2f.(xs, ys)

    @test convert_arguments(Triplot, xs, ys)[1] == ps
    @test convert_arguments(Triplot, ps)[1] == ps

    f, a, p = triplot(xs, ys)
    tri = p.plots[1][1][]
    @test tri.points ≈ ps
end

@testset "Voronoiplot" begin
    xs = rand(Float32, 10)
    ys = rand(Float32, 10)
    ps = Point2f.(xs, ys)

    @test convert_arguments(Voronoiplot, xs, ys)[1] == ps
    @test convert_arguments(Voronoiplot, ps)[1] == ps

    f, a, p = voronoiplot(xs, ys)
    tess = p.plots[1][1][]
    @test Point2f[tess.generators[i] for i in 1:10] ≈ ps

    # Heatmap style signatures
    xs = rand(Float32, 10)
    ys = rand(Float32, 10)
    zs = rand(Float32, 10, 10)

    @test convert_arguments(Voronoiplot, zs)[1] == Point3f.(1:10, (1:10)', zs)[:]
    @test convert_arguments(Voronoiplot, xs, ys, zs)[1] == Point3f.(xs, ys', zs)[:]

    # color sorting
    zs = [exp(-(x - y)^2) for x in LinRange(-1, 1, 10), y in LinRange(-1, 1, 10)]
    fig, ax, sc = voronoiplot(1:10, 1:10, zs, markersize = 10, strokewidth = 3)
    ps = [Point2f(x, y) for x in 1:10 for y in 1:10]
    vorn = Makie.DelTri.voronoi(Makie.DelTri.triangulate(ps))
    sc2 = voronoiplot!(vorn, color = zs, markersize = 10, strokewidth = 3)

    for plot in (sc.plots[1], sc2)
        polycols = plot.plots[1].color[]
        polys = plot.plots[1][1][]
        cs = zeros(10, 10)
        for (p, c) in zip(polys, polycols)
            # calculate center of poly, round to indices
            i, j = clamp.(round.(Int, sum(p.exterior) / length(p.exterior)), 1, 10)
            cs[i, j] = c
        end

        @test isapprox(cs, zs, rtol = 1.0e-6)
    end
end

@testset "align conversions" begin
    for (val, halign) in zip((0.0f0, 0.5f0, 1.0f0), (:left, :center, :right))
        @test Makie.halign2num(halign) == val
    end
    @test_throws ErrorException Makie.halign2num(:bottom)
    @test_throws ErrorException Makie.halign2num("center")
    @test Makie.halign2num(0.73) == 0.73f0

    for (val, valign) in zip((0.0f0, 0.5f0, 1.0f0), (:bottom, :center, :top))
        @test Makie.valign2num(valign) == val
    end
    @test_throws ErrorException Makie.valign2num(:right)
    @test_throws ErrorException Makie.valign2num("center")
    @test Makie.valign2num(0.23) == 0.23f0

    @test Makie.to_align((:center, :bottom)) == Vec2f(0.5, 0.0)
    @test Makie.to_align((:right, 0.3)) == Vec2f(1.0, 0.3)

    for angle in 4pi .* rand(10)
        s, c = sincos(angle)
        @test Makie.angle2align(angle) ≈ Vec2f(0.5c, 0.5s) ./ max(abs(s), abs(c)) .+ Vec2f(0.5)
    end
    # sanity checks
    @test isapprox(Makie.angle2align(pi / 4), Vec2f(1, 1), atol = 1.0e-12)
    @test isapprox(Makie.angle2align(5pi / 4), Vec2f(0, 0), atol = 1.0e-12)
end

@testset "func-Plot conversions" begin
    @test plotfunc(scatter) === scatter
    @test plotfunc(hist!) === hist
    @test plotfunc(ScatterLines) === scatterlines
    @test plotfunc!(mesh) === mesh!
    @test plotfunc!(ablines!) === ablines!
    @test plotfunc!(Image) === image!
    @test func2type(lines) == Lines
    @test func2type(hexbin!) == Hexbin
end

@testset "Dendrogram" begin
    xs = 1:10
    ys = rand(10)
    merges = [(i, i + 1) for i in 1:20]
    @test Makie.convert_arguments(Dendrogram, xs, ys, merges) == Makie.convert_arguments(Dendrogram, Point2.(xs, ys), merges)
end
