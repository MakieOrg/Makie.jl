# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure(size = (800, 800))

Axis(f[1, 1], title = "No grid layout")
Axis(f[2, 1], title = "No grid layout")
Axis(f[3, 1], title = "No grid layout")

Axis(f[1, 2], title = "Inside", alignmode = Inside())
Axis(f[2, 2], title = "Outside", alignmode = Outside())
Axis(f[3, 2], title = "Outside(50)", alignmode = Outside(50))

[Box(f[i, 2], color = :transparent, strokecolor = :red) for i in 1:3]

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_4aa3dde5_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_4aa3dde5.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_4aa3dde5.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide