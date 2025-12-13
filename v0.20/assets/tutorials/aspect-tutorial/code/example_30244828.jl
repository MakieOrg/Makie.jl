# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    f = Figure(size = (800, 500))
ax = Axis(f[1, 1])
Colorbar(f[1, 2])
colsize!(f.layout, 1, Aspect(1, 1.0))
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_30244828_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_30244828.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_30244828.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide