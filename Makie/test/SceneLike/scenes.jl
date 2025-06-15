@testset "Scenes" begin
    scene = Scene()
    @test propertynames(scene) == fieldnames(Scene)
    @testset "getproperty(scene, :$field)" for field in fieldnames(Scene)
        @test getproperty(scene, field) !== missing # well, just don't error
    end
    @test theme(nothing, :nonexistent, default = 1) == 1
    @test theme(scene, :nonexistent, default = 1) == 1
end

@testset "Lighting" begin
    @testset "Shading default" begin
        # Based on number of lights
        lights = Makie.AbstractLight[]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == FastShading # Should this be NoShading?

        # shading mode should be constant after the first get_shading_mode() call
        # (Which should happen when the first renderobject is created)
        push!(lights, PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0)))
        @test Makie.get_shading_mode(scene) == FastShading

        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading

        lights = Makie.AbstractLight[]
        push!(lights, AmbientLight(RGBf(0.1, 0.1, 0.1)))
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == FastShading

        push!(lights, DirectionalLight(RGBf(0.1, 0.1, 0.1), Vec3f(1)))
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == FastShading

        push!(lights, PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0)))
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading

        # Based on light types
        lights = [SpotLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec3f(1), Vec2f(0.2, 0.3))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading

        lights = [EnvironmentLight(1.0, rand(2, 2))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == FastShading # only affects RPRMakie so skipped here

        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading

        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec2f(0.1, 0.2))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading
    end

    @testset "Helper functions" begin
        f, a, p = scatter(rand(Point3f, 10))
        @test length(get_lights(a)) == 1

        set_ambient_light!(a, RGBf(0, 0, 1))
        @test a.scene.compute[:ambient_color][] == RGBf(0, 0, 01)

        @test get_lights(a)[1].color != RGBf(1, 0, 0)
        set_directional_light!(a, color = RGBf(1, 0, 0))
        @test get_lights(a)[1].color == RGBf(1, 0, 0)

        @test get_lights(a)[1].camera_relative != false
        set_directional_light!(a, camera_relative = false)
        @test get_lights(a)[1].camera_relative == false

        @test get_lights(a)[1].direction != Vec3f(1, 0, 0)
        set_directional_light!(a, direction = Vec3f(1, 0, 0))
        @test get_lights(a)[1].direction == Vec3f(1, 0, 0)

        @test a.scene.compute.shading[] == Makie.automatic
        set_shading_algorithm!(a, MultiLightShading)
        @test a.scene.compute.shading[] == MultiLightShading
        @test_throws ErrorException set_directional_light!(a, color = RGBf(0, 0, 1))

        set_shading_algorithm!(a, FastShading)
        @test a.scene.compute.shading[] == FastShading
        @test set_directional_light!(a, color = RGBf(0, 0, 1)) === nothing

        set_shading_algorithm!(a, Makie.automatic)

        set_lights!(a, [])
        @test length(get_lights(a)) == 0

        @test_throws ErrorException set_directional_light!(a, color = RGBf(0, 0, 1))

        push_light!(a, PointLight(RGBf(1, 0, 0), Point3f(0)))
        @test get_lights(a) == [PointLight(RGBf(1, 0, 0), Point3f(0))]

        push_light!(a, PointLight(RGBf(0, 1, 0), Point3f(0)))
        push_light!(a, PointLight(RGBf(0, 0, 1), Point3f(0)))
        @test get_lights(a) == [PointLight(RGBf(1, 0, 0), Point3f(0)), PointLight(RGBf(0, 1, 0), Point3f(0)), PointLight(RGBf(0, 0, 1), Point3f(0))]

        set_light!(a, 2, DirectionalLight(RGBf(1, 1, 1), Vec3f(1, 0, 0)))
        @test get_lights(a) == [PointLight(RGBf(1, 0, 0), Point3f(0)), DirectionalLight(RGBf(1, 1, 1), Vec3f(1, 0, 0)), PointLight(RGBf(0, 0, 1), Point3f(0))]

        @test_throws ErrorException set_directional_light!(a, color = RGBf(0, 0, 1))
        @test_throws BoundsError set_light!(a, 10, color = RGBf(0, 0, 1))

        set_lights!(a, [PointLight(RGBf(1, 1, 0), Vec3f(1))])
        @test get_lights(a) == [PointLight(RGBf(1, 1, 0), Vec3f(1))]

        @test_throws ErrorException set_directional_light!(a, color = RGBf(0, 0, 1))
    end
end
