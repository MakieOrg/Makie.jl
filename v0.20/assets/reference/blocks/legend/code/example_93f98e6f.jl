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
Legend(fig[1, 2], ax, "Default")
Legend(fig[1, 3], ax, "patchlabelgap
= 20", patchlabelgap = 20)
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_93f98e6f_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_93f98e6f.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_93f98e6f.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide