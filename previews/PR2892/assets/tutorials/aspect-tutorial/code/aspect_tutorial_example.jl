# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    Box(f[1, 1], color = (:red, 0.2), strokewidth = 0)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "aspect_tutorial_example_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "aspect_tutorial_example.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "aspect_tutorial_example.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide