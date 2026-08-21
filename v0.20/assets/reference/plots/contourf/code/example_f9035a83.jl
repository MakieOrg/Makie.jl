# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide


volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)

f = Figure(size = (800, 400))

Axis(f[1, 1], title = "Relative mode, drop lowest 30%")
contourf!(volcano, levels = 0.3:0.1:1, mode = :relative)

Axis(f[1, 2], title = "Normal mode")
contourf!(volcano, levels = 10)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f9035a83_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f9035a83.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f9035a83.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide