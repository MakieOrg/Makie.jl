# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie, Distributions
CairoMakie.activate!() # hide


N = 100_000
categories = rand(1:3, N)
values = rand(Uniform(-1, 5), N)

w = pdf.(Normal(), categories .- values)

fig = Figure()

violin(fig[1,1], categories, values)
violin(fig[1,2], categories, values, weights = w)

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d72052dc_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d72052dc.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
 # hide
nothing # hide