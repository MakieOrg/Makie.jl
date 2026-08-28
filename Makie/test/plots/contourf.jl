using Makie
using Makie: Point2f

# flatten open rings into the (points, ids) layout `_group_polys` expects from Isoband
function rings_to_points_ids(rings)
    points = Point2f[]
    ids = Int[]
    for (i, ring) in enumerate(rings), p in ring
        push!(points, Point2f(p))
        push!(ids, i)
    end
    return points, ids
end

# (number of groups, number of holes per group)
group_shape(groups) = (length(groups), map(g -> length(g) - 1, groups))

@testset "_group_polys" begin
    outer = [(0, 0), (4, 0), (4, 4), (0, 4)]

    @testset "interior hole" begin
        hole = [(2, 2), (3, 2), (3, 3), (2, 3)]
        @test group_shape(Makie._group_polys(rings_to_points_ids([outer, hole])...)) == (1, [1])
    end

    @testset "hole sharing its first vertex with the outer ring (#5651)" begin
        hole = [(2, 4), (3, 2), (2, 1), (1, 2)] # first vertex (2, 4) lies on the outer's top edge
        @test group_shape(Makie._group_polys(rings_to_points_ids([outer, hole])...)) == (1, [1])
    end

    @testset "adjacent polygons sharing a boundary point" begin
        tri1 = [(0, 0), (2, 0), (0, 2)] # meets tri2 at (2, 0); neither contains the other
        tri2 = [(2, 0), (4, 0), (4, 2)]
        @test group_shape(Makie._group_polys(rings_to_points_ids([tri1, tri2])...)) == (2, [0, 0])
    end
end

@testset "_group_polys on shared-point Isoband output" begin
    # marching squares can emit polygons that share vertices (the case #5651 missed)
    isoband(z, low, high) = Makie.Isoband.isobands(
        collect(1.0:size(z, 2)), collect(1.0:size(z, 1)), Float64.(z), [Float64(low)], [Float64(high)]
    )[1]
    pts(g) = collect(zip(g.x, g.y))
    shares_points(g) = any(p -> length(unique(g.id[findall(==(p), pts(g))])) >= 2, unique(pts(g)))
    group_polys(g) = Makie._group_polys(Point2f.(g.x, g.y), g.id)

    # four corner triangles, each sharing a midpoint with its neighbours; none nested
    g1 = isoband([0 1 0; 1 2 1; 0 1 0], 0.5, 1.0)
    @test shares_points(g1)
    @test group_shape(group_polys(g1)) == (4, [0, 0, 0, 0])

    # a hole sharing its first vertex (2, 3) with the surrounding ring
    g2 = isoband([0 2 0; 2 0 2; 1 1 1], 1.0, 1.5)
    @test shares_points(g2)
    @test group_shape(group_polys(g2)) == (1, [1])
end

@testset "contourf colormap generation" begin
    # levels can be the number of levels or a value per edge
    # computed_levels is always a value per edge
    #
    data = reshape(range(-0.2, 1.2, 16), 4, 4)

    @testset "N levels" begin
        @testset "no extendlow/high" begin
            f,a,p = contourf(data, levels = 4)
            @test p.levels[] == 4
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 256 # not downsampled to remove extendlow/high
            @test collect(p.computed_colormap[]) == resample_cmap(p.base_colormap[], 4)
        end

        @testset "extendlow/extendhigh" begin
            f,a,p = contourf(data, levels = 4, extendlow = :auto)
            @test p.levels[] == 4
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]

            f,a,p = contourf(data, levels = 4, extendhigh = :auto)
            @test p.levels[] == 4
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]
        end

        @testset "both" begin
            f,a,p = contourf(data, levels = 4, extendlow = :auto, extendhigh = :auto)
            @test p.levels[] == 4
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]
        end
    end

    @testset "edge based levels" begin
        @testset "no extendlow/high" begin
            f,a,p = contourf(data, levels = 0.0:0.25:1.0)
            @test length(p.levels[]) == 5
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 256 # not downsampled to remove extendlow/high
            @test collect(p.computed_colormap[]) == resample_cmap(p.base_colormap[], 4)
        end

        @testset "extendlow/extendhigh" begin
            f,a,p = contourf(data, levels = 0.0:0.25:1.0, extendlow = :auto)
            @test length(p.levels[]) == 5
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]

            f,a,p = contourf(data, levels = 0.0:0.25:1.0, extendhigh = :auto)
            @test length(p.levels[]) == 5
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]
        end

        @testset "both" begin
            f,a,p = contourf(data, levels = 0.0:0.25:1.0, extendlow = :auto, extendhigh = :auto)
            @test length(p.levels[]) == 5
            @test length(p.computed_levels[]) == 5
            @test p.nlevels[] == 4
            @test length(p.base_colormap[]) == 4 # downsampled
            @test collect(p.computed_colormap[]) == p.base_colormap[]
        end
    end

end