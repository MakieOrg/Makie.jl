@testset "derive_colors" begin
    using Makie: derive_colors, DEFAULT_ACCENT_COLOR, RGBf
    using Makie.Colors: red, green, blue

    @testset "default inputs produce the expected light-mode scheme" begin
        c = derive_colors()
        # Black/white poles are returned unchanged in any mix space.
        @test c.background == RGBf(1, 1, 1)
        @test c.text == RGBf(0, 0, 0)
        @test c.accent == DEFAULT_ACCENT_COLOR
        @test c.text_on_accent == RGBf(1, 1, 1)
        # Oklab-mixed neutrals are perceptually-even steps between white and
        # black. Values quoted are what the function produces today; if they
        # shift more than ~1 luminance unit either the algorithm or the
        # weights changed and we want to know about it.
        @test red(c.surface) ≈ 0.92 atol = 0.01
        @test red(c.surface_subtle) ≈ 0.96 atol = 0.01
        @test red(c.border) ≈ 0.74 atol = 0.01
        @test red(c.text_muted) ≈ 0.5 atol = 0.01
        # Neutrals must be gray (no chromaticity) when both poles are neutral.
        for role in (c.surface, c.surface_subtle, c.border, c.text_muted)
            @test red(role) ≈ green(role) atol = 1.0e-3
            @test green(role) ≈ blue(role) atol = 1.0e-3
        end
        @test red(c.accent_subtle) ≈ 0.68 atol = 0.02
        @test green(c.accent_subtle) ≈ 0.77 atol = 0.02
        @test blue(c.accent_subtle) ≈ 0.94 atol = 0.02
    end

    @testset "dark background flips gray pole and inverts neutrals" begin
        # Pure-black background is a corner case: Oklab L just above 0 still
        # maps to a very small sRGB value because of sRGB's gamma curve. The
        # ordering should still be background < surface_subtle < surface
        # < border < text_muted < text, which is what we test here.
        c = derive_colors(background = :black)
        @test c.background == RGBf(0, 0, 0)
        @test c.text == RGBf(1, 1, 1)
        order = (
            c.background, c.surface_subtle, c.surface, c.border,
            c.text_muted, c.text,
        )
        @test issorted(red.(order))

        # A realistic dark theme has a slight lift above pure black, which
        # makes the perceptual mix produce visibly distinct surfaces.
        dark = RGBf(0.12, 0.12, 0.14)
        c2 = derive_colors(background = dark)
        @test red(c2.surface) ≈ 0.16 atol = 0.02
        @test red(c2.border) ≈ 0.27 atol = 0.02
        @test red(c2.text_muted) ≈ 0.44 atol = 0.02
    end

    @testset "explicit gray override biases neutrals toward its hue" begin
        warm = RGBf(0.5, 0.3, 0.2)
        c = derive_colors(gray = warm)
        @test c.text == warm
        # The Oklab mix at weight 0.06 pulls slightly off pure neutral toward
        # the warm pole; check that the result is biased correctly (R > G > B).
        @test red(c.surface) > green(c.surface) > blue(c.surface)
    end

    @testset "text_on_accent picks black for a bright accent" begin
        c = derive_colors(accent = :yellow)
        @test c.text_on_accent == RGBf(0, 0, 0)
    end

    @testset "all returned values are RGBf" begin
        c = derive_colors()
        for (k, v) in pairs(c)
            @test v isa RGBf
        end
    end
end
