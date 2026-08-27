using Makie: apply_tooltip_format, default_tooltip_formatter

@testset "DataInspector" begin
    @testset "formatted label data" begin
        format(x) = apply_tooltip_format(default_tooltip_formatter, x)

        @test format(Vec(pi, pi)) == "(3.142, 3.142)"
        @test format(Vec(pi, pi, pi)) == "(3.142, 3.142, 3.142)"

        @test format(pi) == "3.142"
        @test format(:red) == ":red"
        @test format(Makie.colorant"red") == "RGB(1.000, 0, 0)"

        @test format(("img", 5, 7, RGBAf(0.6, 0.77777, 0.5, 0.3))) == "img\n5.000\n7.000\nRGBA(0.600, 0.778, 0.500, 0.300)"
    end

    @testset "image cell lookup matches orientation at visual top-left" begin
        # Inspector picks via `mat[image_cell_to_matrix_index(orientation, ...)(cx, cy)]`.
        # With `yreversed = true`, the visual top-left corresponds to rect cell (1, 1).
        tl = RGBf(1, 0, 0)
        tr = RGBf(0, 1, 0)
        bl = RGBf(0, 0, 1)
        br = RGBf(1, 1, 0)
        mat = [
            tl                  RGBf(0.5, 0.5, 0)  tr;
            bl                  RGBf(0, 0.5, 0.5)  br
        ]
        nrows, ncols = size(mat)
        expected_visual_top_left = (
            (:down, :right) => tl,
            (:down, :left) => tr,
            (:up, :right) => bl,
            (:up, :left) => br,
            (:right, :down) => tl,
        )
        for (orient, expected) in expected_visual_top_left
            _, _, p = image(mat; orientation = orient)
            indexer = Makie.image_cell_to_matrix_index(orient, nrows, ncols)
            @test p.image[][indexer(1, 1)] == expected
        end
    end

    @testset "tooltip matrix coords for indexed and interpolated accessors" begin
        indexed = Makie.IndexedAccessor(CartesianIndex(2, 3), Makie.Vec{2, Int64}(4, 5))
        @test Makie.continuous_matrix_coords(indexed) == (1.5, 2.5)

        interpolated = Makie.InterpolatedAccessor(
            CartesianIndex(2, 3), CartesianIndex(3, 4), Makie.Vec2f(0.25, 0.75),
            Makie.Vec{2, Int64}(4, 5), false
        )
        @test Makie.continuous_matrix_coords(interpolated) == (1.75, 3.25)
    end

    # TODO: add more tests for DataInspector pipeline, e.g. pick_element.
    # (This is already indirectly tested via refimages)
end
