using Makie: Pattern, LinePattern
using LinearAlgebra

@testset "Patterns" begin

    @testset "Pattern constructors" begin
        for (style, dirs) in zip(
                ['/', '\\', '-', '|', 'x', '+'],
                [[Vec2f(1)], [Vec2f(1, -1)], [Vec2f(1, 0)], [Vec2f(0, 1)], [Vec2f(1), Vec2f(1, -1)], [Vec2f(1, 0), Vec2f(0, 1)]]
            )
            pattern = Pattern(style, linecolor = :red)
            @test pattern isa LinePattern
            @test pattern.dirs == dirs
            @test pattern.colors[1] == Makie.to_color(:red)
        end

        pattern = Pattern(
            width = 5.0f0, tilesize = (20, 20), shift = Vec2f(0),
            linecolor = :blue, background_color = :red
        )
        @test pattern.dirs == [Vec2f(1)]
        @test pattern.widths == 5.0f0
        @test pattern.shifts == [Vec2f(0)]
        @test pattern.tilesize == (20, 20)
        @test pattern.colors == [to_color(:blue), to_color(:red)]

        @test_throws ArgumentError Pattern('j')
    end

    @test "Image Generation" begin
        pattern = Pattern(linecolor = :black, backgroundcolor = RGBAf(1, 1, 1, 0))
        img = Makie.to_image(pattern)
        @test diag(img) == [RGBAf(0, 0, 0, 1) for _ in 1:10]
        @test diag(img, +3) == [RGBAf(1, 1, 1, 0) for _ in 1:7]
        @test diag(img, -3) == [RGBAf(1, 1, 1, 0) for _ in 1:7]
    end

end
