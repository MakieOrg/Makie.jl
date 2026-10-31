using Test, RayMakie, Makie

@testset "glyph smoothing follows the local distance gradient" begin
    # A true distance field must have the same one-pixel smoothing footprint
    # under changes of scale and edge orientation.
    for scale in (0.5f0, 1f0, 1.5f0, 4f0), angle in (0f0, 0.3f0, 0.9f0, 1.5f0)
        dx, dy = cos(angle) / scale, sin(angle) / scale
        center = 0.2f0
        dx2 = RayMakie.glyph_squared_partial(center, center + dx / 2, center - dx / 2)
        dy2 = RayMakie.glyph_squared_partial(center, center + dy / 2, center - dy / 2)
        @test RayMakie.glyph_aa_radius(scale, dx2, dy2) ≈ inv(sqrt(2f0))
        # A stretched or sampled field whose local gradient doubles needs
        # twice the distance-space ramp, not the old fixed width.
        @test RayMakie.glyph_aa_radius(scale, 4dx2, 4dy2) ≈ sqrt(2f0)
    end
    # Opposite sides of a local extremum must not cancel to a zero derivative.
    @test RayMakie.glyph_squared_partial(0f0, 1f0, 1f0) == 2f0
    @test RayMakie.glyph_squared_partial(0f0, -1f0, -1f0) == 2f0
    @test RayMakie.glyph_squared_partial(0f0, 0.25f0, -1f0) == 2f0
end

@testset "adaptive glyph shader renders on the active backend" begin
    scene = Scene(; size = (360,96), camera = campixel!, backgroundcolor = :black)
    text!(scene, Point2f(8,55); text = "opening: up to 25 mm", fontsize = 24, color = :white)
    text!(scene, Point2f(8,20); text = "Öffnung: bis 25 mm", fontsize = 24, color = :white)
    try
        pixels = Makie.colorbuffer(scene; backend = RayMakie)
        @test size(pixels) == (96,360)
        ink = count(c -> max(Makie.Colors.red(c), Makie.Colors.green(c), Makie.Colors.blue(c)) > 0.1, pixels)
        @test 100 < ink < length(pixels) / 3
    finally
        close(Makie.getscreen(scene, RayMakie))
        Makie.free(scene)
    end
end
