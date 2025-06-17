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
