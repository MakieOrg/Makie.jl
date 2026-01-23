# Testing TODO:
# - test that none of the plot! functions drops precision (i.e. converts to Float32)
#   unless they apply float32convert themselves (e.g. convert to pixel space)

using Makie: Float32Convert, LinearScaling, f32_convert, update_limits!,
    f32_convert_matrix, is_identity_transform
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

    @testset "model_f32c and positions_transformed_f32c" begin
        function apply_random_transform!(plot, s, t, rotate = true)
            trans = t .* (2.0 .* rand(Vec2{Float64}) .- 1.0)
            scale = s .* (2.0 .* rand(Vec2{Float64}) .- 1.0)

            rotate && Makie.rotate!(plot, Vec3f(0, 0, 1), 2pi * rand())
            # z is not considered in Axis, so keep its scaling at unit values
            # for easier debugging
            Makie.scale!(plot, scale..., 1)
            Makie.translate!(plot, trans..., 1)

            return
        end

        function is_f32_safe(t)
            scale = Vec3f(t.model[] * Vec4f(1, 1, 1, 0))
            return abs.(scale) .> 1.0e4 * eps(Float32) .* abs.(t.translation[])
        end

        # TODO: nothing conversions get treated as unit conversions atm, which
        # results in unsafe model matrices being applied on the CPU. Not a problem
        # but breaks p.model_f32c[] == Mat4f(p.model[]) below
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
            @test is_identity_transform(p.f32c[])
            @test p.model_f32c[] == Mat4f(p.model[])
            @test p.positions_transformed_f32c[] ≈ p.positions[]

            # unsafe model
            apply_random_transform!(p, 1.0e50, 1.0e50)
            @test is_identity_transform(p.f32c[])
            # @test p.model_f32c[] == Mat4f(p.model[])
            # @test apply_transform_and_f32_conversion(p, f32c, p.converted[1])[] ≈ p.converted[1][]
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

                @test p.f32c[] === a.scene.float32convert.scaling[]
                @test p.model_f32c[] == Mat4f(p.model[])
                @test p.positions_transformed_f32c[] ≈ p.positions[]
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
                        while any(is_f32_safe(p.transformation)[Vec(1, 2)])
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
                        ps = Makie.apply_transform_and_model(p, p.positions[], Point3d)
                        f32_convert(input_f32c, ps)
                    end

                    # TODO: Bring back model preserving paths?
                    # Note: p.f32c[] is the raw float32convert. It does not contain modifications from model
                    # if safe_model
                    #     r3 = @test p.f32c[].scale == input_f32c.scale
                    #     r4 = @test p.f32c[].offset ≈ ((input_f32c.scale .- 1) .* trans .+ input_f32c.offset) ./ scale
                    #     r5 = @test p.model_f32c[] == Mat4f(p.model[])

                    #     ps = Makie._project(p.model_f32c[], p.positions_transformed_f32c[])
                    #     r6 = @test ps ≈ transformed rtol = 1e-6 atol = sqrt(eps(Float32))
                    # else
                    #     r3 = @test p.f32c[].scale ≈ scale * input_f32c.scale
                    #     r4 = @test p.f32c[].offset ≈ input_f32c.scale * trans + input_f32c.offset
                    #     r5 = @test p.model_f32c[] == Mat4f(I)
                    #     r6 = @test p.positions_transformed_f32c[] ≈ transformed rtol = 1e-6 atol = sqrt(eps(Float32))
                    # end

                    r3 = @test p.f32c[].scale == input_f32c.scale
                    r4 = @test p.f32c[].offset == input_f32c.offset
                    r5 = @test p.model_f32c[] == Mat4f(I)
                    r6 = @test p.positions_transformed_f32c[] ≈ transformed rtol = 1.0e-6 atol = sqrt(eps(Float32))

                    # For debugging
                    if any(r -> r isa Test.Fail, (r1, r2, r3, r4, r5, r6))
                        println("transform scale = $scale")
                        println("transform translation = $trans")
                        println("data = $(p.positions[])")
                        println("input_f32c = $(input_f32c)")
                        println("f32c = $(p.f32c)")
                        println("model = $(p.model[])")
                        println("model_f32c = $(p.model_f32c[])")
                        println("transformed = $transformed")
                        println()
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
                        while any(is_f32_safe(p.transformation)[Vec(1, 2)])
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
                        ps = Makie.apply_transform_and_model(p, p.positions[], Point3d)
                        f32_convert(input_f32c, ps)
                    end

                    r3 = @test p.f32c[] == input_f32c
                    r4 = @test p.model_f32c[] == Mat4f(I)
                    r5 = @test p.positions_transformed_f32c[] ≈ transformed rtol = 1.0e-6

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
                transformed = let
                    ps = Makie.apply_transform_and_model(p, p.positions[], Point3d)
                    f32_convert(input_f32c, ps)
                end

                @test p.f32c[] == input_f32c
                @test p.model_f32c[] == Mat4f(I)
                @test to_ndim.(Point3f, p.positions_transformed_f32c[], 0) ≈ transformed rtol = 1.0e-6
            end
        end
    end

    @testset "register_projected_positions! with float32convert changes" begin
        # Test that projecting from relative space to data space correctly
        # applies inverse float32convert and updates when f32c changes.
        # This is important for features like pyramids that place markers
        # at relative screen positions but need data-space coordinates.

        f, a, p = lines(1:(10 .* 1_000_000), 1:(10 .* 1_000_000))

        # Add input positions in relative space (0-1 range representing screen corners)
        input_positions = [Point2f(0, 0), Point2f(1, 1)]
        Makie.add_input!(p.attributes, :test_input_positions, input_positions)
        Makie.register_projected_positions!(
            p;
            input_space = :relative,
            output_space = :space,
            input_name = :test_input_positions,
            output_name = :test_dataspace_positions,
            apply_transform = false,  # input is already in relative space
        )
        Makie.update_state_before_display!(f)

        # Initially, float32convert should be identity (data range fits in Float32)
        @test is_identity_transform(a.scene.float32convert)

        # Get initial output positions - should map relative corners to data limits
        initial_positions = p.test_dataspace_positions[]
        initial_limits = a.finallimits[]

        # Positions should approximately match the axis limits
        # (relative (0,0) -> min of limits, relative (1,1) -> max of limits)
        @test initial_positions[1][1] ≈ initial_limits.origin[1] rtol = 0.1
        @test initial_positions[1][2] ≈ initial_limits.origin[2] rtol = 0.1
        @test initial_positions[2][1] ≈ initial_limits.origin[1] + initial_limits.widths[1] rtol = 0.1
        @test initial_positions[2][2] ≈ initial_limits.origin[2] + initial_limits.widths[2] rtol = 0.1

        # Now zoom into a very small region to trigger float32convert
        limits!(a, (500_000, 500_100), (500_000, 500_100))
        Makie.update_state_before_display!(f)

        # float32convert should now be non-identity due to precision requirements
        @test !is_identity_transform(a.scene.float32convert)

        # Get updated output positions
        updated_positions = p.test_dataspace_positions[]
        updated_limits = a.finallimits[]

        # After zooming, the relative positions should now map to the new limits
        # relative (0,0) -> new min, relative (1,1) -> new max
        @test updated_positions[1][1] ≈ updated_limits.origin[1] rtol = 0.01
        @test updated_positions[1][2] ≈ updated_limits.origin[2] rtol = 0.01
        @test updated_positions[2][1] ≈ updated_limits.origin[1] + updated_limits.widths[1] rtol = 0.01
        @test updated_positions[2][2] ≈ updated_limits.origin[2] + updated_limits.widths[2] rtol = 0.01

        # The key test: positions should be in actual data coordinates, not f32c-scaled
        # After zoom, updated_limits should be around (500_000, 500_000) to (500_100, 500_100)
        @test 499_000 < updated_positions[1][1] < 501_000
        @test 499_000 < updated_positions[1][2] < 501_000
        @test 499_000 < updated_positions[2][1] < 501_000
        @test 499_000 < updated_positions[2][2] < 501_000
    end

    @testset "register_projected_positions! inverse transform_func" begin
        # Test that projecting from pixel space to data space correctly
        # applies inverse transform_func (e.g., exp10 for log10 scale)

        f, a, p = scatter(1:10, 10.0 .^ (1:10), axis = (yscale = log10,))
        Makie.update_state_before_display!(f)

        # Verify we have a non-identity transform
        @test !Makie.is_identity_transform(p.transform_func[])

        # First register pixel positions (they don't exist by default)
        Makie.register_projected_positions!(
            p;
            input_space = :data,
            output_space = :pixel,
            output_name = :test_pixel_positions,
        )
        Makie.update_state_before_display!(f)

        pixel_positions = p.test_pixel_positions[]

        # Create an input from pixel positions and project back to data space
        Makie.add_input!(p.attributes, :pixel_input, pixel_positions)
        Makie.register_projected_positions!(
            p;
            input_space = :pixel,
            output_space = :data,
            input_name = :pixel_input,
            output_name = :roundtrip_positions,
            apply_transform = false,  # input is already in pixel space
        )
        Makie.update_state_before_display!(f)

        roundtrip = p.roundtrip_positions[]
        original = p.positions[]

        # Should roundtrip back to original data coordinates
        for i in eachindex(original)
            @test roundtrip[i][1] ≈ original[i][1] rtol = 0.01
            @test roundtrip[i][2] ≈ original[i][2] rtol = 0.01
        end
    end

    @testset "register_projected_positions! early exit optimization" begin
        # Test that when input_space === output_space, transforms are skipped
        f, a, p = scatter(1:10, 10.0 .^ (1:10), axis = (yscale = log10,))
        Makie.update_state_before_display!(f)

        # Register a projection from :data to :data - should skip transforms
        Makie.add_input!(p.attributes, :data_input, p.positions[])
        n_before = length(p.attributes.outputs)

        Makie.register_projected_positions!(
            p;
            input_space = :data,
            output_space = :data,
            input_name = :data_input,
            output_name = :identity_output,
        )

        # With early exit, fewer nodes should be created since transforms are skipped
        # The output should match the input exactly
        @test p.identity_output[] == p.data_input[]
    end

end
