using Makie
using Makie.GeometryBasics

@testset "poly_convert with empty Float64 polygon vector" begin
    polygons = Observable(Polygon{2, Float64}[])

    @testset "Unit test: poly_convert" begin
        @test Makie.poly_convert(Polygon{2, Float64}[], identity) isa Vector{<:GeometryBasics.Mesh{2, Float64}}
    end

    @testset "Integration test: do this with `poly`" begin
        poly(polygons)
        @test_nowarn push!(polygons[], Polygon([Point(1.0, 2.0), Point(2.0, 3.0), Point(3.0, 2.0)]))
        @test_nowarn notify(polygons)

    end
end

@testset "outline_dim" begin
    # Resolved from the type, and 2D input must not be widened to 3D (#4367)
    @test Makie.outline_dim(Vector{Point2d}) == 2
    @test Makie.outline_dim(Vector{Point3d}) == 3
    @test Makie.outline_dim(Vector{Point2f}) == 2
    @test Makie.outline_dim(Vector{NTuple{2, Float64}}) == 2
    @test Makie.outline_dim(Vector{Polygon{2, Float64}}) == 2
    @test Makie.outline_dim(Vector{MultiPolygon{2, Float64}}) == 2
    @test Makie.outline_dim(Vector{LineString{2, Float64}}) == 2
    @test Makie.outline_dim(Vector{Rect2d}) == 2
    @test Makie.outline_dim(Vector{Vector{Point2d}}) == 2
    @test Makie.outline_dim(MultiPolygon{2, Float64}) == 2
    @test Makie.outline_dim(Polygon{3, Float64}) == 3
    # unknown types fall back to 3, which to_ndim pads safely
    @test Makie.outline_dim(String) == 3

    poly = Polygon(Point2d[(0, 0), (1, 0), (1, 1)])
    @test @inferred(Makie.to_lines([poly])) isa Tuple{Vector{Point2d}, Vector{Int}}
    @test @inferred(Makie.to_lines([poly], 1.0)) isa Tuple{Vector{Point2d}, Vector{Int}}
end

@testset "stroke gating" begin
    polys = [Polygon(Point2d[(0, 0), (1, 0), (1, 1)]), Polygon(Point2d[(2, 2), (3, 2), (3, 3)])]

    # a zero width stroke is not rasterized, so the outline is not built
    outline_on, increment_on = Makie.to_lines(polys, 1.0)
    outline_off, increment_off = Makie.to_lines(polys, 0)
    @test length(outline_on) > 1
    @test length(outline_off) == 1
    @test all(isnan, outline_off[1])
    @test isempty(increment_off)
    # the type must not change, otherwise toggling strokewidth retypes the graph node
    @test typeof(outline_on) === typeof(outline_off)

    # isequal, not ==, since the outlines contain NaN separators
    @test isequal(Makie.to_lines(polys, [0, 0])[1], outline_off)
    @test isequal(Makie.to_lines(polys, [0, 1])[1], outline_on)
    # anything we cannot interpret keeps the outline
    @test isequal(Makie.to_lines(polys, nothing)[1], outline_on)

    @testset "toggling at runtime" begin
        f, ax, pl = poly(polys; strokewidth = 0)
        T = typeof(pl.outline[])
        @test length(pl.outline[]) == 1
        pl.strokewidth = 2.0
        @test length(pl.outline[]) > 1
        @test typeof(pl.outline[]) === T
        pl.strokewidth = 0
        @test length(pl.outline[]) == 1
        @test typeof(pl.outline[]) === T
    end

    @testset "axis limits are unaffected" begin
        # data_limits of an all NaN line is empty, so the mesh still sets the limits
        _, ax1, _ = poly(polys; strokewidth = 1.0)
        _, ax2, _ = poly(polys; strokewidth = 0)
        Makie.reset_limits!(ax1)
        Makie.reset_limits!(ax2)
        @test ax1.finallimits[] == ax2.finallimits[]
    end

    @testset "per-polygon strokecolor still matches the outline" begin
        f, ax, pl = poly(polys; strokewidth = 1.0, strokecolor = [:red, :blue])
        @test length(pl.computed_strokecolor[]) == length(pl.outline[])
        pl.strokewidth = 0
        @test length(pl.computed_strokecolor[]) == length(pl.outline[]) == 1
    end
end
