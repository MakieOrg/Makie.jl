@testset "line indices" begin
    @testset "base" begin
        idxs, valid = GLMakie.generate_indices(Point2f[])
        @test isempty(idxs)
        @test isempty(valid)

        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0)])
        @test idxs == Cuint[] # can't draw a line so no indices necessary
        @test valid == Float32[0] # should be irrelevant, just 0 for safety

        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1)])
        @test idxs == Cuint[0, 0, 1, 1]
        @test valid == Float32[1, 1]

        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1), (0, 1)])
        @test idxs == Cuint[0, 0, 1, 2, 2]
        @test valid == Float32[1, 1, 1]

        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1), (0, 1), (0, 2)])
        @test idxs == Cuint[0, 0, 1, 2, 3, 3]
        @test valid == Float32[1, 1, 1, 1]

        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1), (NaN, NaN), (0, 1), (0, 2)])
        @test idxs == Cuint[0, 0, 1, 2, 2, 3, 4, 4]
        # index 2 marked invalid (0), disabling lines (1-2), (2-2), (2-3)
        @test valid == Float32[1, 1, 0, 1, 1]

        idxs, valid = GLMakie.generate_indices([Point2f(NaN) for _ in 1:4])
        @test idxs == Cuint[]
        @test valid == Float32[0, 0, 0, 0]
    end

    @testset "line loop" begin
        # not a loop, no need for special treatment
        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1), (0, 0)])
        @test idxs == Cuint[0, 0, 1, 2, 2]
        @test valid == Float32[1, 1, 1]

        # smallest possible loop
        idxs, valid = GLMakie.generate_indices(Point2f[(0, 0), (1, 1), (0, 1), (0, 0)])
        @test idxs == Cuint[2, 0, 1, 2, 3, 1]
        @test valid == Float32[1, 2, 2, 1]

        # larger line loop
        idxs, valid = GLMakie.generate_indices([Point2f(cos(x), sin(x)) for x in range(0, 2pi, length = 10)])
        # index 0, 9 are the same, padded by the previous/next value of the other
        @test idxs == vcat(Cuint(8), Cuint.(0:9), Cuint(1))
        # 2 mark index 0, 9 as the same
        @test valid == Float32[1, 2, 1, 1, 1, 1, 1, 1, 2, 1]
    end
end
