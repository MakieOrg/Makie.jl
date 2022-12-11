# This file was generated, do not modify it. # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide
Makie.inline!(true) # hide

ys = 2 .* randn(100) .+ 3

qqnorm(ys, qqline = :fitrobust)
end # hide
save(joinpath(@OUTPUT, "example_11755014972900713185.png"), __result; ) # hide

nothing # hide