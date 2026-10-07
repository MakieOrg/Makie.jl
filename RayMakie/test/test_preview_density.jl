using Test, Makie, RayMakie, Mantle
import GeometryBasics
using Makie.Colors: red, green, blue

@testset "raster bounds of GPU vertices" begin
    points = Point3f[Point3f(-3, 2, 1), Point3f(4, -5, 7), Point3f(1, 0, -2)]
    devicepoints = Mantle.devicearray(Mantle.defaultbackend(), points)
    @test RayMakie.local_bounds(devicepoints) == Rect3f(points)
    @test Makie.extrema_nan(devicepoints) == Makie.extrema_nan(points)
    withnan = Mantle.devicearray(Mantle.defaultbackend(), Point3f[points..., Point3f(NaN)])
    @test Makie.extrema_nan(withnan) == Makie.extrema_nan(points)
end

@testset "raster scenes defer unused trace textures" begin
    for kind in (:mesh, :surface)
        @testset "$kind" begin
            scene = Scene(size = (64, 64), backgroundcolor = :black, lights = [AmbientLight(RGBf(1, 1, 1))])
            cam3d!(scene)
            texture = fill(RGBAf(1, 0, 0, 1), 16, 16)
            quad = GeometryBasics.Mesh(
                [Point3f(0, 0, 0), Point3f(1, 0, 0), Point3f(1, 1, 0), Point3f(0, 1, 0)],
                [GeometryBasics.GLTriangleFace(1, 2, 3), GeometryBasics.GLTriangleFace(1, 3, 4)];
                normal = fill(Vec3f(0, 0, 1), 4),
                uv = [Vec2f(0, 0), Vec2f(1, 0), Vec2f(1, 1), Vec2f(0, 1)]
            )
            plot = kind === :mesh ? mesh!(scene, quad; color = texture, shading = NoShading) :
                surface!(
                    scene, Float32[0, 1], Float32[0, 1], zeros(Float32, 2, 2);
                    color = texture, shading = NoShading
                )
            update_cam!(scene, Vec3f(0.5, 0.5, 2.2), Vec3f(0.5, 0.5, 0), Vec3f(0, 1, 0))
            screen = RayMakie.Screen(
                scene; visible = false, rasterize = true, samples = 8,
                max_depth = 1, device = Mantle.defaultbackend()
            )
            hue(image, channel) = sum(channel, image[28:36, 28:36])
            try
                raster = Makie.colorbuffer(screen)
                @test plot.attributes[:trace_color_tex][] === nothing
                @test hue(raster, red) > 2 * hue(raster, blue)
                plot.color = fill(RGBAf(0, 0, 1, 1), 16, 16)
                raster = Makie.colorbuffer(screen)
                @test plot.attributes[:trace_color_tex][] === nothing
                @test hue(raster, blue) > 2 * hue(raster, red)
                RayMakie.setrasterize!(screen, false)
                traced = Makie.colorbuffer(screen)
                @test plot.attributes[:trace_color_tex][] !== nothing
                @test hue(traced, blue) > 2 * hue(traced, red)
            finally
                close(screen)
            end
        end
    end
end

@testset "offscreen density keeps the logical scene" begin
    scene = Scene(size = (160, 96), camera = campixel!, backgroundcolor = :black)
    poly!(scene, Rect2f(32, 24, 64, 48); color = :red)
    text!(scene, "Hi"; position = Point2f(120, 20), fontsize = 16, color = :green)
    screen = RayMakie.Screen(scene; visible = false, device = Mantle.defaultbackend())
    try
        @test RayMakie.isprogressive(screen)
        full = Makie.colorbuffer(screen; px_per_unit = 1)
        original_state = first(screen.scene_states)
        half = Makie.colorbuffer(screen; px_per_unit = 0.5)
        @test size(scene) == (160, 96)
        @test size(full) == (96, 160)
        @test size(half) == (48, 80)
        @test first(screen.scene_states) === original_state
        redbounds(img) = begin
            points = findall(p -> red(p) > 0.5 && green(p) < 0.2, img)
            (
                minimum(p -> p[1], points), maximum(p -> p[1], points),
                minimum(p -> p[2], points), maximum(p -> p[2], points),
            )
        end
        @test all(abs.(2 .* redbounds(half) .- redbounds(full)) .<= 2)
        restored = Makie.colorbuffer(screen; px_per_unit = 1)
        @test size(restored) == size(full)
        @test redbounds(restored) == redbounds(full)
        @test_throws ArgumentError Makie.colorbuffer(screen; px_per_unit = 0)
        @test_throws ArgumentError Makie.colorbuffer(screen; px_per_unit = NaN)
    finally
        close(screen)
    end
end

@testset "atlas UV animation retains its texture material" begin
    C = Makie.Colors
    sheet = fill(C.RGBA{C.N0f8}(1, 0, 0, 1), 64, 128)
    sheet[:, 65:128] .= C.RGBA{C.N0f8}(0, 1, 0, 1)
    scene = Scene(size = (64, 64), lights = [AmbientLight(RGBf(1, 1, 1))])
    cam3d!(scene)
    quad = GeometryBasics.Mesh(
        [Point3f(0, 0, 0), Point3f(1, 0, 0), Point3f(1, 1, 0), Point3f(0, 1, 0)],
        [GeometryBasics.GLTriangleFace(1, 2, 3), GeometryBasics.GLTriangleFace(1, 3, 4)];
        normal = fill(Vec3f(0, 0, 1), 4),
        uv = [Vec2f(0, 0), Vec2f(1, 0), Vec2f(1, 1), Vec2f(0, 1)]
    )
    cell(c) = GeometryBasics.Mat{2, 3, Float32}(0, 0.5, -1, 0, 1, (c - 1) / 2)
    p = mesh!(scene, quad; color = sheet, uv_transform = cell(1), shading = NoShading)
    update_cam!(scene, Vec3f(0.5, 0.5, 2.2), Vec3f(0.5, 0.5, 0), Vec3f(0, 1, 0))
    screen = RayMakie.Screen(
        scene; visible = false, samples = 8, max_depth = 1,
        device = Mantle.defaultbackend()
    )
    hue(img, channel) = sum(channel, img[28:36, 28:36])
    try
        redframe = Makie.colorbuffer(screen)
        before = p.attributes[:trace_renderobject][]
        p.uv_transform = cell(2)
        greenframe = Makie.colorbuffer(screen)
        after = p.attributes[:trace_renderobject][]
        @test before.material === after.material
        @test before.mat_idx == after.mat_idx
        @test hue(redframe, red) > 2 * hue(redframe, green)
        @test hue(greenframe, green) > 2 * hue(greenframe, red)
        p.color = fill(C.RGBA{C.N0f8}(0, 0, 1, 1), 64, 128)
        blueframe = Makie.colorbuffer(screen)
        @test hue(blueframe, blue) > 2 * hue(blueframe, green)
        RayMakie.setrasterize!(screen, true)
        @test !RayMakie.isprogressive(screen)
        rasterframe = Makie.colorbuffer(screen)
        @test hue(rasterframe, blue) > 2 * hue(rasterframe, green)
        RayMakie.setrasterize!(screen, false)
        @test RayMakie.isprogressive(screen)
        tracedframe = Makie.colorbuffer(screen)
        @test hue(tracedframe, blue) > 2 * hue(tracedframe, green)
    finally
        close(screen)
    end
end
