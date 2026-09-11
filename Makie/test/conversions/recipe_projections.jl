using ComputePipeline
using Makie: is_identity_transform

@testset "Recipe projections" begin
    f, a, p = scatter(1:10, 1000000 .+ (1:10), axis = (xscale = log10,))
    Makie.update_state_before_display!(f)

    scene = a.scene
    @test !Makie.is_identity_transform(scene.float32convert)

    function run_checks(name, values, nodes_added; kwargs...)
        N = length(p.attributes.outputs)
        # before = Set(keys(p.attributes.outputs))
        x = Makie.register_projected_positions!(p; kwargs...)
        # @info setdiff(Set(keys(p.attributes.outputs)), before)
        @test x isa Computed
        @test x.name === name
        @test x[] ≈ values
        @test length(p.attributes.outputs) == N + nodes_added
    end

    # nodes added: output
    run_checks(
        :space_positions, p.positions_transformed_f32c[], 1;
        input_space = :space, output_space = :space, apply_model = false,
    )

    # Nodes added: identity_matrix, combined matrix, output
    run_checks(
        :space_pos2, p.positions_transformed_f32c[], 3;
        output_space = :space, apply_model = true, output_name = :space_pos2,
    )

    # This should throw to avoid overwriting/reusing the wrong output
    @test_throws ErrorException Makie.register_projected_positions!(
        p, input_space = :space, output_space = :space, apply_model = true
    )

    for space in [:pixel, :clip, :relative]
        # explicit so we indirectly test _project too
        pv = Makie.get_space_to_space_matrix(scene, :data, space)
        projected = map(p.positions_transformed_f32c[]) do pos
            p4d = pv * to_ndim(Point4f, to_ndim(Point3f, pos, 0), 1)
            return p4d[Vec(1, 2, 3)] / p4d[4]
        end

        # Nodes added: dynamic matrix name, camera matrix, combined matrix, output
        run_checks(
            Symbol(space, :_positions), projected, 4;
            output_space = space
        )
    end

    # Nodes added: combined matrix, output (space to markerspace already exists)
    run_checks(
        :markerspace_positions, p.pixel_positions[], 2;
        output_space = :markerspace
    )

    # yflip for CairoMakie
    res = scene.compute.resolution[]
    projected = map(p.pixel_positions[]) do (x, y, z)
        return Point3f(x, res[2] - y, z)
    end

    run_checks(
        :px_pos2, projected, 3;
        output_space = :pixel, yflip = true, output_name = :px_pos2
    )

    # ... only works in pixel space (for now?)
    for space in [:data, :clip, :relative, :eye]
        @test_throws ErrorException Makie.register_projected_positions!(
            p, output_space = space, yflip = true
        )
    end

    # No transform & projection
    run_checks(
        :raw, p.positions[], 1;
        output_space = :space, apply_transform = false, output_name = :raw,
        apply_inverse_transform = false
    )

    # Constant space
    # Added nodes: camera matrix, combined matrix, output
    run_checks(
        :px_pos3, p.pixel_positions[], 3;
        input_space = :data, output_space = :pixel, output_name = :px_pos3, apply_transform = true
    )

    # inverse transforms
    positions3D = to_ndim.(Point3f, p.positions[], 0)
    run_checks(
        :inverse_space_positions, positions3D, 5;
        input_name = :space_positions, output_name = :inverse_space_positions,
        input_space = :space, output_space = :space,
        apply_transform = false, apply_inverse_model = false,
    )

    for space in [:pixel, :clip, :relative]
        # Nodes added: dynamic matrix name, camera matrix, combined matrix, output
        input_name = Symbol(space, :_positions)
        run_checks(
            Symbol(:inverse_, input_name), positions3D, 5 + (space == :pixel);
            input_name = input_name, output_name = Symbol(:inverse_, input_name),
            input_space = space, output_space = :space
        )
    end


    @testset "register_projected_positions! with float32convert changes" begin
        # Test that projecting from relative space to data space correctly
        # applies inverse float32convert and updates when f32c changes.
        # This is important for features like pyramids that place markers
        # at relative screen positions but need data-space coordinates.

        f, a, p = lines((1:10) .* 1_000_000, (1:10) .* 1_000_000)

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
