using MakieGallery, AbstractPlotting, GLMakie, Test

empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "Makie")
database = MakieGallery.load_database([
                    "tutorials.jl",
                    "attributes.jl",
                    "short_tests.jl"
                    ])

tested_diff_path = joinpath(@__DIR__, "tested_different")
test_record_path = joinpath(@__DIR__, "test_recordings")
for path in (tested_diff_path, test_record_path)
    rm(path, force = true, recursive = true)
    mkpath(path)
end
recordings = MakieGallery.record_examples(test_record_path)
