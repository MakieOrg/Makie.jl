@testset "arrows - Colorbar" begin
    # Test for:
    # https://github.com/MakieOrg/Makie.jl/issues/3273
    directions = decompose(Point2f, Circle(Point2f(0), 1))
    points = decompose(Point2f, Circle(Point2f(0), 0.5))
    color = range(0, 1, length = length(directions))
    fig, ax, pl = arrows2d(points, directions; color = color)
    cbar = Colorbar(fig[1, 2], pl)
    @test cbar.limits[] == Vec2f(0, 1)
    pl.colorrange = (0.5, 0.6)
    @test cbar.limits[] ≈ Vec2f(0.5, 0.6)
end

@testset "arrows in scaled world" begin
    # https://github.com/MakieOrg/Makie.jl/issues/5711
    onenorm(v) = norm(v) ≈ 1

    ps = rand(Point3f, 5)
    vs = [0.1 .+ rand(Vec3f) for _ in 1:5] #
    f,a,p = arrows3d(ps, vs)
    @testset "unscaled" begin
        @test !all(onenorm.(vs))
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = true
        @test all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "scaled (model)" begin
        scale!(p, 1, 2, 3)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = false
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "model reset/unscaled" begin
        scale!(p, 1, 1, 1)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = true
        @test all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end

    @testset "transform_func scaled" begin
        a.scene.transformation.transform_func[] = Makie.PointTrans{3}(p -> (1f0, 2f0, 3f0) .* p)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = false
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end
end
