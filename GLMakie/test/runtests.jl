using GLMakie, Test
using FileIO
using GeometryBasics
using GeometryBasics: origin
using Makie
using ImageMagick
using Pkg

Pkg.develop(PackageSpec(
    path = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
))

using ReferenceTests
using ReferenceTests: @cell

GLMakie.activate!()
GLMakie.set_window_config!(;
    framerate = 1.0,
    pause_rendering = true
)

# run the unit test suite
include("unit_tests.jl")

basefolder = joinpath(@__DIR__, "reference_test_output")
rm(basefolder; force=true, recursive=true)
mkdir(basefolder)

main_tests_root_folder = joinpath(basefolder, "main_tests")
mkdir(main_tests_root_folder)

main_tests_record_folder = joinpath(main_tests_root_folder, "recorded")
mkdir(main_tests_record_folder)

ReferenceTests.record_tests(ReferenceTests.load_database(), recording_dir = main_tests_record_folder)

main_tests_refimages_download_folder = ReferenceTests.download_refimages()
main_tests_refimages_folder = joinpath(main_tests_root_folder, "reference")
cp(main_tests_refimages_download_folder, main_tests_refimages_folder)

ReferenceTests.record_comparison(main_tests_root_folder)




empty!(ReferenceTests.DATABASE)
include("glmakie_tests.jl")

glmakie_tests_root_folder = joinpath(basefolder, "glmakie_tests")
mkdir(glmakie_tests_root_folder)

glmakie_tests_record_folder = joinpath(glmakie_tests_root_folder, "recorded")
mkdir(glmakie_tests_record_folder)

ReferenceTests.record_tests(ReferenceTests.DATABASE, recording_dir = glmakie_tests_record_folder)

glmakie_tests_refimages_download_folder = ReferenceTests.download_refimages(; name="glmakie_refimages")
glmakie_tests_refimages_folder = joinpath(glmakie_tests_root_folder, "reference")
cp(glmakie_tests_refimages_download_folder, glmakie_tests_refimages_folder)

ReferenceTests.record_comparison(glmakie_tests_root_folder)

# ReferenceTests.run_reference_tests(ReferenceTests.DATABASE, glmakie_tests_record_folder; ref_images=ref_images, difference=0.01)

# needs GITHUB_TOKEN to be defined
# First look at the generated refimages, to make sure they look ok:
# ReferenceTests.generate_test_summary("index_gl.html", glmakie_tests_record_folder)
# Then you can upload them to the latest major release tag with:
# ReferenceTests.upload_reference_images(main_tests_record_folder)

# And do the same for the backend specific tests:
# ReferenceTests.generate_test_summary("index.html", glmakie_tests_record_folder)
# ReferenceTests.upload_reference_images(glmakie_tests_record_folder; name="glmakie_refimages")
