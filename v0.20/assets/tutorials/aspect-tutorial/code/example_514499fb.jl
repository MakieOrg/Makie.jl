# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

set_theme!(backgroundcolor = :gray90)

f = Figure(size = (800, 500))
ax = Axis(f[1, 1], aspect = 1)
Colorbar(f[1, 2])
f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_514499fb_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_514499fb.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_514499fb.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide