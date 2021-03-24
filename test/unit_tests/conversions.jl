using AbstractPlotting: 
    NoConversion, 
    convert_arguments, 
    conversion_trait,
    to_vertices

using StaticArrays

@testset "Conversions" begin

    # NoConversion
    struct NoConversionTestType end
    conversion_trait(::NoConversionTestType) = NoConversion()

    let nctt = NoConversionTestType(), 
        ncttt = conversion_trait(nctt)
        @test convert_arguments(ncttt, 1, 2, 3) == (1, 2, 3)
    end

end

@testset "to_vertices" begin
    X1 = [Point(rand(3)...) for i = 1:10]
    V1 = to_vertices(X1)
    @test Float32(X1[7][1]) == V1[7][1]

    X2 = [tuple(rand(3)...) for i = 1:10]
    V2 = to_vertices(X2)
    @test Float32(X2[7][1]) == V2[7][1]

    X3 = [SVector(rand(3)...) for i = 1:10]
    V3 = to_vertices(X3)
    @test Float32(X3[7][1]) == V3[7][1]

    X4 = rand(2,10)
    V4 = to_vertices(X4)
    @test Float32(X4[1,7]) == V4[7][1]
    @test V4[7][3] == 0

    X5 = rand(3,10)
    V5 = to_vertices(X5)
    @test Float32(X5[1,7]) == V5[7][1]

    X6 = rand(10,2)
    V6 = to_vertices(X6)
    @test Float32(X6[7,1]) == V6[7][1]
    @test V6[7][3] == 0

    X7 = rand(10,3)
    V7 = to_vertices(X7)
    @test Float32(X7[7,1]) == V7[7][1]
end

@testset "functions" begin
    x = -pi..pi
    s = convert_arguments(Lines, x, sin)
    xy = s.args[1]
    @test xy[1][1] ≈ -pi
    @test xy[end][1] ≈ pi
    for (val, fval) in xy
        @test fval ≈ sin(val) atol=1f-6
    end

    x = range(-pi, stop=pi, length=100)
    s = convert_arguments(Lines, x, sin)
    xy = s.args[1]
    @test xy[1][1] ≈ -pi
    @test xy[end][1] ≈ pi
    for (val, fval) in xy
        @test fval ≈ sin(val) atol=1f-6
    end

    pts = [Point(1, 2), Point(4,5), Point(10, 8), Point(1, 2)]
    ls=LineString(pts)
    p = convert_arguments(AbstractPlotting.PointBased(), ls)
    @test p[1] == pts

    pts1 = [Point(5, 2), Point(4,8), Point(2, 8), Point(5, 2)]
    ls1 = LineString(pts1)
    lsa = [ls, ls1]
    p1 = convert_arguments(AbstractPlotting.PointBased(), lsa)
    @test p1[1][1:4] == pts
    @test p1[1][6:9] == pts1
    
    mls = MultiLineString(lsa)
    p2 = convert_arguments(AbstractPlotting.PointBased(), mls)
    @test p2[1][1:4] == pts
    @test p2[1][6:9] == pts1

    pol_e = Polygon(ls)
    p3_e = convert_arguments(AbstractPlotting.PointBased(), pol_e)
    @test p3_e[1] == pts

    pol = Polygon(ls, [ls1])
    p3 = convert_arguments(AbstractPlotting.PointBased(), pol)
    @test p3[1][1:4] == pts
    @test p3[1][6:9] == pts1

    pts2 = Point{2, Int}[(5, 1), (3, 3), (4, 8), (1, 2), (5, 1)]
    pts3 = Point{2, Int}[(2, 2), (2, 3),(3, 4), (2, 2)]
    pts4 = Point{2, Int}[(2, 2), (3, 8),(5, 6), (3, 4), (2, 2)]
    ls2 = LineString(pts2)
    ls3 = LineString(pts3)
    ls4 = LineString(pts4)
    pol1 = Polygon(ls2, [ls3, ls4])
    apol = [pol, pol1]
    p4 = convert_arguments(AbstractPlotting.PointBased(), apol)
    mpol = MultiPolygon([pol, pol1])
    @test p4[1][1:4] == pts
    @test p4[1][6:9] == pts1
    @test p4[1][11:15] == pts2 
    @test p4[1][17:20] == pts3
    @test p4[1][22:26] == pts4
end

@testset "Categorical values" begin
    # AbstractPlotting.jl#345
    a = Any[Int64(1), Int32(1), Int128(2)] # vector of categorical values of different types
    ilabels = AbstractPlotting.categoric_labels(a)
    @test ilabels == [1, 2]
    @test AbstractPlotting.categoric_position.(a, Ref(ilabels)) == [1, 1, 2]
end

using AbstractPlotting: check_line_pattern, line_diff_pattern

@testset "Linetype" begin
    @test isnothing(check_line_pattern("-."))
    @test isnothing(check_line_pattern("--"))
    @test_throws ArgumentError check_line_pattern("-.*")

    # for readability, the length of dash and dot
    dash, dot = 3.0, 1.0
    
    @test line_diff_pattern(:dash)             ==
          line_diff_pattern("-",   :normal)    == [dash, 3.0]
    @test line_diff_pattern(:dot)              == 
          line_diff_pattern(".",   :normal)    == [dot, 2.0]
    @test line_diff_pattern(:dashdot)          ==
          line_diff_pattern("-.",  :normal)    == [dash, 3.0, dot, 3.0]
    @test line_diff_pattern(:dashdotdot)       == 
          line_diff_pattern("-..", :normal)    == [dash, 3.0, dot, 2.0, dot, 3.0]
        
    @test line_diff_pattern(:dash, :loose)     == [dash, 6.0]
    @test line_diff_pattern(:dot,  :loose)     == [dot, 4.0]
    @test line_diff_pattern("-",   :dense)     == [dash, 2.0]
    @test line_diff_pattern(".",   :dense)     == [dot, 1.0]
    @test line_diff_pattern(:dash, 0.5)        == [dash, 0.5]
    @test line_diff_pattern(:dot,  0.5)        == [dot, 0.5]
    @test line_diff_pattern("-",   (0.4, 0.6)) == [dash, 0.6]
    @test line_diff_pattern(:dot,  (0.4, 0.6)) == [dot, 0.4]
    @test line_diff_pattern("-..", (0.4, 0.6)) == [dash, 0.6, dot, 0.4, dot, 0.6]

    # gaps must be Symbol, a number, or two numbers
    @test_throws ArgumentError line_diff_pattern(:dash, :NORMAL)
    @test_throws ArgumentError line_diff_pattern(:dash, ()) 
    @test_throws ArgumentError line_diff_pattern(:dash, (1, 2, 3))
end
