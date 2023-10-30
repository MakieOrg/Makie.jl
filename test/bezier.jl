using Makie, Test

# nice reference: https://www.nan.fyi/svg-paths
@testset "BezierPath construction" begin
    @test_nowarn BezierPath("m 0,9 L 0,5138 0,9 z")
    @test_broken BezierPath("m 0,1e-5 L 0,5138 0,9 z") isa BezierPath
    @test_nowarn BezierPath("M 100,100 C 100,200 200,100 200,200 z")
    @test_broken BezierPath("M 100,100 Q 50,150,100,100 z") isa BezierPath
    @test_broken BezierPath("M 3.0 10.0 A 10.0 7.5 0.0 0.0 0.0 20.0 15.0 z") isa BezierPath
end
