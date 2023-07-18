using Test
using CairoMakie
using Pkg
using Makie.FileIO

path = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
# Before changing Pkg environment, try the test in #864
@testset "Runs without error" begin
    fig = Figure()
    scatter(fig[1, 1], rand(10))
    fn = tempname()*".png"
    try
        save(fn, fig)
    finally
        rm(fn)
    end
end

include(joinpath(@__DIR__, "svg_tests.jl"))
include(joinpath(@__DIR__, "rasterization_tests.jl"))


@testset "changing screens" begin
    @testset "svg -> png" begin
        # Now that scene.current_screens contains a CairoMakie screen after save
        # switching formats is a bit more problematic
        # See comments in src/display.jl + backend_show(screen::Screen, ...)
        f = scatter(1:4)
        save("test.svg", f)
        save("test.png", f)
        save("test.svg", f)
        @test isfile("test.svg")
        @test isfile("test.png")
        rm("test.png")
        rm("test.svg")

    end

    @testset "saving pdf two times" begin
        # https://github.com/MakieOrg/Makie.jl/issues/2433
        fig = Figure(resolution=(480, 792))
        ax = Axis(fig[1, 1])
        # The IO was shared between screens, which left the second figure empty
        save("fig.pdf", fig, pt_per_unit=0.5)
        save("fig2.pdf", fig, pt_per_unit=0.5)
        @test !isempty("fig.pdf")
        @test !isempty("fig2.pdf")
        rm("fig.pdf")
        rm("fig2.pdf")
    end

    @testset "switching from pdf screen to png, colorbuffer" begin
        # https://github.com/MakieOrg/Makie.jl/issues/2438
        # This bug was caused by using the screen size of the pdf screen, which
        # has a different device_scaling_factor, and therefore a different screen size
        fig = scatter(1:4, figure=(; resolution=(800, 800)))
        save("test.pdf", fig)
        size(Makie.colorbuffer(fig)) == (800, 800)
        rm("test.pdf")
    end

    @testset "switching from pdf screen to png, save" begin
        fig = scatter(1:4, figure=(; resolution=(800, 800)))
        save("test.pdf", fig)
        save("test.png", fig)
        @test size(load("test.png")) == (800, 800)
        rm("test.pdf")
        rm("test.png")
    end

    @testset "removing old screen" begin
        f, ax, pl = scatter(1:4)
        test_type(f, typ) = CairoMakie.get_render_type(Makie.getscreen(f.scene).surface) == typ
        save("test.png", f)
        @test length(f.scene.current_screens) == 1
        @test test_type(f, CairoMakie.IMAGE)

        save("test.svg", f)
        @test length(f.scene.current_screens) == 1
        @test test_type(f, CairoMakie.SVG)

        save("test.png", f)
        @test length(f.scene.current_screens) == 1
        @test test_type(f, CairoMakie.IMAGE)

        rm("test.svg")
        rm("test.png")
    end

    @testset "changing resolution of same format" begin
        # see: https://github.com/MakieOrg/Makie.jl/issues/2433
        # and: https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/441
        scene = Scene(resolution=(800, 800));
        load_save(s; kw...) = (save("test.png", s; kw...); load("test.png"))
        @test size(load_save(scene, px_per_unit=2)) == (1600, 1600)
        @test size(load_save(scene, px_per_unit=1)) == (800, 800)
        rm("test.png")
    end
end

@testset "mimes" begin
    f, ax, pl = scatter(1:4)
    CairoMakie.activate!(type="pdf")
    @test showable("application/pdf", f)
    CairoMakie.activate!(type="eps")
    @test showable("application/postscript", f)
    CairoMakie.activate!(type="svg")
    @test showable("image/svg+xml", f)
    CairoMakie.activate!(type="png")
    @test showable("image/png", f)
    # see https://github.com/MakieOrg/Makie.jl/pull/2167
    @test !showable("blaaa", f)

    CairoMakie.activate!(type="png")
    @test showable("image/png", Scene())
    @test !showable("image/svg+xml", Scene())
    # setting svg should leave png as showable, since it's usually lower in the display stack priority
    CairoMakie.activate!(type="svg")
    @test showable("image/png", Scene())
    @test showable("image/svg+xml", Scene())
end

@testset "VideoStream & screen options" begin
    N = 3
    points = Observable(Point2f[])
    f, ax, pl = scatter(points, axis=(type=Axis, aspect=DataAspect(), limits=(0.4, N + 0.6, 0.4, N + 0.6),), figure=(resolution=(600, 800),))
    vio = Makie.VideoStream(f; format="mp4", px_per_unit=2.0, backend=CairoMakie)
    @test vio.screen isa CairoMakie.Screen{CairoMakie.IMAGE}
    @test size(vio.screen) == size(f.scene) .* 2
    @test vio.screen.device_scaling_factor == 2.0

    Makie.recordframe!(vio)
    save("test.mp4", vio)
    @test isfile("test.mp4") # Make sure no error etc
    rm("test.mp4")
end

using ReferenceTests

excludes = Set([
    "Colored Mesh",
    "Line GIF",
    "Streamplot animation",
    "Line changing colour",
    "Axis + Surface",
    "Streamplot 3D",
    "Meshscatter Function",
    "Hollow pie chart",
    "Record Video",
    "Image on Geometry (Earth)",
    "Image on Geometry (Moon)",
    "Comparing contours, image, surfaces and heatmaps",
    "Textured Mesh",
    "Simple pie chart",
    "Animated surface and wireframe",
    "Open pie chart",
    "image scatter",
    "surface + contour3d",
    "Orthographic Camera",
    "Legend",
    "rotation",
    "3D Contour with 2D contour slices",
    "Surface with image",
    "Test heatmap + image overlap",
    "Text Annotation",
    "step-2",
    "FEM polygon 2D.png",
    "Text rotation",
    "Image on Surface Sphere",
    "FEM mesh 2D",
    "Hbox",
    "Subscenes",
    "Arrows 3D",
    "Layouting",
    # sigh this is actually super close,
    # but doesn't interpolate the values inside the
    # triangles, so looks pretty different
    "FEM polygon 2D",
    "Connected Sphere",
    # markers too big, close otherwise, needs to be assimilated with glmakie
    "Unicode Marker",
    "Depth Shift",
    "Order Independent Transparency",
    "heatmap transparent colormap",
    "fast pixel marker",
    "scatter with glow",
    "scatter with stroke",
    "heatmaps & surface",
    "Textured meshscatter" # not yet implemented
])

functions = [:volume, :volume!, :uv_mesh]

@testset "refimages" begin
    CairoMakie.activate!(type = "png")
    ReferenceTests.mark_broken_tests(excludes, functions=functions)
    recorded_files, recording_dir = @include_reference_tests "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(scores; threshold = 0.032)
end
