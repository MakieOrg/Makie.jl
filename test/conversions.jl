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
end

@testset "Categorical values" begin
    # AbstractPlotting.jl#345
    a = Any[Int64(1), Int32(1), Int128(2)] # vector of categorical values of different types
    ilabels = AbstractPlotting.categoric_labels(a)
    @test ilabels == [1, 2]
    @test AbstractPlotting.categoric_position.(a, Ref(ilabels)) == [1, 1, 2]
end
