using AbstractPlotting

using Test

include("quaternions.jl")

# if get(ENV, "IS_TRAVIS_CI", "false") == "false"
#   exit(0);
# end

## begin CI-only testing
# if get(ENV, "IS_TRAVIS_CI", "false") == "false"
#   exit(0);
# end

 ## begin CI-only testing=

using MakieGallery

 # Load the database
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

# combine all exceptions into a single Set
exc_str = union(ffmpeg_exs, glmakie_exs, gdal_exs, moderngl_exs, save_exs, color_exs, curl_exs)

# iterate over database
for i in 1:length(database)

   # skip if the title is in the list of exceptions
  if database[i].title ∈ exc_str

     print("Skipping " * database[i].title * "\n(removed from tests explicitly)\n")

     continue  # skip the entry

   end

   print("Running " * database[i].title * "\n(index $i)\n")

   MakieGallery.eval_example(database[i]);  # evaluate the entry

   end
