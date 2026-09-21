@testset "Volumeslices" begin
    @testset "color data, defaulted xy, ys, zs" begin
        cols = [RGBf(i / 4, j / 4, k / 4) for i in 1:4, j in 1:4, k in 1:4]
        f, a, p = volumeslices(cols)

        @test p.x[] == 1:4
        @test p.y[] == 1:4
        @test p.z[] == 1:4

        @test p.plots[1].image[] == cols[1, :, :]
        @test p.plots[2].image[] == cols[:, 1, :]
        @test p.plots[3].image[] == cols[:, :, 1]

        @test data_limits(p) == Rect3f(1, 1, 1, 3, 3, 3)
        # Not sure where this padding is coming from...
        @test boundingbox(p) ≈ Rect3f(Point3d(0.5), Vec3d(4))
    end

    @testset "arg types" begin
        # ranges are already covered by refimages
        f, a, p = volumeslices(Makie.EndPoints(8, 20), [1, 2, 3, 4], 7 .. 10, rand(4, 4, 4))
        @test p.x[] == range(8.0, 20.0, 4)
        @test p.y[] == [1, 2, 3, 4]
        @test p.z[] == 7.0:10.0

        @test data_limits(p) == Rect3f(8, 1, 7, 12, 3, 3)
        @test boundingbox(p) ≈ Rect3f(6, 0.5, 6.5, 16, 4, 4)
    end
end
