Pkg.develop(Pkg.PackageSpec(path=joinpath(@__DIR__, "ReferenceTests")))

using ReferenceTests
using ReferenceTests: @cell

db = ReferenceTests.load_database()
ReferenceTests.record_tests(db)
# needs GITHUB_TOKEN to be set:
# ReferenceTests.upload_reference_images()
# Needs a backend to actually have something recoreded:
# ReferenceTests.reference_tests(recorded)
