#!/usr/bin/julia
#####################
#       Notes       #
#####################
# Shadercleanup:
#   -> For now I will leave the shitty push! robj + pipeline situation as it is
#      to later implement a better way, redoing all the visualizes into also
#      returning what pipeline.
#   -> Reason why shader for heatmap doesn't compile is that it can't find certain things in the data!
#
# Renderingcleanup:
#   -> Right now the way that the screenbuffer is displayed to the plot window
#      requires there to be at least one pipeline is inside the pipelines of the Screen.
#      This should probably change.
#
# VertexArraycleanup:
#   -> Instancing is now done the other way around to what it should be.
#   -> Rewrite constructor
#
#
# generalcleanup:
#   -> So many speedups possible!
#
using Makie
begin
    large_sphere = Sphere(Point3f0(0), 1f0)
    positions = decompose(Point3f0, large_sphere)
    linepos = view(positions, rand(1:length(positions), 1000))
    scene = lines(linepos, linewidth = 0.1, color = :black)
    scatter!(scene, positions, strokewidth = 10, strokecolor = :white, color = RGBAf0(0.9, 0.2, 0.4, 0.6))
    scene
end
