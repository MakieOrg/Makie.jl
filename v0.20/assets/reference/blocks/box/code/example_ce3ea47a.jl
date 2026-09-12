# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
Box(fig[1, 1], cornerradius = 0)
Box(fig[1, 2], cornerradius = 20)
Box(fig[1, 3], cornerradius = (0, 10, 20, 30))
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_ce3ea47a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_ce3ea47a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_ce3ea47a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide