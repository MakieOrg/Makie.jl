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
        plot = (attributes = Attributes(),) # simplified "plot"

        # Based on number of lights
        lights = Makie.AbstractLight[]
        Makie.default_shading!(plot, lights)
        @test !haskey(plot.attributes, :shading)

        plot.attributes[:shading] = Observable(Makie.automatic)
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === NoShading

        plot.attributes[:shading] = Observable(Makie.automatic)
        push!(lights, AmbientLight(RGBf(0.1, 0.1, 0.1)))
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === FastShading

        plot.attributes[:shading] = Observable(Makie.automatic)
        push!(lights, DirectionalLight(RGBf(0.1, 0.1, 0.1), Vec3f(1)))
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === FastShading

        plot.attributes[:shading] = Observable(Makie.automatic)
        push!(lights, PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0)))
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === MultiLightShading

        # Based on light types
        plot.attributes[:shading] = Observable(Makie.automatic)
        lights = [SpotLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec3f(1), Vec2f(0.2, 0.3))]
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === MultiLightShading

        plot.attributes[:shading] = Observable(Makie.automatic)
        lights = [EnvironmentLight(1.0, rand(2, 2))]
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === NoShading # only affects RPRMakie so skipped here

        plot.attributes[:shading] = Observable(Makie.automatic)
        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0))]
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === MultiLightShading

        plot.attributes[:shading] = Observable(Makie.automatic)
        lights = [PointLight(RGBf(0.1, 0.1, 0.1), Point3f(0), Vec2f(0.1, 0.2))]
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === MultiLightShading

        # keep existing shading type
        lights = Makie.AbstractLight[]
        Makie.default_shading!(plot, lights)
        @test to_value(plot.attributes[:shading]) === MultiLightShading
    end
end
