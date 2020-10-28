using MakieGallery, Makie, Test

using MakieGallery: @block, @cell

@info "It is normal for the Makie window to not appear during tests"

database = MakieGallery.load_test_database()
tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
isdir(tested_diff_path) && rm(tested_diff_path, force = true, recursive = true)
mkpath(tested_diff_path)
isdir(test_record_path) && rm(test_record_path, force = true, recursive = true)
mkpath(test_record_path)
examples = MakieGallery.record_examples(test_record_path)
@test length(examples) == length(database)
MakieGallery.run_comparison(test_record_path, tested_diff_path)

empty!(database) # remove other examples
# These examples download additional data - don't want to deal with that!
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end

examples = MakieGallery.record_examples(test_record_path)
MakieGallery.run_comparison(test_record_path, tested_diff_path, maxdiff=0.00001)
