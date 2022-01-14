database = MakieGallery.load_database(["short_tests.jl"]);

filter!(database) do example
    !("3d" ∈ example.tags)
end

format_save_path = joinpath(@__DIR__, "test_formats")
isdir(format_save_path) && rm(format_save_path, recursive = true)
mkpath(format_save_path)
savepath(uid, fmt) = joinpath(format_save_path, "$uid.$fmt")

@testset "Saving formats" begin
    for example in database
        scene = MakieGallery.eval_example(example)
        for fmt in ("png", "pdf", "svg")
            @test try
                save(savepath(example.title, fmt), scene)
                true
            catch e
                @warn "Saving $(example.title) in format `$fmt` failed!" exception=(e, Base.catch_backtrace())
                false
            end
        end
    end
end
