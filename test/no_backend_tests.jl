database = MakieGallery.load_test_database()

@test AbstractPlotting.current_backend[] isa Missing # should we change this, so e.g. CairoMakie works?

@info "Starting minimal software tests"

filter!(database) do example
    !("record" in example.tags)
end

@testset "Gallery short tests" begin
    # iterate over database
    @testset "$(database[i].title) (#$i)" for i in 1:length(database)

        printstyled("Running "; bold = true, color = :blue)
        print(database[i].title * "\n(index $i)\n")

        # evaluate the entry
        try
            MakieGallery.eval_example(database[i])
            @test true
        catch e
            # THis is ok, since we try to record something, which we can't
            # without backend
            if e isa LoadError && e.error isa MethodError && (
                    e.error.f == AbstractPlotting.backend_display ||
                    e.error.f == AbstractPlotting.format2mime
                )
                @test true
            else
                @test rethrow(e)
            end
        end
        @debug AbstractPlotting.current_backend[] isa Missing
   end
end
