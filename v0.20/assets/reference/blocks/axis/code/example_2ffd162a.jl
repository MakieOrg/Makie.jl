# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
Axis(fig[1, 1], xticks = 1:10)
Axis(fig[2, 1], xticks = (1:2:9, ["A", "B", "C", "D", "E"]))
Axis(fig[3, 1], xticks = WilkinsonTicks(5))
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_2ffd162a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_2ffd162a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_2ffd162a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide