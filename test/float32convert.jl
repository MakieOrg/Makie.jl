# Testing TODO:
# - test that none of the plot! functions drops precision (i.e. converts to Float32)
#   unless they apply float32convert themselves (e.g. convert to pixel space)

using Makie: Float32Convert, LinearScaling, f32_convert, update_limits!,
    f32_convert_matrix, patch_model, apply_transform_and_f32_conversion
using Makie: Mat4f, Vec2d, Vec3d, Point2d, Point3d, Point4d

@testset "float32convert" begin
    f32c = Float32Convert()

    approx(r1, r2) = minimum(r1) ≈ minimum(r2) && widths(r1) ≈ widths(r2)
    unit_rect = Rect2f(-1.0, -1.0, 2.0, 2.0)
    unit_scaling = LinearScaling(Vec3d(1), Vec3d(0))
    f32max = Float64(floatmax(Float32)) / f32c.resolution
    f32min = Float64(floatmin(Float32)) * f32c.resolution
    f32eps = Float64(eps(Float32)) * f32c.resolution

    @testset "Initialization" begin
        @test f32c.scaling[] == unit_scaling
        @test f32c.resolution == 1.0f4 # this may be subject to change
    end

    @testset "Modification" begin
        # no update necessary
        @test !update_limits!(f32c, Rect(-1, -1, 2, 2))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(-f32max, -f32max, 2 * f32max, 2 * f32max))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(-f32min, -f32min, 2 * f32min, 2 * f32min))
        @test f32c.scaling[] == unit_scaling
        @test !update_limits!(f32c, Rect(1.0e6, 1.0e6, 2.0e6 * f32eps, 2.0e6 * f32eps))
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
        @test update_limits!(f32c, Rect(2.0e6, 2.0e6, 1.0e6 * f32eps, 1.0e6 * f32eps))
        @test f32c.scaling[] != prev
        @test approx(f32_convert(f32c, Rect(2.0e6, 2.0e6, 1.0e6 * f32eps, 1.0e6 * f32eps)), unit_rect)
        prev = f32c.scaling[]
    end

    # some random scaling
    f32c.scaling[] = LinearScaling(Vec3f(1.0e-5, 2.35e3, 1), Vec3f(3.6e20, 9.2e-50, 0))


    @testset "f32_convert & matrix" begin
        f32m = f32_convert_matrix(f32c, :data)
        for input in (rand(Vec2d), rand(Vec3d), rand(Point2d), rand(Point3d))
            output = f32_convert(f32c, input)
            @test eltype(output) == Float32
            @test typeof(output)(f32m * to_ndim(Point4d, to_ndim(Point3d, input, 0), 1)) ≈ output
            D = length(input)
            @test isapprox(output, f32c.scaling[].scale[1:D] .* input + f32c.scaling[].offset[1:D], rtol = 1.0e-7)
        end

        for input in (rand(Vec2d, 10), rand(Vec3d, 10))
            @test f32_convert(f32c, input) == f32_convert.((f32c,), input)
        end

        # TODO: test the rest
    end

    @testset "patch_model() and apply_transform_and_f32_conversion()" begin
        let
            # COV_EXCL_START
            scene = Scene()
            p = scatter!(scene, rand(10))
            # COV_EXCL_STOP

            a, b = patch_model(p)
            c, d = patch_model(plot, scene.float32convert, p.model)
            @test a[] == c[]
            @test b[] == d[]
        end

        function apply_random_transform!(plot, s, t, rotate = true)
            v1 = normalize(2.0 .* rand(Vec3{Float64}) .- 1.0)
            v2 = normalize(2.0 .* rand(Vec3{Float64}) .- 1.0)
            rot = Makie.rotation_between(v1, v2)
            trans = t .* (2.0 .* rand(Vec3{Float64}) .- 1.0)
            scale = s .* (2.0 .* rand(Vec3{Float64}) .- 1.0)

            rotate && Makie.rotate!(plot, rot)
            Makie.scale!(plot, scale)
            Makie.translate!(plot, trans)

            return
        end

        function is_f32_safe(t)
            return abs.(t.scale[]) .> 1.0e4 * eps(Float32) .* abs.(t.translation[])
        end

        # With no conversion model should not change
        @testset "no Float32Convert" begin
            # COV_EXCL_START
            scene = Scene()
            scene.float32convert = nothing
            p = scatter!(scene, rand(10))
            Makie.update_state_before_display!(scene)
            # COV_EXCL_STOP

            # safe model
            apply_random_transform!(p, 10.0, 10.0)
            f32c, model = patch_model(p)
            @test f32c[] === nothing
            @test model[] == Mat4f(p.model[])
            @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ p.converted[1][]

            # unsafe model
            apply_random_transform!(p, 1.0e50, 1.0e50)
            f32c, model = patch_model(p)
            @test f32c[] === nothing
            @test model[] == Mat4f(p.model[])
            @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ p.converted[1][]
        end


        @testset "Safe data, safe model" begin
            for _ in 1:10
                # COV_EXCL_START
                f, a, p = scatter(rand(10))
                apply_random_transform!(p, 100.0, 100.0)
                # since we choose a random scale and translation we can get a
                # scale that is not Float32 compatible with the translation
                # (i.e. a abs(scale) ⪅ eps(translation))
                # this is effectively an explicit Makie.is_float_safe(scale, translation)
                while !all(is_f32_safe(p.transformation))
                    apply_random_transform!(p, 100.0, 100.0)
                end
                Makie.update_state_before_display!(f)
                # COV_EXCL_STOP

                # Verify State
                @test a.scene.float32convert.scaling[] == Makie.LinearScaling(Vec3d(1), Vec3d(0))
                @test Makie.is_float_safe(p.transformation.scale[], p.transformation.translation[])

                f32c, model = patch_model(p)
                @test f32c[] === a.scene.float32convert.scaling[]
                @test model[] == Mat4f(p.model[])
                @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ p.converted[1][]
            end
        end


        # Note that we just increase precision from Float32 to Float64 so if
        # these values are too large we'll see Float64 precision issues here
        for (data_scale, model_scale) in ((10.0, 1.0e9), (1.0e9, 10.0), (1.0e9, 1.0e9))
            data_info = data_scale == 10.0 ? "safe" : "unsafe"
            model_info = model_scale == 10.0 ? "safe" : "unsafe"
            @testset "$data_info data + $model_info rotation-free model" begin
                for _ in 1:10
                    # Prepare example
                    # COV_EXCL_START
                    f, a, p = scatter(rand(10) .+ data_scale, rand(10) .+ data_scale)
                    apply_random_transform!(p, 10.0, model_scale, false)
                    if model_scale != 10.0
                        while any(is_f32_safe(p.transformation))
                            apply_random_transform!(p, 10.0, model_scale, false)
                        end
                    else
                        while !all(is_f32_safe(p.transformation))
                            apply_random_transform!(p, 10.0, model_scale, false)
                        end
                    end
                    Makie.update_state_before_display!(f)
                    # COV_EXCL_STOP

                    # Verify State
                    r1 = @test a.scene.float32convert.scaling[] != Makie.LinearScaling(Vec3d(1), Vec3d(0))
                    safe_model = model_scale == 10.0
                    r2 = @test Makie.is_float_safe(p.transformation.scale[], p.transformation.translation[]) == safe_model

                    # compute expected f32c convert and transformed data
                    # (should follow is_rot_free branches)
                    scale = p.transformation.scale[]
                    trans = p.transformation.translation[]
                    input_f32c = a.scene.float32convert.scaling[]
                    transformed = let
                        ps = Makie.apply_transform_and_model(p, p.converted[1][], Point3d)
                        f32_convert(input_f32c, ps)
                    end
                    f32c, model = patch_model(p)

                    if safe_model
                        r3 = @test f32c[].scale == input_f32c.scale
                        r4 = @test f32c[].offset ≈ ((input_f32c.scale .- 1) .* trans .+ input_f32c.offset) ./ scale
                        r5 = @test model[] == Mat4f(p.model[])

                        ps = apply_transform_and_f32_conversion(p, f32c, p.converted[1])[]
                        ps = [to_ndim(Point3f, model[] * to_ndim(Point4f, to_ndim(Point3f, p, 0), 1), NaN) for p in ps]
                        r6 = @test ps ≈ transformed rtol = 1.0e-6 atol = sqrt(eps(Float32))
                    else
                        r3 = @test f32c[].scale ≈ scale * input_f32c.scale
                        r4 = @test f32c[].offset ≈ input_f32c.scale * trans + input_f32c.offset
                        r5 = @test model[] == Mat4f(I)
                        r6 = @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ transformed rtol = 1.0e-6 atol = sqrt(eps(Float32))
                    end

                    # For debugging
                    if any(r -> r isa Test.Fail, (r1, r2, r3, r4, r5, r6))
                        println("scale = $scale")
                        println("translation = $trans")
                        println("data = $(p.converted[1][])")
                        println("input_f32c = $(input_f32c)")
                        println("f32c = $(f32c[])")
                        println("model = $(p.model[])")
                        println("transformed = $transformed")
                    end
                end
            end
        end


        # Note that we just increase precision from Float32 to Float64 so if
        # these values are too large we'll see Float64 precision issues here
        for (data_scale, model_scale) in ((10.0, 1.0e9), (1.0e9, 10.0), (1.0e9, 1.0e9))
            data_info = data_scale == 10.0 ? "safe" : "unsafe"
            model_info = model_scale == 10.0 ? "safe" : "unsafe"
            @testset "$data_info data + $model_info rotation model" begin
                for _ in 1:10
                    # Prepare example
                    # COV_EXCL_START
                    f, a, p = scatter(rand(10) .+ data_scale, rand(10) .+ data_scale)
                    apply_random_transform!(p, 10.0, model_scale, true)
                    if model_scale != 10.0
                        while any(is_f32_safe(p.transformation))
                            apply_random_transform!(p, 10.0, model_scale, true)
                        end
                    else
                        while !all(is_f32_safe(p.transformation))
                            apply_random_transform!(p, 10.0, model_scale, true)
                        end
                    end
                    Makie.update_state_before_display!(f)
                    # COV_EXCL_STOP

                    # Verify State
                    r1 = @test a.scene.float32convert.scaling[] != Makie.LinearScaling(Vec3d(1), Vec3d(0))
                    r2 = @test Makie.is_float_safe(p.transformation.scale[], p.transformation.translation[]) == (model_scale == 10.0)

                    # compute expected f32c convert and transformed data
                    # (should follow else branches)
                    scale = p.transformation.scale[]
                    trans = p.transformation.translation[]
                    input_f32c = a.scene.float32convert.scaling[]
                    transformed = let
                        ps = Makie.apply_transform_and_model(p, p.converted[1][], Point3d)
                        f32_convert(input_f32c, ps)
                    end

                    f32c, model = patch_model(p)
                    r3 = @test f32c[] == input_f32c
                    r4 = @test model[] == Mat4f(I)
                    r5 = @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ transformed rtol = 1.0e-6

                    # For debugging
                    if any(r -> r isa Test.Fail, (r1, r2, r3, r4, r5))
                        println("scale = $scale")
                        println("translation = $trans")
                        println("data = $(p.converted[1][])")
                        println("input_f32c = $(input_f32c)")
                        println("f32c = $(f32c[])")
                        println("model = $(p.model[])")
                    end
                end
            end
        end


        @testset "edge case - unsafe data and model with safe world space" begin
            for _ in 1:10
                # Prepare example
                # COV_EXCL_START
                scale = rand(Vec2d) .+ 1.0
                trans = 1.0e9 .* rand(Vec2d) .- 1
                f, a, p = scatter([scale .* (rand(Point2d) .+ trans) for _ in 1:10])
                scale!(p, (1.0 ./ scale)..., 1.0)
                translate!(p, -trans..., 0.0)
                Makie.update_state_before_display!(f)
                # COV_EXCL_STOP

                # Verify State
                @test a.scene.float32convert.scaling[] == Makie.LinearScaling(Vec3d(1), Vec3d(0))
                @test !Makie.is_float_safe(p.transformation.scale[], p.transformation.translation[])

                # compute expected f32c convert and transformed data
                # (should follow else branches)
                scale = p.transformation.scale[]
                trans = p.transformation.translation[]
                input_f32c = a.scene.float32convert.scaling[]
                expected_f32c = Makie.LinearScaling(
                    scale * input_f32c.scale, input_f32c.scale * trans + input_f32c.offset
                )
                transformed = let
                    ps = Makie.apply_transform_and_model(p, p.converted[1][], Point3d)
                    f32_convert(input_f32c, ps)
                end

                f32c, model = patch_model(p)
                @test f32c[].scale ≈ expected_f32c.scale
                @test f32c[].offset ≈ expected_f32c.offset
                @test model[] == Mat4f(I)
                @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ transformed rtol = 1.0e-6
            end
        end
    end

end
