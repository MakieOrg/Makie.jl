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

@testset "VideoStream & screen options" begin
    N = 3
    points = Observable(Point2f[])
    f, ax, pl = scatter(points, axis=(type=Axis, aspect=DataAspect(), limits=(0.4, N + 0.6, 0.4, N + 0.6),), figure=(resolution=(600, 800),))
    vio = Makie.VideoStream(f; format="mp4", px_per_unit=2.0, backend=CairoMakie)
    @test vio.screen isa CairoMakie.Screen{CairoMakie.IMAGE}
    @test size(vio.screen) == size(f.scene) .* 2
    @test vio.screen.device_scaling_factor == 2.0

    Makie.recordframe!(vio)
    save("test.mp4", vio)
    @test isfile("test.mp4") # Make sure no error etc
    rm("test.mp4")
end
