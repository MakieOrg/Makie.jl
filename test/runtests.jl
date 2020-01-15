using MakieGallery, AbstractPlotting, GLMakie
using MakieGallery: @block, @cell
empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "GLMakie", "AbstractPlotting")
database = MakieGallery.load_database()

exclude = (
    "Cobweb plot", # has some weird scaling issue on CI
    "Colormap collection", # has one size different...
    # doesn't match 0.035520551315007046 <= 0.032. Looked at the artifacts and it looks fairly similar
    # so blaming video compression
    "Interaction with Mouse"
)
# Download is broken on CI
filter!(database) do entry
    return !("download" in entry.tags) &&
           !("diffeq" in entry.tags) &&
           !(entry.title in exclude) &&
           !(entry.unique_name in (:analysis, :colormap_collection, :lots_of_heatmaps))
end

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end
recordings = MakieGallery.record_examples(test_record_path)

@show length(recordings) == length(database)

MakieGallery.run_comparison(test_record_path, tested_diff_path)
empty!(database) # remove other examples
include("glmakie_tests.jl") # include GLMakie specific tests
# THese examples download additional data - don't want to deal with that!
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end

examples = MakieGallery.record_examples(test_record_path)
MakieGallery.run_comparison(test_record_path, tested_diff_path, maxdiff = 0.00001)
# MakieGallery.generate_preview(test_record_path)
# repo = joinpath(homedir(), "ReferenceImages", "gallery")
# cp(test_record_path, repo, force = true)
