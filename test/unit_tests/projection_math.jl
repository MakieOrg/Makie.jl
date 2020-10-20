@testset "Projection math" begin
    @test eltype(AbstractPlotting.rotationmatrix_x(1)) == Float64
    @test eltype(AbstractPlotting.rotationmatrix_x(1f0)) == Float32 
end
