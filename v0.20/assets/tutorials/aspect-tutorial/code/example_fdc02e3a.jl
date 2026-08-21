# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure()
for i in 1:5, j in 1:5
    Axis(f[i, j], width = 150, height = 150)
end
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_fdc02e3a_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_fdc02e3a.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_fdc02e3a.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide