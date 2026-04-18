# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
using CairoMakie # hide
CairoMakie.activate!() # hide
fig = Figure()
Box(fig[1, 1], strokewidth = 1)
Box(fig[1, 2], strokewidth = 10)
Box(fig[1, 3], strokewidth = 0)
fig
end # hide
save(joinpath(@OUTPUT, "example_15431918423985766845.png"), __result; ) # hide
save(joinpath(@OUTPUT, "example_15431918423985766845.svg"), __result; ) # hide
nothing # hide