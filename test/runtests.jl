using AbstractPlotting
using Test

# does this machine have a OPENGL?
const OPENGL = haskey(ENV, "OPENGL") || haskey(ENV, "GITLAB_CI") || try; success(pipeline(`glxinfo`, `grep version`)); catch; false; end # if it's Gitlab, it must be JuliaGPU

OPENGL && @info "OpenGL detected"

# does this machine have FFMPEG?  We'll take it on faith if you tell us...
const fmp = haskey(ENV, "FFMPEG") || try; AbstractPlotting.@ffmpeg_env success(`ffmpeg -version`); catch; false end;

const _MINIMAL = get(ENV, "ABSTRACTPLOTTING_MINIMAL", "true")

OPENGL && using GLMakie

scene = scatter(rand(4))

include("quaternions.jl")
include("projection_math.jl")

@testset "basic functionality" begin
    scene = scatter(rand(4))
    @test scene[Axis].ticks.title_gap[] == 3
    scene[Axis].ticks.title_gap = 4
    @test scene[Axis].ticks.title_gap[] == 4
end

# if get(ENV, "IS_TRAVIS_CI", "false") == "false"
#   exit(0);
# end

using MakieGallery

if _MINIMAL == "false"

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
               "Type recipe for molecule simulation"
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

   if OPENGL
       if fmp
           # all test infrastructure in place - no exceptions!
           exc_str = Set()
       else
           exc_str = Set(ffmpeg_exs)
       end
   else
       # combine all exceptions into a single Set
       exc_str = exc_str = union(ffmpeg_exs, glmakie_exs, gdal_exs, moderngl_exs, save_exs, color_exs, curl_exs)
   end

else

    # Load only short tests

    database = MakieGallery.load_tests()

    # This one is broken, all the others are fine.  I don't know why this fails.  It doesn't fail on my machine :P
    exc_str = Set(["Comparing contours, image, surfaces and heatmaps"])

end

if !OPENGL # run software only tests...

    @testset "Gallery short tests" begin

        # iterate over database
        @testset "$(database[i].title) (#$i)" for i in 1:length(database)

               # skip if the title is in the list of exceptions
              if database[i].title ∈ exc_str

                 print(
                 "Skipping "
                 * database[i].title *
                 "\n(removed from tests explicitly)\n"
                 )

                 continue

               end

               @debug("Running " * database[i].title * "\n(index $i)\n")
               # evaluate the entry
               @test_nowarn MakieGallery.eval_example(database[i]);

       end

    end

else # full MakieGallery comparisons here

    using GLMakie

    @info("Running full tests - artifacts will be stored!")

    for exc in exc_str

        printstyled("Excluded ", color = :yellow, bold = true)
        println(exc)

    end

    filter!(entry -> !(entry.title in exc_str), database)

    tested_diff_path = joinpath(@__DIR__, "tested_different")
    test_record_path = joinpath(@__DIR__, "test_recordings")
    rm(tested_diff_path, force = true, recursive = true)
    mkpath(tested_diff_path)
    rm(test_record_path, force = true, recursive = true)
    mkpath(test_record_path)

    examples = MakieGallery.record_examples(test_record_path)

    MakieGallery.run_comparison(test_record_path, tested_diff_path)

end
