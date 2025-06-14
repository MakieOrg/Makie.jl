@testset "Camera utilities" begin
    negative_rect = Rect2f(0, 0, -1, 1)
    @test Makie.absrect(negative_rect) == Rect2(-1, 0, 1, 1)
end
