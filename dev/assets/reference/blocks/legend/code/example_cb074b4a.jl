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
Legend(fig[2, 1], ax, "orientation
= :horizontal", orientation = :horizontal)
Legend(fig[1, 2], ax, "orientation
= :vertical", orientation = :vertical)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_cb074b4a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_cb074b4a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_cb074b4a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide