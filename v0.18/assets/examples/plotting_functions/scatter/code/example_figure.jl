# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
using DelimitedFiles
CairoMakie.activate!() # hide


a = readdlm(assetpath("airportlocations.csv"))

scatter(a[1:50:end, :], marker = '✈',
    markersize = 20, color = :black)
end # hide
save(joinpath(@OUTPUT, "example_12425206804685228712.png"), __result; ) # hide

nothing # hide