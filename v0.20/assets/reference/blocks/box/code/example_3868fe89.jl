# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
Box(fig[1, 1], strokecolor = :red)
Box(fig[1, 2], strokecolor = (:red, 0.5))
Box(fig[2, 1], strokecolor = RGBf(0.2, 0.5, 0.7))
Box(fig[2, 2], strokecolor = RGBAf(0.2, 0.5, 0.7, 0.5))
fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3868fe89_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3868fe89.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_3868fe89.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide