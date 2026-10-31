using Test, RayMakie, Makie
using Makie: Mat4f, Vec4f, Vec4d, Vec2d, Plane3f

@testset "text clips to ancestor viewports" begin
    scene = Scene(; size = (300, 120), camera = campixel!, backgroundcolor = :black)
    parent_scene = Scene(scene; viewport = Rect2i(40, 20, 100, 80), camera = campixel!)
    child = Scene(parent_scene; viewport = Rect2i(0, 0, 180, 80), camera = campixel!)
    text!(child, Point2f(12, 30); text = "ABCDEFGHI", fontsize = 30,
        color = :white, fxaa = false)
    screen = RayMakie.Screen(scene; rasterize = true, fxaa = false)
    try
        pixels = copy(Makie.colorbuffer(screen))
        @test count(c -> Makie.green(c) > 0.5, pixels) > 100
        @test all(c -> Makie.green(c) == 0, pixels[:, 141:end])
        @test all(c -> Makie.green(c) == 0, pixels[:, 1:40])
        parent_scene.viewport[] = Rect2i(40, 20, 50, 80)
        smaller = copy(Makie.colorbuffer(screen))
        @test all(c -> Makie.green(c) == 0, smaller[:, 91:end])
        parent_scene.viewport[] = Rect2i(250, 20, 50, 80)
        @test all(c -> Makie.green(c) == 0, Makie.colorbuffer(screen))
    finally
        close(screen)
        Makie.free(scene)
    end
end

@testset "text overdraw bypasses depth and restores it" begin
    scene = Scene(; size = (240, 100), camera = campixel!, backgroundcolor = :black)
    poly!(scene, Point3f[(0, 0, 10), (240, 0, 10), (240, 100, 10), (0, 100, 10)];
        color = :red, shading = NoShading, fxaa = false)
    plot = text!(scene, Point3f(12, 40, 0); text = "overdraw", fontsize = 30,
        color = :white, fxaa = false, overdraw = false)
    screen = RayMakie.Screen(scene; rasterize = true, fxaa = false)
    try
        hidden = copy(Makie.colorbuffer(screen))
        @test all(c -> Makie.green(c) == 0, hidden)
        plot.overdraw[] = true
        visible = copy(Makie.colorbuffer(screen))
        @test count(c -> Makie.green(c) > 0.5, visible) > 500
        plot.overdraw[] = false
        @test Makie.colorbuffer(screen) == hidden
    finally
        close(screen)
        Makie.free(scene)
    end
end

@testset "shared sprite shapes retain their GLMakie distance functions" begin
    @test RayMakie.scatter_rectangle_distance(Vec2f(0.5), Vec2f(1), true) ≈ 0.5f0
    @test RayMakie.scatter_rectangle_distance(Vec2f(0, 0.5), Vec2f(1), true) ≈ 0f0 atol = 1e-6
    @test RayMakie.scatter_ellipse_distance(Vec2f(0.5), Vec2f(2, 1)) ≈ 0.5f0 atol = 1e-5
    @test RayMakie.scatter_ellipse_distance(Vec2f(1, 0.5), Vec2f(2, 1)) ≈ 0f0 atol = 1e-5
    @test RayMakie.scatter_ellipse_distance(Vec2f(1.1, 0.5), Vec2f(2, 1)) ≈ -0.2f0 atol = 1e-5
end

@testset "sprite transforms follow GLMakie's vertex and geometry equations" begin
    rotation = Mat4f(0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
    @test RayMakie.scatter_model_offset(rotation, Vec3f(1, 0, 0)) == Vec3f(0, 1, 0)

    clip = Vec4f(0.3, 0.2, 0.4, 2)
    trans = Mat4f(0.8, 0.1, 0, 0.2, 0.3, 0.9, 0, -0.15,
                 0, 0, 1, 0, 0, 0, 0, 1)
    res = Vec2f(1280, 720)
    density = 1.5f0
    function project_offset(x, y)
        p = Float64.(clip) + Float64.(trans) * Vec4d(x, y, 0, 0)
        return 0.5 * Float64(density) .* Float64.(res) .* Vec2d(p[1], p[2]) ./ p[4]
    end
    h = 1e-6
    dx = (project_offset(h, 0) - project_offset(-h, 0)) / (2h)
    dy = (project_offset(0, h) - project_offset(0, -h)) / (2h)
    expected = sqrt(abs(dx[1] * dy[2] - dx[2] * dy[1]))
    @test RayMakie.scatter_viewport_scale(clip, trans, res, density) ≈ expected rtol = 1e-5
end

@testset "text respects world-space clip planes" begin
    scene = Scene(; size = (360, 96), camera = campixel!, backgroundcolor = :black)
    plot = text!(scene, [Point2f(20, 40), Point2f(210, 40)];
        text = ["left", "right"], fontsize = 31, color = :white, fxaa = false)
    screen = RayMakie.Screen(scene; rasterize = true, fxaa = false)
    try
        before = copy(Makie.colorbuffer(screen))
        @test count(c -> Makie.red(c) > 0.5, before[:, 1:150]) > 30
        plot.clip_planes[] = [Plane3f(Point3f(180, 0, 0), Vec3f(1, 0, 0))]
        after = copy(Makie.colorbuffer(screen))
        @test all(c -> Makie.red(c) == 0, after[:, 1:150])
        @test count(c -> Makie.red(c) > 0.5, after[:, 200:360]) > 30
    finally
        close(screen)
        Makie.free(scene)
    end
end

@testset "text stroke and glow follow attribute updates" begin
    scene = Scene(; size = (360, 96), camera = campixel!, backgroundcolor = :black)
    plot = text!(scene, Point2f(12, 40); text = "Optical resolution",
        fontsize = 31, color = :white, fxaa = false,
        strokewidth = 0, strokecolor = :red, glowwidth = 0, glowcolor = (:blue, 0.5))
    screen = RayMakie.Screen(scene; rasterize = true, fxaa = false)
    try
        original = copy(Makie.colorbuffer(screen))
        plot.strokewidth[] = 1.2
        plot.glowwidth[] = 2
        decorated = copy(Makie.colorbuffer(screen))
        @test count(c -> Makie.red(c) > Makie.green(c) + 0.05, decorated) > 30
        @test count(c -> Makie.blue(c) > Makie.red(c) + 0.05, decorated) > 30
        plot.strokewidth[] = 0
        plot.glowwidth[] = 0
        @test Makie.colorbuffer(screen) == original
    finally
        close(screen)
        Makie.free(scene)
    end
end

@testset "density changes keep line antialiasing in output pixels" begin
    scene = Scene(; size = (400, 100), camera = campixel!, backgroundcolor = :black)
    lines!(scene, [Point2f(10, 40.25), Point2f(390, 40.25)];
        color = :white, linewidth = 1, fxaa = false)
    screen = RayMakie.Screen(scene; rasterize = true, fxaa = false)
    try
        original = copy(Makie.colorbuffer(screen; px_per_unit = 1))
        dense = copy(Makie.colorbuffer(screen; px_per_unit = 1.5))
        @test size(dense) == (150, 600)
        # A 1.5-pixel line, at this subpixel position, covers the central pixel
        # almost completely. Stale creation density spreads AA over 1.2 pixels
        # and lowers its coverage to about 0.85.
        @test Makie.red(dense[90, 300]) > 0.95
        @test Makie.colorbuffer(screen; px_per_unit = 1) == original
    finally
        close(screen)
        Makie.free(scene)
    end
end

@testset "text coverage retains the label backing" begin
    function labelpixels(textfirst)
        scene = Scene(; size = (360, 96), camera = campixel!, backgroundcolor = :black)
        function addtext!()
            p = text!(scene, Point2f(12, 40); text = "Optical resolution",
                fontsize = 31, color = :white, fxaa = false)
            translate!(p, 0, 0, 2)
        end
        function addbacking!()
            p = poly!(scene, Rect2f(0, 0, 360, 96); color = (:gray, 0.8),
                strokewidth = 0, shading = NoShading, fxaa = false)
            translate!(p, 0, 0, 1)
        end
        if textfirst
            addtext!(); addbacking!()
        else
            addbacking!(); addtext!()
        end
        try
            return copy(Makie.colorbuffer(scene; backend = RayMakie,
                rasterize = true, fxaa = false))
        finally
            close(Makie.getscreen(scene, RayMakie))
            Makie.free(scene)
        end
    end
    @test labelpixels(true) == labelpixels(false)
end

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

@testset "screen without FXAA keeps analytic glyph antialiasing" begin
    scene = Scene(; size = (360,96), camera = campixel!, backgroundcolor = :black)
    text!(scene, Point2f(8,40); text = "Optical resolution", fontsize = 31, color = :white, fxaa = true)
    try
        pixels = Makie.colorbuffer(scene; backend = RayMakie, rasterize = true, fxaa = false)
        # Hard step edges have only black and white. Analytic coverage must
        # remain even when the screen suppresses the plot's FXAA request.
        partial = count(c -> 0.02 < Makie.Colors.red(c) < 0.98, pixels)
        @test partial > 30
    finally
        close(Makie.getscreen(scene, RayMakie))
        Makie.free(scene)
    end
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
