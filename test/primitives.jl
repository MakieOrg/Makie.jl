@testset "ablines" begin
    # Test ablines with 0 dim arrays
    f, ax, pl = ablines(fill(0), fill(1))
    reset_limits!(ax)
    points = pl.plots[1][1]
    @test Point2f.(points[]) == [Point2f(0), Point2f(10)]
    limits!(ax, 5, 15, 6, 17)
    @test Point2f.(points[]) == [Point2f(5), Point2f(15)]
end

@testset "arrows" begin
    # Test for:
    # https://github.com/MakieOrg/Makie.jl/issues/3273
    directions = decompose(Point2f, Circle(Point2f(0), 1))
    points = decompose(Point2f, Circle(Point2f(0), 0.5))
    color = range(0, 1, length = length(directions))
    fig, ax, pl = arrows(points, directions; color = color)
    cbar = Colorbar(fig[1, 2], pl)
    @test cbar.limits[] == Vec2f(0, 1)
    pl.colorrange = (0.5, 0.6)
    @test cbar.limits[] ≈ Vec2f(0.5, 0.6)
end

@testset "voxels" begin
    data = reshape(collect(range(0.3, 1.8, length = 6 * 5 * 4)), 6, 5, 4)
    f, a, p = voxels(
        data,
        lowclip = RGBf(1, 0, 1), highclip = RGBf(0, 1, 0),
        colormap = [RGBf(0, 0, 0), RGBf(1, 1, 1)], gap = 0.1
    )

    # data conversion pipeline
    @test p.args[1][] === data
    @test p.converted[1][] == (-3.0, 3.0)
    @test p.converted[2][] == (-2.5, 2.5)
    @test p.converted[3][] == (-2.0, 2.0)

    @test p.colorrange[] == Makie.automatic # otherwise no auto _limits
    @test all(p._limits[] .≈ (0.3, 1.8)) # controls conversion to voxel ids
    ids = map(data) do val
        trunc(UInt8, clamp(2 + 253 * (val - 0.3) / (1.8 - 0.3), 2, 254))
    end
    @test p.converted[4][] == ids

    # colormap
    cc = p.calculated_colors[]
    @test length(cc.colormap[]) == 255
    @test cc.colormap[][1] == RGBAf(1, 0, 1, 1)
    @test cc.colormap[][2] == RGBAf(0, 0, 0, 1)
    @test cc.colormap[][2:(end - 1)] == resample_cmap([RGBAf(0, 0, 0, 1), RGBAf(1, 1, 1, 1)], 253)
    @test cc.colormap[][end - 1] == RGBAf(1, 1, 1, 1)
    @test cc.colormap[][end] == RGBAf(0, 1, 0, 1)

    # voxels-as-meshscatter helpers
    @test Makie.voxel_size(p) ≈ Vec3f(0.9)
    ps = [Point3f(x - 2.5, y - 2.0, z - 1.5) for z in 0:3 for y in 0:4 for x in 0:5]
    @test Makie.voxel_positions(p) ≈ ps
    @test Makie.voxel_colors(p) == cc.colormap[][p.converted[end][][:]]
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
    f, ax, sl = scatterlines(1:10, 1:10, color = 3, colormap = colormap, colorrange = colorrange)
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
