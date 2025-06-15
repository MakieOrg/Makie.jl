using Makie, Test

@testset "Colors with missing generators (#4344)" begin
    points = [(0.005, 0.0), (1.0, 0.0), (1.01, 1.0), (-0.1, 1.0), (0.5, 0.5)]
    w1 = [0.0, 0.0, 0.0, 0.0, -0.3]
    w2 = [0.0, 0.0, 0.0, 0.0, -0.6]
    fig, ax, sc = voronoiplot(Makie.DelTri.voronoi(Makie.DelTri.triangulate(points; weights = w1)))
    sc2 = voronoiplot!(Axis(fig[1, 2]), Makie.DelTri.voronoi(Makie.DelTri.triangulate(points; weights = w2)))
    @test sc.plots[1].color[] == [1, 2, 3, 4, 5]
    @test sc2.plots[1].color[] == [1, 2, 3, 4]

    points = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0)]
    append!(points, tuple.(rand(50), rand(50))) # just making sure the deleted point is never on the boundary
    tri = Makie.DelTri.triangulate(points)
    vorn = Makie.DelTri.voronoi(tri)
    Makie.DelTri.delete_point!(tri, 17)
    vorn2 = Makie.DelTri.voronoi(tri)
    fig, ax, sc = voronoiplot(vorn)
    sc2 = voronoiplot!(Axis(fig[1, 2]), vorn2)
    @test sc.plots[1].color[] == 1:54
    @test sc2.plots[1].color[] == setdiff(1:54, 17)
end
