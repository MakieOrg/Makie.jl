using Pkg
using GLMakie, Test
path = normpath(joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "ReferenceTests"))
Pkg.develop(PackageSpec(path = path))
using ReferenceTests
files, recorded = ReferenceTests.record_tests()
recorded = ReferenceTests.basedir("recorded")
ReferenceTests.reference_tests(recorded)
# needs GITHUB_TOKEN to be defined
# ReferenceTests.upload_reference_images()
# Run the below, to generate a html to view all differences:
# recorded, ref_images, scores = ReferenceTests.reference_tests(recorded)
# ReferenceTests.generate_test_summary("preview.html", recorded, ref_images, scores)
