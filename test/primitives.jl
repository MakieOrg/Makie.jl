@testset "ablines" begin
    # Test ablines with 0 dim arrays
    f, ax, pl = ablines(fill(0), fill(1))
    reset_limits!(ax)
    points = pl.plots[1][1]
    @test points[] == [Point2f(0), Point2f(10)]
    limits!(ax, 5, 15, 6, 17)
    @test points[] == [Point2f(5), Point2f(15)]
end


@testset "arrows" begin
    # Test for:
    # https://github.com/MakieOrg/Makie.jl/issues/3273
    directions = decompose(Point2f, Circle(Point2f(0), 1))
    points = decompose(Point2f, Circle(Point2f(0), 0.5))
    color = range(0, 1, length=length(directions))
    fig, ax, pl = arrows(points, directions; color=color)
    cbar = Colorbar(fig[1, 2], pl)
    @test cbar.limits[] == Vec2f(0, 1)
    pl.colorrange = (0.5, 0.6)
    @test cbar.limits[] ≈ Vec2f(0.5, 0.6)
end


# TODO, test all primitives and argument conversions

# text()
# fig, ax, p = meshscatter(1:5, (1:5) .+ 5, rand(5))
# fig, ax, p = scatter(1:5, rand(5))
# fig, ax, p = mesh(Sphere(Point3f(0), 1.0))
# fig, ax, p = linesegments(1:5, rand(5))
# fig, ax, p = lines(1:5, rand(5))
# fig, ax, p = surface(rand(4, 7))
# fig, ax, p = volume(rand(4, 4, 4))
# begin
#     fig, ax, p = heatmap(rand(4, 4))
#     scatter!(Makie.point_iterator(p) |> collect, color=:red, markersize=10)
#     display(fig)
# end

# fig, ax, p = image(rand(4, 5))
# scatter!(Makie.point_iterator(p) |> collect, color=:red, markersize=10)
# display(fig)

# begin
#     fig, ax, p = scatter(1:5, rand(5))
#     linesegments!(Makie.data_limits(ax.scene), color=:red)
#     display(fig)
# end

@testset "barplot errors for three args" begin
    @test_throws ErrorException barplot(1:10, 1:10, 1:10)
end

# https://github.com/MakieOrg/Makie.jl/issues/3551
@testset "scalar color for scatterlines" begin
    colorrange = (1, 5)
    colormap = :Blues
    f, ax, sl = scatterlines(1:10,1:10,color=3,colormap=colormap,colorrange=colorrange)
    l = sl.plots[1]::Lines
    sc = sl.plots[2]::Scatter
    @test l.color[] == 3
    @test l.colorrange[] == colorrange
    @test l.colormap[] == colormap
    @test sc.color[] == 3
    @test sc.colorrange[] == colorrange
    @test sc.colormap[] == colormap
    sl.markercolor = 4
    sl.markercolormap = :jet
    sl.markercolorrange = (2, 7)
    @test l.color[] == 3
    @test l.colorrange[] == colorrange
    @test l.colormap[] == colormap
    @test sc.color[] == 4
    @test sc.colorrange[] == (2, 7)
    @test sc.colormap[] == :jet
end
