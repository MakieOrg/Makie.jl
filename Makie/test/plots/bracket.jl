using Makie.LaTeXStrings
@testset "bracket" begin
    @testset "LaTeXString support" begin
        # Test that LaTeX strings are preserved in bracket text child plot's input_text
        fig = Figure()
        ax = Axis(fig[1, 1])

        # Regular string should work - check child text plot's input_text
        b1 = bracket!(ax, 0, 0, 1, 0, text = "regular text")
        @test b1.plots[2].input_text[][1] isa String

        # LaTeX string should be preserved as LaTeXString in child text plot's input_text
        latex_str = L"u(x) = \sin(x)"
        b2 = bracket!(ax, 1, 0, 2, 0, text = latex_str)
        @test b2.plots[2].input_text[][1] isa LaTeXString

        # Mixed vector should preserve types in child text plot's input_text
        texts = ["regular", L"\alpha + \beta"]
        b3 = bracket!(ax, [0, 1], [0.5, 0.5], [1, 2], [0.5, 0.5], text = texts)
        @test b3.plots[2].input_text[][1] isa String
        @test b3.plots[2].input_text[][2] isa LaTeXString

        richtext = rich(
            "H", subscript("2"), "O is the formula for ",
            rich("water", color = :cornflowerblue, font = :italic)
        )
        b4 = bracket!(ax, 0.0, 0.1, 1, 0.1, text = richtext)
        @test b4.plots[2].input_text[][1] isa Makie.RichText
    end
end
