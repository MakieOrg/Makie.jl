# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie

f = Figure()

Axis(f[1, 1], title = "I'm square and aligned")
Box(f[1, 2], color = (:blue, 0.1), strokecolor = :transparent)
Axis(f[1, 2], aspect = AxisAspect(1),
    title = "I'm square but break the layout.\nMy actual cell is the blue rect.")
Axis(f[2, 1])
Axis(f[2, 2])

rowsize!(f.layout, 2, Relative(2/3))
colsize!(f.layout, 1, Aspect(1, 1))

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_f34a4bcb_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_f34a4bcb.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_f34a4bcb.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide