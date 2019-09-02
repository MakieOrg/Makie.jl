using AbstractPlotting
using MakieGallery
using Test

const MINIMAL = get(ENV, "ABSTRACTPLOTTING_MINIMAL", "false")

# does this machine have a OPENGL?
const OPENGL = haskey(ENV, "OPENGL") || haskey(ENV, "GITLAB_CI") || try success(pipeline(`glxinfo`, `grep version`)) catch; false end # if it's Gitlab, it must be JuliaGPU
OPENGL || (MINIMAL = "true")

@show OPENGL MINIMAL

OPENGL && begin @info "OpenGL detected"; using GLMakie end
OPENGL || @warn "No OpenGL detected!  Software tests only."

include("conversions.jl")
include("quaternions.jl")
include("projection_math.jl")

@testset "basic functionality" begin
    scene = scatter(rand(4))
    @test scene[Axis].ticks.title_gap[] == 3
    scene[Axis].ticks.title_gap = 4
    @test scene[Axis].ticks.title_gap[] == 4
end


if MINIMAL == "false"

    # Load all entries in the database

    database = MakieGallery.load_database()

    ## Exceptions are made on basis of title and not index,
    # because index may change as MakieGallery changes.

    # All these require FFMpeg and need to save,
    # and are therefore ignored
    ffmpeg_exs  = [
        "Animation", "Lots of Heatmaps","Animated Scatter",
        "Chess Game", "Record Video",  "Animated surface and wireframe",
        "Moire", "pong", "pulsing marker", "Travelling wave",
        "Type recipe for molecule simulation", "Cobweb plot"
    ]

    # All these require GLMakie and so are ignored
    glmakie_exs = [
        "Textured Mesh", "Load Mesh", "Wireframe of a Mesh",
        "FEM mesh 3D", "Normals of a Cat", "Line GIF"
    ]

    # Requires GDAL (a GL package) so ignored
    gdal_exs = [
        "WorldClim visualization"
    ]

    # Requires GLMakie and ModernGL, so ignored
    moderngl_exs = [
        "Explicit frame rendering"
    ]

    # use Stepper plots, which save, so ignored
    save_exs = [
        "Axis theming", "Labels", "Color Legend",
        "Stepper demo"
    ]

    # hopefullly fixed by next tag of MakieGallery (already in AbstractPlotting
    color_exs = ["colormaps"]

    # curl fails with this for some reason, so it has been ignored.
    curl_exs = ["Earth & Ships"]
    stepper_exclude = ["Tutorial plot transformation", "Legend"]
    if OPENGL
        excluded_examples = Set()
    else
        # combine all exceptions into a single Set
        excluded_examples = excluded_examples = union(
            ffmpeg_exs, glmakie_exs, gdal_exs, moderngl_exs,
            save_exs, color_exs, curl_exs, stepper_exclude
        )
    end

else
    # Load only short tests
    database = MakieGallery.load_tests()
    excluded_examples = Set(["Comparing contours, image, surfaces and heatmaps"])
end

if !OPENGL # run software only tests...
    # Make sure we don't include Makie in the usings
    empty!(MakieGallery.plotting_backends)
    push!(MakieGallery.plotting_backends, "AbstractPlotting")
    @test AbstractPlotting.current_backend[] isa Missing
    @info "Starting minimal software tests"
    filter!(database) do example
        !(example.title in excluded_examples) &&
        !("record" in example.tags)
    end
    @testset "Gallery short tests" begin
        # iterate over database
        @testset "$(database[i].title) (#$i)" for i in 1:length(database)
            @debug("Running " * database[i].title * "\n(index $i)\n")
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
            @assert AbstractPlotting.current_backend[] isa Missing
       end
    end
else # full MakieGallery comparisons here
    using GLMakie
    @info("Running full tests - artifacts will be stored!")
    for exc in excluded_examples
        printstyled("Excluded ", color = :yellow, bold = true)
        println(exc)
    end
    filter!(entry -> !(entry.title in excluded_examples), database)
    tested_diff_path = joinpath(@__DIR__, "tested_different")
    test_record_path = joinpath(@__DIR__, "test_recordings")
    rm(tested_diff_path, force = true, recursive = true)
    mkpath(tested_diff_path)
    rm(test_record_path, force = true, recursive = true)
    mkpath(test_record_path)
    examples = MakieGallery.record_examples(test_record_path)
    MakieGallery.run_comparison(test_record_path, tested_diff_path)
end
