using Makie: Mat, Mat3f, convert_attribute, uv_transform, automatic
using Makie: to_color
using Makie.Colors

@testset "uv_transform" begin
    key = Makie.key"uv_transform"()

    # defaults matching previous Makie versions
    @test convert_attribute(automatic, key, Makie.key"meshscatter"()) == Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
    @test convert_attribute(automatic, key, Makie.key"mesh"()) == Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0)
    @test convert_attribute(automatic, key, Makie.key"surface"()) == Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)
    @test convert_attribute(automatic, key, Makie.key"image"()) == Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1)

    # General Pipeline
    # Each should work as a value or as a vector element
    for wrap in (identity, x -> [x])
        M = Mat{2, 3, Float32}(1, 2, 3, 4, 5, 6)
        @test convert_attribute(wrap(M), key) == wrap(M)

        M3 = Mat3f(1, 2, 0, 3, 4, 0, 5, 6, 0)
        @test convert_attribute(wrap(M3), key) == wrap(M)

        # transformationmatrix-like
        @test convert_attribute(wrap(Vec2f(2, 3)), key) == wrap(Mat{2, 3, Float32}(2, 0, 0, 3, 0, 0))
        @test convert_attribute(wrap((Vec2f(-1, -2), Vec2f(2, 3))), key) ==
            wrap(Mat{2, 3, Float32}(2, 0, 0, 3, -1, -2))
        @test convert_attribute(wrap(I), key) == wrap(Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0))

        # Named
        @test convert_attribute(wrap(:rotr90), key) == wrap(Mat{2, 3, Float32}(0, 1, -1, 0, 1, 0))
        @test convert_attribute(wrap(:rotl90), key) == wrap(Mat{2, 3, Float32}(0, -1, 1, 0, 0, 1))
        @test convert_attribute(wrap(:swap_xy), key) == wrap(Mat{2, 3, Float32}(0, 1, 1, 0, 0, 0))
        @test convert_attribute(wrap(:flip_x), key) == wrap(Mat{2, 3, Float32}(-1, 0, 0, 1, 1, 0))
        @test convert_attribute(wrap(:flip_y), key) == wrap(Mat{2, 3, Float32}(1, 0, 0, -1, 0, 1))
        @test convert_attribute(wrap(:flip_xy), key) == wrap(Mat{2, 3, Float32}(-1, 0, 0, -1, 1, 1))

        # Chaining
        @test convert_attribute(wrap((:flip_x, :flip_xy, :flip_y)), key) == wrap(Mat{2, 3, Float32}(1, 0, 0, 1, 0, 0))
        @test convert_attribute(wrap((:rotr90, :swap_xy)), key) == wrap(Mat{2, 3, Float32}(-1, 0, 0, 1, 1, 0))
        @test convert_attribute(wrap((:rotl90, (Vec2f(0.5, 0.5), Vec2f(0.5, 0.5)), :flip_y)), key) == wrap(Mat{2, 3, Float32}(0.0, -0.5, -0.5, 0.0, 1.0, 0.5))
    end

    @test convert_attribute(nothing, key) === nothing

    # Not meant to be used via convert_attribute, util for uv_transform
    @test uv_transform(:meshscatter)[Vec(1, 2), Vec(1, 2, 3)] == convert_attribute(automatic, key, Makie.key"meshscatter"())
    @test uv_transform(:mesh)[Vec(1, 2), Vec(1, 2, 3)] == convert_attribute(automatic, key, Makie.key"mesh"())
    @test uv_transform(:image)[Vec(1, 2), Vec(1, 2, 3)] == convert_attribute(automatic, key, Makie.key"image"())
    @test uv_transform(:surface)[Vec(1, 2), Vec(1, 2, 3)] == convert_attribute(automatic, key, Makie.key"surface"())
end

@testset "to_color" begin
    @test to_color(nothing) === nothing
    @test to_color(1) == 1.0f0
    @test to_color(17.0) == 17.0f0
    @test to_color(colorant"blue") == RGBAf(0, 0, 1, 1)
    @test to_color(HSV(120, 1, 1)) == RGBAf(0, 1, 0, 1)
    @test to_color(RGB(1, 0, 0)) == RGBAf(1, 0, 0, 1)
    @test to_color(RGBA(1, 0, 0, 0.5)) == RGBAf(1, 0, 0, 0.5)
    @test to_color(Vec3f(0.5, 0.6, 0.4)) == RGBAf(0.5, 0.6, 0.4, 1)
    @test to_color(Vec4f(0.2, 0.3, 0.4, 0.5)) == RGBAf(0.2, 0.3, 0.4, 0.5)
    @test to_color(:black) == RGBAf(0, 0, 0, 1)
    @test to_color("red") == RGBAf(1, 0, 0, 1)
    @test to_color([RGBf(0.5, 1, 0.5), :red, "blue"]) == [RGBAf(0.5, 1, 0.5, 1), RGBAf(1, 0, 0, 1), RGBAf(0, 0, 1, 1)]
    @test to_color([HSV(0, 1, 1), HSV(120, 1, 1)]) == [RGBAf(1, 0, 0, 1), RGBAf(0, 1, 0, 1)]
    @test to_color((:red, 0.5)) == RGBAf(1, 0, 0, 0.5)
    @test to_color((RGBAf(0.2, 0.3, 0.4, 0.5), 0.5)) == RGBAf(0.2, 0.3, 0.4, 0.25)

    # TODO: Pattern, Palette
end
