# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure(size = (800, 800))

for i in 1:3, j in 1:3
    Axis(f[i, j])
end

Label(f[0, :], text = "First Supertitle", fontsize = 20)
Label(f[-1, :], text = "Second Supertitle", fontsize = 30)
Label(f[-2, :], text = "Third Supertitle", fontsize = 40)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_da9117dc_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_da9117dc.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_da9117dc.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide