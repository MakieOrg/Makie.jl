# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

fig = Figure()
ax1, l1 = lines(fig[1, 1], 0..10, sin, color = :red)
ax2, l2 = lines(fig[2, 1], 0..10, cos, color = :blue)
Legend(fig[1:2, 2], [l1, l2], ["sin", "cos"])
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_e51a7527_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_e51a7527.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_e51a7527.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide