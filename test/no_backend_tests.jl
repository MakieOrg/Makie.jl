# Assure, that we're testing without backend!
@test AbstractPlotting.current_backend[] isa Missing

@info "Starting minimal software tests"

example_dir = joinpath(@__DIR__, "reference_image_tests")

database = MakieGallery.load_database(joinpath.(example_dir, readdir(example_dir)))

filter!(database) do example
    !("record" in example.tags) &&
    (match(r"record\(.*?\) do", example.source) === nothing) &&
    (match(r"Stepper((.*), @replace_with_a_path)", example.source) === nothing)
end

@testset "Gallery short tests" begin
    # iterate over database
    @testset "$(database[i].title) (#$i)" for i in 1:length(database)
        printstyled("Running "; bold = true, color = :blue)
        print(database[i].title * "\n(index $i)\n")
        # evaluate the entry
        MakieGallery.eval_example(database[i])
        @test true
        @test AbstractPlotting.current_backend[] isa Missing
   end
end
