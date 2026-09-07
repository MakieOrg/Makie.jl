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
    f, a, p = arrows3d(ps, vs)
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
        a.scene.transformation.transform_func[] = Makie.PointTrans{3}(p -> (1.0f0, 2.0f0, 3.0f0) .* p)
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))

        p.normalize[] = false
        @test !all(onenorm.(p.world_directions[]))
        @test all(onenorm.(p.normalized_dir[]))
    end
end

@testset "arrows color flattening" begin
    cs = 1:8
    f,a,p = arrows3d(rand(2, 4), rand(2, 4), rand(8), rand(8), color = reshape(cs, (2, 4)))
    @test p.resolved_tailcolor[] == cs
    @test p.resolved_shaftcolor[] == cs
    @test p.resolved_tipcolor[] == cs

    f,a,p = arrows2d(
        rand(2), rand(4), p -> rand(Vec2f),
        color = reshape(cs, (2, 4)),
        tailcolor = 4:12, shaftcolor = reshape(8:-1:1, (2, 4))
    )
    @test p.resolved_tailcolor[] == 4:12
    @test p.resolved_shaftcolor[] == 8:-1:1
    @test p.resolved_tipcolor[] == cs

    f,a,p = arrows3d(
        rand(Point3f, 6), rand(Vec3f, 1, 2, 3),
        tipcolor = reshape(1:6, (1, 2, 3)),
        tailcolor = 4:10,
        shaftcolor = reshape(6:-1:1, (1, 2, 3))
    )
    @test p.resolved_tailcolor[] == 4:10
    @test p.resolved_shaftcolor[] == 6:-1:1
    @test p.resolved_tipcolor[] == 1:6
end
