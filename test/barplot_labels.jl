@testset "Barplot label align" begin
    @testset "automatic" begin
        # for more info see https://github.com/MakieOrg/Makie.jl/issues/3160
        # below is the best square angles behavior for bar labels

        al = Makie.automatic

        y_dir, flip = false, false
        @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.0, 0.5)
        @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(1.0, 0.5)
        @test Makie.calculate_bar_label_align(al, π/2, y_dir, flip) ≈ Vec2f(0.5, 1.0)
        @test Makie.calculate_bar_label_align(al, -π/2, y_dir, flip) ≈ Vec2f(0.5, 0.0)

        y_dir, flip = true, false
        @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.5, 0.0)
        @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.5, 1.0)
        @test Makie.calculate_bar_label_align(al, π/2, y_dir, flip) ≈ Vec2f(0.0, 0.5)
        @test Makie.calculate_bar_label_align(al, -π/2, y_dir, flip) ≈ Vec2f(1.0, 0.5)

        y_dir, flip = false, true
        @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(1.0, 0.5)
        @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.0, 0.5)
        @test Makie.calculate_bar_label_align(al, π/2, y_dir, flip) ≈ Vec2f(0.5, 0.0)
        @test Makie.calculate_bar_label_align(al, -π/2, y_dir, flip) ≈ Vec2f(0.5, 1.0)

        y_dir, flip = true, true
        @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.5, 1.0)
        @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.5, 0.0)
        @test Makie.calculate_bar_label_align(al, π/2, y_dir, flip) ≈ Vec2f(1.0, 0.5)
        @test Makie.calculate_bar_label_align(al, -π/2, y_dir, flip) ≈ Vec2f(0.0, 0.5)
    end

    @testset "manual" begin
        input = 0.0, false, false
        for align in (Vec2f(1.0, 0.5), Point2f(1.0, 0.5), (1.0, 0.5), (1, 0), (1.0, 0))
            @test Makie.calculate_bar_label_align(align, input...) ≈ Vec2f(align)
        end
    end

    @testset "symbols" begin
        input = 0.0, false, false
        @test Makie.calculate_bar_label_align((:center, :center), input...) ≈ Makie.calculate_bar_label_align((0.5, 0.5), input...)
    end

    @testset "error" begin
        input = 0.0, false, false
        for align in ("center", 0.5, ("center", "center"))
            @test_throws ErrorException Makie.calculate_bar_label_align(align, input...)
        end
    end

end