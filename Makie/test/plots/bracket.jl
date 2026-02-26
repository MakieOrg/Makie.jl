using Makie.LaTeXStrings
@testset "bracket" begin
    @testset "LaTeXString support" begin
        # Test that LaTeX strings are preserved in bracket text, not converted to String
        fig = Figure()
        ax = Axis(fig[1, 1])

        # Regular string should work
        b1 = bracket!(ax, 0, 0, 1, 0, text = "regular text")
        @test b1.text[] isa String

        # LaTeX string should be preserved as LaTeXString
        latex_str = L"u(x) = \sin(x)"
        b2 = bracket!(ax, 0, 0, 1, 0, text = latex_str)
        @test b2.text[] isa LaTeXString

        # Mixed vector should preserve types
        texts = ["regular", L"\alpha + \beta"]
        b3 = bracket!(ax, [1, 2], [1, 1], [2, 3], [1, 1], text = texts)
        @test b3.text[][1] isa String
        @test b3.text[][2] isa LaTeXString
    end
end
