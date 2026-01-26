# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


ys = 2 .* randn(100) .+ 3

qqnorm(ys, qqline = :fitrobust)
end # hide
save(joinpath(@OUTPUT, "example_9691093552756571072.png"), __result; ) # hide

nothing # hide