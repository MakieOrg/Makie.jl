using AbstractPlotting: 
    NoConversion, 
    convert_arguments, 
    conversion_trait

@testset "Conversions" begin

    # NoConversion
    struct NoConversionTestType end
    conversion_trait(::NoConversionTestType) = NoConversion()

    let nctt = NoConversionTestType(), 
        ncttt = conversion_trait(nctt)
        @test convert_arguments(ncttt, 1, 2, 3) == (1, 2, 3)
    end

end