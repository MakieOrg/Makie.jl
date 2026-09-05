# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide

f = Figure(fontsize = 24, fonts = (; regular = "Dejavu", weird = "Blackchancery"))
Axis(f[1, 1], title = "A title", xlabel = "An x label", xlabelfont = :weird)

f
end # hide
save(joinpath(@OUTPUT, "example_12399573883916472122.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_12399573883916472122.svg"), __result; ) # hide
nothing # hide