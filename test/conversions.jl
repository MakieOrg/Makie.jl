using AbstractPlotting: 
    NoConversion, 
    convert_arguments, 
    conversion_trait

using IntervalSets

@testset "Conversions" begin

    # NoConversion
    struct NoConversionTestType end
    conversion_trait(::NoConversionTestType) = NoConversion()

    let nctt = NoConversionTestType(), 
        ncttt = conversion_trait(nctt)
        @test convert_arguments(ncttt, 1, 2, 3) == (1, 2, 3)
    end

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
end

@testset "Categorical values" begin
    # AbstractPlotting.jl#345
    a = Any[Int64(1), Int32(1), Int128(2)] # vector of categorical values of different types
    ilabels = AbstractPlotting.categoric_labels(a)
    @test ilabels == [1, 2]
    @test AbstractPlotting.categoric_position.(a, Ref(ilabels)) == [1, 1, 2]
end
