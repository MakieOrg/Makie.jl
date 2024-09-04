using Test
using CairoMakie
using Makie.FileIO
using ReferenceTests

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
        fig = Figure(size = (480, 792))
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
        fig = scatter(1:4, figure=(; size = (800, 800)))
        save("test.pdf", fig)
        size(Makie.colorbuffer(fig)) == (800, 800)
        rm("test.pdf")
    end

    @testset "switching from pdf screen to png, save" begin
        fig = scatter(1:4, figure=(; size = (800, 800)))
        save("test.pdf", fig)
        save("test.png", fig)
        @test size(load("test.png")) == (1600, 1600)
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
        scene = Scene(size = (800, 800));
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
    f, ax, pl = scatter(points, axis=(type=Axis, aspect=DataAspect(), limits=(0.4, N + 0.6, 0.4, N + 0.6),), figure=(size=(600, 800),))

    vio = Makie.VideoStream(f; format="mp4", px_per_unit=2.0, backend=CairoMakie)
    tmp_path = vio.path

    @test vio.screen isa CairoMakie.Screen{CairoMakie.IMAGE}
    @test size(vio.screen) == size(f.scene) .* 2
    @test vio.screen.device_scaling_factor == 2.0

    Makie.recordframe!(vio)
    save("test.mp4", vio)
    save("test_2.mkv", vio)
    save("test_3.mp4", vio)
    # make sure all files are correctly saved:
    @test all(isfile, ["test.mp4", "test_2.mkv", "test_3.mp4"])
    @test filesize("test.mp4") == filesize("test_3.mp4") > 3000
    @test filesize("test.mp4") != filesize("test_2.mkv") > 3000
    rm.(["test.mp4", "test_2.mkv", "test_3.mp4"])
    finalize(vio); yield()
    @test !isfile(tmp_path)
end

@testset "plotlist no ambiguity (#4038)" begin
    f = plotlist([Makie.SpecApi.Scatter(1:10)])
    Makie.colorbuffer(f; backend=CairoMakie)
    plotlist!([Makie.SpecApi.Scatter(1:10)])
end

@testset "multicolor line clipping (#4313)" begin
    fig, ax, p = contour(rand(20,20))
    xlims!(ax, 0, 10)
    Makie.colorbuffer(fig; backend=CairoMakie)
end

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
    "Textured meshscatter", # not yet implemented
    "Voxel - texture mapping", # not yet implemented
    "Miter Joints for line rendering", # CairoMakie does not show overlap here
    "Scatter with FastPixel" # almost works, but scatter + markerspace=:data seems broken for 3D
])

functions = [:volume, :volume!, :uv_mesh]

@testset "refimages" begin
    CairoMakie.activate!(type = "png", px_per_unit = 1)
    ReferenceTests.mark_broken_tests(excludes, functions=functions)
    recorded_files, recording_dir = @include_reference_tests CairoMakie "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(scores; threshold = 0.05)
end

@testset "PdfVersion" begin
    @test CairoMakie.pdfversion("1.4") === CairoMakie.PDFv14
    @test CairoMakie.pdfversion("1.5") === CairoMakie.PDFv15
    @test CairoMakie.pdfversion("1.6") === CairoMakie.PDFv16
    @test CairoMakie.pdfversion("1.7") === CairoMakie.PDFv17
    @test_throws ArgumentError CairoMakie.pdfversion("foo")
end

@testset "restrict PDF version" begin
    magic_number(filename) = open(filename) do f
        return String(read(f, sizeof("%PDF-X.Y")))
    end

    filename = "$(tempname()).pdf"

    try
        save(filename, Figure(), pdf_version=nothing)
        @test startswith(magic_number(filename), "%PDF-")
    finally
        rm(filename)
    end

    for version in ["1.4", "1.5", "1.6", "1.7"]
        try
            save(filename, Figure(), pdf_version=version)
            @test magic_number(filename) == "%PDF-$version"
        finally
            rm(filename)
        end
    end

    @test_throws ArgumentError save(filename, Figure(), pdf_version="foo")
end

@testset "Tick Events" begin
    f, a, p = scatter(rand(10));
    @test events(f).tick[] == Makie.Tick()

    filename = "$(tempname()).png"
    try
        save(filename, f)
        tick = events(f).tick[]
        @test tick.state == Makie.OneTimeRenderTick
        @test tick.count == 0
        @test tick.time == 0.0
        @test tick.delta_time == 0.0
    finally
        rm(filename)
    end

    filename = "$(tempname()).mp4"
    try
        tick_record = Makie.Tick[]
        record(_ -> push!(tick_record, events(f).tick[]), f, filename, 1:10, framerate = 30)
        dt = 1.0 / 30.0

        for (i, tick) in enumerate(tick_record)
            @test tick.state == Makie.OneTimeRenderTick
            @test tick.count == i-1
            @test tick.time ≈ dt * (i-1)
            @test tick.delta_time ≈ dt
        end
    finally
        rm(filename)
    end

    # test destruction of tick overwrite
    f, a, p = scatter(rand(10));
    let
        io = VideoStream(f)
        @test events(f).tick[] == Makie.Tick(Makie.OneTimeRenderTick, 0, 0.0, 1.0 / io.options.framerate)
        nothing
    end
    tick = Makie.Tick(Makie.UnknownTickState, 1, 1.0, 1.0)
    events(f).tick[] = tick
    @test events(f).tick[] == tick
end