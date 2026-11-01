using Test, GeometryBasics, Raycore, Makie

@testset "device-backed Raycore geometry converts to a Makie mesh" begin
    tlas = Raycore.TLAS(BACKEND)
    geometry = GeometryBasics.normal_mesh(
        GeometryBasics.Rect3f(Point3f(-1), Vec3f(2))
    )
    push!(tlas, geometry)
    Raycore.sync!(tlas)

    converted = Makie.convert_arguments(Makie.Mesh, tlas)
    @test length(converted) == 1
    @test length(GeometryBasics.faces(only(converted))) == length(GeometryBasics.faces(geometry))
    @test length(GeometryBasics.coordinates(only(converted))) == 3 * length(GeometryBasics.faces(geometry))
    @test all(isfinite, Iterators.flatten(GeometryBasics.coordinates(only(converted))))
end
