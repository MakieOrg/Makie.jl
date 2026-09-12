# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide


f, ax, sc = scatter(1, 1, marker = 'A', markersize = 50)
text!(2, 1, text = "A", fontsize = 50, align = (:center, :center))
xlims!(ax, -1, 4)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c4786e91_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c4786e91.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c4786e91.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide