using Pkg
using GLMakie, Test
using GLMakie.FileIO
using GLMakie.AbstractPlotting
using GLMakie.GeometryBasics
using GLMakie.GeometryBasics: origin
using ImageMagick
# ImageIO seems broken on 1.6 ... and there doesn't
# seem to be a clean way anymore to force not to use a loader library?
filter!(x-> x !== :ImageIO, FileIO.sym2saver[:PNG])
filter!(x-> x !== :ImageIO, FileIO.sym2loader[:PNG])

# run the unit test suite
include("unit_tests.jl")

path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests
using ReferenceTests: @cell

# Run the AbstractPlotting reference image testsuite
recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(recording_dir=recorded)
ReferenceTests.reference_tests(recorded)

# Run the GLMakie specific backend reference tests
empty!(ReferenceTests.DATABASE)
include("glmakie_tests.jl")
recorded = joinpath(@__DIR__, "recorded_glmakie")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(ReferenceTests.DATABASE, recording_dir=recorded)
ref_images = ReferenceTests.download_refimages(; name="glmakie_refimages")
ReferenceTests.reference_tests(recorded; ref_images=ref_images, difference=0.01)

# needs GITHUB_TOKEN to be defined
# ReferenceTests.upload_reference_images()
# Run the below, to generate a html to view all differences:
# recorded, ref_images, scores = ReferenceTests.reference_tests(recorded)
# ReferenceTests.generate_test_summary("preview.html", recorded, ref_images, scores)
# ReferenceTests.upload_reference_images(recorded; name="glmakie_refimages")
