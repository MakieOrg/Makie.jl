# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str                       # hide
__result = begin                                       # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 30)
Label(
    f[1, 1],
    rich(
        "ITALIC",
        superscript("Regular without x offset", font = :regular),
        font = :italic
    )
)

Label(
    f[2, 1],
    rich(
        "ITALIC",
        superscript("Regular with x offset", font = :regular, offset = (0.15, 0)),
        font = :italic
    )
)

f
end                                                    # hide
sz = size(Makie.parent_scene(__result))                # hide
open(joinpath(@OUTPUT, "example_5a219a13_size.txt"), "w") do io # hide
    print(io, sz[1], " ", sz[2])                       # hide
end                                                    # hide
save(joinpath(@OUTPUT, "example_5a219a13.png"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
save(joinpath(@OUTPUT, "example_5a219a13.svg"), __result; px_per_unit = 2, pt_per_unit = 0.75, ) # hide
nothing # hide