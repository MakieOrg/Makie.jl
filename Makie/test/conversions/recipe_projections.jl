using ComputePipeline

@testset "Recipe projections" begin
    f, a, p = scatter(1:10, 1000000 .+ (1:10), axis = (xscale = log10,))
    Makie.update_state_before_display!(f)

    scene = a.scene
    @test !Makie.is_identity_transform(scene.float32convert)

    function run_checks(name, values, nodes_added; kwargs...)
        N = length(p.attributes.outputs)
        x = Makie.register_projected_positions!(p; kwargs...)
        @test x isa Computed
        @test x.name === name
        @test x[] ≈ values
        @test length(p.attributes.outputs) == N + nodes_added
    end

    run_checks(
        :space_positions, p.positions_transformed_f32c[], 1;
        input_space = :space, output_space = :space, apply_model = false
    )

    # Nodes added: identity_matrix, combined matrix, output
    run_checks(
        :space_pos2, p.positions_transformed_f32c[], 3;
        output_space = :space, apply_model = true, output_name = :space_pos2
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
        :px_pos2, projected, 2;
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
        output_space = :space, apply_transform = false, output_name = :raw
    )

    # Constant space
    # Added nodes: camera matrix, combined matrix, output
    run_checks(
        :px_pos3, p.pixel_positions[], 3;
        input_space = :data, output_space = :pixel, output_name = :px_pos3, apply_transform = true
    )
end
