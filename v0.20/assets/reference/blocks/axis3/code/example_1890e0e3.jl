# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()

Axis3(fig[1, 1], aspect = (1, 1, 1), title = "aspect = (1, 1, 1)")
Axis3(fig[1, 2], aspect = (2, 1, 1), title = "aspect = (2, 1, 1)")
Axis3(fig[2, 1], aspect = (1, 2, 1), title = "aspect = (1, 2, 1)")
Axis3(fig[2, 2], aspect = (1, 1, 2), title = "aspect = (1, 1, 2)")

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_1890e0e3_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_1890e0e3.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_1890e0e3.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide