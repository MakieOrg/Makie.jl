# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
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
end # hide
save(joinpath(@OUTPUT, "example_6494641544194656655.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_6494641544194656655.svg"), __result; ) # hide
nothing # hide