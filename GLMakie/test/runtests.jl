using GLMakie, Test
using FileIO
using GeometryBasics
using GeometryBasics: origin
using Makie
using ImageMagick
using Pkg

reference_tests_dir = normpath(joinpath(dirname(pathof(Makie)), "..", "ReferenceTests"))
Pkg.develop(PackageSpec(path = reference_tests_dir))
using ReferenceTests

GLMakie.activate!()
GLMakie.set_window_config!(;
    framerate = 1.0,
    pause_rendering = true
)

# run the unit test suite
include("unit_tests.jl")

@testset "refimages" begin
    ReferenceTests.mark_broken_tests()
    recorded_files, recording_dir = @include_reference_tests "refimages.jl"
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(missing_images, scores; threshold = 0.032)
end

@testset "glmakie_refimages" begin
    recorded_files, recording_dir = @include_reference_tests joinpath(@__DIR__, "glmakie_refimages.jl")
    missing_images, scores = ReferenceTests.record_comparison(recording_dir)
    ReferenceTests.test_comparison(missing_images, scores; threshold = 0.01)
end
