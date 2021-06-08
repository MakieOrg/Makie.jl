using ReferenceTests
using ReferenceTests: @cell

using CairoMakie
CairoMakie.activate!()
recorded = joinpath(@__DIR__, "cairo_images")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(recording_dir=recorded)
# ReferenceTests.reference_tests(recorded)

# using WGLMakie
# WGLMakie.activate!()
# recorded = joinpath(@__DIR__, "wgl_images")
# rm(recorded; force=true, recursive=true); mkdir(recorded)
# ReferenceTests.record_tests(recording_dir=recorded)
# ReferenceTests.reference_tests(recorded)

using GLMakie
GLMakie.activate!()
recorded = joinpath(@__DIR__, "gl_images")
rm(recorded; force=true, recursive=true); mkdir(recorded)
ReferenceTests.record_tests(recording_dir=recorded)
# ReferenceTests.reference_tests(ecorded)

# needs GITHUB_TOKEN to be set:
# ReferenceTests.upload_reference_images()
# Needs a backend to actually have something recoreded:
# ReferenceTests.reference_tests(recorded)
