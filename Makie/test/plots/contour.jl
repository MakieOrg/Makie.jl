using Makie, Test
using Makie: label_info

@testset "contour label placement" begin
    @testset "open line is labeled at the middle by arc length" begin
        l_shape = [(0.0, 0.0), (0.5, 0.0), (1.0, 0.0), (4.0, 0.0), (4.0, 2.0)]
        expected = (Point3f(1, 0, 7), Point3f(3, 0, 7), Point3f(4, 0, 7))
        @test label_info(7, l_shape) == expected
        @test label_info(7, reverse(l_shape)) == expected
    end

    @testset "middle on a vertex uses its neighbors" begin
        line = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (2.0, 1.0), (2.0, 2.0)]
        expected = (Point3f(1, 0, 0), Point3f(1, 1, 0), Point3f(2, 1, 0))
        @test label_info(0, line) == expected
        @test label_info(0, reverse(line)) == expected
    end

    @testset "NaN vertices are skipped and the longest finite piece wins" begin
        line = [(NaN, 0.0), (NaN, 0.0), (0.0, 0.0), (2.0, 0.0), (NaN, 1.0), (5.0, 0.0), (5.0, 4.0), (NaN, 0.0)]
        expected = (Point3f(5, 0, 1), Point3f(5, 2, 1), Point3f(5, 4, 1))
        @test label_info(1, line) == expected
        @test label_info(1, reverse(line)) == expected
    end

    @testset "closed loop is labeled at its top vertex" begin
        loop = [(0.0, 0.0), (2.0, 1.0), (1.0, 3.0), (-1.0, 2.0), (0.0, 0.0)]
        rotated = [(1.0, 3.0), (-1.0, 2.0), (0.0, 0.0), (2.0, 1.0), (1.0, 3.0)]
        expected = (Point3f(-1, 2, 0), Point3f(1, 3, 0), Point3f(2, 1, 0))
        @test label_info(0, loop) == expected
        @test label_info(0, reverse(loop)) == expected
        @test label_info(0, rotated) == expected
    end

    @testset "closed loop with a flat top is labeled at the middle of the top edge" begin
        square = [(0.0, 0.0), (0.0, 1.0), (2.0, 1.0), (2.0, 0.0), (0.0, 0.0)]
        expected = (Point3f(0, 1, 0), Point3f(1, 1, 0), Point3f(2, 1, 0))
        @test label_info(0, square) == expected
        @test label_info(0, reverse(square)) == expected
    end

    @testset "closed loop with NaN vertices is labeled like an open line" begin
        loop = [(0.0, 0.0), (0.0, 4.0), (NaN, 5.0), (1.0, 0.0), (0.0, 0.0)]
        @test label_info(0, loop) == (Point3f(0, 0, 0), Point3f(0, 1.5, 0), Point3f(0, 4, 0))
    end

    @testset "line without finite segment does not error" begin
        no_label = ntuple(_ -> Point3f(NaN, NaN, 2), 3)
        @test isequal(label_info(2, [(NaN, 0.0), (1.0, 1.0), (NaN, 1.0)]), no_label)
        @test isequal(label_info(2, [(1.0, 1.0), (1.0, 1.0)]), no_label)
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
