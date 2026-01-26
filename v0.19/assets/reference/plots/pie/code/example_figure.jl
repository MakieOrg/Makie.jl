# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f, ax, plt = pie([π/2, 2π/3, π/4],
                normalize=false,
                offset = π/2,
                color = [:orange, :purple, :green],
                axis = (autolimitaspect = 1,)
                )

f
end # hide
save(joinpath(@OUTPUT, "example_9649408673783848679.png"), __result; ) # hide

nothing # hide