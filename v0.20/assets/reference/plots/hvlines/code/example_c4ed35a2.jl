# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure()

ax1 = Axis(f[1, 1], title = "vlines")

lines!(ax1, 0..4pi, sin)
vlines!(ax1, [pi, 2pi, 3pi], color = :red)

ax2 = Axis(f[1, 2], title = "hlines")
hlines!(ax2, [1, 2, 3, 4], xmax = [0.25, 0.5, 0.75, 1], color = :blue)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_c4ed35a2_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_c4ed35a2.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_c4ed35a2.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide