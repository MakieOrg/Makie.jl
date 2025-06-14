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
end
