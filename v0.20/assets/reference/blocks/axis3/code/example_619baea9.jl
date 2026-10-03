# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()

for (i, perspectiveness) in enumerate(range(0, 1, length = 6))
    ax = Axis3(fig[fldmod1(i, 3)...]; perspectiveness, protrusions = (0, 0, 0, 15),
        title = ":perspectiveness = $(perspectiveness)")
    hidedecorations!(ax)
end

fig
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_619baea9_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_619baea9.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_619baea9.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide