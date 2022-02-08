using ElectronDisplay
ElectronDisplay.CONFIG.showable = showable
ElectronDisplay.CONFIG.single_window = true
ElectronDisplay.CONFIG.focus = false
using ImageMagick, FileIO
using WGLMakie, Makie, Test
using Pkg
path = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
WGLMakie.activate!()
using ReferenceTests
using ReferenceTests: database_filtered

excludes = Set([
    "Streamplot animation",
    "Transforming lines",
    "image scatter",
    "Line GIF",
    "surface + contour3d",
    # Hm weird, looks like some internal JSServe error missing an Observable:
    "Errorbars x y low high",
    "Rangebars x y low high",
    # These are a bit sad, since it's just missing interpolations
    "FEM mesh 2D",
    "FEM polygon 2D",
    # missing transparency & image
    "Wireframe of a Surface",
    "Image on Surface Sphere",
    "Surface with image",
    # Marker size seems wrong in some occasions:
    "Hbox",
    "UnicodeMarker",
    # Not sure, looks pretty similar to me! Maybe blend mode?
    "Test heatmap + image overlap",
    "Stars",
    "heatmaps & surface",
    "OldAxis + Surface",
    "Order Independent Transparency",
    "Record Video"
])

database = database_filtered(excludes)

recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
@time ReferenceTests.run_reference_tests(database, recorded; difference=0.032)
