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
#   -> Really redo how attriblocations are assigned very error prone!
#   -> Rewrite constructor
#
#
# generalcleanup:
#   -> So many speedups possible!
#



using Makie


begin
    N = 30
    function xy_data(x, y)
        r = sqrt(x^2 + y^2)
        r == 0.0 ? 1f0 : (sin(r)/r)
    end
    lspace = linspace(-10, 10, N)
    z = Float32[xy_data(x, y) for x in lspace, y in lspace]
    range = linspace(0, 3, N)
    surface(
        range, range, z,
        colormap = :Spectral
    )
end
