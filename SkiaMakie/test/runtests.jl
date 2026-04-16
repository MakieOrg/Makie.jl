ENV["ENABLE_COMPUTE_CHECKS"] = "true"

using Test
using SkiaMakie
using Makie.FileIO
using ReferenceTests

# Same excludes as CairoMakie — these tests are known to not work on 2D raster backends
excludes = Set([
    "Streamplot animation",
    "Axis + Surface",
    "Streamplot 3D",
    "Meshscatter Function",
    "Record Video",
    "Comparing contours, image, surfaces and heatmaps",
    "Animated surface and wireframe",
    "surface + contour3d",
    "Orthographic Camera",
    "3D Contour with 2D contour slices",
    "Surface with image",
    "FEM poly and mesh",
    "Image on Surface Sphere",
    "Arrows 3D",
    "Connected Sphere",
    "Depth Shift",
    "Order Independent Transparency",
    "scatter with glow",
    "Textured meshscatter",
    "Voxel - texture mapping",
    "Voxel uvs",
    "picking",
    "MetaMesh (Sponza)",
    "Mesh with 3d volume texture",
    "Volume absorption",
    "DataInspector", "DataInspector 2",
])

functions = [:volume, :volume!, :uv_mesh]

@testset "refimages" begin
    SkiaMakie.activate!(type = "png", px_per_unit = 1)
    ReferenceTests.mark_broken_tests(excludes, functions = functions)
    recorded_files, recording_dir = @include_reference_tests SkiaMakie "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir, "SkiaMakie")
    # Use a higher threshold than CairoMakie (0.05) since we expect small AA differences
    ReferenceTests.test_comparison(scores; threshold = 0.1)
end
