using Makie, Test

# nice reference: https://www.nan.fyi/svg-paths
@testset "BezierPath construction" begin
    @test_nowarn BezierPath("m 0,9 L 0,5138 0,9 z")
    @test_broken BezierPath("m 0,1e-5 L 0,5138 0,9 z") isa BezierPath
    @test_nowarn BezierPath("M 100,100 C 100,200 200,100 200,200 z")
    @test_nowarn BezierPath("M 100,100 Q 50,150,100,100 z") isa BezierPath
    @test_broken BezierPath("M 3.0 10.0 A 10.0 7.5 0.0 0.0 0.0 20.0 15.0 z") isa BezierPath
end

@testset "Parsing Q/q" begin
    x0, y0, x1, y1, x, y = 5.0, 0.0, 14.6, 5.2, 13.0, 15.9
    C = Makie.quadratic_curve_to(x0, y0, x1, y1, x, y)
    C2 = Makie.CurveTo(
        x0 + 2 / 3 * (x1 - x0), y0 + 2 / 3 * (y1 - y0), x + 2 / 3 * (x1 - x),
        y + 2 / 3 * (y1 - y),
        x, y
    )
    @test C == C2
    path = BezierPath("M 5.0 0.0 Q 14.6 5.2 13.0 15.9")
    @test path.commands[2] == C2
    path = BezierPath("M 5.0 0.0 q 0.2 2.3 1.0 -2.0")
    C = Makie.quadratic_curve_to(x0, y0, x0 + 0.2, y0 + 2.3, x0 + 1.0, y0 - 2.0)
    @test path.commands[2] == C
end
