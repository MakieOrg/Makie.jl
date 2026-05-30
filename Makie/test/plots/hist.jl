@testset "Histogram plotting" begin
    unequal_vec = [1; rand(2:9, rand(1:9))]
    allequal_vec = fill(rand(1:9), rand(1:9))
    # normal range
    @test_nowarn hist(0:rand(1:9))
    # initialize with unequal observable vector
    v = Observable(unequal_vec)
    @test_nowarn hist(v)
    # change to allequal vector
    @test_nowarn v[] = allequal_vec
    # initialize with allequal observable vector
    v = Observable(allequal_vec)
    @test_nowarn hist(v)
    # change to unequal vector
    @test_nowarn v[] = unequal_vec

    f, a, p = hist(1:10, bins = [0.5, 2.5, 10.5])
    @test p.plots[1].width[] == [2.0, 8.0]

    f, a, p = hist(Float64[], bins = [0.5, 2.5, 10.5])
    @test p.plots[1].width[] == [2.0, 8.0]
    @test p.points[] == [Point2d(1.5, 0.0), Point2d(6.5, 0.0)]
    update!(p, arg1 = 1:10)
    @test p.plots[1].width[] == [2.0, 8.0]
    @test p.points[] == [Point2d(1.5, 2.0), Point2d(6.5, 8.0)]

    f, a, p = hist([1:10, 1:10], stack = [1, 2], color = [:red, :blue], bins = 10)
    @test length(p.plots[1].width[]) == 20
    @test all(x -> x ≈ 0.9, p.plots[1].width[])

    f, a, p = hist([1:10, 1:10], stack = [1, 2], color = [:red, :blue], bins = [0.5, 2.5, 10.5])
    @test p.plots[1].width[] == [2.0, 8.0, 2.0, 8.0]
end

@testset "Empty histogram" begin
    for plotfunc in (hist, stephist)
        arg = Observable(Float64[])
        f, a, p = @test_nowarn plotfunc(arg)
        Makie.update_state_before_display!(f)
        @test isempty(p.plots[1][1][])
        push!(arg[], 0.1)
        notify(arg)
        @test !isempty(p.plots[1][1][])
    end
end

using StatsBase
        
@testset "StatsBase.Histogram" begin
    edges = [-1, -0.5, 0, 0.1, 0.9, 1]
    h = fit(Histogram, sin.(1:100), edges)
    counts = [eps(); h.weights; eps()]
    f, a, p = stairs(h)
    @test p.converted_1[] ≈ Point2.([edges; 1], counts)

    h = fit(Histogram, sin.(1:100), -1:0.5:1)
    f, a, p = plot(h)
    @test p.plots[1] isa BarPlot
    @test p.plots[1].positions[] ≈ Point2.(-0.75:0.5:0.75, h.weights)
    @test p.plots[1].width[] ≈ fill(0.5, 4)
    @test p.plots[1].gap[] == 0

    h = fit(Histogram, sin.(1:100), [-1, 0.2, 1])
    f, a, p = plot(h)
    @test p.plots[1] isa BarPlot
    @test p.plots[1].positions[] ≈ Point2.([-0.4, 0.6], h.weights)
    @test p.plots[1].width[] ≈ [1.2, 0.8]
    @test p.plots[1].gap[] == 0

    h = fit(Histogram, (sin.(1:100), cos.(1:100)), ([-1, 0.2, 1.0], [-1, 0.0, 1.0]))
    f, a, p = plot(h)
    @test p.plots[1] isa Heatmap
    @test p.plots[1].x[] ≈ h.edges[1]
    @test p.plots[1].y[] ≈ h.edges[2]
    @test p.plots[1].image[] ≈ h.weights

    h = fit(Histogram, (sin.(1:100), cos.(1:100), sin.(1:100)), ([-1, 0.2, 1.0], [-1, 0.0, 1.0], [-1, 0, 1]))
    @test_throws ErrorException plot(h)
    h = fit(Histogram, (sin.(1:100), cos.(1:100), sin.(1:100)), ([-1, -0.5, 0, 0.5, 1.0], [-1, 0.0, 1.0], [-1, 1]))
    f, a, p = plot(h)
    @test p.plots[1] isa Voxels
    @test all(p.plots[1].x[].data .≈ extrema(h.edges[1]))
    @test all(p.plots[1].y[].data .≈ extrema(h.edges[2]))
    @test all(p.plots[1].z[].data .≈ extrema(h.edges[3]))
    @test p.plots[1].chunk[] ≈ h.weights
end
