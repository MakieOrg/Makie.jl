@testset "Ray Casting" begin
    @testset "View Rays" begin
        scene = Scene()
        xy = 0.5 * widths(viewport(scene)[])

        orthographic_cam3d!(x) = cam3d!(x, perspectiveprojection = Makie.Orthographic)

        for set_cam! in (cam2d!, cam_relative!, campixel!, cam3d!, orthographic_cam3d!)
            @testset "$set_cam!" begin
                set_cam!(scene)
                ray = convert(Makie.Ray{Float32}, Makie.Ray(scene, xy))
                ref_ray = Makie.ray_from_projectionview(scene, xy)
                # Direction matches and is normalized
                @test ref_ray.direction ≈ ray.direction
                @test norm(ray.direction) ≈ 1.0f0
                # origins are on the same ray
                @test Makie.is_point_on_ray(ray.origin, ref_ray)
            end
        end
    end


    # transform() is used to apply a translation-rotation-scale matrix to rays
    # instead of point like data
    # Generate random point + transform
    rot = Makie.rotation_between(rand(Vec3f), rand(Vec3f))
    model = Makie.transformationmatrix(rand(Vec3f), rand(Vec3f), rot)
    point = Point3f(1) + rand(Point3f)

    # Generate rate that passes through transformed point
    transformed = Point3f(model * Point4f(point..., 1))
    direction = (1 + 10 * rand()) * rand(Vec3f)
    ray = Makie.Ray(transformed + direction, normalize(direction))

    @test Makie.is_point_on_ray(transformed, ray)
    transformed_ray = Makie.transform(inv(model), ray)
    @test Makie.is_point_on_ray(point, transformed_ray)


    @testset "Intersections" begin
        p = rand(Point3f)
        v = rand(Vec3f)
        ray = Makie.Ray(p + 10v, normalize(v))

        # ray - line
        w = cross(v, rand(Vec3f))
        A = p - 5w
        B = p + 5w
        result = Makie.closest_point_on_line(A, B, ray)
        @test result ≈ p

        # ray - triangle
        w2 = cross(v, w)
        A = p - 5w - 5w2
        B = p + 5w
        C = p + 5w2
        result = Makie.ray_triangle_intersection(A, B, C, ray)
        @test result ≈ p

        # ray - rect3
        rect = Rect(Vec(A), 10w + 10w2 + 10v)
        result = Makie.ray_rect_intersection(rect, ray)
        @test Makie.is_point_on_ray(result, ray)

        # ray - rect2
        p2 = Point2f(ray.origin - ray.origin[3] / ray.direction[3] * ray.direction)
        w = rand(Vec2f)
        rect = Rect2f(p2 - 5w, 10w)
        result = Makie.ray_rect_intersection(rect, ray)
        @test result ≈ Point3f(p2..., 0)
    end


    # Note that these tests depend on the exact placement of plots and may
    # error when cameras are adjusted
    @testset "position_on_plot()" begin
        using Makie: Vec3d
        struct ScaleTransform
            xyz::Vec3d
        end
        Base.broadcastable(x::ScaleTransform) = (x,)
        Makie.inverse_transform(x::ScaleTransform) = ScaleTransform(1.0 ./ x.xyz)
        function Makie.apply_transform(t::ScaleTransform, p::VT) where {VT <: VecTypes}
            return to_ndim(VT, t.xyz, NaN) .* p
        end
        function Makie.apply_transform(t::ScaleTransform, p::VT) where {VT <: VecTypes}
            return to_ndim(VT, t.xyz, NaN) .* p
        end

        transform = Transformation(
            Vec3d(0.2, -0.3, 0.2), Vec3d(1), Makie.qrotation(Vec3f(1, 0.5, 0.1), 0.1),
            ScaleTransform(Vec3d(1.1, 0.8, 1.2))
        )
        # Some plots don't support transform_funcs
        simple_transform = Transformation(
            Vec3d(0.2, -0.3, 0.2), Vec3d(1), Makie.qrotation(Vec3f(1, 0.5, 0.1), 0.1),
            identity
        )

        @testset "apply_transform = true" begin
            # Lines (2D) & Linesegments (3D)
            ps = [exp(-0.01phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 501)]
            scene = Scene(size = (400, 400))
            p = lines!(scene, ps, transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (304.0, 46.0))
            pos = Makie.position_on_plot(p, 343, ray, apply_transform = true)
            @test pos ≈ Point3f(0.51691383, -0.76265544, 0.14444983)

            scene = Scene(size = (400, 400))
            p = linesegments!(scene, ps, transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (175.0, 179.0))
            pos = Makie.position_on_plot(p, 110, ray, apply_transform = true)
            @test pos ≈ Point3f(0.6449571, 0.31751874, 0.23500901)


            # Heatmap (2D) & Image (3D)
            scene = Scene(size = (400, 400))
            p = heatmap!(scene, 0 .. 1, -1 .. 1, rand(10, 10), transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (344.0, 156.0))
            pos = Makie.position_on_plot(p, 0, ray, apply_transform = true)
            @test pos ≈ Point3f(0.72, -0.22000003, 0.18368815)

            scene = Scene(size = (400, 400))
            p = image!(scene, -1 .. 1, -1 .. 1, rand(10, 10), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (201.0, 244.0))
            pos = Makie.position_on_plot(p, 3, ray, apply_transform = true)
            @test pos ≈ Point3f(-0.40582713, -0.38963372, 0.21932258)

            # Mesh (3D)
            scene = Scene(size = (400, 400))
            p = mesh!(scene, Rect3f(Point3f(0), Vec3f(1)), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (86.0, 204.0))
            pos = Makie.position_on_plot(p, 8, ray, apply_transform = true)
            @test pos ≈ Point3f(1.3195645, -0.036446463, 0.6827639)

            # Surface (3D)
            scene = Scene(size = (400, 400))
            p = surface!(
                scene, -2 .. 2, -2 .. 2, [sin(x) * cos(y) for x in -10:10, y in -10:10],
                transformation = simple_transform
            )
            cam3d!(scene)
            ray = Makie.Ray(scene, (129.0, 188.0))
            pos = Makie.position_on_plot(p, 332, ray, apply_transform = true)
            @test pos ≈ Point3f(1.2557555, 0.47272062, 0.7496249)

            # Volume (3D)
            scene = Scene(size = (400, 400))
            p = volume!(scene, rand(10, 10, 10), transformation = simple_transform)
            cam3d!(scene)
            center!(scene)
            ray = Makie.Ray(scene, (265.0, 197.0))
            pos = Makie.position_on_plot(p, 0, ray, apply_transform = true)
            @test pos ≈ Point3f(6.7095942, 9.059586, 8.309836)

            # scatter (3D), meshscatter (2D)
            scene = Scene(size = (400, 400))
            ps = [exp(-0.02phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 198)]
            p = meshscatter!(scene, ps, markersize = 0.03, transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (355.0, 153.0))
            pos = Makie.position_on_plot(p, 100, ray, apply_transform = true)
            @test pos ≈ Point3f(0.7764834, -0.22643188, 0.18056774)

            scene = Scene(size = (400, 400))
            p = scatter!(scene, Sphere(Point3f(0), 1.0f0), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (160.0, 279.0))
            pos = Makie.position_on_plot(p, 102, ray, apply_transform = true)
            @test pos ≈ Point3f(0.5577118, 0.0673411, 1.1521214)
        end


        @testset "apply_transform = false" begin
            # Lines (2D) & Linesegments (3D)
            ps = [exp(-0.01phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 501)]
            scene = Scene(size = (400, 400))
            p = lines!(scene, ps, transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (103.0, 132.0))
            pos = Makie.position_on_plot(p, 377, ray, apply_transform = true)
            @test pos ≈ Point3f(-0.48247042, -0.33972764, 0.22722912)

            scene = Scene(size = (400, 400))
            p = linesegments!(scene, ps, transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (202.0, 203.0))
            pos = Makie.position_on_plot(p, 314, ray, apply_transform = true)
            @test pos ≈ Point3f(0.20256737, 0.23707463, 0.24778186)


            # Heatmap (2D) & Image (3D)
            scene = Scene(size = (400, 400))
            p = heatmap!(scene, 0 .. 1, -1 .. 1, rand(10, 10), transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (334.0, 80.0))
            pos = Makie.position_on_plot(p, 0, ray, apply_transform = true)
            @test pos ≈ Point3f(0.66999996, -0.6, 0.1520533)

            scene = Scene(size = (400, 400))
            p = image!(scene, -1 .. 1, -1 .. 1, rand(10, 10), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (136.0, 172.0))
            pos = Makie.position_on_plot(p, 4, ray, apply_transform = true)
            @test pos ≈ Point3f(0.9401679, 0.100687966, 0.20236067)

            # Mesh (3D)
            scene = Scene(size = (400, 400))
            p = mesh!(scene, Rect3f(Point3f(0), Vec3f(1)), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (172.0, 282.0))
            pos = Makie.position_on_plot(p, 15, ray, apply_transform = true)
            @test pos ≈ Point3f(0.7139215, 0.40438107, 1.344213)

            # Surface (3D)
            scene = Scene(size = (400, 400))
            p = surface!(
                scene, -2 .. 2, -2 .. 2, [sin(x) * cos(y) for x in -10:10, y in -10:10],
                transformation = simple_transform
            )
            cam3d!(scene)
            ray = Makie.Ray(scene, (118.0, 208.0))
            pos = Makie.position_on_plot(p, 310, ray, apply_transform = true)
            @test pos ≈ Point3f(1.0995945, 0.11597935, 0.69089276)

            # Volume (3D)
            scene = Scene(size = (400, 400))
            p = volume!(scene, rand(10, 10, 10), transformation = transform)
            cam3d!(scene)
            center!(scene)
            ray = Makie.Ray(scene, (168.0, 159.0))
            pos = Makie.position_on_plot(p, 0, ray, apply_transform = true)
            @test pos ≈ Point3f(11.36708, 7.0137014, 9.09381)

            # scatter (3D), meshscatter (2D)
            scene = Scene(size = (400, 400))
            ps = [exp(-0.02phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 198)]
            p = meshscatter!(scene, ps, markersize = 0.03, transformation = transform)
            cam2d!(scene)
            ray = Makie.Ray(scene, (301.0, 199.0))
            pos = Makie.position_on_plot(p, 122, ray, apply_transform = true)
            @test pos ≈ Point3f(0.5164561, -0.009674309, 0.21162316)

            scene = Scene(size = (400, 400))
            p = scatter!(scene, Sphere(Point3f(0), 1.0f0), transformation = transform)
            cam3d!(scene)
            ray = Makie.Ray(scene, (166.0, 132.0))
            pos = Makie.position_on_plot(p, 527, ray, apply_transform = true)
            @test pos ≈ Point3f(0.27489948, -0.24948473, -0.9936166)
        end
    end

    # For recreating the above: (may not work on unfocused window, needs transform definitions above)
    #=
    # Scene setup from tests:
            ps = [exp(-0.01phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 501)]
            scene = Scene(size = (400, 400))
            p = lines!(scene, ps, transformation = transform)
            cam2d!(scene)
    pos = Observable(Point3f(0.5))
    on(events(scene).mousebutton, priority = 100) do event
        if event.button == Mouse.left && event.action == Mouse.press
            mp = events(scene).mouseposition[]
            _p, idx = pick(scene, mp, 10)
            println(_p == p, " ", idx, " ", _p)
            if _p == p
                pos[] = Makie.position_on_plot(p, idx, apply_transform = true)
                println("ray = Makie.Ray(scene, $mp)")
                println("pos = Makie.position_on_plot(p, $idx, ray)")
                println("@test pos ≈ Point3f(", pos[][1], ", ", pos[][2], ", ", pos[][3], ")")
            end
            println()
        end
    end

    # Optional - show selected position
    # This may change the camera, so don't use it for test values
    # for apply_transform = false, add `transformation = transform`
    scatter!(scene, pos, color = :red, strokewidth = 1.0, strokecolor = :yellow, depth_shift = -1f-1)

    display(scene, update = false)
    =#
end
