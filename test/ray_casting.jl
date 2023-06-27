@testset "Ray Casting" begin
    @testset "View Rays" begin
        scene = Scene()
        xy = 0.5 * widths(pixelarea(scene)[])

        orthographic_cam3d!(x) = cam3d!(x, perspectiveprojection = Makie.Orthographic)

        for set_cam! in (cam2d!, cam_relative!, campixel!, cam3d!, orthographic_cam3d!)
            @testset "$set_cam!" begin
                set_cam!(scene)
                ray = Makie.Ray(scene, xy)
                ref_ray = Makie.ray_from_projectionview(scene, xy)
                # Direction matches and is normalized
                @test ref_ray.direction ≈ ray.direction
                @test norm(ray.direction) ≈ 1f0
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
    direction = (1 + 10*rand()) * rand(Vec3f)
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
end