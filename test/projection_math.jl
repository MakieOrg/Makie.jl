using Makie

@testset "Projection math" begin
    @testset "Rotation matrix" begin
        @test eltype(Makie.rotationmatrix_x(1)) == Float64
        @test eltype(Makie.rotationmatrix_x(1f0)) == Float32
    end
    @testset "Projection between spaces in 3D" begin
        # Set up an LScene and some points there
        sc = Scene(size = (650, 400), camera = cam3d!)
        corner_points_px = [Point3f(0, 0, 0), Point3f(650, 400, 0)]

        @testset "Clip space and pixel space equivalence" begin
            far_bottom_left_clip = Point3f(-1)
            near_top_right_clip = Point3f(1)
            
            fbl_px = Makie.project(sc, :clip, :pixel, far_bottom_left_clip)
            ntr_px = Makie.project(sc, :clip, :pixel, near_top_right_clip)
            @test Point2f(fbl_px) == Point2f(0, 0)
            @test Point2f(ntr_px) == Point2f(650, 400)
        end

        @testset "No warnings in projections between spaces" begin
            for (source, dest) in unique(Iterators.product(Makie.spaces(), Makie.spaces()))
                source == dest && continue
                current_space_points = Makie.project.(sc, :pixel, source, corner_points_px)
                @testset "$source → $dest" begin
                    @test_nowarn Makie.project.(sc, source, dest, current_space_points)
                end
            end
        end
    end
end

@testset "transformation matrix decomposition" begin
    for _ in 1:10
        v1 = normalize(2f0 .* rand(Vec3f) .- 1.0)
        v2 = normalize(2f0 .* rand(Vec3f) .- 1.0)
        rot = Makie.rotation_between(v1, v2)
        trans = 10.0 .* (2.0 .* rand(Vec3f) .- 1.0)
        scale = 10.0 .* rand(Vec3f) # avoid negative because decomposition puts negative into rotation

        M = Makie.translationmatrix(trans) *
            Makie.scalematrix(scale) *
            Makie.rotationmatrix4(rot)

        t, s, r = Makie.decompose_translation_scale_rotation_matrix(M)
        @test t ≈ trans
        @test s ≈ scale
        @test r ≈ rot

        M2 = Makie.translationmatrix(t) *
            Makie.scalematrix(s) *
            Makie.rotationmatrix4(r)

        @test M ≈ M2
    end
end