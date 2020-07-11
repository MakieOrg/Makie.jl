example_dir = joinpath(@__DIR__, "reference_image_tests")

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")

isdir(tested_diff_path) && rm(tested_diff_path, force = true, recursive = true)
mkpath(tested_diff_path)

isdir(test_record_path) && rm(test_record_path, force = true, recursive = true)
mkpath(test_record_path)
database = MakieGallery.load_database(joinpath.(example_dir, readdir(example_dir)))

examples = MakieGallery.record_examples(test_record_path);

@test length(examples) == length(database)
#
# # Download test images manually, so we can specify the folder
# # TODO, refactor makiegallery
path = MakieGallery.download_reference("v0.6.3")

MakieGallery.run_comparison(test_record_path, tested_diff_path, joinpath(dirname(path), "test_recordings"))
