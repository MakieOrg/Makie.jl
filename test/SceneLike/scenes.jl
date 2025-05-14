@testset "Scenes" begin
    scene = Scene()
    @test propertynames(scene) == fieldnames(Scene)
    @testset "getproperty(scene, :$field)" for field in fieldnames(Scene)
        @test getproperty(scene, field) !== missing # well, just don't error
    end
    @test theme(nothing, :nonexistent, default=1) == 1
    @test theme(scene, :nonexistent, default=1) == 1
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

        lights = [EnvironmentLight(1.0, rand(2,2))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == FastShading # only affects RPRMakie so skipped here

        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading

        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec2f(0.1, 0.2))]
        scene = Scene(lights = lights)
        @test Makie.get_shading_mode(scene) == MultiLightShading
    end
end
