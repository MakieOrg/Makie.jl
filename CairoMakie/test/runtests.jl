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

using ReferenceTests
using ReferenceTests: database_filtered

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
    "Depth Shift",
    "Order Independent Transparency",
    "heatmap transparent colormap"
])

functions = [:volume, :volume!, :uv_mesh]
database = database_filtered(excludes, functions=functions)

recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
@time ReferenceTests.run_reference_tests(database, recorded)
