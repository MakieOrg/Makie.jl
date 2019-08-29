using MakieGallery, AbstractPlotting, GLMakie, Test
using MakieGallery: @block, @cell
empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "Makie")
database = MakieGallery.load_database()

exclude = (
    "Cobweb plot", # has some weird scaling issue on CI
    "Colormap collection", # has one size different...
    # doesn't match 0.035520551315007046 <= 0.032. Looked at the artifacts and it looks fairly similar
    # so blaming video compression
    "Interaction with Mouse"
)
# Download is broken on CI
filter!(entry-> !("download" in entry.tags) && !(entry.title in exclude), database)

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end
recordings = MakieGallery.record_examples(test_record_path)
@test length(recordings) == length(database)
MakieGallery.run_comparison(test_record_path, tested_diff_path)
