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

    f,a,p = hist(1:10, bins = [0.5, 2.5, 10.5])
    @test p.plots[1].width[] == [2.0, 8.0]

    f,a,p = hist(Float64[], bins = [0.5, 2.5, 10.5])
    @test p.plots[1].width[] == [2.0, 8.0]
    @test p.points[] == [Point2d(1.5, 0.0), Point2d(6.5, 0.0)]
    update!(p, arg1 = 1:10)
    @test p.plots[1].width[] == [2.0, 8.0]
    @test p.points[] == [Point2d(1.5, 2.0), Point2d(6.5, 8.0)]

    f,a,p = hist([1:10, 1:10], stack = [1, 2], color = [:red, :blue], bins = 10)
    @test length(p.plots[1].width[]) == 20
    @test all(x -> x ≈ 0.9, p.plots[1].width[])

    f,a,p = hist([1:10, 1:10], stack = [1, 2], color = [:red, :blue], bins = [0.5, 2.5, 10.5])
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
