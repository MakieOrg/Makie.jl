ENV["ENABLE_COMPUTE_CHECKS"] = "true"

using Test
using CairoMakie
using Makie.FileIO
using ReferenceTests

# Before changing Pkg environment, try the test in #864
@testset "Runs without error" begin
    fig = Figure()
    scatter(fig[1, 1], rand(10))
    fn = tempname() * ".png"
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
        save("fig.pdf", fig, pt_per_unit = 0.5)
        save("fig2.pdf", fig, pt_per_unit = 0.5)
        @test !isempty("fig.pdf")
        @test !isempty("fig2.pdf")
        rm("fig.pdf")
        rm("fig2.pdf")
    end

    @testset "switching from pdf screen to png, colorbuffer" begin
        # https://github.com/MakieOrg/Makie.jl/issues/2438
        # This bug was caused by using the screen size of the pdf screen, which
        # has a different device_scaling_factor, and therefore a different screen size
        fig = scatter(1:4, figure = (; size = (800, 800)))
        save("test.pdf", fig)
        size(Makie.colorbuffer(fig)) == (800, 800)
        rm("test.pdf")
    end

    @testset "switching from pdf screen to png, save" begin
        fig = scatter(1:4, figure = (; size = (800, 800)))
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
        scene = Scene(size = (800, 800))
        load_save(s; kw...) = (save("test.png", s; kw...); load("test.png"))
        @test size(load_save(scene, px_per_unit = 2)) == (1600, 1600)
        @test size(load_save(scene, px_per_unit = 1)) == (800, 800)
        rm("test.png")
    end
end

@testset "mimes" begin
    f, ax, pl = scatter(1:4)
    CairoMakie.activate!(type = "pdf")
    @test showable("application/pdf", f)
    CairoMakie.activate!(type = "eps")
    @test showable("application/postscript", f)
    CairoMakie.activate!(type = "svg")
    @test showable("image/svg+xml", f)
    CairoMakie.activate!(type = "png")
    @test showable("image/png", f)
    # see https://github.com/MakieOrg/Makie.jl/pull/2167
    @test !showable("blaaa", f)

    CairoMakie.activate!(type = "png")
    @test showable("image/png", Scene())
    @test !showable("image/svg+xml", Scene())
    # setting svg should leave png as showable, since it's usually lower in the display stack priority
    CairoMakie.activate!(type = "svg")
    @test showable("image/png", Scene())
    @test showable("image/svg+xml", Scene())
end

@testset "VideoStream & screen options" begin
    N = 3
    points = Observable(Point2f[])
    width = 600
    height = 800
    f, ax, pl = scatter(points, axis = (type = Axis, aspect = DataAspect(), limits = (0.4, N + 0.6, 0.4, N + 0.6)), figure = (size = (width, height),))

    vio = Makie.VideoStream(f; format = "mp4", px_per_unit = 2.0, backend = CairoMakie)
    tmp_path = vio.path

    @test vio.screen isa CairoMakie.Screen{CairoMakie.IMAGE}
    @test size(vio.screen) == size(f.scene) .* 2
    @test vio.screen.device_scaling_factor == 2.0

    Makie.recordframe!(vio)

    html = repr(MIME"text/html"(), vio)
    @test occursin("width=\"$width\"", html)
    @test occursin("height=\"$height\"", html)

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

# @testset "plotlist no ambiguity (#4038)" begin
#     f = plotlist([Makie.SpecApi.Scatter(1:10)])
#     Makie.colorbuffer(f; backend=CairoMakie)
#     plotlist!([Makie.SpecApi.Scatter(1:10)])
# end

@testset "multicolor line clipping (#4313)" begin
    fig, ax, p = contour(rand(20, 20))
    xlims!(ax, 0, 10)
    Makie.colorbuffer(fig; backend = CairoMakie)
end

@testset "ComputeGraph Sanity Checks" begin
    # This is supposed to catch changes in ComputePipeline causing nodes to
    # be skipped or become duplicated. This will also trigger if plot attributes
    # are modified in which case the numbers should just be updated
    f, a, p = scatter(rand(10))
    colorbuffer(f)
    @test length(p.attributes.inputs) == 44
    @test length(p.attributes.outputs) == 88
end

excludes = Set(
    [
        "Line GIF",
        "Streamplot animation",
        "Axis + Surface",
        "Streamplot 3D",
        "Meshscatter Function",
        "Record Video",
        # "mesh textured and loaded", # bad texture resolution on mesh
        "Comparing contours, image, surfaces and heatmaps",
        "Animated surface and wireframe",
        "surface + contour3d",
        "Orthographic Camera", # This renders blank, why?
        "3D Contour with 2D contour slices",
        "Surface with image",
        "FEM poly and mesh", # different color due to bad colormap resolution on mesh
        "Image on Surface Sphere", # bad texture resolution
        "Arrows 3D",
        "Connected Sphere",
        # markers too big, close otherwise, needs to be assimilated with glmakie
        "Depth Shift",
        "Order Independent Transparency",
        "scatter with glow", # some are missing
        "Textured meshscatter", # not yet implemented
        "Voxel - texture mapping", # textures not implemented
        "Voxel uvs", # textures not implemented
        "picking", # Not implemented
        "MetaMesh (Sponza)", # makes little sense without per pixel depth order
        "Mesh with 3d volume texture", # Not implemented yet
        "Volume absorption",
        "DataInspector", "DataInspector 2", # No DataInspector without pick/interactivity
    ]
)

functions = [:volume, :volume!, :uv_mesh]

@testset "refimages" begin
    CairoMakie.activate!(type = "png", px_per_unit = 1)
    ReferenceTests.mark_broken_tests(excludes, functions = functions)
    recorded_files, recording_dir = @include_reference_tests CairoMakie "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir, "CairoMakie")
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
        save(filename, Figure(), pdf_version = nothing)
        @test startswith(magic_number(filename), "%PDF-")
    finally
        rm(filename)
    end

    for version in ["1.4", "1.5", "1.6", "1.7"]
        try
            save(filename, Figure(), pdf_version = version)
            @test magic_number(filename) == "%PDF-$version"
        finally
            rm(filename)
        end
    end

    @test_throws ArgumentError save(filename, Figure(), pdf_version = "foo")
end

@testset "Tick Events" begin
    f, a, p = scatter(rand(10))
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
            @test tick.count == i - 1
            @test tick.time ≈ dt * (i - 1)
            @test tick.delta_time ≈ dt
        end
    finally
        rm(filename)
    end

    # test destruction of tick overwrite
    f, a, p = scatter(rand(10))
    let
        io = VideoStream(f)
        @test events(f).tick[] == Makie.Tick(Makie.OneTimeRenderTick, 0, 0.0, 1.0 / io.options.framerate)
        nothing
    end
    tick = Makie.Tick(Makie.UnknownTickState, 1, 1.0, 1.0)
    events(f).tick[] = tick
    @test events(f).tick[] == tick
end

@testset "line projection" begin
    # Check #4627
    f = Figure(size = (600, 450))
    a, p = stephist(f[1, 1], 1:10, bins = [0, 5, 10], axis = (; limits = (0 .. 10, nothing)))
    Makie.update_state_before_display!(f)
    colorbuffer(f) # trigger add_computations! for CairoMakie
    lp = p.plots[1].plots[1]
    ps = lp.clipped_points[]
    # Points 1, 2, 5, 6 are on the clipping boundary, 7 is a duplicate of 6.
    # The output may drop 1, 6, 7 and adjust 2, 5 if these points are recognized
    # as outside. The adjustment of 2, 5 should be negligible.
    necessary_points = Vec{2, Float32}[[0.0, 89.77272], [275.5, 89.77272], [275.5, 17.95454], [551.0, 17.95454]]
    @test length(ps) >= 4
    @test all(ref -> findfirst(p -> isapprox(p, ref, atol = 1.0e-4), ps) !== nothing, necessary_points)

    ls_points = lp.positions[][[1, 2, 2, 3, 3, 4, 4, 5, 5, 6]]
    ls = linesegments!(a, ls_points, xautolimits = false, yautolimits = false)
    colorbuffer(f)
    ps = ls.clipped_points[]
    @test length(ps) >= 6 # at least 6 points: [2,3,3,4,4,5]
    @test all(ref -> findfirst(p -> isapprox(p, ref, atol = 1.0e-4), ps) !== nothing, necessary_points)

    # Check that `reinterpret`ed arrays of points are handled correctly
    # ref. https://github.com/MakieOrg/Makie.jl/issues/4661

    data = reinterpret(Point2f, rand(Point2f, 10) .=> rand(Point2f, 10))

    f, a, p = lines(data)
    Makie.update_state_before_display!(f)
    colorbuffer(f)
    ps = @test_nowarn p.clipped_points[]
    @test length(ps) == length(data) # this should never clip!
end

@testset "issue 4970 (invalid io use during finalization)" begin
    @testset "$mime" for mime in CairoMakie.SUPPORTED_MIMES
        @test_nowarn begin
            sprint(io -> show(io, mime, Scene()))
            GC.gc()
        end
    end
end
