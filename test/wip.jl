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
#   -> contours
#   -> during the multiple polygon test, does the bottom circle get fully drawn?
using Makie


begin
    function xy_data(x, y)
        r = sqrt(x*x + y*y)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    r = linspace(-1, 1, 100)
    contour3d(r, r, (x,y)-> xy_data(10x, 10y), levels = 20, linewidth = 3)
end
