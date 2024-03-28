# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1])

xs = 0:0.1:10
lins = [lines!(xs, sin.(xs .+ 3v), color = RGBf(v, 0, 1-v)) for v in 0:0.1:1]

Legend(f[1, 2], lins, string.(1:length(lins)), nbanks = 3)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_332ec270_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_332ec270.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_332ec270.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide