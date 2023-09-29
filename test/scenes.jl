@testset "Scenes" begin
    scene = Scene()
    @test propertynames(scene) == fieldnames(Scene)
    @testset "getproperty(scene, :$field)" for field in fieldnames(Scene)
        @test getproperty(scene, field) !== missing # well, just don't error
    end
    @test theme(nothing, :nonexistant, default=1) == 1
    @test theme(scene, :nonexistant, default=1) == 1
end

@testset "Lighting" begin
    @testset "Shading default" begin
        # Based on number of lights
        lights = Makie.AbstractLight[]
        @test Makie.get_shading_default(lights) === NoShading
        push!(lights, AmbientLight(RGBf(0.1, 0.1, 0.1)))
        @test Makie.get_shading_default(lights) === FastShading
        push!(lights, PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0)))
        @test Makie.get_shading_default(lights) === FastShading
        push!(lights, PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0)))
        @test Makie.get_shading_default(lights) === MultiLightShading

        # Based on light types
        lights = [SpotLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec3f(1), Vec2f(0.2, 0.3))]
        @test Makie.get_shading_default(lights) === MultiLightShading
        lights = [DirectionalLight(RGBf(0.1, 0.1, 0.1), Vec3f(1))]
        @test Makie.get_shading_default(lights) === MultiLightShading
        lights = [EnvironmentLight(1.0, rand(2,2))]
        @test Makie.get_shading_default(lights) === NoShading # only affects RPRMakie so skipped here
        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0))]
        @test Makie.get_shading_default(lights) === FastShading
        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec2f(0.1, 0.2))]
        @test Makie.get_shading_default(lights) === MultiLightShading
    end
end