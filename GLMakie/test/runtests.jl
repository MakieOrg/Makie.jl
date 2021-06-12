using GLMakie, Test
using GLMakie.FileIO
using GLMakie.Makie
using GLMakie.GeometryBasics
using GLMakie.GeometryBasics: origin
using ImageMagick
# run the unit test suite
include("unit_tests.jl")

using ReferenceTests
using ReferenceTests: @cell

# Run the Makie reference image testsuite
recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(recording_dir=recorded)
ReferenceTests.reference_tests(recorded)
# Run the below, to generate a html to view all differences:
# recorded, ref_images, scores = ReferenceTests.reference_tests(recorded)
# ReferenceTests.generate_test_summary("preview.html", recorded, ref_images, scores)
# ReferenceTests.generate_test_summary("preview.html", recorded)

# Run the GLMakie specific backend reference tests
empty!(ReferenceTests.DATABASE)
include("glmakie_tests.jl")
recorded_glmakie = joinpath(@__DIR__, "recorded_glmakie")
rm(recorded_glmakie; force=true, recursive=true); mkdir(recorded_glmakie)
ReferenceTests.record_tests(ReferenceTests.DATABASE, recording_dir=recorded_glmakie)
ref_images = ReferenceTests.download_refimages(; name="glmakie_refimages")
ReferenceTests.reference_tests(recorded_glmakie; ref_images=ref_images, difference=0.01)
# needs GITHUB_TOKEN to be defined
# First look at the generated refimages, to make sure they look ok:
# ReferenceTests.generate_test_summary("index_gl.html", recorded_glmakie)
# Then you can upload them to the latest major release tag with:
# ReferenceTests.upload_reference_images(recorded)

# And do the same for the backend specific tests:
# ReferenceTests.generate_test_summary("index.html", recorded_glmakie)
# ReferenceTests.upload_reference_images(recorded_glmakie; name="glmakie_refimages")
