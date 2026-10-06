using Makie, Test
using LinearAlgebra: normalize

function label_at(line, labelposition = 0.0)
    anchor = Makie.label_anchor(line, labelposition)
    direction = normalize(Vec2d(anchor.direction))
    points_left_or_down = direction[1] < -1.0e-9 || (abs(direction[1]) <= 1.0e-9 && direction[2] < 0)
    return Makie.anchor_point(line, anchor), points_left_or_down ? -direction : direction
end

const horizontal = Vec2d(1, 0)
const vertical = Vec2d(0, 1)

@testset "contour label placement" begin
    @testset "open line is labeled at the middle by arc length" begin
        l_shape = Point2f[(0, 0), (0.5, 0), (1, 0), (4, 0), (4, 2)]
        @test all(label_at(l_shape) .≈ (Point2f(3, 0), horizontal))
        @test all(label_at(reverse(l_shape)) .≈ (Point2f(3, 0), horizontal))
    end

    @testset "labelposition moves along an open line towards its right end" begin
        l_shape = Point2f[(0, 0), (0.5, 0), (1, 0), (4, 0), (4, 2)]
        for line in (l_shape, reverse(l_shape))
            @test all(label_at(line, 0.5) .≈ (Point2f(4, 0.5), vertical))
            @test all(label_at(line, 1.0) .≈ (Point2f(4, 2), vertical))
            @test all(label_at(line, -1.0) .≈ (Point2f(0, 0), horizontal))
        end
    end

    @testset "middle on a vertex is oriented along its neighbors" begin
        line = Point2f[(0, 0), (1, 0), (1, 1), (2, 1), (2, 2)]
        @test all(label_at(line) .≈ (Point2f(1, 1), normalize(Vec2d(1, 1))))
        @test all(label_at(reverse(line)) .≈ (Point2f(1, 1), normalize(Vec2d(1, 1))))
    end

    @testset "NaN vertices are skipped and the longest finite piece wins" begin
        line = Point2f[(NaN, 0), (NaN, 0), (0, 0), (2, 0), (NaN, 1), (5, 0), (5, 4), (NaN, 0)]
        @test all(label_at(line) .≈ (Point2f(5, 2), vertical))
        @test all(label_at(reverse(line)) .≈ (Point2f(5, 2), vertical))
    end

    @testset "closed loop is labeled horizontally at the peak of the parabola through its top" begin
        loop = Point2f[(0, 0), (2, 1), (1, 3), (-1, 2), (0, 0)]
        rotated = Point2f[(1, 3), (-1, 2), (0, 0), (2, 1), (1, 3)]
        for line in (loop, reverse(loop), rotated)
            @test all(label_at(line) .≈ (Point2f(0.3, 2.65), horizontal))
        end
    end

    @testset "labelposition moves clockwise around a closed loop" begin
        square = Point2f[(0, 0), (0, 2), (2, 2), (2, 0), (0, 0)]
        for loop in (square, reverse(square))
            @test all(label_at(loop) .≈ (Point2f(1, 2), horizontal))
            @test all(label_at(loop, 0.5) .≈ (Point2f(2, 1), vertical))
            @test all(label_at(loop, -0.5) .≈ (Point2f(0, 1), vertical))
            @test all(label_at(loop, 1.0) .≈ label_at(loop, -1.0) .≈ (Point2f(1, 0), horizontal))
        end
    end

    @testset "closed loop with NaN vertices is labeled like an open line" begin
        loop = Point2f[(0, 0), (0, 4), (NaN, 5), (1, 0), (0, 0)]
        @test all(label_at(loop) .≈ (Point2f(0, 1.5), vertical))
    end

    @testset "line without a visible segment has no label" begin
        @test Makie.label_anchor(Point2f[(NaN, 0), (1, 1), (NaN, 1)], 0.0) === nothing
        @test Makie.label_anchor(Point2f[(1, 1), (1, 1)], 0.0) === nothing
    end
end

@testset "contour label gap" begin
    box = Rect2d(-1.5, -1, 3, 2)
    masked(line, center, angle) = Makie.label_gap_masked_line(line, line, center, angle, box)

    @testset "line is cut exactly at the label box" begin
        line = Point2f.(0:10, 0)
        expected = Point2f[(0, 0), (1, 0), (2, 0), (3, 0), (3.5, 0), (NaN, NaN), (6.5, 0), (7, 0), (8, 0), (9, 0), (10, 0)]
        @test isequal(masked(line, Point2f(5, 0), 0.0), expected)
    end

    @testset "segment crossing the whole label box is cut" begin
        line = Point2f[(0, 0), (10, 0)]
        @test isequal(masked(line, Point2f(5, 0), 0.0), Point2f[(0, 0), (3.5, 0), (NaN, NaN), (6.5, 0), (10, 0)])
    end

    @testset "rotated label box" begin
        line = Point2f[(0, 0), (4, 4)]
        result = masked(line, Point2f(2, 2), pi / 4)
        offset = 1.5 / sqrt(2)
        @test result[[1, 5]] == line
        @test isnan(result[3])
        @test result[2] ≈ Point2f(2 - offset, 2 - offset)
        @test result[4] ≈ Point2f(2 + offset, 2 + offset)
    end

    @testset "line ending inside the label box" begin
        line = Point2f[(0, 0), (4, 0), (5, 0), (NaN, NaN)]
        @test isequal(masked(line, Point2f(5, 0), 0.0), Point2f[(0, 0), (3.5, 0), (NaN, NaN)])
    end
end

@testset "contour labels are placed on screen" begin
    xs = range(-1, 1, length = 101)
    zs = [x^2 + y^2 for x in xs, y in xs]

    fig, ax, pl = contour(xs, xs, zs, levels = [0.25, 0.5], labels = true, labelposition = [0, 1])
    Makie.update_state_before_display!(fig)
    @test pl.text_positions[] ≈ Point2f[(0, 0.5), (0, -sqrt(0.5))] atol = 1.0e-3
    @test pl.text_rotation[] ≈ [0, 0] atol = 0.05

    fig, ax, pl = contour(xs, xs, zs, levels = [0.5], labels = true)
    Makie.update_state_before_display!(fig)
    @test pl.text_positions[] ≈ Point2f[(0, sqrt(0.5))] atol = 1.0e-3
    @test pl.text_rotation[] == [0]
end
