using MakieGallery, AbstractPlotting, GLMakie, Test
using MakieGallery: @block, @cell

push!(MakieGallery.plotting_backends, "GLMakie")
database = MakieGallery.load_database()
tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end
recordings = MakieGallery.record_examples(test_record_path)
@test length(recordings) == length(database)
MakieGallery.run_comparison(test_record_path, tested_diff_path)

empty!(database) # remove other examples
include("glmakie_tests.jl") # include GLMakie specific tests
# THese examples download additional data - don't want to deal with that!
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end
examples = MakieGallery.record_examples(test_record_path)
MakieGallery.run_comparison(test_record_path, tested_diff_path, maxdiff = 0.0)
# MakieGallery.generate_preview(test_record_path)
# repo = joinpath(homedir(), "ReferenceImages", "gallery")
# cp(test_record_path, repo, force = true)
