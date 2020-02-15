using MakieGallery, AbstractPlotting, GLMakie, Test

empty!(MakieGallery.plotting_backends)
push!(MakieGallery.plotting_backends, "Makie")
database = MakieGallery.load_database([
                    "tutorials.jl",
                    "attributes.jl",
                    "short_tests.jl"
                    ])

test_record_path = joinpath(@__DIR__, "test_recordings")
recordings = MakieGallery.record_examples(test_record_path)
@assert length(recordings) == length(database)
@info "Precompile script has completed execution."
