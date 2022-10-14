using Test
using CairoMakie
using Pkg
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
    "heatmaps & surface"
])

functions = [:volume, :volume!, :uv_mesh]

@testset "refimages" begin
    CairoMakie.activate!(type = "png")
    ReferenceTests.mark_broken_tests(excludes, functions=functions)
    recorded_files, recording_dir = @include_reference_tests "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(scores; threshold = 0.032)
end
