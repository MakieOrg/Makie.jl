using Makie

@testset "Projection math" begin
    @testset "Rotation matrix" begin
        @test eltype(Makie.rotationmatrix_x(1)) == Float64
        @test eltype(Makie.rotationmatrix_x(1f0)) == Float32
    end

    @testset "Projection between spaces in 3D" begin
        # Set up an LScene and some points there
        sc = Scene(size = (650, 400), camera = cam3d!)
        update_cam!(sc, Vec3d(0, 1, 0), Vec3d(0))
        corner_points_px = [Point3f(0, 0, 0), Point3f(650, 400, 0)]

        @testset "Clip space and pixel space equivalence" begin
            far_bottom_left_clip = Point3f(-1)
            near_top_right_clip = Point3f(1)

            fbl_px = Makie.project(sc, :clip, :pixel, far_bottom_left_clip)
            ntr_px = Makie.project(sc, :clip, :pixel, near_top_right_clip)
            @test fbl_px == Point3f(0, 0, 10_000)
            @test ntr_px == Point3f(650, 400, -10_000)

            # These tests are sensitive to camera settings. If the projectionview
            # check fails the rest probably needs to be recalculated.
            pv = Mat4d(-1.4856698845372893, 0.0, 0.0, 0.0, 0.0, 0.0, -1.024204047037133, -1.0, 0.0, 2.4142135623730954, 0.0, 0.0, 0.0, 0.0, 0.8217836423334196, 1.0)
            @test pv ≈ sc.camera.projectionview[] atol = 1e-10

            bottom_left_data = Vec3d(0.13302875, 0.8023632, -0.08186384)
            top_righ_data = Vec3d(-0.13302875, 0.8023632, 0.08186384)
            @test Makie.project(sc, bottom_left_data) ≈ Point2f(0, 0)     atol = 1e-4
            @test Makie.project(sc, top_righ_data)    ≈ Point2f(650, 400) atol = 1e-4

            @test Makie.project(sc, :pixel, :data, Vec2f(0, 0))     ≈ bottom_left_data
            @test Makie.project(sc, :pixel, :data, Vec2f(650, 400)) ≈ top_righ_data
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