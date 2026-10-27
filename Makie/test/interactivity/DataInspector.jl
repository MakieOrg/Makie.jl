using Makie: apply_tooltip_format, default_tooltip_formatter

@testset "DataInspector" begin
    @testset "formatted label data" begin
        format(x) = apply_tooltip_format(default_tooltip_formatter, x)

        @test format(Vec(pi, pi)) == "(3.142, 3.142)"
        @test format(Vec(pi, pi, pi)) == "(3.142, 3.142, 3.142)"

        @test format(pi) == "3.142"
        @test format(:red) == ":red"
        @test format(Makie.colorant"red") == "RGB(1.000, 0, 0)"

        @test format(("img", 5, 7, RGBAf(0.6, 0.77777, 0.5, 0.3))) == "img\n5.000\n7.000\nRGBA(0.600, 0.778, 0.500, 0.300)"
    end

    # TODO: add more tests for DataInspector pipeline, e.g. pick_element.
    # (This is already indirectly tested via refimages)
end
