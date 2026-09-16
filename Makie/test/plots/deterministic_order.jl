using Makie, Test
using Random: MersenneTwister, shuffle

@testset "Closed cycles start at a fixed element" begin
    loop = [(1.0, 1.0), (0.0, 1.0), (0.0, 0.0), (1.0, 0.0), (1.0, 1.0)]
    rotated = [(0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (0.0, 0.0)]
    @test Makie.canonical_cycle_start(loop) == Makie.canonical_cycle_start(rotated) == rotated

    @test Makie.canonical_cycle_start([3, 4, 1, 2, 3]) == [1, 2, 3, 4, 1]

    open_line = [(1.0, 1.0), (0.0, 1.0), (0.0, 0.0)]
    @test Makie.canonical_cycle_start(open_line) == open_line
end

@testset "hexbin bin order independent of input order" begin
    x = repeat(range(0, 1, length = 20), 20)
    y = repeat(range(0, 1, length = 20), inner = 20)
    perm = shuffle(MersenneTwister(1), eachindex(x))
    fig, ax, hb = hexbin(x, y, bins = 10)
    fig2, ax2, hb2 = hexbin(x[perm], y[perm], bins = 10)
    @test hb.points[] == hb2.points[]
    @test hb.count_hex[] == hb2.count_hex[]
end

@testset "datashader categories are sorted" begin
    ps = Point2f.(range(0, 1, length = 10), range(0, 1, length = 10))
    names = string.(collect("abcdef"))
    fig, ax, pl = datashader(Dict(name => ps for name in names); async = false)
    @test first.(pl._categories[]) == names
end
