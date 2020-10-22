Pkg.develop(path="./ReferenceTests")
using ReferenceTests

ReferenceTests.run_tests()
# needs GITHUB_TOKEN to be set:
# ReferenceTests.upload_reference_images()
# Needs a backend to actually have something recoreded:
# ReferenceTests.reference_tests(recorded)
