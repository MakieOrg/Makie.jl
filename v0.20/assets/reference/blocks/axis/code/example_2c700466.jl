# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
f = Figure(figure_padding = 50)

Axis(f[1, 1], xtickformat = values -> ["$(value)kg" for value in values])
Axis(f[2, 1], xtickformat = "{:.2f}ms")
Axis(f[3, 1], xtickformat = values -> [L"\sqrt{%$(value^2)}" for value in values])
Axis(f[4, 1], xtickformat = values -> [rich("$value", superscript("XY", color = :red))
                                       for value in values])

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_2c700466_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_2c700466.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_2c700466.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide