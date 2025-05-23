# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

using Random
Random.seed!(1234)

x = randn(100000)
y = randn(100000)

f = Figure()
hexbin(f[1, 1], x, y, bins = 40,
    axis = (aspect = DataAspect(), title = "colorscale = identity"))
hexbin(f[1, 2], x, y, bins = 40, colorscale=log10,
    axis = (aspect = DataAspect(), title = "colorscale = log10"))
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_d8283bcc_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_d8283bcc.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_d8283bcc.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide