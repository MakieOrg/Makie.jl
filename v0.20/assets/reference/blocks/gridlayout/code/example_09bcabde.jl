# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

fig = Figure()

axs = [Axis(fig[i, j]) for i in 1:3, j in 1:3]
axs[1, 1].title = "Group A"
axs[1, 2].title = "Group B.1"
axs[1, 3].title = "Group B.2"

hidedecorations!.(axs, grid=false)

colgap!(fig.layout, 1, Relative(0.15))

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_09bcabde_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_09bcabde.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_09bcabde.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide