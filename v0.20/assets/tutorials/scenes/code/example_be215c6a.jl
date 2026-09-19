# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    GLMakie.activate!() # hide
screen = display(scene) # use display, to get a reference to the screen object
depth_color = GLMakie.depthbuffer(screen)
close(screen)
# Look at result:
f, ax, pl = heatmap(depth_color)
Colorbar(f[1, 2], pl)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_be215c6a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_be215c6a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide