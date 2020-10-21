using Pkg
using GLMakie, Test
using GLMakie.AbstractPlotting
path = joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests")
Pkg.develop(path=path)

using ReferenceTests
files, recorded = ReferenceTests.record_tests()
# needs GITHUB_TOKEN to be defined
# ReferenceTests.upload_reference_images()
ReferenceTests.reference_tests(recorded)
