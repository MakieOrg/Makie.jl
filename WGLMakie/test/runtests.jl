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
    "Record Video",
    "fast pixel marker"
])

database = database_filtered(excludes)

basefolder = joinpath(@__DIR__, "reference_test_output")
rm(basefolder; force=true, recursive=true)
mkdir(basefolder)

refimage_set = "refimages"
tests_root_folder = joinpath(basefolder, refimage_set)
mkdir(tests_root_folder)

tests_record_folder = joinpath(tests_root_folder, "recorded")
mkdir(tests_record_folder)

ReferenceTests.record_tests(database, recording_dir = tests_record_folder)

tests_refimages_download_folder = ReferenceTests.download_refimages(; name=refimage_set)
tests_refimages_folder = joinpath(tests_root_folder, "reference")
cp(tests_refimages_download_folder, tests_refimages_folder)

missing_refimages, scores = ReferenceTests.record_comparison(tests_root_folder)
ReferenceTests.test_comparison(missing_refimages, scores; threshold = 0.032)
