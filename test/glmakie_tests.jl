database = MakieGallery.load_test_database()

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")

isdir(tested_diff_path) && rm(tested_diff_path, force = true, recursive = true)
mkpath(tested_diff_path)

isdir(test_record_path) && rm(test_record_path, force = true, recursive = true)
mkpath(test_record_path)

examples = MakieGallery.record_examples(test_record_path)

@test length(examples) == length(database)

printstyled("Running ", color = :green, bold = true)
println("visual regression tests")

MakieGallery.run_comparison(test_record_path, tested_diff_path)
