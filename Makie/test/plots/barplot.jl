@testset "Barplot" begin
    @testset "label align" begin
        @testset "automatic" begin
            # for more info see https://github.com/MakieOrg/Makie.jl/issues/3160
            # below is the best square angles behavior for bar labels

            al = Makie.automatic

            y_dir, flip = false, false
            @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.0, 0.5)
            @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(1.0, 0.5)
            @test Makie.calculate_bar_label_align(al, π / 2, y_dir, flip) ≈ Vec2f(0.5, 1.0)
            @test Makie.calculate_bar_label_align(al, -π / 2, y_dir, flip) ≈ Vec2f(0.5, 0.0)

            y_dir, flip = true, false
            @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.5, 0.0)
            @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.5, 1.0)
            @test Makie.calculate_bar_label_align(al, π / 2, y_dir, flip) ≈ Vec2f(0.0, 0.5)
            @test Makie.calculate_bar_label_align(al, -π / 2, y_dir, flip) ≈ Vec2f(1.0, 0.5)

            y_dir, flip = false, true
            @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(1.0, 0.5)
            @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.0, 0.5)
            @test Makie.calculate_bar_label_align(al, π / 2, y_dir, flip) ≈ Vec2f(0.5, 0.0)
            @test Makie.calculate_bar_label_align(al, -π / 2, y_dir, flip) ≈ Vec2f(0.5, 1.0)

            y_dir, flip = true, true
            @test Makie.calculate_bar_label_align(al, 0.0, y_dir, flip) ≈ Vec2f(0.5, 1.0)
            @test Makie.calculate_bar_label_align(al, π, y_dir, flip) ≈ Vec2f(0.5, 0.0)
            @test Makie.calculate_bar_label_align(al, π / 2, y_dir, flip) ≈ Vec2f(1.0, 0.5)
            @test Makie.calculate_bar_label_align(al, -π / 2, y_dir, flip) ≈ Vec2f(0.0, 0.5)
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

    @testset "stack" begin
        x1 = [1, 1, 1, 1]
        grp_dodge1 = [2, 2, 1, 1]
        grp_stack1 = [1, 2, 1, 2]
        y1 = [2, 3, -3, -2]

        x2 = [2, 2, 2, 2]
        grp_dodge2 = [3, 4, 3, 4]
        grp_stack2 = [3, 4, 3, 4]
        y2 = [2, 3, -3, -2]

        from, to = Makie.stack_grouped_from_to(grp_stack1, y1, (; x1 = x1, grp_dodge1 = grp_dodge1))
        from1 = [0.0, 2.0, 0.0, -3.0]
        to1 = [2.0, 5.0, -3.0, -5.0]
        @test from == from1
        @test to == to1

        from, to = Makie.stack_grouped_from_to(grp_stack2, y2, (; x2 = x2, grp_dodge2 = grp_dodge2))
        from2 = [0.0, 0.0, 0.0, 0.0]
        to2 = [2.0, 3.0, -3.0, -2.0]
        @test from == from2
        @test to == to2

        perm = [1, 4, 2, 7, 5, 3, 8, 6]
        x = [x1; x2][perm]
        y = [y1; y2][perm]
        grp_dodge = [grp_dodge1; grp_dodge2][perm]
        grp_stack = [grp_stack1; grp_stack2][perm]

        from_test = [from1; from2][perm]
        to_test = [to1; to2][perm]

        from, to = Makie.stack_grouped_from_to(grp_stack, y, (; x = x, grp_dodge = grp_dodge))
        @test from == from_test
        @test to == to_test
    end

    @testset "zero-height" begin
        grp_stack = [1, 2, 1, 2]
        x = [1, 1, 2, 2]

        y = [1.0, 0.0, -1.0, -1.0]
        from = [0.0, 1.0, 0.0, -1.0]
        to = [1.0, 1.0, -1.0, -2.0]
        from_, to_ = Makie.stack_grouped_from_to(grp_stack, y, (; x))
        @test from == from_
        @test to == to_

        y = [-1.0, 0.0, -1.0, -1.0]
        from = [0.0, -1.0, 0.0, -1.0]
        to = [-1.0, -1.0, -1.0, -2.0]
        from_, to_ = Makie.stack_grouped_from_to(grp_stack, y, (; x))
        @test from == from_
        @test to == to_

        y = [0.0, 1.0, -1.0, -1.0]
        from = [0.0, 0.0, 0.0, -1.0]
        to = [0.0, 1.0, -1.0, -2.0]
        from_, to_ = Makie.stack_grouped_from_to(grp_stack, y, (; x))
        @test from == from_
        @test to == to_

        y = [0.0, -1.0, -1.0, -1.0]
        from = [0.0, 0.0, 0.0, -1.0]
        to = [0.0, -1.0, -1.0, -2.0]
        from_, to_ = Makie.stack_grouped_from_to(grp_stack, y, (; x))
        @test from == from_
        @test to == to_

        y = [0.0, 1.0, -1.0, -1.0]
        from = [0.0, 0.0, 0.0, -1.0]
        to = [0.0, 1.0, -1.0, -2.0]
        from_, to_ = Makie.stack_grouped_from_to(1:4, y, (; x = ones(4)))
        @test from == from_
        @test to == to_
    end

    @testset "stack fillto" begin
        # https://github.com/MakieOrg/Makie.jl/issues/4549
        rects(p) = p.plots[1][1][]
        bottoms(p) = [r.origin[2] for r in rects(p)]
        tops(p) = [r.origin[2] + r.widths[2] for r in rects(p)]

        x = [1, 2, 3, 1, 2, 3]
        y = [1, 2, 3, 1, 2, 3]
        stack = [1, 1, 1, 2, 2, 2]

        # explicit fillto is the baseline of the stack
        f, ax, p = barplot(x, y; stack, fillto = 0.5)
        @test bottoms(p) == [0.5, 0.5, 0.5, 1.0, 2.0, 3.0]
        @test tops(p) == [1.0, 2.0, 3.0, 2.0, 4.0, 6.0]

        # log scale automatic fillto: half of the smallest positive stack total
        f, ax, p = barplot(x, y; stack, axis = (; yscale = log10))
        @test bottoms(p) == [0.5, 0.5, 0.5, 1.0, 2.0, 3.0]
        @test tops(p) == [1.0, 2.0, 3.0, 2.0, 4.0, 6.0]
        @test all(>(0), bottoms(p))

        # zeros anywhere in the stack must not produce a 0 (-> -Inf) boundary
        x = [1, 2, 3, 4, 1, 2, 3, 4]
        y = [0, 2, 3, 0, 1, 0, 3, 0]
        stack = [1, 1, 1, 1, 2, 2, 2, 2]
        f, ax, p = barplot(x, y; stack, axis = (; yscale = log10))
        @test all(>(0), bottoms(p))
        @test all(>(0), tops(p))
        @test bottoms(p) == [0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 3.0, 0.5]
        @test tops(p) == [0.5, 2.0, 3.0, 0.5, 1.0, 2.0, 6.0, 0.5]

        # log scale in x direction
        f, ax, p = barplot(x, y; stack, direction = :x, axis = (; xscale = log10))
        @test [r.origin[1] for r in rects(p)] == [0.5, 0.5, 0.5, 0.5, 0.5, 2.0, 3.0, 0.5]

        # linear scale is unchanged by default
        f, ax, p = barplot(x, y; stack)
        @test bottoms(p) == [0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 3.0, 0.0]

        # negative stacks are clamped symmetrically
        f, ax, p = barplot([1, 1, 2, 2], [-1, -2, 1, 2]; stack = [1, 2, 1, 2], fillto = -0.5)
        @test bottoms(p) == [-1.0, -3.0, 0.0, 1.0]
        @test tops(p) == [-0.5, -1.0, 1.0, 3.0]

        @test_throws ArgumentError barplot(x, y; stack, fillto = zeros(length(x)))
    end
end
