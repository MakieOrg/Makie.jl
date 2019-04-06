using AbstractPlotting

using Test

include("quaternions.jl")

# if get(ENV, "IS_TRAVIS_CI", "false") == "false"
#   exit(0);
# end

## begin CI-only testing

using MakieGallery

database = MakieGallery.load_database()

ffmpeg_exs  = [
                "Animation", "Lots of Heatmaps","Animated Scatter",
                "Chess Game", "Record Video",  "Animated surface and wireframe",
                "Moire", "pong", "pulsing marker", "Travelling wave",
                "Type recipe for molecule simulation"

]

glmakie_exs = [
                "Textured Mesh", "Load Mesh", "Wireframe of a Mesh",
                "FEM mesh 3D", "Normals of a Cat", "Line GIF"
]

gdal_exs = ["WorldClim visualization"]

moderngl_exs = ["Explicit frame rendering"]

save_exs = ["Axis theming", "Labels", "Color Legend"]      # probably display scene at the end, should be changed?

color_exs = ["Stepper demo", "colormaps"]  # hopefullly fixed by next tag of MakieGallery

curl_exs = ["Earth & Ships"]

exc_str = cat(ffmpeg_exs, glmakie_exs, gdal_exs, moderngl_exs, save_exs, color_exs, curl_exs, dims=1)

for i in 1:length(database)

  if database[i].title ∈ exc_str

    print("Skipping " * database[i].title * "\n(removed from tests explicitly)\n")

    continue

  end

  try

    print("Running " * database[i].title * "\n(index $i)\n")

    MakieGallery.eval_example(database[i]);

  catch err

    if isa(err, ArgumentError)

      print(err)

      @warn("Test " * database[i].title * " used an unloaded package." * "\nPerhaps it needs to be added to `Project.toml`?")

    else

        throw(err) # throw that error - it's not a Pkg error

    end

  end
end

# TODO write some AbstractPlotting specific tests... So far functionality is tested in Makie.jl
