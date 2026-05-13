@testset "derive_colors" begin
    using Makie: derive_colors, DEFAULT_ACCENT_COLOR, RGBf
    using Makie.Colors: red, green, blue

    @testset "default inputs match historical block defaults" begin
        c = derive_colors()
        @test c.background == RGBf(1, 1, 1)
        @test c.surface == RGBf(0.94, 0.94, 0.94)         # Slider/Button idle
        @test c.surface_subtle == RGBf(0.97, 0.97, 0.97)  # Menu rows
        @test c.border == RGBf(0.8, 0.8, 0.8)          # Textbox idle border
        @test c.text == RGBf(0, 0, 0)                     # default :black
        @test c.text_muted == RGBf(0.5, 0.5, 0.5)
        @test c.text_on_accent == RGBf(1, 1, 1)           # white on dark blue
        @test c.accent == DEFAULT_ACCENT_COLOR
        # Historical accent_dimmed was hand-tuned to RGBf(0.68, 0.75, 0.90);
        # we reproduce it within a couple of luminance units.
        @test red(c.accent_subtle) ≈ 0.69 atol = 0.02
        @test green(c.accent_subtle) ≈ 0.77 atol = 0.02
        @test blue(c.accent_subtle) ≈ 0.93 atol = 0.03
    end

    @testset "dark background flips gray pole and inverts neutrals" begin
        c = derive_colors(background = :black)
        @test c.background == RGBf(0, 0, 0)
        @test c.text == RGBf(1, 1, 1)
        @test c.surface == RGBf(0.06, 0.06, 0.06)
        @test c.border == RGBf(0.2, 0.2, 0.2)
        @test c.text_muted == RGBf(0.5, 0.5, 0.5)
    end

    @testset "explicit gray override biases neutrals toward its hue" begin
        warm = RGBf(0.5, 0.3, 0.2)
        c = derive_colors(gray = warm)
        @test c.text == warm
        # surface = bg + 0.06 * (gray - bg); for bg=white this lifts each channel
        # toward gray by 6 %.
        @test c.surface ≈ RGBf(0.97, 0.958, 0.952) atol = 0.01
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
