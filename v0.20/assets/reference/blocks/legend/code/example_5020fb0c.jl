# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
ax = Axis(fig[1, 1])
lines!(ax, 1:10, linestyle = :dash, label = "Line")
poly!(ax, [(5, 0), (10, 0), (7.5, 5)], label = "Poly")
scatter!(ax, 4:13, label = "Scatter")
Legend(fig[1, 2], ax, "Default", nbanks = 2)
Legend(fig[1, 3], ax, "colgap = 40", nbanks = 2, colgap = 40)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5020fb0c_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5020fb0c.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5020fb0c.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide