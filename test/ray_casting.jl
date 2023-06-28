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


    # Note that these tests depend on the exact placement of plots and may 
    # error when cameras are adjusted
    @testset "position_on_plot()" begin
    
        # Lines (2D) & Linesegments (3D)
        ps = [exp(-0.01phi) * Point2f(cos(phi), sin(phi)) for phi in range(0, 20pi, length = 501)]
        scene = Scene(resolution = (400, 400))
        p = lines!(scene, ps)
        cam2d!(scene)
        ray = Makie.Ray(scene, (325.0, 313.0))
        pos = Makie.position_on_plot(p, 157, ray)
        @test pos ≈ Point3f(0.6087957666683925, 0.5513198993583837, 0.0)
    
        scene = Scene(resolution = (400, 400))
        p = linesegments!(scene, ps)
        cam3d!(scene)
        ray = Makie.Ray(scene, (238.0, 233.0))
        pos = Makie.position_on_plot(p, 178, ray)
        @test pos ≈ Point3f(-0.7850463447725504, -0.15125213957100314, 0.0)
    
    
        # Heatmap (2D) & Image (3D)
        scene = Scene(resolution = (400, 400))
        p = heatmap!(scene, 0..1, -1..1, rand(10, 10))
        cam2d!(scene)
        ray = Makie.Ray(scene, (228.0, 91.0))
        pos = Makie.position_on_plot(p, 0, ray)
        @test pos ≈ Point3f(0.13999999, -0.54499996, 0.0)
    
        scene = Scene(resolution = (400, 400))
        p = image!(scene, -1..1, -1..1, rand(10, 10))
        cam3d!(scene)
        ray = Makie.Ray(scene, (309.0, 197.0))
        pos = Makie.position_on_plot(p, 3, ray)
        @test pos ≈ Point3f(-0.7830243, 0.8614166, 0.0)
    
    
        # Mesh (3D)
        scene = Scene(resolution = (400, 400))
        p = mesh!(scene, Rect3f(Point3f(0), Vec3f(1)))
        cam3d!(scene)
        ray = Makie.Ray(scene, (201.0, 283.0))
        pos = Makie.position_on_plot(p, 15, ray)
        @test pos ≈ Point3f(0.029754717, 0.043159597, 1.0)
    
        # Surface (3D)
        scene = Scene(resolution = (400, 400))
        p = surface!(scene, -2..2, -2..2, [sin(x) * cos(y) for x in -10:10, y in -10:10])
        cam3d!(scene)
        ray = Makie.Ray(scene, (52.0, 238.0))
        pos = Makie.position_on_plot(p, 57, ray)
        @test pos ≈ Point3f(0.80910987, -1.6090667, 0.137722)
    
        # Volume (3D)
        scene = Scene(resolution = (400, 400))
        p = volume!(scene, rand(10, 10, 10))
        cam3d!(scene)
        center!(scene)
        ray = Makie.Ray(scene, (16.0, 306.0))
        pos = Makie.position_on_plot(p, 0, ray)
        @test pos ≈ Point3f(10.0, 0.18444633, 9.989262)
    end

    # For recreating the above:
    #= 
    # Scene setup from tests:
    scene = Scene(resolution = (400, 400))
    p = surface!(scene, -2..2, -2..2, [sin(x) * cos(y) for x in -10:10, y in -10:10])
    cam3d!(scene)
    
    pos = Observable(Point3f(0.5))
    on(events(scene).mousebutton, priority = 100) do event
        if event.button == Mouse.left && event.action == Mouse.press
            mp = events(scene).mouseposition[]
            _p, idx = pick(scene, mp, 10)
            pos[] = Makie.position_on_plot(p, idx)
            println(_p == p)
            println("ray = Makie.Ray(scene, $mp)")
            println("pos = Makie.position_on_plot(p, $idx, ray)")
            println("@test pos ≈ Point3f(", pos[][1], ", ", pos[][2], ", ", pos[][3], ")")
        end
    end

    # Optional - show selected positon
    # This may change the camera, so don't use it for test values
    # scatter!(scene, pos)

    scene
    =#
end