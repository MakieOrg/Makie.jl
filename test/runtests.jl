using Pkg
using GLMakie, Test
using GLMakie.FileIO
using ImageMagick
# ImageIO seems broken on 1.6 ... and there doesn't
# seem to be a clean way anymore to force not to use a loader library?
filter!(x-> x !== :ImageIO, FileIO.sym2saver[:PNG])
filter!(x-> x !== :ImageIO, FileIO.sym2loader[:PNG])

path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))

using ReferenceTests
recorded = joinpath(@__DIR__, "recorded")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(recording_dir=recorded)
ReferenceTests.reference_tests(recorded)

# needs GITHUB_TOKEN to be defined
# ReferenceTests.upload_reference_images()
# Run the below, to generate a html to view all differences:
# recorded, ref_images, scores = ReferenceTests.reference_tests(recorded)
# ReferenceTests.generate_test_summary("preview.html", recorded, ref_images, scores)
