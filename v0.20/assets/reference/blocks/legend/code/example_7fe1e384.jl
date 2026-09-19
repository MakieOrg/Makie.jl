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
grid = GridLayout(fig[2, 1], tellwidth = false)
Legend(grid[1, 1], ax, "nbanks = 1", nbanks = 1,
    orientation = :horizontal, tellwidth = true)
Legend(grid[2, 1], ax, "nbanks = 2", nbanks = 2,
    orientation = :horizontal, tellwidth = true)
Legend(grid[:, 2], ax, "nbanks = 3", nbanks = 3,
    orientation = :horizontal, tellwidth = true)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_7fe1e384_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_7fe1e384.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_7fe1e384.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide