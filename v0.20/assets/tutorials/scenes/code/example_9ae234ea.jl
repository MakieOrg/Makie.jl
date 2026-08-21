# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    GLMakie.activate!() # hide
campixel!(scene)
w, h = size(scene) # get the size of the scene in pixels
# this draws a line at the scene window boundary
image!(scene, [sin(i/w) + cos(j/h) for i in 1:w, j in 1:h])
scene
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_9ae234ea_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_9ae234ea.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide