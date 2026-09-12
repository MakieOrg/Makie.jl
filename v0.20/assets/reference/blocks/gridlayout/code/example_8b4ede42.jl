# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1], title = "My column infers my width\nof 200 units")
Axis(f[1, 2], title = "My column gets 1/3rd\nof the remaining space")
Axis(f[1, 3], title = "My column gets 2/3rds\nof the remaining space")

colsize!(f.layout, 2, Auto(1)) # equivalent to Auto(true, 1)
colsize!(f.layout, 3, Auto(2)) # equivalent to Auto(true, 2)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_8b4ede42_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_8b4ede42.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_8b4ede42.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide