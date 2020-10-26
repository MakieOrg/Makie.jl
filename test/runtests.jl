using Pkg
using GLMakie, Test
path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path=path))
using ReferenceTests
files, recorded = ReferenceTests.record_tests()
ReferenceTests.reference_tests(recorded)
# needs GITHUB_TOKEN to be defined
# ReferenceTests.upload_reference_images()
