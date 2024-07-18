using Makie

@testset "Projection math" begin
    @testset "Rotation matrix" begin
        @test eltype(Makie.rotationmatrix_x(1)) == Float64
        @test eltype(Makie.rotationmatrix_x(1f0)) == Float32
    end
    @testset "Projection between spaces in 3D" begin
        # Set up an LScene and some points there
        sc = Scene(size = (650, 400), camera = cam3d!)
        corner_points_px = [Point3f(0, 0, 0), Point3f(650, 400, 0)]

        @testset "Clip space and pixel space equivalence" begin
            far_bottom_left_clip = Point3f(-1)
            near_top_right_clip = Point3f(1)
            
            fbl_px = Makie.project(sc, :clip, :pixel, far_bottom_left_clip)
            ntr_px = Makie.project(sc, :clip, :pixel, near_top_right_clip)
            @test Point2f(fbl_px) == Point2f(0, 0)
            @test Point2f(ntr_px) == Point2f(650, 400)
        end

        @testset "No warnings in projections between spaces" begin
            for (source, dest) in unique(Iterators.product(Makie.spaces(), Makie.spaces()))
                source == dest && continue
                current_space_points = Makie.project.(sc, :pixel, source, corner_points_px)
                @testset "$source → $dest" begin
                    @test_nowarn Makie.project.(sc, source, dest, current_space_points)
                end
            end
        end
    end
end
