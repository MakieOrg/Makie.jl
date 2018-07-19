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
    p1 = heatmap(rand(100, 100), interpolate = true)
    p2 = heatmap(rand(100, 100), interpolate = false)
    scene = AbstractPlotting.vbox(p1, p2)
    text!(campixel(p1), "Interpolate = true", position = widths(p1) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    text!(campixel(p2), "Interpolate = false", position = widths(p2) .* Vec(0.5, 1), align = (:center, :top), raw = true)
    scene
end
