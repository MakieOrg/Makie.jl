using Makie

@testset "Camera space_to_space matrices" begin
    # Sanity check - these should all be mat * inv
    f, a, p = scatter(rand(Point2f, 10))
    Makie.update_state_before_display!(f)
    cam = a.scene.compute
    spaces = [:world, :pixel, :clip, :relative, :eye]
    for i in 1:5, j in i:5
        a = spaces[i]; b = spaces[j]
        @testset ":$a <-> :$b" begin
            @test cam[Symbol(a, :_to_, b)][] * cam[Symbol(b, :_to_, a)][] ≈ Makie.Mat4d(I)
            @test cam[Symbol(b, :_to_, a)][] * cam[Symbol(a, :_to_, b)][] ≈ Makie.Mat4d(I)
        end
    end
end

@testset "Projection math" begin
    @testset "Rotation matrix" begin
        @test eltype(Makie.rotationmatrix_x(1)) == Float64
        @test eltype(Makie.rotationmatrix_x(1.0f0)) == Float32
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

            ipv = inv(sc.camera.projectionview[])
            div4(p) = p[Vec(1, 2, 3)] / p[4]
            bottom_left_data = div4(ipv * Point4d(-1, -1, 0, 1))
            top_right_data = div4(ipv * Point4d(+1, +1, 0, 1))
            @test Makie.project(sc, bottom_left_data) ≈ Point2f(0, 0)     atol = 1.0e-4
            @test Makie.project(sc, top_right_data) ≈ Point2f(650, 400) atol = 1.0e-4

            @test Makie.project(sc, :pixel, :data, Vec2f(0, 0)) ≈ bottom_left_data
            @test Makie.project(sc, :pixel, :data, Vec2f(650, 400)) ≈ top_right_data
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
        v1 = normalize(2.0f0 .* rand(Vec3f) .- 1.0)
        v2 = normalize(2.0f0 .* rand(Vec3f) .- 1.0)
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
