# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

x = range(0, 10, length=100)

colors = repeat([:crimson, :dodgerblue, :slateblue1, :sienna1, :orchid1], 20)

scatter(x, sin, color = colors, markersize = 20)
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_76f1aed3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_76f1aed3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_76f1aed3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide