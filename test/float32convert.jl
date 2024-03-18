# Testing TODO:
# - test that none of the plot! functions drops precision (i.e. converts to Float32)
#   unless they apply float32convert themselves (e.g. convert to pixel space)

using Makie: Float32Convert, LinearScaling, f32_convert, update_limits!,
    f32_convert_matrix, patch_model, transformationmatrix

@testset "float32convert" begin
    f32c = Float32Convert()

    approx(r1, r2) = minimum(r1) ≈ minimum(r2) && widths(r1) ≈ widths(r2)
    unit_rect = Rect2f(-1.0, -1.0, 2.0, 2.0)
    unit_scaling = LinearScaling(Vec3d(1), Vec3d(0))
    f32max = Float64(floatmax(Float32)) / f32c.resolution
    f32min = Float64(floatmin(Float32)) * f32c.resolution
    f32eps = Float64(eps(Float32)) * f32c.resolution

    @testset "Intialization" begin
        @test f32c.scaling[] == unit_scaling
        @test f32c.resolution == 1f4 # this may be subject to change
    end

    @testset "Modificaiton" begin
        # no update necessary
        @test !update_limits!(f32c, Rect(-1, -1, 2, 2))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(-f32max, -f32max, 2 * f32max, 2 * f32max))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(-f32min, -f32min, 2 * f32min, 2 * f32min))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(1e6, 1e6, 2e6 * f32eps, 2e6 * f32eps))
        @test f32c.scaling[] == unit_scaling

        # should trigger updates based on  abs(extrema) > floatmax(Float32)
        @test update_limits!(f32c, Rect(-2 * f32max, -2 * f32max, 4 * f32max, 4 * f32max))
        @test f32c.scaling[] != unit_scaling
        @test approx(f32_convert(f32c, Rect(-2 * f32max, -2 * f32max, 4 * f32max, 4 * f32max)), unit_rect)
        prev = f32c.scaling[]

        # back to -1..1 should reset
        @test update_limits!(f32c, unit_rect)
        @test f32c.scaling[] == unit_scaling
        @test approx(f32_convert(f32c, unit_rect), unit_rect)
        prev = f32c.scaling[]

        # abs(extrema) < floatmin(Float32)
        @test update_limits!(f32c, Rect(-0.5 * f32min, -0.5 * f32min, f32min, f32min))
        @test f32c.scaling[] != prev
        @test approx(f32_convert(f32c, Rect(-0.5 * f32min, -0.5 * f32min, f32min, f32min)), unit_rect)
        prev = f32c.scaling[]

        # This wouldn't trigger because Float32 numbers have a little more room
        # towards large value than small ones (f32min * f32max > 1)
        # @test update_limits!(f32c, unit_rect)
        f32c.scaling[] = unit_scaling
        prev = f32c.scaling[]

        # widths < resolution * eps(extrema)
        @test update_limits!(f32c, Rect(2e6, 2e6, 1e6 * f32eps, 1e6 * f32eps))
        @test f32c.scaling[] != prev
        @test approx(f32_convert(f32c,Rect(2e6, 2e6, 1e6 * f32eps, 1e6 * f32eps)), unit_rect)
        prev = f32c.scaling[]
    end

    # some random scaling
    f32c.scaling[] = LinearScaling(Vec3f(1e-5, 2.35e3, 1), Vec3f(3.6e20, 9.2e-50, 0))


    @testset "f32_convert & matrix" begin
        f32m = f32_convert_matrix(f32c, :data)
        for input in (rand(Vec2d), rand(Vec3d), rand(Point2d), rand(Point3d))
            output = f32_convert(f32c, input)
            @test eltype(output) == Float32
            @test typeof(output)(f32m * to_ndim(Point4d, to_ndim(Point3d, input, 0), 1)) ≈ output
            D = length(input)
            @test isapprox(output, f32c.scaling[].scale[1:D] .* input + f32c.scaling[].offset[1:D], rtol = 1e-7)
        end

        for input in (rand(Vec2d, 10), rand(Vec3d, 10))
            @test f32_convert(f32c, input) == f32_convert.((f32c,), input)
        end

        # TODO: test the rest
    end

    @testset "model patching" begin
        @assert f32c.scaling[] != unit_scaling "model patching tests invalid"
        f32m = f32_convert_matrix(f32c, :data)

        translation = transformationmatrix(rand(Vec3d), Vec3d(1))
        @test Mat4f(f32m * translation) ≈ Mat4f(patch_model(f32c.scaling[], translation) * f32m)

        scaling = transformationmatrix(Vec3d(0), rand(Vec3d))
        @test Mat4f(f32m * scaling) ≈ Mat4f(patch_model(f32c.scaling[], scaling) * f32m)

        # This causes the model/rotation matrix to require higher precision
        # because it mixes the vastly different scaling from float32convert
        # rotation = transformationmatrix(Vec3d(0), Vec3d(1), qrotation(2 * rand(Vec3d) .- 1, 2pi * rand(Float64)))
        # @test f32m * rotation ≈ patch_model(f32c.scaling[], rotation) * f32m
    end
end