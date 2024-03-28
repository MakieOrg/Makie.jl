# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    x = range(0, 10, length=100)

f, ax, l1 = lines(x, sin)
lines!(x, cos)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5eb66f5d_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5eb66f5d.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5eb66f5d.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide