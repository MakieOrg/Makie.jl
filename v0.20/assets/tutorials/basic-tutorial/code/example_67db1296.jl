# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    x = range(0, 10, length=100)

f, ax, sc1 = scatter(x, sin, color = :red, markersize = 5)
sc2 = scatter!(ax, x, cos, color = :blue, markersize = 10)
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_67db1296_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_67db1296.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_67db1296.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide