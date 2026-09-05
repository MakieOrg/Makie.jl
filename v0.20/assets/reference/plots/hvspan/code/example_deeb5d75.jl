# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

lines(0..20, sin)
vspan!([0, 2pi, 4pi], [pi, 3pi, 5pi],
    color = [(c, 0.2) for c in [:red, :orange, :pink]])
hspan!(-1.1, -0.9, color = (:blue, 0.2))
current_figure()
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_deeb5d75_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_deeb5d75.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_deeb5d75.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide