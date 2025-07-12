# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1], title = "My column has size Relative(2/3)")
Axis(f[1, 2], title = "My column has size Auto()")
Colorbar(f[1, 3])

colsize!(f.layout, 1, Relative(2/3))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_eda62b53_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_eda62b53.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_eda62b53.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide