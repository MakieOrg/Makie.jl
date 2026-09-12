# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()
ax = Axis(f[1, 1])

edges_x = 1:6
edges_y = 7:12
data = reshape(1:25, 5, 5)

heatmap!(ax, edges_x, edges_y, data)

scatter!(ax, [(x, y) for x in edges_x for y in edges_y], color=:white, strokecolor=:black, strokewidth=1)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_7b7cb9d3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_7b7cb9d3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide