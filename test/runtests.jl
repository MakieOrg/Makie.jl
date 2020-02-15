using AbstractPlotting
using MakieGallery
using Test
using GLMakie

# Download reference images from master
MakieGallery.current_ref_version[] = "master"

const MINIMAL = get(ENV, "ABSTRACTPLOTTING_MINIMAL", "false")

# does this machine have a OPENGL?
const OPENGL = GLMakie.WORKING_OPENGL
OPENGL || (MINIMAL = "true")

@show OPENGL MINIMAL

OPENGL && begin @info "OpenGL detected"; using GLMakie end
OPENGL || @warn "No OpenGL detected!  Software tests only."

@info "Running conversion tests"
include("conversions.jl")

@info "Running quaternion tests"
include("quaternions.jl")

@info "Running projection tests"
include("projection_math.jl")

@info "Running shorthand tests"
include("shorthands.jl")

@info "Running basic Scene test"
@testset "basic functionality" begin
    scene = scatter(rand(4))
    @test scene[Axis].ticks.title_gap[] == 3
    scene[Axis].ticks.title_gap = 4
    @test scene[Axis].ticks.title_gap[] == 4
    @test scene[Axis].tickmarks.length[] == (3, 3)
end


if MINIMAL == "false"

    @info "Minimal was false; running full tests!"

    # Load all entries in the database

    database = MakieGallery.load_database()

    ## Exceptions are made on basis of title and not index,
    # because index may change as MakieGallery changes.

    # we found which ones are the slowest, and kicked those out!
    slow_examples = [
        "Animated time series",
        "Animation",
        "Lots of Heatmaps",
        "Chess Game",
        "Line changing colour",
        "Line changing colour with Observables",
        "Colormap collection",
        "Record Video",
        "Animated surface and wireframe",
        "Moire",
        "Line GIF",
        "Electrostatic repulsion",
        "pong",
        "pulsing marker",
        "Travelling wave",
        "Axis theming",
        "Legend",
        "Color Legend",
        "DifferentialEquations path animation",
        "Interactive Differential Equation",
        "Spacecraft from a galaxy far, far away",
        "WorldClim visualization",
        "Image on Geometry (Moon)",
        "Image on Geometry (Earth)",
        "Interaction with mouse",
        "Air Particulates",
    ]

    # diffeq is also slow, as are analysis heatmaps.  Colormap collection likes to
    # fail a lot.
    filter!(MakieGallery.database) do entry
        !("diffeq" in entry.tags) &&
        !(entry.unique_name in (:analysis, :colormap_collection, :lots_of_heatmaps)) &&
        !(entry.title in slow_examples)
     end

    # Download is broken on CI
    if get(ENV, "CI", "false") == "true"
        printstyled("CI detected\n"; bold = true, color = :yellow)
        println("Filtering out examples which download")
        filter!(entry-> !("download" in entry.tags), database)
    end

else
    # Load only short tests
    database = MakieGallery.load_tests()
end

# one last time to make sure
filter!(database) do entry
    !("diffeq" in entry.tags) &&
    !(entry.unique_name in (:analysis, :colormap_collection, :lots_of_heatmaps))
 end

# Here, we specialize on two cases.
# If there is no opengl, then we have to run software-only tests, i.e., eval the
# examples and test that nothing errors.
# If there is opengl, then we use MakieGallery's test protocol.

if !OPENGL # run software only tests...
    # Make sure we don't include Makie in the usings
    empty!(MakieGallery.plotting_backends)
    push!(MakieGallery.plotting_backends, "AbstractPlotting")

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

else # full MakieGallery comparisons here
    @info("Running full tests - artifacts will be stored!")

    tested_diff_path = joinpath(@__DIR__, "tested_different")
    test_record_path = joinpath(@__DIR__, "test_recordings")

    rm(tested_diff_path, force = true, recursive = true)
    mkpath(tested_diff_path)

    rm(test_record_path, force = true, recursive = true)
    mkpath(test_record_path)

    examples = MakieGallery.record_examples(test_record_path)

    @test length(examples) == length(database)

    printstyled("Running ", color = :green, bold = true)
    println("visual regression tests")
end
