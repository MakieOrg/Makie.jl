@testset "DataInspector" begin
    @testset "strings" begin
        @test Makie.vec2string(Vec(pi, pi)) == "(3.142, 3.142)"
        @test Makie.vec2string(Vec(pi, pi, pi)) == "(3.142, 3.142, 3.142)"

        @test Makie.position2string(Vec(pi, pi)) == "x: 3.141593\ny: 3.141593"
        @test Makie.position2string(Vec(pi, pi, pi)) == "x: 3.141593\ny: 3.141593\nz: 3.141593"

        @test Makie.bbox2string(Rect2(pi, pi, 1, 1)) == "Bounding Box:\n x: (3.142, 4.142)\n y: (3.142, 4.142)\n"
        @test Makie.bbox2string(Rect3(Point3(pi), Vec3(1))) == "Bounding Box:\n x: (3.142, 4.142)\n y: (3.142, 4.142)\n z: (3.142, 4.142)\n"

        @test Makie.color2text(pi) == "3.142"
        @test Makie.color2text(:red) == "red"
        @test Makie.color2text(Makie.colorant"red") == "RGB(1.00, 0.00, 0.00)"
        @test Makie.color2text("img", 5, 7, RGBAf(0.6, 0.77777, 0.5, 0.3)) == "img[5, 7] = RGBA(0.60, 0.78, 0.50, 0.30)"
    end

    # TODO: Consider moving this to GeometryBasics (with ray intersection math)
    @testset "2D position resolution" begin
        @testset "closest_point_on_line" begin
            @test Makie.closest_point_on_line(Point2(0, -1), (0, 1), Vec2(1, 0)) == Point2(0.0, 0.0)
            @test Makie.closest_point_on_line(Point2f(0, 1), Point2f(2, 3), Vec2f(0, 3)) == Point2f(1.0, 2.0)
            @test Makie.closest_point_on_line((0, 0), (1, 0), (-2, 1)) == (0.0, 0.0)
        end

        @testset "point_in_triangle" begin
            @test Makie.point_in_triangle((-1, -1), (1, -1), (0, 1), Point2f(0, 0)) == true
            # Check edges and corners
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (-0.5, 0)) == true
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (0.5, 0)) == true
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (0, -1)) == true
            @test Makie.point_in_triangle(Point2f(-1, -1), Vec2f(1, -1), Vec2f(0, 1), Point2f(-0.51, 0)) == false
            @test Makie.point_in_triangle(Point2f(-1, -1), Vec2f(1, -1), Vec2f(0, 1), Point2f(0.51, 0)) == false
            @test Makie.point_in_triangle(Point2f(-1, -1), Vec2f(1, -1), Vec2f(0, 1), Point2f(0, -1.1)) == false

            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (-1, -1)) == true
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (1, -1)) == true
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (0, 1)) == true
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (-1.01, -1.01)) == false
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (1.01, -1.01)) == false
            @test Makie.point_in_triangle(Point(-1, -1), Vec(1, -1), (0, 1), (0, 1.01)) == false
        end

    end
end
