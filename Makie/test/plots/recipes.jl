@testset "series labels" begin
    # Test #5850
    f, a, p = series(rand(4, 4))
    for (i, p) in enumerate(p.plots[1].plots) # spec plots
        @test p.label[] == "series $i"
    end
end
