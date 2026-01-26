# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

g1 = GridLayout(f[1, 1], alignmode = Outside(15))
g2 = GridLayout(f[1, 2], alignmode = Outside(15))
box1 = Box(f[1, 1], cornerradius = 10, color = (:tomato, 0.5), strokecolor = :transparent)
box2 = Box(f[1, 2], cornerradius = 10, color = (:teal, 0.5), strokecolor = :transparent)

# move the boxes back so the Axis background polys are in front of them
Makie.translate!(box1.blockscene, 0, 0, -100)
Makie.translate!(box2.blockscene, 0, 0, -100)

Axis(g1[1, 1], backgroundcolor = :white)
Axis(g1[2, 1], backgroundcolor = :white)

Axis(g2[1, 1], backgroundcolor = :white)
Axis(g2[1, 2], backgroundcolor = :white)
Axis(g2[2, 1:2], backgroundcolor = :white)

Label(f[0, :], "Two boxes indicate groups of axes that belong together")

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_208b3552_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_208b3552.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide