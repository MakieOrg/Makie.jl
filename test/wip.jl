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
#
#
#
# generalcleanup:
#   -> Put finalizer(free) for all the GLobjects!
#   -> So many speedups possible!
#
# What doesn't work:
#   -> poly colormap
#   -> contours
#   -> during the multiple polygon test, does the bottom circle get fully drawn?
using Makie

begin
    coordinates = [
        0.0 0.0;
        0.5 0.0;
        1.0 0.0;
        0.0 0.5;
        0.5 0.5;
        1.0 0.5;
        0.0 1.0;
        0.5 1.0;
        1.0 1.0;
    ]
    connectivity = [
        1 2 5;
        1 4 5;
        2 3 6;
        2 5 6;
        4 5 8;
        4 7 8;
        5 6 9;
        5 8 9;
    ]
    color = [0.0, 0.0, 0.0, 0.0, -0.675, 0.0, 0.0, 0.0,-0.675]
    poly(coordinates, connectivity, color = color, linecolor = (:black, 0.6), linewidth = 4, shading=false)
end

#this also does not work, putting shading =true shows some color.
begin
    mesh(
        [(0.0, 0.0), (0.5, 1.0), (1.0, 0.0)], color = [:red, :green, :blue],
        shading = false
    )
end

N = 10
r = [(rand(7, 2) .- 0.5) .* 25 for i = 1:N]
scene = scatter(r[1][:, 1], r[1][:, 2], markersize = 1, limits = FRect(-25/2, -25/2, 25, 25))
s = scene[end] # last plot in scene

record(scene, "test/tmp/blabla.mp4", r) do m
    s[1] = m[:, 1]
    s[2] = m[:, 2]
end
