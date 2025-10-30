# This file was generated, do not modify it. # hide
using Makie.LaTeXStrings: @L_str # hide
__result = begin # hide
    using CairoMakie
CairoMakie.activate!() # hide


f = Figure()
Axis(f[1, 1])

x = rand(200)
w = @. x^2 * (1 - x)^2
ecdfplot!(x)
ecdfplot!(x; weights = w, color=:orange)

f
end # hide
save(joinpath(@OUTPUT, "example_4633394883468088688.png"), __result; ) # hide

nothing # hide