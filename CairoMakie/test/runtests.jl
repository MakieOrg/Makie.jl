using Test, Pkg
using CairoMakie

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

path = normpath(joinpath(dirname(pathof(Makie)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path=path))
using ReferenceTests
using ReferenceTests: nice_title
CairoMakie.activate!(type = "png")

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
    "Stars",
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
])

database = ReferenceTests.load_database()

filter!(database) do (name, entry)
    !(entry.title in excludes) &&
    !(:volume in entry.used_functions) &&
    !(:volume! in entry.used_functions) &&
    !(:uv_mesh in entry.used_functions) &&
    nice_title(entry) !== "short_tests_90" &&
    nice_title(entry) !== "short_tests_111" &&
    nice_title(entry) !== "short_tests_35" &&
    nice_title(entry) !== "short_tests_13" &&
    nice_title(entry) !== "short_tests_3"
end

recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(database; recording_dir=recorded)
ReferenceTests.reference_tests(recorded)
