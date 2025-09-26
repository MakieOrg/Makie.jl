# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    x = range(0, 10, length=100)

f, ax, l1 = lines(x, sin, color = :tomato)
l2 = lines!(ax, x, cos, color = RGBf(0.2, 0.7, 0.9))
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_205e27a3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_205e27a3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_205e27a3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide