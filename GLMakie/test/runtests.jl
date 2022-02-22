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

main_refimage_set = "refimages"
main_tests_root_folder = joinpath(basefolder, main_refimage_set)
mkdir(main_tests_root_folder)

main_tests_record_folder = joinpath(main_tests_root_folder, "recorded")
mkdir(main_tests_record_folder)

ReferenceTests.record_tests(ReferenceTests.load_database(), recording_dir = main_tests_record_folder)

main_tests_refimages_download_folder = ReferenceTests.download_refimages(; name=main_refimage_set)
main_tests_refimages_folder = joinpath(main_tests_root_folder, "reference")
cp(main_tests_refimages_download_folder, main_tests_refimages_folder)

missing_refimages_main, scores_main = ReferenceTests.record_comparison(main_tests_root_folder)



empty!(ReferenceTests.DATABASE)
include("glmakie_tests.jl")

glmakie_refimage_set = "glmakie_refimages"
glmakie_tests_root_folder = joinpath(basefolder, glmakie_refimage_set)
mkdir(glmakie_tests_root_folder)

glmakie_tests_record_folder = joinpath(glmakie_tests_root_folder, "recorded")
mkdir(glmakie_tests_record_folder)

ReferenceTests.record_tests(ReferenceTests.DATABASE, recording_dir = glmakie_tests_record_folder)

glmakie_tests_refimages_download_folder = ReferenceTests.download_refimages(; name=glmakie_refimage_set)
glmakie_tests_refimages_folder = joinpath(glmakie_tests_root_folder, "reference")
cp(glmakie_tests_refimages_download_folder, glmakie_tests_refimages_folder)

missing_refimages_glmakie, scores_glmakie = ReferenceTests.record_comparison(glmakie_tests_root_folder)

@testset "compare refimages" begin
    @testset "refimages" begin
        ReferenceTests.test_comparison(missing_refimages_main, scores_main; threshold = 0.032)
    end
    @testset "glmakie_refimages" begin
        ReferenceTests.test_comparison(missing_refimages_glmakie, scores_glmakie; threshold = 0.01)
    end
end

