using MakieGallery, AbstractPlotting, GLMakie, Test

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
isdir(tested_diff_path) && rm(tested_diff_path, force = true, recursive = true)
mkpath(tested_diff_path)
isdir(test_record_path) && rm(test_record_path, force = true, recursive = true)
mkpath(test_record_path)

abstractplotting_test_dir = joinpath(dirname(pathof(AbstractPlotting)), "..", "test", "reference_image_tests")
abstractplotting_tests = joinpath.(abstractplotting_test_dir, readdir(abstractplotting_test_dir))
# Add GLMakie specific tests
push!(abstractplotting_tests, joinpath(@__DIR__, "glmakie_tests.jl"))
database = MakieGallery.load_database(abstractplotting_tests)

examples = MakieGallery.record_examples(test_record_path)
@test length(examples) == length(database)
MakieGallery.run_comparison(test_record_path, tested_diff_path)
