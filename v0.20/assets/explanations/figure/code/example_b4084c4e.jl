# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
pos = f[1, 1]
scatter(pos, rand(100, 2))

pos2 = f[1, 2]
lines(pos2, cumsum(randn(100)))

# you don't have to store the position in a variable first, of course
heatmap(f[1, 3], randn(10, 10))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_b4084c4e_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_b4084c4e.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide