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

    @testset "empty construction" begin
        # Also indirectly checks that boundingbox works
        f, a, p = barplot(Float64[], Float64[])
        Makie.update_state_before_display!(f)
        @test isempty(p.bar_rectangles[])

        # ... with multiple transform_funcs
        f, a, p = barplot(Float64[], Float64[], axis = (yscale = log10, xscale = log2))
        Makie.update_state_before_display!(f)
        @test isempty(p.bar_rectangles[])

        # PolarAxis doesn't work but that's on PolarAxis, not boundingbox() with
        # a Polar transform
        # f = Figure()
        # a = PolarAxis(f[1, 1])
        # p = barplot!(a, Float64[], Float64[])
        # Makie.update_state_before_display!(f)
        # @test isempty(p.bar_rectangles[])
    end

    @testset "zero construction" begin
        f, a, p = barplot(1:10, zeros(10))
        Makie.update_state_before_display!(f)
        whs = widths.(Rect2d.(coordinates.(p.bar_rectangles[])))
        @test all(wh -> wh ≈ Vec2d(0.8, 0), whs)

        # no regular width here because space isn't linear
        f, a, p = barplot(1:10, zeros(10), axis = (yscale = log10, xscale = log2))
        Makie.update_state_before_display!(f)
        whs = widths.(Rect2d.(coordinates.(p.bar_rectangles[])))
        @test all(wh -> wh[2] == 0, whs)

        # 0 radius means all points collapse to (0, 0) post transform
        f = Figure()
        a = PolarAxis(f[1, 1])
        p = barplot!(a, 1:10, zeros(10))
        Makie.update_state_before_display!(f)
        whs = widths.(Rect2d.(coordinates.(p.bar_rectangles[])))
        @test all(wh -> wh ≈ Vec2d(0.0, 0), whs)
    end

    @testset "stack fillto" begin
        # https://github.com/MakieOrg/Makie.jl/issues/4549
        rects(p) = p.bar_rectangles[]
        bottoms(p) = [minimum(Rect2(poly))[2] for poly in rects(p)]
        tops(p) = [maximum(Rect2(poly))[2] for poly in rects(p)]

        x = [1, 2, 3, 1, 2, 3]
        y = [1, 2, 3, 1, 2, 3]
        stack = [1, 1, 1, 2, 2, 2]

        # explicit fillto is the baseline of the stack
        f, ax, p = barplot(x, y; stack, fillto = 0.5)
        @test bottoms(p) == [0.5, 0.5, 0.5, 1.0, 2.0, 3.0]
        @test tops(p) == [1.0, 2.0, 3.0, 2.0, 4.0, 6.0]

        # log scale transforms the default fillto = 0 to -Inf. This transformed
        # value gets clamped when creating the bar polygons, in this case to
        # -300. (This value can change in the future. It should just remain
        # (far) below the transformed axis y limits)
        f, ax, p = barplot(x, y; stack, axis = (; yscale = log10))
        @test bottoms(p) ≈ [-300.0, -300.0, -300.0, log10(1.0), log10(2.0), log10(3.0)]
        @test tops(p) ≈ log10.([1.0, 2.0, 3.0, 2.0, 4.0, 6.0])

        # zeros anywhere in the stack must not produce a 0 (-> -Inf) boundary
        x = [1, 2, 3, 4, 1, 2, 3, 4]
        y = [0, 2, 3, 0, 1, 0, 3, 0]
        stack = [1, 1, 1, 1, 2, 2, 2, 2]
        f, ax, p = barplot(x, y; stack, axis = (; yscale = log10))
        @test bottoms(p) ≈ [-300.0, -300.0, -300.0, -300.0, -300.0, log10(2.0), log10(3.0), -300.0]
        @test tops(p) ≈ [-300.0, log10(2.0), log10(3.0), -300.0, log10(1.0), log10(2.0), log10(6.0), -300.0]

        # log scale in x direction
        f, ax, p = barplot(x, y; stack, direction = :x, axis = (; xscale = log10))
        @test [minimum(r)[1] for r in rects(p)] == [-300.0, -300.0, -300.0, -300.0, -300.0, log10(2.0), log10(3.0), -300.0]

        # linear scale is unchanged by default
        f, ax, p = barplot(x, y; stack)
        @test bottoms(p) == [0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 3.0, 0.0]

        # negative stacks are clamped symmetrically
        f, ax, p = barplot([1, 1, 2, 2], [-1, -2, 1, 2]; stack = [1, 2, 1, 2], fillto = -0.5)
        @test bottoms(p) == [-1.0, -3.0, -0.5, 1.0]
        @test tops(p) == [-0.5, -1.0, 1.0, 3.0]

        # bars fully within 0 .. fillto should become 0 width (top == bottom)
        f, ax, p = barplot([1, 1], [1, 2]; stack = [1, 1], fillto = 2)
        @test bottoms(p) == [2.0, 2.0]
        @test tops(p) == [2.0, 3.0]

        f, ax, p = barplot([1, 1], [-1, -2]; stack = [1, 1], fillto = -2)
        @test bottoms(p) == [-2.0, -3.0]
        @test tops(p) == [-2.0, -2.0]

        # Maybe mixing positive and negative heights within a stack is nonsensical,
        # but let's test this so we're at least aware when the behavior changes
        f, ax, p = barplot([1, 1, 1, 1], [1, -2, 3, -4]; stack = [1, 1, 1, 1], fillto = 1.5)
        @test bottoms(p) == [1.5, -2.0, 1.5, -6.0]
        @test tops(p) == [1.5, 1.5, 4.0, -2.0]

        # TODO: probably needs more work...
        f, a, p = barplot(x, y; stack, fillto = 0.1:0.1:0.8)
        @test bottoms(p) == [0.1, 0.2, 0.3, 0.4, 0.5, 2.0, 3.0, 0.8]
        @test tops(p) == [0.1, 2.0, 3.0, 0.4, 1.0, 2.0, 6.0, 0.8]
    end
end
