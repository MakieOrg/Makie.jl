using Test, Pkg
using CairoMakie

path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path=path))
using ReferenceTests
using ReferenceTests: unique_name
CairoMakie.activate!(type = "png")

excludes = Set((
    "examples3d:65-Colored Mesh",
    "examples3d:466-Line GIF",
    "short_tests:115",
    "examples2d:205-Streamplot animation",
    "examples2d:220-Line changing colour",
    "examples3d:272-Axis + Surface",
    "examples3d:518-Streamplot 3D",
    "examples3d:134-Meshscatter Function",
    "examples2d:330-Hollow pie chart",
    "examples3d:150-Record Video",
    "examples3d:12-Image on Geometry (Earth)",
    "layouting:16-Comparing contours, image, surfaces and heatmaps",
    "examples3d:56-Textured Mesh",
    "examples2d:321-Simple pie chart",
    "examples3d:393-Animated surface and wireframe",
    "examples2d:339-Open pie chart",
    "examples3d:376-image scatter",
    "examples3d:244-surface + contour3d",
    "short_tests:111",
    "examples3d:18-Orthographic Camera",
    "documentation:23-Legend",
    "attributes:43-rotation",
    "examples3d:168-3D Contour with 2D contour slices",
    "examples3d:113-Surface with image",
    "examples2d:4-Test heatmap + image overlap",
    "examples2d:164-Text Annotation",
    "step-2",
    "examples2d:40-FEM polygon 2D.png",
    "examples2d:174-Text rotation",
    "examples3d:211-Image on Surface Sphere",
    "examples2d:66-FEM mesh 2D",
    "examples2d:145-Hbox",
    "examples3d:427-Stars",
    "examples2d:108-Subscenes",
    "examples3d:196-Arrows 3D",
    "layouting:1-Layouting",
    # sigh this is actually super close,
    # but doesn't interpolate the values inside the
    # triangles, so looks pretty different
    "examples2d:40-FEM polygon 2D"
))

database = ReferenceTests.load_database()

filter!(database) do (name, entry)
    !(unique_name(entry) in excludes) && 
    !(:volume in entry.used_functions) &&
    !(:volume! in entry.used_functions)
end

files, recorded = ReferenceTests.record_tests(database)

ReferenceTests.reference_tests(recorded)
