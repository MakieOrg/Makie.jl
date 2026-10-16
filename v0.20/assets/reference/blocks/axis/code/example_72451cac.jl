# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure()

Axis(f[1, 1], ytickformat = values -> ["$(value)kg" for value in values])
Axis(f[1, 2], ytickformat = "{:.2f}ms")
Axis(f[1, 3], ytickformat = values -> [L"\sqrt{%$(value^2)}" for value in values])
Axis(f[1, 4], ytickformat = values -> [rich("$value", superscript("XY", color = :red))
                                       for value in values])

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_72451cac_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_72451cac.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_72451cac.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide