@testset "Reported issues" begin

  @testset "Volume errors if data is not a cube (#659)" begin
      fig, ax, vplot = volume(1:8, 1:8, 1:10, rand(8, 8, 10))
      lims = Makie.data_limits(vplot)
      lo, hi = extrema(lims)
      @test all(lo .<= 1)
      @test all(hi .>= (8,8,10))
  end

  @testset "Hexbin singleton (#3357)" begin
      # degenerate case with singleton 0
      hexbin([0, 0], [1, 2])
      hexbin([1, 2], [0, 0])

      # degenerate case with singleton 1
      hexbin([1, 1], [1, 2])
      hexbin([1, 2], [1, 1])
  end

end