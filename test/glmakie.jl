using GLMakie
GLMakie.activate!()
recorded = joinpath(@__DIR__, "gl_images")
rm(recorded; force=true, recursive=true); mkdir(recorded)
database = ReferenceTests.load_database()
ReferenceTests.record_tests(database, recording_dir=recorded)
ReferenceTests.reference_tests(recorded)
ReferenceTests.generate_test_summary("preview2.html", recorded)

# needs GITHUB_TOKEN to be set:
# ReferenceTests.upload_reference_images()
# Needs a backend to actually have something recoreded:
# ReferenceTests.reference_tests(recorded)

# Run the below, to generate a html to view all differences:
# recorded, ref_images, scores = ReferenceTests.reference_tests(recorded)
# ReferenceTests.generate_test_summary("preview.html", recorded, ref_images, scores)
# ReferenceTests.generate_test_summary("preview.html", recorded)

# needs GITHUB_TOKEN to be defined
# First look at the generated refimages, to make sure they look ok:
# ReferenceTests.generate_test_summary("index_gl.html", recorded_glmakie)
# Then you can upload them to the latest major release tag with:
# ReferenceTests.upload_reference_images(recorded)

# And do the same for the backend specific tests:
# ReferenceTests.generate_test_summary("index.html", recorded_glmakie)
# ReferenceTests.upload_reference_images(recorded_glmakie; name="glmakie_refimages")
