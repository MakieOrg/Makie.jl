using Makie: Plane, Plane3f, Point3d, Rect3d, Vec3d

@testset "Plane" begin
    @testset "Constructors" begin
        for T in (Float32, Float64)
            plane = Plane(Point3{T}(1), Vec3{T}(1, 1, 0))
            @test plane isa Plane{3, T}
            @test plane.normal ≈ normalize(Vec3{T}(1, 1, 0))
            @test plane.distance ≈ T(sqrt(2.0))

            plane = Plane(Point2{T}(1), Vec2{T}(0, 1))
            @test plane isa Plane{2, T}
            @test plane.normal == Vec2{T}(0, 1)
            @test plane.distance ≈ T(1)

            plane = Plane(Vec3{T}(1), 2.0)
            @test plane isa Plane{3, T}
            @test plane.normal ≈ normalize(Vec3{T}(1))
            @test plane.distance ≈ T(2)

            clip_box = Rect3f(Point3f(0), Vec3f(1))
            planes = Makie.planes(clip_box)
            @test planes == [
                Plane3f(Vec3f(1, 0, 0), 0.0f0),
                Plane3f(Vec3f(0, 1, 0), 0.0f0),
                Plane3f(Vec3f(0, 0, 1), 0.0f0),
                Plane3f(Vec3f(-1, 0, 0), -1.0f0),
                Plane3f(Vec3f(0, -1, 0), -1.0f0),
                Plane3f(Vec3f(0, 0, -1), -1.0f0),
            ]

            plane = Plane(Vec3{T}(0), 2.0)
            @test plane isa Plane{3, T}
            @test plane.normal ≈ Vec3{T}(0)
            @test plane.distance ≈ T(2)
        end
    end

    @testset "Basic clipping" begin
        plane = Plane(Point3f(0, 1, 0), Vec3f(0, 1, 0))
        @test Makie.distance(plane, Point3f(0)) ≈ -1.0f0
        @test Makie.distance(plane, Point3f(0, 1, 0)) ≈ 0.0f0
        @test Makie.distance(plane, Point3f(0, 2, 0)) ≈ 1.0f0
        @test Makie.distance(plane, Point3f(pi, 1, -9.5)) ≈ 0.0f0

        @test Makie.is_clipped(plane, Point3f(0)) == true
        @test Makie.is_clipped(plane, Point3f(2)) == false

        @test Makie.is_visible(plane, Point3f(0)) == false
        @test Makie.is_visible(plane, Point3f(2)) == true

        clip_box = Rect3f(Point3f(-1), Vec3f(2))
        planes = Makie.planes(clip_box)

        # while not clipped: closest distance to plane
        @test Makie.min_clip_distance(planes, Point3f(0)) ≈ 1.0f0
        @test Makie.min_clip_distance(planes, Point3f(0.5, 0, 0)) ≈ 0.5f0
        # while clipped: closest distance to a plane that clips the point
        @test Makie.min_clip_distance(planes, Point3f(1.2, 0, 0)) ≈ -0.2f0
        @test Makie.min_clip_distance(planes, Point3f(1.5, 0.9, 0)) ≈ -0.5f0
    end

    @testset "Utilities" begin
        # perpendicular_vector()
        for _ in 1:10
            v = normalize(2.0f0 .* rand(Vec3f) .- 1)
            v2 = Makie.perpendicular_vector(v)
            @test abs(dot(v, v2)) < 1.0f-6
        end

        # closest_point_on_plane()
        plane = Plane(Point3f(0, 0, 1), Vec3f(1))
        p = Makie.closest_point_on_plane(plane, Point3f(0))
        @test abs(Makie.distance(plane, p)) < 1.0f-6
        p = Makie.closest_point_on_plane(plane, Point3f(0, 0, 1))
        @test abs(Makie.distance(plane, p)) < 1.0f-6
        @test p ≈ Point3f(0, 0, 1)

        # to_mesh()
        m = Makie.to_mesh(plane, origin = Point3f(0, 0, 1), scale = 1)
        ps = coordinates(m)
        @test all(p -> abs(Makie.distance(plane, p)) < 1.0f-6, ps)
        @test all(p -> norm(p - Point3f(0, 0, 1)) ≈ sqrt(2.0f0), ps)

        # unclipped_indices()
        ps = rand(Point3f, 100)
        plane = Plane(Point3f(0.5), Vec3f(1, 0, 0))
        visible = Makie.is_visible.((plane,), ps)
        idxs = collect(1:100)[visible]
        @test idxs == Makie.unclipped_indices([plane], ps, :data)
        @test eachindex(ps) == Makie.unclipped_indices([plane], ps, :other)
    end

    @testset "Transformations" begin
        # Test apply_transform()
        plane = Plane(Point3f(1), Vec3f(0, 0, 1))
        v = normalize(2.0f0 .* rand(Vec3f) .- 1)
        R = Makie.rotationmatrix4(Makie.rotation_between(Vec3f(0, 0, 1), v))
        plane2 = Makie.apply_transform(R, plane)
        @test plane2.normal ≈ v
        @test plane2.distance ≈ 1.0f0

        T = Makie.translationmatrix(Vec3f(1, 1, 1))
        plane2 = Makie.apply_transform(T, plane)
        @test plane2.normal ≈ Vec3f(0, 0, 1)
        @test plane2.distance ≈ 2.0f0

        # test to_model_space()
        ps = [2.0f0 .* rand(Point3f) .- 1.0f0 for _ in 1:1000]
        q = Makie.rotation_between(Vec3f(1, 0, 0), Vec3f(0, 0, 1))
        model = Makie.transformationmatrix(Vec3f(1, 0, 0), Vec3f(2, 2, 2), q)
        plane = Plane3f(Point3f(0.5), Vec3f(0, 0, 1))

        # transform points
        ds = let
            transformed = map(p -> Point3f(model * to_ndim(Point4f, p, 1)), ps)
            Makie.distance.((plane,), transformed)
        end
        # transform plane
        plane2 = Makie.to_model_space(model, [plane])[1]
        ds2 = Makie.distance.((plane2,), ps)
        @test all(isapprox.(ds, 2.0f0 .* ds2, rtol = 1.0e-6, atol = sqrt(eps(Float32))))

        # apply_clipping_planes()
        bbox = Rect3d(Point3d(-1), Vec3d(2))
        planes = [Plane3f(Point3f(0.5), Vec3f(-0.5))]
        @test Makie.apply_clipping_planes(planes, bbox) == bbox

        planes = [Plane3f(Point3f(0, 0, 0.5), Vec3f(-0.0, -0.0, -0.5))]
        @test Makie.apply_clipping_planes(planes, bbox) == Rect3d(Point3d(-1), Vec3d(2, 2, 1.5))

        planes = Makie.planes(Rect3f(Point3f(-0.5), Vec3f(1)))
        bb = Makie.apply_clipping_planes(planes, bbox)
        @test minimum(bb) ≈ Vec3f(-0.5)
        @test maximum(bb) ≈ Vec3f(0.5)

        planes = Makie.planes(Rect3f(Point3f(0.5), Vec3f(1)))
        bb = Makie.apply_clipping_planes(planes, bbox)
        @test minimum(bb) ≈ Vec3f(0.5)
        @test maximum(bb) ≈ Vec3f(1.0)

        # to_clip_space()
        ps = [2.0f0 .* rand(Point3f) .- 1.0f0 for _ in 1:1000]
        planes = Makie.planes(Rect3f(Point3f(-0.5), Vec3f(1)))
        filter!(ps) do p # drop points that may cause tests to fail due to float precision issues
            min_dist = mapreduce(plane -> abs(Makie.distance(plane, p)), min, planes)
            return min_dist > 1.0f-10
        end
        inside = sum(Makie.is_visible.((planes,), ps))

        # COV_EXCL_START
        f, a, p = scatter(ps)
        Makie.update_state_before_display!(f)
        # COV_EXCL_STOP
        cam = a.scene.camera
        planes2 = Makie.to_clip_space(cam, planes)
        # clip_points = Makie.project.((cam.projectionview[],), ps)
        clip_points = map(ps) do p
            p4d = Makie.to_ndim(Point4f, p, 1)
            p4d = cam.projectionview[] * p4d
            Point3f(p4d) / p4d[4]
        end
        inside2 = sum(Makie.is_visible.((planes2,), clip_points))
        @test inside == inside2
    end
end
