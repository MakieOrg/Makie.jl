# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie, Distributions
CairoMakie.activate!() # hide


N = 100_000
x = rand(Uniform(-2, 2), N)

w = pdf.(Normal(), x)

fig = Figure()
density(fig[1,1], x)
density(fig[1,2], x, weights = w)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_3d7f991b_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_3d7f991b.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide